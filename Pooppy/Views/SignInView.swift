import AuthenticationServices
import SwiftUI

struct SignInView: View {
    @ObservedObject var authManager: AuthManager

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 24)

            VStack(spacing: 18) {
                Text("Pooppy")
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundStyle(PooppyTheme.espresso)

                Text("The shared field journal for a dog with more than one loyal poop witness.")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(PooppyTheme.cocoa)

                VStack(alignment: .leading, spacing: 10) {
                    accountStep(icon: "person.crop.circle.badge.checkmark", title: "Sign in as the human", detail: "Apple handles the identity bit so your dog does not have to.")
                    accountStep(icon: "dog.fill", title: "Create or join a dog", detail: "Use a quick invite code to gather the whole walking committee.")
                    accountStep(icon: "sparkles", title: "Log to one shared history", detail: "Every owner sees the same poops, badges, stats, and suspiciously strong streaks.")
                }
                .pooppyCardStyle()
            }
            .padding(.horizontal)

            VStack(spacing: 12) {
                SignInWithAppleButton(.signIn, onRequest: { request in
                    request.requestedScopes = [.fullName]
                }, onCompletion: authManager.handleSignInCompletion)
                .signInWithAppleButtonStyle(.black)
                .frame(height: 52)

                Text("One tap now, shared poop governance moments later.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            if let statusMessage = authManager.statusMessage {
                Text(statusMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .pooppyBackground()
    }

    private func accountStep(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(PooppyTheme.caramel)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(PooppyTheme.espresso)

                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
