import CloudKit
import Foundation

struct CloudKitDiagnostics {
    let containerIdentifier: String
    let accountStatus: String
    let ownerIDLine: String
    let dogFetchLine: String
    let inviteLookupLine: String
}

enum CloudKitDogServiceError: LocalizedError {
    case invalidInviteCode
    case missingDogSelection
    case inviteCodeGenerationFailed
    case emptyDogName
    case duplicateDogName
    case dogNotFound
    case noICloudAccount
    case iCloudRestricted
    case iCloudTemporarilyUnavailable
    case iCloudStatusUnknown

    var errorDescription: String? {
        switch self {
        case .invalidInviteCode:
            return "That invite code didn't lead to a dog. Check the six-character code and try again."
        case .missingDogSelection:
            return "Pick a dog before logging poops."
        case .inviteCodeGenerationFailed:
            return "Couldn't generate a unique invite code right now."
        case .emptyDogName:
            return "Give the dog a name before founding the poop empire."
        case .duplicateDogName:
            return "You already have a dog with that name in your crew."
        case .dogNotFound:
            return "That dog could not be found in CloudKit anymore."
        case .noICloudAccount:
            return "This iPhone is not signed into iCloud for CloudKit yet. Open Settings, sign into iCloud on this device, then try again."
        case .iCloudRestricted:
            return "CloudKit is restricted on this device. Check Screen Time, MDM, or parental restrictions for iCloud access."
        case .iCloudTemporarilyUnavailable:
            return "CloudKit is temporarily unavailable on this device. Give it a moment, then try again."
        case .iCloudStatusUnknown:
            return "CloudKit could not confirm this device's iCloud status yet. Try again in a moment."
        }
    }
}

struct CloudKitDogService {
    static let containerIdentifier = "iCloud.com.codex.Pooppy"

    private let container = CKContainer(identifier: Self.containerIdentifier)
    private var database: CKDatabase { container.publicCloudDatabase }

    func fetchDiagnostics(ownerID: String?, inviteCode: String?) async -> CloudKitDiagnostics {
        let accountStatusLine: String

        do {
            let status = try await container.accountStatus()
            accountStatusLine = Self.describe(status: status)
        } catch {
            accountStatusLine = "error: \(error.localizedDescription)"
        }

        let ownerIDLine = ownerID.map { "owner id present (\($0.prefix(8)))" } ?? "missing owner id"

        let dogFetchLine: String
        if let ownerID {
            do {
                let dogs = try await fetchDogs(for: ownerID)
                dogFetchLine = "ok: \(dogs.count) dog(s)"
            } catch {
                dogFetchLine = "error: \(error.pooppyCloudKitMessage)"
            }
        } else {
            dogFetchLine = "skipped: no owner id"
        }

        let inviteLookupLine: String
        let cleanedInvite = inviteCode?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() ?? ""
        if cleanedInvite.isEmpty {
            inviteLookupLine = "skipped: no invite code"
        } else {
            do {
                let record = try await fetchDogRecord(inviteCode: cleanedInvite)
                inviteLookupLine = record == nil ? "not found for \(cleanedInvite)" : "found invite \(cleanedInvite)"
            } catch {
                inviteLookupLine = "error: \(error.pooppyCloudKitMessage)"
            }
        }

        return CloudKitDiagnostics(
            containerIdentifier: Self.containerIdentifier,
            accountStatus: accountStatusLine,
            ownerIDLine: ownerIDLine,
            dogFetchLine: dogFetchLine,
            inviteLookupLine: inviteLookupLine
        )
    }

    func ensureAccountReady() async throws {
        let status = try await container.accountStatus()

        switch status {
        case .available:
            return
        case .noAccount:
            throw CloudKitDogServiceError.noICloudAccount
        case .restricted:
            throw CloudKitDogServiceError.iCloudRestricted
        case .temporarilyUnavailable:
            throw CloudKitDogServiceError.iCloudTemporarilyUnavailable
        case .couldNotDetermine:
            throw CloudKitDogServiceError.iCloudStatusUnknown
        @unknown default:
            throw CloudKitDogServiceError.iCloudStatusUnknown
        }
    }

    func fetchDogs(for ownerID: String) async throws -> [DogAccount] {
        try await ensureAccountReady()
        let predicate = NSPredicate(format: "ANY ownerIDs == %@", ownerID)
        let query = CKQuery(recordType: "DogAccount", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        return try await performDogQuery(query)
    }

    func createDog(named name: String, ownerID: String, ownerDisplayName: String?) async throws -> DogAccount {
        try await ensureAccountReady()
        let cleanedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedName.isEmpty else {
            throw CloudKitDogServiceError.emptyDogName
        }

        let existingDogs = try await fetchDogs(for: ownerID)
        if existingDogs.contains(where: { $0.name.compare(cleanedName, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame }) {
            throw CloudKitDogServiceError.duplicateDogName
        }

        let inviteCode = try await generateUniqueInviteCode()
        let record = CKRecord(recordType: "DogAccount")
        record["name"] = cleanedName as CKRecordValue
        record["inviteCode"] = inviteCode as CKRecordValue
        record["ownerIDs"] = [ownerID] as CKRecordValue
        record["ownerDisplayNames"] = ownerDisplayName.map { [$0] as CKRecordValue }
        record["createdAt"] = Date() as CKRecordValue
        record["coatColorName"] = DogColorName.white.rawValue as CKRecordValue
        record["earStyle"] = DogEarStyle.floppy.rawValue as CKRecordValue
        record["leftEarColorName"] = DogColorName.white.rawValue as CKRecordValue
        record["rightEarColorName"] = DogColorName.white.rawValue as CKRecordValue
        record["noseColorName"] = DogColorName.charcoal.rawValue as CKRecordValue
        let saved = try await database.save(record)
        return makeDog(from: saved)
    }

    func joinDog(inviteCode: String, ownerID: String, ownerDisplayName: String?) async throws -> DogAccount {
        try await ensureAccountReady()
        guard let record = try await fetchDogRecord(inviteCode: inviteCode) else {
            throw CloudKitDogServiceError.invalidInviteCode
        }

        var ownerIDs = record["ownerIDs"] as? [String] ?? []
        var ownerDisplayNames = record["ownerDisplayNames"] as? [String] ?? []

        if !ownerIDs.contains(ownerID) {
            ownerIDs.append(ownerID)
            record["ownerIDs"] = ownerIDs as CKRecordValue

            if let ownerDisplayName, !ownerDisplayName.isEmpty, !ownerDisplayNames.contains(ownerDisplayName) {
                ownerDisplayNames.append(ownerDisplayName)
                record["ownerDisplayNames"] = ownerDisplayNames as CKRecordValue
            }
        }

        let saved = try await database.save(record)
        return makeDog(from: saved)
    }

    func fetchEntries(dogID: String) async throws -> [PoopEntry] {
        try await ensureAccountReady()
        let predicate = NSPredicate(format: "dogID == %@", dogID)
        let query = CKQuery(recordType: "PoopEntry", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        let result = try await database.records(matching: query)

        return try result.matchResults.compactMap { _, recordResult in
            let record = try recordResult.get()
            return try makeEntry(from: record)
        }
    }

    func saveDog(_ dog: DogAccount) async throws -> DogAccount {
        try await ensureAccountReady()
        let recordID = CKRecord.ID(recordName: dog.id)
        let record = try await database.record(for: recordID)
        record["name"] = dog.name as CKRecordValue
        record["inviteCode"] = dog.inviteCode as CKRecordValue
        record["ownerIDs"] = dog.ownerIDs as CKRecordValue
        record["ownerDisplayNames"] = dog.ownerDisplayNames as CKRecordValue
        record["createdAt"] = dog.createdAt as CKRecordValue
        record["coatColorName"] = dog.coatColorName.rawValue as CKRecordValue
        record["earStyle"] = dog.earStyle.rawValue as CKRecordValue
        record["leftEarColorName"] = dog.leftEarColorName.rawValue as CKRecordValue
        record["rightEarColorName"] = dog.rightEarColorName.rawValue as CKRecordValue
        record["noseColorName"] = dog.noseColorName.rawValue as CKRecordValue

        let saved = try await database.save(record)
        return makeDog(from: saved)
    }

    func saveEntry(_ entry: PoopEntry, dogID: String) async throws -> PoopEntry {
        try await ensureAccountReady()
        let recordID = CKRecord.ID(recordName: entry.id.uuidString)
        let record = CKRecord(recordType: "PoopEntry", recordID: recordID)
        record["dogID"] = dogID as CKRecordValue
        record["rating"] = entry.rating as CKRecordValue
        record["timestamp"] = entry.timestamp as CKRecordValue
        record["latitude"] = entry.latitude as CKRecordValue?
        record["longitude"] = entry.longitude as CKRecordValue?
        record["altitudeMeters"] = entry.altitudeMeters as CKRecordValue?
        record["placeName"] = entry.placeName as CKRecordValue?
        record["cityName"] = entry.cityName as CKRecordValue?
        record["regionName"] = entry.regionName as CKRecordValue?
        record["countryName"] = entry.countryName as CKRecordValue?
        record["continentName"] = entry.continentName as CKRecordValue?
        record["review"] = entry.review as CKRecordValue?
        record["weatherSummary"] = entry.weatherSummary as CKRecordValue?
        record["weatherConditionName"] = entry.weatherConditionName as CKRecordValue?
        record["temperatureCelsius"] = entry.temperatureCelsius as CKRecordValue?

        let saved = try await database.save(record)
        return try makeEntry(from: saved)
    }

    func deleteEntry(id: UUID) async throws {
        try await ensureAccountReady()
        _ = try await database.deleteRecord(withID: CKRecord.ID(recordName: id.uuidString))
    }

    func deleteDog(_ dog: DogAccount, ownerID: String, ownerDisplayName: String?) async throws {
        try await ensureAccountReady()
        let recordID = CKRecord.ID(recordName: dog.id)
        let record = try await database.record(for: recordID)
        var ownerIDs = record["ownerIDs"] as? [String] ?? []
        var ownerDisplayNames = record["ownerDisplayNames"] as? [String] ?? []

        ownerIDs.removeAll { $0 == ownerID }
        if let ownerDisplayName, !ownerDisplayName.isEmpty {
            ownerDisplayNames.removeAll { $0 == ownerDisplayName }
        }

        if !ownerIDs.isEmpty {
            record["ownerIDs"] = ownerIDs as CKRecordValue
            record["ownerDisplayNames"] = ownerDisplayNames as CKRecordValue
            _ = try await database.save(record)
            return
        }

        let entries = try await fetchEntries(dogID: dog.id)
        for entry in entries {
            try await deleteEntry(id: entry.id)
        }

        _ = try await database.deleteRecord(withID: recordID)
    }

    private func performDogQuery(_ query: CKQuery) async throws -> [DogAccount] {
        let result = try await database.records(matching: query)
        return try result.matchResults.compactMap { _, recordResult in
            let record = try recordResult.get()
            return makeDog(from: record)
        }
    }

    private func fetchDogRecord(inviteCode: String) async throws -> CKRecord? {
        let predicate = NSPredicate(format: "inviteCode == %@", inviteCode.uppercased())
        let query = CKQuery(recordType: "DogAccount", predicate: predicate)
        let result = try await database.records(matching: query)
        return try result.matchResults.first.map { _, recordResult in
            try recordResult.get()
        }
    }

    private func generateUniqueInviteCode() async throws -> String {
        for _ in 0..<10 {
            let code = Self.randomInviteCode()
            if try await fetchDogRecord(inviteCode: code) == nil {
                return code
            }
        }

        throw CloudKitDogServiceError.inviteCodeGenerationFailed
    }

    private func makeDog(from record: CKRecord) -> DogAccount {
        let legacyEarColor = DogColorName(rawValue: record["earColorName"] as? String ?? "") ?? .white
        return DogAccount(
            id: record.recordID.recordName,
            name: record["name"] as? String ?? "Unnamed Dog",
            inviteCode: record["inviteCode"] as? String ?? "",
            ownerIDs: record["ownerIDs"] as? [String] ?? [],
            ownerDisplayNames: record["ownerDisplayNames"] as? [String] ?? [],
            createdAt: record["createdAt"] as? Date ?? .now,
            coatColorName: DogColorName(rawValue: record["coatColorName"] as? String ?? "") ?? .white,
            earStyle: DogEarStyle(rawValue: record["earStyle"] as? String ?? "") ?? .floppy,
            leftEarColorName: DogColorName(rawValue: record["leftEarColorName"] as? String ?? "") ?? legacyEarColor,
            rightEarColorName: DogColorName(rawValue: record["rightEarColorName"] as? String ?? "") ?? legacyEarColor,
            noseColorName: DogColorName(rawValue: record["noseColorName"] as? String ?? "") ?? .charcoal
        )
    }

    private func makeEntry(from record: CKRecord) throws -> PoopEntry {
        let ratingValue = record["rating"] as? Int ?? Int(record["rating"] as? Int64 ?? 0)
        let timestamp = record["timestamp"] as? Date ?? .now

        return PoopEntry(
            id: UUID(uuidString: record.recordID.recordName) ?? UUID(),
            rating: ratingValue,
            timestamp: timestamp,
            latitude: record["latitude"] as? Double,
            longitude: record["longitude"] as? Double,
            altitudeMeters: record["altitudeMeters"] as? Double,
            placeName: record["placeName"] as? String,
            cityName: record["cityName"] as? String,
            regionName: record["regionName"] as? String,
            countryName: record["countryName"] as? String,
            continentName: record["continentName"] as? String,
            review: record["review"] as? String,
            weatherSummary: record["weatherSummary"] as? String,
            weatherConditionName: record["weatherConditionName"] as? String,
            temperatureCelsius: record["temperatureCelsius"] as? Double
        )
    }

    private static func randomInviteCode() -> String {
        let letters = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<6).map { _ in letters.randomElement()! })
    }

    private static func describe(status: CKAccountStatus) -> String {
        switch status {
        case .available:
            return "available"
        case .noAccount:
            return "noAccount"
        case .restricted:
            return "restricted"
        case .temporarilyUnavailable:
            return "temporarilyUnavailable"
        case .couldNotDetermine:
            return "couldNotDetermine"
        @unknown default:
            return "unknown"
        }
    }
}

extension Error {
    var pooppyCloudKitMessage: String {
        guard let ckError = self as? CKError else {
            return localizedDescription
        }

        switch ckError.code {
        case .badContainer, .badDatabase:
            return "CloudKit is still warming up for \(CloudKitDogService.containerIdentifier). Give Apple a moment, then try again."
        case .unknownItem:
            return "CloudKit could not find the expected schema yet. Double-check the DogAccount and PoopEntry record types in the Development environment."
        case .permissionFailure, .notAuthenticated:
            return "Cloud access is not fully ready on this device yet. Check iCloud sign-in and try again."
        case .networkFailure, .networkUnavailable:
            return "CloudKit had a network wobble. Try again in a moment."
        default:
            return ckError.localizedDescription
        }
    }
}
