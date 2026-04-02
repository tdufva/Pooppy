import SwiftUI

struct PoopHistoryView: View {
    @ObservedObject var store: PoopStore
    @State private var selectedEntry: PoopEntry?
    @State private var pendingDeleteEntry: PoopEntry?

    var body: some View {
        NavigationStack {
            Group {
                if store.entries.isEmpty && store.currentDogArchivedEntries.isEmpty {
                    ContentUnavailableView(
                        "No Poops Logged Yet",
                        systemImage: "dog.fill",
                        description: Text("Go log the first masterpiece on your next walk.")
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 14) {
                            if !store.currentDogArchivedEntries.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Recently Deleted")
                                        .font(.headline)
                                        .foregroundStyle(PooppyTheme.espresso)

                                    Text("These logs can be rescued for 24 hours before they drift into legend.")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)

                                    ForEach(store.currentDogArchivedEntries) { archivedEntry in
                                        HStack(alignment: .top, spacing: 12) {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(archivedEntry.entry.ratingLabel)
                                                    .font(.headline)
                                                Text(archivedEntry.entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                                Text(restoreDeadlineLabel(for: archivedEntry))
                                                    .font(.caption2.weight(.semibold))
                                                    .foregroundStyle(PooppyTheme.caramel)
                                            }

                                            Spacer()

                                            Button {
                                                Task {
                                                    await store.restoreArchivedEntry(id: archivedEntry.id)
                                                }
                                            } label: {
                                                Label("Restore", systemImage: "arrow.uturn.backward.circle.fill")
                                                    .font(.subheadline.weight(.semibold))
                                            }
                                            .buttonStyle(.borderedProminent)
                                            .tint(PooppyTheme.moss)
                                        }
                                        .padding(12)
                                        .background(PooppyTheme.cream.opacity(0.7))
                                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                    }
                                }
                                .pooppyCardStyle()
                            }

                            ForEach(Array(store.entries.enumerated()), id: \.element.id) { index, entry in
                                let previousEntry = index + 1 < store.entries.count ? store.entries[index + 1] : nil
                                VStack(alignment: .leading, spacing: 12) {
                                    PoopPostcardView(entry: entry, previousEntry: previousEntry, dog: store.selectedDog)

                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(entry.ratingLabel)
                                                .font(.title3)
                                            Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                                                .font(.headline)
                                                .foregroundStyle(PooppyTheme.espresso)
                                        }

                                        Spacer()

                                        VStack(alignment: .trailing, spacing: 6) {
                                            Text(badgeLabel(for: entry.rating))
                                                .font(.caption.bold())
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(badgeColor(for: entry.rating).opacity(0.16))
                                                .foregroundStyle(badgeColor(for: entry.rating))
                                                .clipShape(Capsule())

                                            if let gapLabel = timeGapLabel(from: previousEntry, to: entry) {
                                                Text(gapLabel)
                                                    .font(.caption2.weight(.semibold))
                                                    .foregroundStyle(PooppyTheme.caramel)
                                            }
                                        }
                                    }

                                    Text(entry.weatherAddressLine)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(PooppyTheme.espresso)

                                    if !entry.locationBadgeLine.isEmpty {
                                        Text(entry.locationBadgeLine)
                                            .font(.caption.weight(.medium))
                                            .foregroundStyle(PooppyTheme.caramel)
                                    }

                                    Text(entry.displayReview)
                                        .font(.subheadline)
                                        .foregroundStyle(PooppyTheme.cocoa)
                                        .fixedSize(horizontal: false, vertical: true)

                                    HStack(spacing: 10) {
                                        Button {
                                            selectedEntry = entry
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                                .font(.subheadline.weight(.semibold))
                                        }
                                        .buttonStyle(.bordered)
                                        .tint(PooppyTheme.caramel)

                                        Button(role: .destructive) {
                                            pendingDeleteEntry = entry
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                                .font(.subheadline.weight(.semibold))
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .pooppyCardStyle()
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Poop Log")
                        .font(.headline.bold())
                        .foregroundStyle(PooppyTheme.espresso)
                }
            }
            .pooppyBackground()
            .sheet(item: $selectedEntry) { entry in
                EditPoopEntryView(
                    entry: entry,
                    onSave: { rating, timestamp, latitude, longitude in
                        Task {
                            await store.updateEntry(
                                id: entry.id,
                                rating: rating,
                                timestamp: timestamp,
                                latitude: latitude,
                                longitude: longitude
                            )
                        }
                    },
                    onDelete: {
                        pendingDeleteEntry = entry
                    }
                )
                .presentationDetents([.medium, .large])
            }
            .alert("Delete this poop log?", isPresented: Binding(
                get: { pendingDeleteEntry != nil },
                set: { isPresented in
                    if !isPresented {
                        pendingDeleteEntry = nil
                    }
                }
            )) {
                Button("Delete", role: .destructive) {
                    guard let pendingDeleteEntry else { return }
                    Task {
                        await store.deleteEntry(id: pendingDeleteEntry.id)
                    }
                    self.pendingDeleteEntry = nil
                }
                Button("Cancel", role: .cancel) {
                    pendingDeleteEntry = nil
                }
            } message: {
                Text("The log will leave history, stats, badges, and the map, but it can still be restored here for 24 hours.")
            }
            .task {
                await store.refreshMissingPlaceNames()
            }
        }
    }

    private func badgeLabel(for rating: Int) -> String {
        switch rating {
        case 5: return "Legend"
        case 4: return "Strong"
        case 3: return "Solid"
        case 2: return "Average"
        default: return "Rough"
        }
    }

    private func badgeColor(for rating: Int) -> Color {
        rating >= 4 ? PooppyTheme.moss : (rating == 3 ? PooppyTheme.caramel : PooppyTheme.espresso)
    }

    private func timeGapLabel(from previousEntry: PoopEntry?, to entry: PoopEntry) -> String? {
        guard let previousEntry else { return "Opening act" }
        let gap = entry.timestamp.timeIntervalSince(previousEntry.timestamp)

        if gap < 60 * 60 {
            return "Back-to-back"
        }
        if gap < 60 * 60 * 8 {
            return "Quick return"
        }
        if gap >= 60 * 60 * 24 {
            return "After a long pause"
        }
        return nil
    }

    private func restoreDeadlineLabel(for archivedEntry: ArchivedPoopEntry) -> String {
        let remaining = max(0, archivedEntry.expiresAt.timeIntervalSinceNow)
        let hours = Int(remaining / 3_600)
        let minutes = Int((remaining.truncatingRemainder(dividingBy: 3_600)) / 60)

        if hours > 0 {
            return "Rescue window: \(hours)h \(minutes)m left"
        }
        return "Rescue window: \(minutes)m left"
    }
}
