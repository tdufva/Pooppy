import AuthenticationServices
import Foundation

@MainActor
final class AuthManager: ObservableObject {
    @Published private(set) var ownerUserID: String?
    @Published private(set) var ownerDisplayName: String?
    @Published private(set) var isRestoringSession = true
    @Published var statusMessage: String?

    private let defaults = UserDefaults.standard
    private let userIDKey = "pooppy.ownerUserID"
    private let userDisplayNameKey = "pooppy.ownerDisplayName"
    private let appleIDProvider = ASAuthorizationAppleIDProvider()

    init() {
        Task {
            await restoreSession()
        }
    }

    func handleSignInCompletion(_ result: Result<ASAuthorization, any Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                statusMessage = "Couldn't read the Apple ID credential."
                return
            }

            ownerUserID = credential.user
            defaults.set(credential.user, forKey: userIDKey)

            let formatter = PersonNameComponentsFormatter()
            let fullName = formatter.string(from: credential.fullName ?? PersonNameComponents())
            if !fullName.isEmpty {
                ownerDisplayName = fullName
                defaults.set(fullName, forKey: userDisplayNameKey)
            } else {
                ownerDisplayName = defaults.string(forKey: userDisplayNameKey)
            }

            statusMessage = nil
        case .failure(let error):
            statusMessage = error.localizedDescription
        }
    }

    func signOut() {
        clearStoredSession()
    }

    private func restoreSession() async {
        defer { isRestoringSession = false }

        guard let storedUserID = defaults.string(forKey: userIDKey) else {
            ownerUserID = nil
            ownerDisplayName = nil
            return
        }

        do {
            let credentialState = try await credentialState(for: storedUserID)
            switch credentialState {
            case .authorized:
                ownerUserID = storedUserID
                ownerDisplayName = defaults.string(forKey: userDisplayNameKey)
            case .revoked, .notFound, .transferred:
                clearStoredSession()
            default:
                clearStoredSession()
            }
        } catch {
            ownerUserID = storedUserID
            ownerDisplayName = defaults.string(forKey: userDisplayNameKey)
        }
    }

    private func credentialState(for userID: String) async throws -> ASAuthorizationAppleIDProvider.CredentialState {
        try await withCheckedThrowingContinuation { continuation in
            appleIDProvider.getCredentialState(forUserID: userID) { credentialState, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: credentialState)
                }
            }
        }
    }

    private func clearStoredSession() {
        ownerUserID = nil
        ownerDisplayName = nil
        statusMessage = nil
        defaults.removeObject(forKey: userIDKey)
        defaults.removeObject(forKey: userDisplayNameKey)
        isRestoringSession = false
    }
}
