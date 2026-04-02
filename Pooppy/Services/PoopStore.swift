import CoreLocation
import Foundation
import WeatherKit

@MainActor
final class PoopStore: ObservableObject {
    @Published private(set) var entries: [PoopEntry] = []
    @Published private(set) var archivedEntries: [ArchivedPoopEntry] = []
    @Published private(set) var dogAccounts: [DogAccount] = []
    @Published private(set) var selectedDog: DogAccount?
    @Published var statusMessage: String?
    @Published var isWorking = false
    @Published private(set) var cloudDiagnostics: CloudKitDiagnostics?
    @Published private(set) var currentWeatherSnapshot: PoopWeatherSnapshot?
    @Published private(set) var weatherStatusMessage: String?

    private let cloudService = CloudKitDogService()
    private let placeNameResolver = PlaceNameResolver()
    private let weatherService = PoopWeatherService()
    private let defaults = UserDefaults.standard
    private let selectedDogKey = "pooppy.selectedDogID"
    private let archivedEntriesKey = "pooppy.archivedEntries"
    private var pendingRefreshDogID: String?
    private var appearanceSaveTask: Task<Void, Never>?

    private var ownerID: String?
    private var ownerDisplayName: String?

    init() {
        loadArchivedEntries()
        purgeExpiredArchivedEntries()
    }

    func configure(ownerID: String, ownerDisplayName: String?) async {
        let shouldReload = self.ownerID != ownerID || dogAccounts.isEmpty
        self.ownerID = ownerID
        self.ownerDisplayName = ownerDisplayName

        if shouldReload {
            await loadDogs()
        }
    }

    func reset() {
        entries = []
        archivedEntries = []
        dogAccounts = []
        selectedDog = nil
        ownerID = nil
        ownerDisplayName = nil
        statusMessage = nil
        defaults.removeObject(forKey: selectedDogKey)
        defaults.removeObject(forKey: archivedEntriesKey)
    }

    func loadDogs() async {
        guard let ownerID else { return }
        isWorking = true
        defer { isWorking = false }

        do {
            let dogs = try await cloudService.fetchDogs(for: ownerID)
            dogAccounts = dogs

            let savedDogID = defaults.string(forKey: selectedDogKey)
            if let savedDogID, let matchedDog = dogs.first(where: { $0.id == savedDogID }) {
                selectedDog = matchedDog
            } else if selectedDog == nil {
                selectedDog = dogs.first
            } else if let currentID = selectedDog?.id {
                selectedDog = dogs.first(where: { $0.id == currentID }) ?? dogs.first
            }

            if let selectedDog {
                defaults.set(selectedDog.id, forKey: selectedDogKey)
                await refreshEntries()
            } else {
                entries = []
            }
        } catch {
            statusMessage = error.pooppyCloudKitMessage
        }
    }

    func createDog(named name: String) async {
        guard let ownerID else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            statusMessage = CloudKitDogServiceError.emptyDogName.localizedDescription
            return
        }

        isWorking = true
        defer { isWorking = false }

        do {
            let dog = try await cloudService.createDog(
                named: trimmed,
                ownerID: ownerID,
                ownerDisplayName: ownerDisplayName
            )
            dogAccounts.append(dog)
            dogAccounts.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            selectDog(dog)
            statusMessage = "Meet \(dog.name), now accepting legendary deposits. Invite code: \(dog.inviteCode)"
        } catch {
            statusMessage = error.pooppyCloudKitMessage
        }
    }

    func joinDog(inviteCode: String) async {
        guard let ownerID else { return }
        let cleanedCode = inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !cleanedCode.isEmpty else {
            statusMessage = "Paste a six-character invite code and we'll open the poop gates."
            return
        }

        isWorking = true
        defer { isWorking = false }

        do {
            let dog = try await cloudService.joinDog(
                inviteCode: cleanedCode,
                ownerID: ownerID,
                ownerDisplayName: ownerDisplayName
            )
            if let existingIndex = dogAccounts.firstIndex(where: { $0.id == dog.id }) {
                dogAccounts[existingIndex] = dog
            } else {
                dogAccounts.append(dog)
                dogAccounts.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            }
            selectDog(dog)
            statusMessage = "Joined \(dog.name). The shared poop ledger awaits."
        } catch {
            statusMessage = error.pooppyCloudKitMessage
        }
    }

    func selectDog(_ dog: DogAccount) {
        selectedDog = dog
        defaults.set(dog.id, forKey: selectedDogKey)
        purgeExpiredArchivedEntries()

        Task {
            await refreshEntries()
        }
    }

    func refreshFromCloud() async {
        await loadDogs()
    }

    func refreshCloudDiagnostics(inviteCode: String? = nil) async {
        cloudDiagnostics = await cloudService.fetchDiagnostics(ownerID: ownerID, inviteCode: inviteCode)
    }

    func previewSelectedDogAppearance(
        coatColorName: DogColorName,
        earStyle: DogEarStyle,
        leftEarColorName: DogColorName,
        rightEarColorName: DogColorName,
        noseColorName: DogColorName
    ) {
        guard var selectedDog else { return }

        selectedDog.coatColorName = coatColorName
        selectedDog.earStyle = earStyle
        selectedDog.leftEarColorName = leftEarColorName
        selectedDog.rightEarColorName = rightEarColorName
        selectedDog.noseColorName = noseColorName

        self.selectedDog = selectedDog
        if let index = dogAccounts.firstIndex(where: { $0.id == selectedDog.id }) {
            dogAccounts[index] = selectedDog
        }
    }

    func queueSelectedDogAppearanceSave(
        coatColorName: DogColorName,
        earStyle: DogEarStyle,
        leftEarColorName: DogColorName,
        rightEarColorName: DogColorName,
        noseColorName: DogColorName
    ) {
        previewSelectedDogAppearance(
            coatColorName: coatColorName,
            earStyle: earStyle,
            leftEarColorName: leftEarColorName,
            rightEarColorName: rightEarColorName,
            noseColorName: noseColorName
        )
        appearanceSaveTask?.cancel()
        appearanceSaveTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            if Task.isCancelled { return }
            await persistSelectedDogAppearance()
        }
    }

    private func persistSelectedDogAppearance() async {
        guard let selectedDog else { return }

        do {
            let savedDog = try await cloudService.saveDog(selectedDog)
            self.selectedDog = savedDog
            if let index = dogAccounts.firstIndex(where: { $0.id == savedDog.id }) {
                dogAccounts[index] = savedDog
            }
            statusMessage = "\(savedDog.name) received a fresh royal makeover."
        } catch {
            statusMessage = error.pooppyCloudKitMessage
        }
    }

    func refreshEntries() async {
        guard let selectedDog else {
            entries = []
            pendingRefreshDogID = nil
            return
        }

        if pendingRefreshDogID == selectedDog.id {
            return
        }

        pendingRefreshDogID = selectedDog.id
        defer { pendingRefreshDogID = nil }
        purgeExpiredArchivedEntries()

        do {
            entries = try await cloudService.fetchEntries(dogID: selectedDog.id)
            Task {
                await refreshMissingPlaceNames()
            }
        } catch {
            statusMessage = error.pooppyCloudKitMessage
        }
    }

    func addEntry(rating: Int, latitude: Double?, longitude: Double?, altitudeMeters: Double?) async -> PoopEntry? {
        guard let selectedDog else {
            statusMessage = CloudKitDogServiceError.missingDogSelection.localizedDescription
            return nil
        }

        let clampedRating = min(max(rating, 1), 5)
        let timestamp = Date.now
        let placeSnapshot = await resolvedPlaceSnapshot(latitude: latitude, longitude: longitude)
        let placeName = placeSnapshot?.displayName
        let weatherSnapshot = await fetchWeatherSnapshot(latitude: latitude, longitude: longitude, surfaceFailure: false)
        let gapSincePrevious = entries.first.map { timestamp.timeIntervalSince($0.timestamp) }
        var entry = PoopEntry(
            rating: clampedRating,
            timestamp: timestamp,
            latitude: latitude,
            longitude: longitude,
            altitudeMeters: altitudeMeters,
            placeName: placeName,
            cityName: placeSnapshot?.cityName,
            regionName: placeSnapshot?.regionName,
            countryName: placeSnapshot?.countryName,
            continentName: placeSnapshot?.continentName,
            review: nil,
            weatherSummary: weatherSnapshot?.summary,
            weatherConditionName: weatherSnapshot?.conditionName,
            temperatureCelsius: weatherSnapshot?.temperatureCelsius
        )
        let prospectiveEntries = [entry] + entries
        entry.review = PoopReviewComposer.review(
            for: clampedRating,
            at: timestamp,
            placeName: placeName,
            cityName: placeSnapshot?.cityName,
            regionName: placeSnapshot?.regionName,
            countryName: placeSnapshot?.countryName,
            continentName: placeSnapshot?.continentName,
            weatherSummary: weatherSnapshot?.summary,
            temperatureCelsius: weatherSnapshot?.temperatureCelsius,
            altitudeMeters: altitudeMeters,
            gapSincePrevious: gapSincePrevious,
            badgeHint: PoopBadgeEngine.badgeNarrative(previousEntries: entries, updatedEntries: prospectiveEntries)
        )

        do {
            let savedEntry = try await cloudService.saveEntry(entry, dogID: selectedDog.id)
            entries.insert(savedEntry, at: 0)
            entries.sort { $0.timestamp > $1.timestamp }
            if let weatherSnapshot {
                currentWeatherSnapshot = weatherSnapshot
                weatherStatusMessage = nil
            }
            return savedEntry
        } catch {
            statusMessage = error.pooppyCloudKitMessage
            return nil
        }
    }

    func updateEntry(id: UUID, rating: Int, timestamp: Date, latitude: Double?, longitude: Double?) async {
        guard let selectedDog, let existingEntry = entries.first(where: { $0.id == id }) else {
            return
        }

        var updatedEntry = existingEntry
        updatedEntry.rating = min(max(rating, 1), 5)
        updatedEntry.timestamp = timestamp
        let locationChanged = updatedEntry.latitude != latitude || updatedEntry.longitude != longitude
        updatedEntry.latitude = latitude
        updatedEntry.longitude = longitude
        if locationChanged {
            let placeSnapshot = await resolvedPlaceSnapshot(latitude: latitude, longitude: longitude)
            let weatherSnapshot = await fetchWeatherSnapshot(latitude: latitude, longitude: longitude, surfaceFailure: false)
            if latitude == nil || longitude == nil {
                updatedEntry.altitudeMeters = nil
            }
            updatedEntry.placeName = placeSnapshot?.displayName
            updatedEntry.cityName = placeSnapshot?.cityName
            updatedEntry.regionName = placeSnapshot?.regionName
            updatedEntry.countryName = placeSnapshot?.countryName
            updatedEntry.continentName = placeSnapshot?.continentName
            updatedEntry.weatherSummary = weatherSnapshot?.summary
            updatedEntry.weatherConditionName = weatherSnapshot?.conditionName
            updatedEntry.temperatureCelsius = weatherSnapshot?.temperatureCelsius
        }
        let gapSincePrevious = entries
            .filter { $0.id != id && $0.timestamp < timestamp }
            .sorted { $0.timestamp > $1.timestamp }
            .first
            .map { timestamp.timeIntervalSince($0.timestamp) }
        let prospectiveEntries = ([updatedEntry] + entries.filter { $0.id != id }).sorted { $0.timestamp > $1.timestamp }
        updatedEntry.review = PoopReviewComposer.review(
            for: updatedEntry.rating,
            at: timestamp,
            placeName: updatedEntry.placeName,
            cityName: updatedEntry.cityName,
            regionName: updatedEntry.regionName,
            countryName: updatedEntry.countryName,
            continentName: updatedEntry.continentName,
            weatherSummary: updatedEntry.weatherSummary,
            temperatureCelsius: updatedEntry.temperatureCelsius,
            altitudeMeters: updatedEntry.altitudeMeters,
            gapSincePrevious: gapSincePrevious,
            badgeHint: PoopBadgeEngine.badgeNarrative(previousEntries: entries, updatedEntries: prospectiveEntries)
        )

        do {
            let savedEntry = try await cloudService.saveEntry(updatedEntry, dogID: selectedDog.id)
            if let index = entries.firstIndex(where: { $0.id == id }) {
                entries[index] = savedEntry
                entries.sort { $0.timestamp > $1.timestamp }
            }
        } catch {
            statusMessage = error.pooppyCloudKitMessage
        }
    }

    func deleteEntry(id: UUID) async {
        guard let selectedDog, let entry = entries.first(where: { $0.id == id }) else {
            return
        }

        do {
            try await cloudService.deleteEntry(id: id)
            archiveEntry(entry, dogID: selectedDog.id)
            entries.removeAll { $0.id == id }
            statusMessage = "Poop log archived for 24 hours in case that delete was an oopsie."
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func restoreArchivedEntry(id: UUID) async {
        guard let selectedDog, let archivedEntry = archivedEntries.first(where: { $0.id == id && $0.dogID == selectedDog.id }) else {
            return
        }

        guard !archivedEntry.isExpired else {
            purgeExpiredArchivedEntries()
            statusMessage = "That rescue window has closed. The poop has left the building."
            return
        }

        do {
            let restoredEntry = try await cloudService.saveEntry(archivedEntry.entry, dogID: archivedEntry.dogID)
            entries.insert(restoredEntry, at: 0)
            entries.sort { $0.timestamp > $1.timestamp }
            archivedEntries.removeAll { $0.id == id }
            persistArchivedEntries()
            statusMessage = "Poop log restored. Justice has been served."
        } catch {
            statusMessage = error.pooppyCloudKitMessage
        }
    }

    var currentDogArchivedEntries: [ArchivedPoopEntry] {
        guard let selectedDog else { return [] }
        return archivedEntries
            .filter { $0.dogID == selectedDog.id && !$0.isExpired }
            .sorted { $0.deletedAt > $1.deletedAt }
    }

    func deleteSelectedDog() async {
        guard let selectedDog, let ownerID else {
            statusMessage = CloudKitDogServiceError.missingDogSelection.localizedDescription
            return
        }

        isWorking = true
        defer { isWorking = false }

        do {
            let removedDogName = selectedDog.name
            try await cloudService.deleteDog(selectedDog, ownerID: ownerID, ownerDisplayName: ownerDisplayName)

            dogAccounts.removeAll { $0.id == selectedDog.id }
            if let nextDog = dogAccounts.first {
                self.selectedDog = nextDog
                defaults.set(nextDog.id, forKey: selectedDogKey)
                await refreshEntries()
                statusMessage = "Removed \(removedDogName) from this phone's dog roster."
            } else {
                self.selectedDog = nil
                entries = []
                defaults.removeObject(forKey: selectedDogKey)
                statusMessage = "\(removedDogName) has been retired from the poop kingdom."
            }
        } catch {
            statusMessage = error.pooppyCloudKitMessage
        }
    }

    func refreshMissingPlaceNames() async {
        guard let selectedDog else { return }

        for entry in entries where (
            entry.placeName == nil ||
            entry.placeName?.isEmpty == true ||
            entry.cityName == nil ||
            entry.countryName == nil ||
            entry.continentName == nil
        ) && entry.coordinate != nil {
            let placeSnapshot = await resolvedPlaceSnapshot(latitude: entry.latitude, longitude: entry.longitude)
            guard let placeName = placeSnapshot?.displayName, !placeName.isEmpty else { continue }

            var updatedEntry = entry
            updatedEntry.placeName = placeName
            updatedEntry.cityName = placeSnapshot?.cityName
            updatedEntry.regionName = placeSnapshot?.regionName
            updatedEntry.countryName = placeSnapshot?.countryName
            updatedEntry.continentName = placeSnapshot?.continentName
            let prospectiveEntries = ([updatedEntry] + entries.filter { $0.id != entry.id }).sorted { $0.timestamp > $1.timestamp }
            updatedEntry.review = PoopReviewComposer.review(
                for: updatedEntry.rating,
                at: updatedEntry.timestamp,
                placeName: updatedEntry.placeName,
                cityName: updatedEntry.cityName,
                regionName: updatedEntry.regionName,
                countryName: updatedEntry.countryName,
                continentName: updatedEntry.continentName,
                weatherSummary: updatedEntry.weatherSummary,
                temperatureCelsius: updatedEntry.temperatureCelsius,
                altitudeMeters: updatedEntry.altitudeMeters,
                gapSincePrevious: nil,
                badgeHint: PoopBadgeEngine.badgeNarrative(previousEntries: entries, updatedEntries: prospectiveEntries)
            )

            do {
                let savedEntry = try await cloudService.saveEntry(updatedEntry, dogID: selectedDog.id)
                if let index = entries.firstIndex(where: { $0.id == entry.id }) {
                    entries[index] = savedEntry
                }
            } catch {
                statusMessage = error.pooppyCloudKitMessage
            }
        }
    }

    private func resolvedPlaceSnapshot(latitude: Double?, longitude: Double?) async -> PlaceSnapshot? {
        guard let latitude, let longitude else {
            return nil
        }

        return await placeNameResolver.resolveSnapshot(for: latitude, longitude: longitude)
    }

    func refreshWeatherPreview(latitude: Double?, longitude: Double?) async {
        currentWeatherSnapshot = await fetchWeatherSnapshot(latitude: latitude, longitude: longitude, surfaceFailure: true)
    }

    private func fetchWeatherSnapshot(latitude: Double?, longitude: Double?, surfaceFailure: Bool) async -> PoopWeatherSnapshot? {
        guard let latitude, let longitude else {
            if surfaceFailure {
                currentWeatherSnapshot = nil
                weatherStatusMessage = "Weather needs a live location fix first."
            }
            return nil
        }

        if let snapshot = await weatherService.snapshot(latitude: latitude, longitude: longitude) {
            if surfaceFailure {
                currentWeatherSnapshot = snapshot
                weatherStatusMessage = nil
            }
            return snapshot
        }

        if surfaceFailure {
            currentWeatherSnapshot = nil
            weatherStatusMessage = "WeatherKit didn’t answer. Check the WeatherKit capability and try again."
        }
        return nil
    }

    func clearStatusMessage() {
        statusMessage = nil
    }

    private func archiveEntry(_ entry: PoopEntry, dogID: String) {
        archivedEntries.removeAll { $0.id == entry.id }
        archivedEntries.insert(ArchivedPoopEntry(entry: entry, dogID: dogID), at: 0)
        persistArchivedEntries()
    }

    private func loadArchivedEntries() {
        guard let data = defaults.data(forKey: archivedEntriesKey) else {
            archivedEntries = []
            return
        }

        do {
            archivedEntries = try JSONDecoder().decode([ArchivedPoopEntry].self, from: data)
        } catch {
            archivedEntries = []
        }
    }

    private func persistArchivedEntries() {
        do {
            let data = try JSONEncoder().encode(archivedEntries)
            defaults.set(data, forKey: archivedEntriesKey)
        } catch {
            statusMessage = "The recycle bin had a paperwork issue and could not save locally."
        }
    }

    private func purgeExpiredArchivedEntries() {
        let previousCount = archivedEntries.count
        archivedEntries.removeAll(where: { $0.isExpired })
        if archivedEntries.count != previousCount {
            persistArchivedEntries()
        }
    }
}

struct PoopWeatherSnapshot {
    let summary: String
    let conditionName: String
    let temperatureCelsius: Double
}

private struct PoopWeatherService {
    func snapshot(latitude: Double, longitude: Double) async -> PoopWeatherSnapshot? {
        let location = CLLocation(latitude: latitude, longitude: longitude)

        do {
            let weather = try await WeatherService.shared.weather(for: location)
            let current = weather.currentWeather
            return PoopWeatherSnapshot(
                summary: summary(for: current.condition),
                conditionName: String(describing: current.condition),
                temperatureCelsius: current.temperature.converted(to: .celsius).value
            )
        } catch {
            return nil
        }
    }

    private func summary(for condition: WeatherCondition) -> String {
        switch condition {
        case .clear:
            return "Clear skies"
        case .mostlyClear:
            return "Mostly clear"
        case .cloudy:
            return "Cloudy"
        case .mostlyCloudy:
            return "Mostly cloudy"
        case .partlyCloudy:
            return "Partly cloudy"
        case .drizzle:
            return "Drizzly"
        case .rain:
            return "Rainy"
        case .heavyRain:
            return "Pouring rain"
        case .snow:
            return "Snowy"
        case .heavySnow:
            return "Heavy snow"
        case .flurries:
            return "Flurries"
        case .sleet:
            return "Sleety"
        case .hail:
            return "Hailing"
        case .windy:
            return "Windy"
        case .foggy:
            return "Foggy"
        case .haze:
            return "Hazy"
        case .hot:
            return "Hot"
        case .blizzard:
            return "Blizzardy"
        case .blowingSnow:
            return "Blowing snow"
        case .blowingDust:
            return "Dusty"
        case .freezingDrizzle:
            return "Freezing drizzle"
        case .freezingRain:
            return "Freezing rain"
        case .frigid:
            return "Biting cold"
        case .smoky:
            return "Smoky"
        case .sunFlurries:
            return "Sun flurries"
        case .sunShowers:
            return "Sunshowers"
        case .thunderstorms:
            return "Thunderstorms"
        case .tropicalStorm:
            return "Tropical storm"
        case .hurricane:
            return "Hurricane mood"
        case .isolatedThunderstorms:
            return "Isolated thunder"
        case .strongStorms:
            return "Strong storms"
        case .breezy:
            return "Breezy"
        case .wintryMix:
            return "Wintry mix"
        case .scatteredThunderstorms:
            return "Scattered thunder"
        @unknown default:
            return "Weather with personality"
        }
    }
}
