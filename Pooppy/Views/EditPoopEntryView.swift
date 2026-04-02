import SwiftUI

struct EditPoopEntryView: View {
    @Environment(\.dismiss) private var dismiss

    let entry: PoopEntry
    let onSave: (Int, Date, Double?, Double?) -> Void
    let onDelete: () -> Void

    @State private var rating: Int
    @State private var timestamp: Date
    @State private var latitudeText: String
    @State private var longitudeText: String
    @State private var validationMessage: String?

    init(entry: PoopEntry, onSave: @escaping (Int, Date, Double?, Double?) -> Void, onDelete: @escaping () -> Void) {
        self.entry = entry
        self.onSave = onSave
        self.onDelete = onDelete
        _rating = State(initialValue: entry.rating)
        _timestamp = State(initialValue: entry.timestamp)
        _latitudeText = State(initialValue: Self.formatCoordinate(entry.latitude))
        _longitudeText = State(initialValue: Self.formatCoordinate(entry.longitude))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Poop Score") {
                    HStack {
                        Spacer()
                        StarRatingPicker(rating: $rating)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)

                    Text("Adjusted score: \(rating) / 5")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }

                Section("When It Happened") {
                    DatePicker("Timestamp", selection: $timestamp)
                }

                Section("Where") {
                    Text(entry.displayLocationName)
                        .foregroundStyle(.secondary)

                    TextField("Latitude", text: $latitudeText)
                        .keyboardType(.numbersAndPunctuation)
                        .textInputAutocapitalization(.never)

                    TextField("Longitude", text: $longitudeText)
                        .keyboardType(.numbersAndPunctuation)
                        .textInputAutocapitalization(.never)

                    Text("Leave both blank to clear the saved location. Updating coordinates will refresh the place and weather.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let validationMessage {
                        Text(validationMessage)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button("Delete This Entry", role: .destructive) {
                        onDelete()
                        dismiss()
                    }
                }
            }
            .navigationTitle("Edit Poop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let coordinates = validatedCoordinates() {
                            onSave(rating, timestamp, coordinates.latitude, coordinates.longitude)
                            dismiss()
                        }
                    }
                    .fontWeight(.bold)
                }
            }
            .onChange(of: latitudeText) { _, _ in
                validationMessage = nil
            }
            .onChange(of: longitudeText) { _, _ in
                validationMessage = nil
            }
        }
    }

    private func validatedCoordinates() -> (latitude: Double?, longitude: Double?)? {
        let parsedLatitude = parsedCoordinate(latitudeText)
        let parsedLongitude = parsedCoordinate(longitudeText)
        let trimmedLatitude = latitudeText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLongitude = longitudeText.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedLatitude.isEmpty && trimmedLongitude.isEmpty {
            return (nil, nil)
        }

        guard !trimmedLatitude.isEmpty, !trimmedLongitude.isEmpty else {
            validationMessage = "Enter both latitude and longitude, or leave both blank."
            return nil
        }

        guard let latitude = parsedLatitude, let longitude = parsedLongitude else {
            validationMessage = "Coordinates need valid numbers, like 60.1699 and 24.9384."
            return nil
        }

        guard (-90...90).contains(latitude) else {
            validationMessage = "Latitude must be between -90 and 90."
            return nil
        }

        guard (-180...180).contains(longitude) else {
            validationMessage = "Longitude must be between -180 and 180."
            return nil
        }

        return (latitude, longitude)
    }

    private func parsedCoordinate(_ value: String) -> Double? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return Double(trimmed.replacingOccurrences(of: ",", with: "."))
    }

    private static func formatCoordinate(_ value: Double?) -> String {
        guard let value else { return "" }
        return value.formatted(.number.precision(.fractionLength(6)))
    }
}
