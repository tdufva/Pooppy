import SwiftUI
import UIKit

struct DogAccountView: View {
    @ObservedObject var store: PoopStore
    @ObservedObject var authManager: AuthManager

    @State private var dogName = ""
    @State private var inviteCode = ""
    @State private var selectedCoatColorName: DogColorName = .white
    @State private var selectedEarStyle: DogEarStyle = .floppy
    @State private var selectedLeftEarColorName: DogColorName = .white
    @State private var selectedRightEarColorName: DogColorName = .white
    @State private var selectedNoseColorName: DogColorName = .charcoal
    @State private var isSyncingAppearance = false
    @State private var isShowingDeleteDogAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if let dog = store.selectedDog {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 14) {
                                HappyDogFaceBadge(
                                    size: 68,
                                    coatColorName: selectedCoatColorName,
                                    earStyle: selectedEarStyle,
                                    leftEarColorName: selectedLeftEarColorName,
                                    rightEarColorName: selectedRightEarColorName,
                                    noseColorName: selectedNoseColorName
                                )

                                Text(dog.name)
                                    .font(.largeTitle.bold())
                                    .foregroundStyle(PooppyTheme.espresso)
                            }

                            Text("Invite Code: \(dog.inviteCode)")
                                .font(.headline)
                                .foregroundStyle(PooppyTheme.caramel)

                            Text("Share the code with the other walkers and the whole council can log into the same poop kingdom.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Button("Copy Invite Code") {
                                UIPasteboard.general.string = dog.inviteCode
                                store.statusMessage = "Invite code copied. Release the household group chat."
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(PooppyTheme.cocoa)

                            HStack(spacing: 10) {
                                Button("Refresh Shared Dog") {
                                    Task {
                                        await store.refreshFromCloud()
                                    }
                                }
                                .buttonStyle(.bordered)
                                .tint(PooppyTheme.caramel)

                                Button("Delete Dog", role: .destructive) {
                                    isShowingDeleteDogAlert = true
                                }
                                .buttonStyle(.bordered)
                            }

                            if !dog.ownerDisplayNames.isEmpty {
                                Text("Owners: \(dog.ownerDisplayNames.joined(separator: ", "))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("\(dog.ownerIDs.count) owner(s) linked")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Divider()

                            Text("Royal Grooming")
                                .font(.headline)
                                .foregroundStyle(PooppyTheme.espresso)

                            Picker("Ear Style", selection: $selectedEarStyle) {
                                ForEach(DogEarStyle.allCases) { style in
                                    Text(style.label).tag(style)
                                }
                            }
                            .pickerStyle(.segmented)

                            dogColorPicker(title: "Coat Color", selection: $selectedCoatColorName)
                            dogColorPicker(title: "Left Ear", selection: $selectedLeftEarColorName)
                            dogColorPicker(title: "Right Ear", selection: $selectedRightEarColorName)
                            dogColorPicker(title: "Nose Color", selection: $selectedNoseColorName)

                            Text("The royal face updates instantly while we save the fresh look in the background.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .pooppyCardStyle()
                        .padding(.horizontal)
                        .onAppear {
                            syncAppearanceSelection(from: dog)
                        }
                        .onChange(of: dog.id) { _, _ in
                            syncAppearanceSelection(from: dog)
                        }
                        .onChange(of: selectedCoatColorName) { _, _ in
                            applyAppearanceChangeIfNeeded()
                        }
                        .onChange(of: selectedEarStyle) { _, _ in
                            applyAppearanceChangeIfNeeded()
                        }
                        .onChange(of: selectedLeftEarColorName) { _, _ in
                            applyAppearanceChangeIfNeeded()
                        }
                        .onChange(of: selectedRightEarColorName) { _, _ in
                            applyAppearanceChangeIfNeeded()
                        }
                        .onChange(of: selectedNoseColorName) { _, _ in
                            applyAppearanceChangeIfNeeded()
                        }
                        .alert("Delete this dog?", isPresented: $isShowingDeleteDogAlert) {
                            Button("Delete", role: .destructive) {
                                Task {
                                    await store.deleteSelectedDog()
                                }
                            }
                            Button("Cancel", role: .cancel) { }
                        } message: {
                            Text("If other owners still share this dog, only this phone will be removed from the dog. If you are the last owner, the dog and its poop history will be deleted from CloudKit.")
                        }
                    }

                    if store.dogAccounts.count > 1 {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Switch Dogs")
                                .font(.title3.bold())

                            ForEach(store.dogAccounts) { dog in
                                Button {
                                    store.selectDog(dog)
                                } label: {
                                    HStack {
                                        HappyDogFaceBadge(
                                            size: 34,
                                            coatColorName: dog.coatColorName,
                                            earStyle: dog.earStyle,
                                            leftEarColorName: dog.leftEarColorName,
                                            rightEarColorName: dog.rightEarColorName,
                                            noseColorName: dog.noseColorName
                                        )

                                        Text(dog.name)
                                            .foregroundStyle(PooppyTheme.espresso)
                                        Spacer()
                                        if dog.id == store.selectedDog?.id {
                                            Text("Active")
                                                .font(.caption.bold())
                                                .foregroundStyle(PooppyTheme.moss)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .pooppyCardStyle()
                        .padding(.horizontal)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Create Another Dog")
                            .font(.title3.bold())

                        TextField("Dog name", text: $dogName)
                            .textFieldStyle(.roundedBorder)
                            .submitLabel(.go)
                            .onSubmit {
                                createDog()
                            }

                        Button(action: createDog) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Create Dog")
                                    .font(.headline)
                                Text("Another noble beast, another data kingdom")
                                    .font(.caption)
                                    .opacity(0.9)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(PooppyTheme.cocoa)
                        .disabled(dogName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.isWorking)
                    }
                    .pooppyCardStyle()
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Join Another Dog")
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

                        Button(action: joinDog) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Join Dog")
                                    .font(.headline)
                                Text("Add this phone to another furry bureaucracy")
                                    .font(.caption)
                                    .opacity(0.9)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(PooppyTheme.caramel)
                        .disabled(inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.isWorking)
                    }
                    .pooppyCardStyle()
                    .padding(.horizontal)

                    if let statusMessage = store.statusMessage {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "checklist.checked")
                                .foregroundStyle(PooppyTheme.caramel)
                            Text(statusMessage)
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
                        .padding(.horizontal)
                    }

                    diagnosticsCard
                        .padding(.horizontal)
                }
                .padding(.vertical, 20)
            }
            .navigationTitle("Dog")
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
                await store.refreshCloudDiagnostics(inviteCode: store.selectedDog?.inviteCode)
            }
        }
    }

    private func createDog() {
        Task {
            await store.createDog(named: dogName)
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
            if store.selectedDog?.inviteCode == attemptedCode {
                inviteCode = ""
            }
        }
    }

    private func syncAppearanceSelection(from dog: DogAccount) {
        isSyncingAppearance = true
        selectedCoatColorName = dog.coatColorName
        selectedEarStyle = dog.earStyle
        selectedLeftEarColorName = dog.leftEarColorName
        selectedRightEarColorName = dog.rightEarColorName
        selectedNoseColorName = dog.noseColorName
        DispatchQueue.main.async {
            isSyncingAppearance = false
        }
    }

    private func applyAppearanceChangeIfNeeded() {
        guard !isSyncingAppearance else { return }
        store.queueSelectedDogAppearanceSave(
            coatColorName: selectedCoatColorName,
            earStyle: selectedEarStyle,
            leftEarColorName: selectedLeftEarColorName,
            rightEarColorName: selectedRightEarColorName,
            noseColorName: selectedNoseColorName
        )
    }

    private func dogColorPicker(title: String, selection: Binding<DogColorName>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(PooppyTheme.espresso)

            HStack(spacing: 10) {
                ForEach(DogColorName.allCases) { colorName in
                    Button {
                        selection.wrappedValue = colorName
                    } label: {
                        Circle()
                            .fill(colorName.color)
                            .frame(width: 28, height: 28)
                            .background {
                                Circle()
                                    .fill(PooppyTheme.sky.opacity(colorName == .white ? 0.36 : 0))
                                    .frame(width: 30, height: 30)
                            }
                            .overlay {
                                Circle()
                                    .stroke(selection.wrappedValue == colorName ? PooppyTheme.espresso : .white.opacity(0.75), lineWidth: 2)
                            }
                            .overlay {
                                if colorName == .white {
                                    Circle()
                                        .stroke(PooppyTheme.cocoa.opacity(0.22), lineWidth: 1)
                                        .frame(width: 28, height: 28)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(colorName.label)
                }
            }
        }
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
                        await store.refreshCloudDiagnostics(inviteCode: store.selectedDog?.inviteCode ?? inviteCode)
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
                Text("Run the cloud check on this phone and it will show exactly what CloudKit is saying.")
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
