import CoreLocation
import SwiftUI

struct LogPoopView: View {
    @ObservedObject var store: PoopStore
    @ObservedObject var locationManager: PoopLocationManager

    @State private var rating = 3
    @State private var confirmationMessage: String?
    @State private var isLogging = false
    @State private var activeCelebration: CelebrationOverlay?
    @State private var queuedBadgeCelebration: [PoopBadge] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Rate the latest masterpiece")
                            .font(.largeTitle.bold())
                            .foregroundStyle(PooppyTheme.espresso)

                        Text("When the dog delivers, tap a star score and save the exact drop zone.")
                            .font(.headline)
                            .foregroundStyle(PooppyTheme.cocoa.opacity(0.84))

                        HStack(spacing: 12) {
                            Label("\(store.entries.count) total logs", systemImage: "number.circle.fill")
                            Label(ratingSummary, systemImage: "star.leadinghalf.filled")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PooppyTheme.caramel)

                        mascotBanner
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .pooppyCardStyle()
                    .padding(.top, 6)

                    VStack(spacing: 18) {
                        StarRatingPicker(rating: $rating)
                        Text("Current score: \(rating) / 5")
                            .font(.headline)
                            .foregroundStyle(PooppyTheme.cocoa)
                    }
                    .pooppyCardStyle()

                    VStack(spacing: 12) {
                        locationStatusCard

                        Button {
                            Task {
                                await logPoop()
                            }
                        } label: {
                            Label(isLogging ? "Logging..." : "Log This Poop", systemImage: isLogging ? "hourglass" : "checkmark.circle.fill")
                                .font(.title3.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 22)
                                .padding(.horizontal, 18)
                                .background(PooppyTheme.espresso)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        }
                        .disabled(isLogging)

                        Button("Refresh Location") {
                            locationManager.refreshLocation()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(PooppyTheme.caramel)
                    }

                    if let confirmationMessage {
                        Text(confirmationMessage)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(PooppyTheme.moss)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding()
            }
            .padding()
            .navigationTitle("Pooppy")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                locationManager.requestAccessIfNeeded()
                locationManager.refreshLocation()
            }
            .task(id: locationManager.currentLocation?.timestamp) {
                guard let location = locationManager.currentLocation else { return }
                await store.refreshWeatherPreview(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
            }
            .overlay {
                if let activeCelebration {
                    CelebrationOverlayView(
                        celebration: activeCelebration,
                        onContinue: advanceCelebrationQueue
                    )
                        .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
                }
            }
            .pooppyBackground()
        }
    }

    @ViewBuilder
    private var locationStatusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Current Location", systemImage: "location.fill")
                .font(.headline)
                .foregroundStyle(PooppyTheme.caramel)

            if let location = locationManager.currentLocation {
                Text(coordinateString(for: location.coordinate))
                    .font(.body)
                    .foregroundStyle(.primary)
                if let weatherSnapshot = store.currentWeatherSnapshot {
                    Text("\(weatherSnapshot.summary) • \(weatherSnapshot.temperatureCelsius.formatted(.number.precision(.fractionLength(0))))°C")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PooppyTheme.moss)
                } else if let weatherStatusMessage = store.weatherStatusMessage {
                    Text(weatherStatusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if let error = locationManager.lastErrorMessage {
                Text(error)
                    .foregroundStyle(.secondary)
            } else {
                Text("Fetching your dog-walk coordinates...")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .pooppyCardStyle()
    }

    private func logPoop() async {
        isLogging = true
        let location = await locationManager.captureLocationForLog()
        let badgesBefore = Set(PoopBadgeEngine.badges(for: store.entries).filter(\.earned).map(\.id))
        let savedEntry = await store.addEntry(
            rating: rating,
            latitude: location?.coordinate.latitude,
            longitude: location?.coordinate.longitude,
            altitudeMeters: location?.altitude
        )

        confirmationMessage = "Logged a \(rating)-star poop\(location == nil ? ", and the GPS ghosted us." : " with the exact scene of the crime.")"
        if let savedEntry {
            let earnedBadgesAfter = PoopBadgeEngine.badges(for: store.entries).filter(\.earned)
            queuedBadgeCelebration = earnedBadgesAfter.filter { !badgesBefore.contains($0.id) }
            withAnimation(.spring(response: 0.42, dampingFraction: 0.8)) {
                activeCelebration = .poopLogged(savedEntry)
            }
        }
        isLogging = false
    }

    private func advanceCelebrationQueue() {
        withAnimation(.easeOut(duration: 0.25)) {
            if case .poopLogged = activeCelebration, let badge = queuedBadgeCelebration.first {
                queuedBadgeCelebration.removeFirst()
                activeCelebration = .badgeUnlocked(badge, queuedBadgeCelebration.count)
            } else if case .badgeUnlocked = activeCelebration, let badge = queuedBadgeCelebration.first {
                queuedBadgeCelebration.removeFirst()
                activeCelebration = .badgeUnlocked(badge, queuedBadgeCelebration.count)
            } else {
                activeCelebration = nil
                queuedBadgeCelebration = []
            }
        }
    }

    private func coordinateString(for coordinate: CLLocationCoordinate2D) -> String {
        "\(coordinate.latitude.formatted(.number.precision(.fractionLength(4)))), \(coordinate.longitude.formatted(.number.precision(.fractionLength(4))))"
    }

    private var ratingSummary: String {
        if store.entries.isEmpty {
            return "No ratings yet"
        }

        let average = Double(store.entries.map(\.rating).reduce(0, +)) / Double(store.entries.count)
        return "\(average.formatted(.number.precision(.fractionLength(1)))) avg"
    }

    private var mascotBanner: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(PooppyTheme.gold.opacity(0.24))
                    .frame(width: 44, height: 44)

                Text("💩")
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Captain Plop reporting for duty")
                    .font(.subheadline.bold())
                    .foregroundStyle(PooppyTheme.espresso)

                Text("He salutes every five-star performance.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(PooppyTheme.sand.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private enum CelebrationOverlay: Identifiable {
    case poopLogged(PoopEntry)
    case badgeUnlocked(PoopBadge, Int)

    var id: String {
        switch self {
        case .poopLogged(let entry):
            return "poop-\(entry.id.uuidString)"
        case .badgeUnlocked(let badge, let remaining):
            return "badge-\(badge.id)-\(remaining)"
        }
    }
}

private struct CelebrationOverlayView: View {
    let celebration: CelebrationOverlay
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.18)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                switch celebration {
                case .poopLogged(let entry):
                    Text("Poop Logged")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(PooppyTheme.espresso)

                    Text(entry.ratingLabel)
                        .font(.system(size: 34))

                    Text(entry.weatherAddressLine)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(PooppyTheme.cocoa)

                    Text(entry.displayReview)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                case .badgeUnlocked(let badge, let remaining):
                    Text("New Badge")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(PooppyTheme.espresso)

                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [PooppyTheme.gold.opacity(0.95), PooppyTheme.sand.opacity(0.88)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 108, height: 108)

                        Image(systemName: badge.symbol)
                            .font(.system(size: 40, weight: .black))
                            .foregroundStyle(PooppyTheme.espresso)
                    }

                    Text(badge.title)
                        .font(.title3.bold())
                        .multilineTextAlignment(.center)
                        .foregroundStyle(PooppyTheme.espresso)

                    Text(badge.blurb)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)

                    if remaining > 0 {
                        Text("\(remaining) more badge surprise\(remaining == 1 ? "" : "s") waiting.")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(PooppyTheme.caramel)
                    }
                }

                Button("OK") {
                    onContinue()
                }
                .font(.headline.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(PooppyTheme.espresso)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .padding(24)
            .frame(maxWidth: 340)
            .background(.white.opacity(0.96))
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: PooppyTheme.espresso.opacity(0.15), radius: 20, y: 14)
            .overlay(alignment: .topTrailing) {
                Circle()
                    .fill(PooppyTheme.gold.opacity(0.9))
                    .frame(width: 22, height: 22)
                    .offset(x: 8, y: -8)
            }
        }
    }
}

struct StarRatingPicker: View {
    @Binding var rating: Int

    var body: some View {
        HStack(spacing: 12) {
            ForEach(1...5, id: \.self) { value in
                Button {
                    rating = value
                } label: {
                    VStack(spacing: 10) {
                        Image(systemName: value <= rating ? "star.fill" : "star")
                            .font(.system(size: 34))
                            .foregroundStyle(value <= rating ? PooppyTheme.gold : PooppyTheme.caramel.opacity(0.45))
                    }
                    .frame(width: 56, height: 56)
                    .background(value == rating ? PooppyTheme.espresso.opacity(0.12) : .white.opacity(0.7))
                    .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(value) star\(value == 1 ? "" : "s")")
            }
        }
    }
}
