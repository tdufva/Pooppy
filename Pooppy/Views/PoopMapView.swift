import MapKit
import SwiftUI

struct PoopMapView: View {
    @ObservedObject var store: PoopStore

    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        NavigationStack {
            Group {
                if mappedEntries.isEmpty {
                    ContentUnavailableView(
                        "No Mapped Poops Yet",
                        systemImage: "map",
                        description: Text("Once a poop has a location, it will appear here as a big brown circle.")
                    )
                } else {
                    ZStack(alignment: .top) {
                        Map(position: $cameraPosition) {
                            ForEach(mappedEntries) { entry in
                                if let coordinate = entry.coordinate {
                                    Annotation("Poop", coordinate: coordinate) {
                                        VStack(spacing: 4) {
                                            Circle()
                                                .fill(PooppyTheme.cocoa)
                                                .frame(width: 32, height: 32)
                                                .overlay {
                                                    Circle()
                                                        .stroke(Color.white.opacity(0.75), lineWidth: 3)
                                                }

                                            Text("\(entry.rating)")
                                                .font(.caption.bold())
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(.ultraThinMaterial)
                                                .clipShape(Capsule())

                                            if let placeName = entry.placeName {
                                                Text(placeName)
                                                    .font(.caption2.weight(.medium))
                                                    .lineLimit(1)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(.ultraThinMaterial)
                                                    .clipShape(Capsule())
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .mapStyle(.standard(elevation: .realistic))
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

                        HStack(spacing: 14) {
                            mapMetric(title: "Spots", value: "\(mappedEntries.count)")
                            mapMetric(title: "Best", value: "\(mappedEntries.map(\.rating).max() ?? 0)★")
                        }
                        .padding(.top, 14)
                        .padding(.horizontal, 14)
                    }
                }
            }
            .padding()
            .navigationTitle("Poop Map")
            .navigationBarTitleDisplayMode(.inline)
            .pooppyBackground()
            .task {
                cameraPosition = .region(mapRegion)
                await store.refreshMissingPlaceNames()
            }
        }
    }

    private var mappedEntries: [PoopEntry] {
        store.entries.filter { $0.coordinate != nil }
    }

    private var mapRegion: MKCoordinateRegion {
        let coordinates = mappedEntries.compactMap(\.coordinate)
        guard let first = coordinates.first else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 60.1699, longitude: 24.9384),
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
        }

        let latitudes = coordinates.map(\.latitude)
        let longitudes = coordinates.map(\.longitude)

        let minLatitude = latitudes.min() ?? first.latitude
        let maxLatitude = latitudes.max() ?? first.latitude
        let minLongitude = longitudes.min() ?? first.longitude
        let maxLongitude = longitudes.max() ?? first.longitude

        let center = CLLocationCoordinate2D(
            latitude: (minLatitude + maxLatitude) / 2,
            longitude: (minLongitude + maxLongitude) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLatitude - minLatitude) * 1.8, 0.01),
            longitudeDelta: max((maxLongitude - minLongitude) * 1.8, 0.01)
        )

        return MKCoordinateRegion(center: center, span: span)
    }

    private func mapMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption.bold())
                .foregroundStyle(PooppyTheme.caramel)

            Text(value)
                .font(.headline.bold())
                .foregroundStyle(PooppyTheme.espresso)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.white.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
