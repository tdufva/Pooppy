import SwiftUI

struct DogAccessView: View {
    @ObservedObject var store: PoopStore
    @ObservedObject var authManager: AuthManager

    @State private var dogName = ""
    @State private var inviteCode = ""
    @State private var createCoatColorName: DogColorName = .white
    @State private var createEarStyle: DogEarStyle = .floppy
    @State private var createLeftEarColorName: DogColorName = .white
    @State private var createRightEarColorName: DogColorName = .white
    @State private var createNoseColorName: DogColorName = .charcoal

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Choose The Poop Monarch")
                            .font(.largeTitle.bold())
                            .foregroundStyle(PooppyTheme.espresso)

                        Text("Create a shared dog account in seconds, or join one with an invite code and step directly into the family poop chronicles.")
                            .font(.headline)
                            .foregroundStyle(PooppyTheme.cocoa.opacity(0.85))

                        HStack(spacing: 12) {
                            quickTip(icon: "sparkles", text: "Fast setup")
                            quickTip(icon: "person.2.fill", text: "Many owners")
                            quickTip(icon: "icloud.fill", text: "Cloud synced")
                        }
                    }
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Found A New Dog Club")
                            .font(.title3.bold())

                        TextField("Dog name", text: $dogName)
                            .textFieldStyle(.roundedBorder)
                            .submitLabel(.go)
                            .onSubmit {
                                createDog()
                            }

                        HStack(spacing: 14) {
                            HappyDogFaceBadge(
                                size: 58,
                                coatColorName: createCoatColorName,
                                earStyle: createEarStyle,
                                leftEarColorName: createLeftEarColorName,
                                rightEarColorName: createRightEarColorName,
                                noseColorName: createNoseColorName
                            )

                            VStack(alignment: .leading, spacing: 8) {
                                Picker("Ear Style", selection: $createEarStyle) {
                                    ForEach(DogEarStyle.allCases) { style in
                                        Text(style.label).tag(style)
                                    }
                                }
                                .pickerStyle(.segmented)

                                dogColorRow(title: "Coat", selection: $createCoatColorName)
                                dogColorRow(title: "Left Ear", selection: $createLeftEarColorName)
                                dogColorRow(title: "Right Ear", selection: $createRightEarColorName)
                                dogColorRow(title: "Nose", selection: $createNoseColorName)
                            }
                        }

                        Text("Try the actual dog name. \"Sir Wiggles\" and \"Chairman Sniff\" are both valid leadership titles.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        Button(action: createDog) {
                            accountButtonLabel(
                                title: "Create Shared Dog",
                                subtitle: "Make a fresh invite code for the household"
                            )
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(PooppyTheme.cocoa)
                        .disabled(dogName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.isWorking)
                    }
                    .pooppyCardStyle()
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Join An Existing Legend")
                            .font(.title3.bold())

                        TextField("ABC123", text: $inviteCode)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .textFieldStyle(.roundedBorder)
                            .submitLabel(.join)
                            .onChange(of: inviteCode) { _, newValue in
                                let filtered = newValue.uppercased().filter { $0.isLetter || $0.isNumber }
                                if filtered != newValue {
                                    inviteCode = filtered
                                }
                            }
                            .onSubmit {
                                joinDog()
                            }

                        Text("Ask the other human for the six-character code. Dramatic whispering is optional.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        Button(action: joinDog) {
                            accountButtonLabel(
                                title: "Join Dog",
                                subtitle: "Open the shared logbook with one code"
                            )
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(PooppyTheme.caramel)
                        .disabled(inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.isWorking)
                    }
                    .pooppyCardStyle()
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Dogs")
                            .font(.title3.bold())

                        if store.dogAccounts.isEmpty {
                            Text("No dogs connected yet. Time to found a poop dynasty.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(store.dogAccounts) { dog in
                                Button {
                                    store.selectDog(dog)
                                } label: {
                                    HStack {
                                        HappyDogFaceBadge(
                                            size: 38,
                                            coatColorName: dog.coatColorName,
                                            earStyle: dog.earStyle,
                                            leftEarColorName: dog.leftEarColorName,
                                            rightEarColorName: dog.rightEarColorName,
                                            noseColorName: dog.noseColorName
                                        )

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(dog.name)
                                                .font(.headline)
                                                .foregroundStyle(PooppyTheme.espresso)
                                            Text("Invite: \(dog.inviteCode)")
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right.circle.fill")
                                            .foregroundStyle(PooppyTheme.caramel)
                                    }
                                }
                                .buttonStyle(.plain)
                                .padding(.vertical, 6)
                            }
                        }
                    }
                    .pooppyCardStyle()
                    .padding(.horizontal)

                    if let statusMessage = store.statusMessage {
                        statusBanner(message: statusMessage)
                            .padding(.horizontal)
                    }

                    diagnosticsCard
                        .padding(.horizontal)
                }
                .padding(.vertical, 20)
            }
            .navigationTitle("Dog Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sign Out") {
                        authManager.signOut()
                        store.reset()
                    }
                }
            }
            .pooppyBackground()
            .task {
                await store.refreshCloudDiagnostics(inviteCode: inviteCode)
            }
        }
    }

    private func createDog() {
        Task {
            await store.createDog(named: dogName)
            if let dog = store.selectedDog, dog.name.compare(dogName.trimmingCharacters(in: .whitespacesAndNewlines), options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame {
                store.queueSelectedDogAppearanceSave(
                    coatColorName: createCoatColorName,
                    earStyle: createEarStyle,
                    leftEarColorName: createLeftEarColorName,
                    rightEarColorName: createRightEarColorName,
                    noseColorName: createNoseColorName
                )
            }
            if store.selectedDog?.name.compare(dogName.trimmingCharacters(in: .whitespacesAndNewlines), options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame {
                dogName = ""
            }
        }
    }

    private func joinDog() {
        Task {
            let attemptedCode = inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            await store.joinDog(inviteCode: attemptedCode)
            await store.refreshCloudDiagnostics(inviteCode: attemptedCode)
            if store.selectedDog != nil, store.selectedDog?.inviteCode == attemptedCode {
                inviteCode = ""
            }
        }
    }

    private func quickTip(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(PooppyTheme.cocoa)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.white.opacity(0.72), in: Capsule())
    }

    private func accountButtonLabel(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .opacity(0.9)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func dogColorRow(title: String, selection: Binding<DogColorName>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(PooppyTheme.espresso)

            HStack(spacing: 8) {
                ForEach(DogColorName.allCases) { colorName in
                    Button {
                        selection.wrappedValue = colorName
                    } label: {
                        Circle()
                            .fill(colorName.color)
                            .frame(width: 22, height: 22)
                            .background {
                                Circle()
                                    .fill(PooppyTheme.sky.opacity(colorName == .white ? 0.35 : 0))
                                    .frame(width: 24, height: 24)
                            }
                            .overlay {
                                Circle()
                                    .stroke(selection.wrappedValue == colorName ? PooppyTheme.espresso : PooppyTheme.cocoa.opacity(colorName == .white ? 0.28 : 0), lineWidth: 2)
                            }
                            .overlay {
                                if colorName == .white {
                                    Circle()
                                        .stroke(PooppyTheme.cocoa.opacity(0.18), lineWidth: 1)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func statusBanner(message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "bubble.left.and.exclamationmark.bubble.right.fill")
                .foregroundStyle(PooppyTheme.caramel)
            Text(message)
                .font(.footnote)
                .foregroundStyle(PooppyTheme.espresso)
            Spacer()
            Button {
                store.clearStatusMessage()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var diagnosticsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Cloud Check")
                    .font(.title3.bold())
                    .foregroundStyle(PooppyTheme.espresso)
                Spacer()
                Button("Run Cloud Check") {
                    Task {
                        await store.refreshCloudDiagnostics(inviteCode: inviteCode)
                    }
                }
                .buttonStyle(.bordered)
                .tint(PooppyTheme.caramel)
            }

            if let diagnostics = store.cloudDiagnostics {
                diagnosticLine("Container", diagnostics.containerIdentifier)
                diagnosticLine("Account", diagnostics.accountStatus)
                diagnosticLine("Owner", diagnostics.ownerIDLine)
                diagnosticLine("Dog fetch", diagnostics.dogFetchLine)
                diagnosticLine("Invite lookup", diagnostics.inviteLookupLine)
            } else {
                Text("Run the cloud check on this phone and it will spell out what CloudKit is returning.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .pooppyCardStyle()
    }

    private func diagnosticLine(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(PooppyTheme.caramel)
            Text(value)
                .font(.footnote)
                .foregroundStyle(PooppyTheme.espresso)
                .textSelection(.enabled)
        }
    }
}
