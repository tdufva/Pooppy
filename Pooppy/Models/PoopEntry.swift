import CoreLocation
import Foundation

struct PoopEntry: Identifiable, Codable, Hashable {
    let id: UUID
    var rating: Int
    var timestamp: Date
    var latitude: Double?
    var longitude: Double?
    var altitudeMeters: Double?
    var placeName: String?
    var cityName: String?
    var regionName: String?
    var countryName: String?
    var continentName: String?
    var review: String?
    var weatherSummary: String?
    var weatherConditionName: String?
    var temperatureCelsius: Double?

    init(
        id: UUID = UUID(),
        rating: Int,
        timestamp: Date = .now,
        latitude: Double? = nil,
        longitude: Double? = nil,
        altitudeMeters: Double? = nil,
        placeName: String? = nil,
        cityName: String? = nil,
        regionName: String? = nil,
        countryName: String? = nil,
        continentName: String? = nil,
        review: String? = nil,
        weatherSummary: String? = nil,
        weatherConditionName: String? = nil,
        temperatureCelsius: Double? = nil
    ) {
        self.id = id
        self.rating = rating
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.altitudeMeters = altitudeMeters
        self.placeName = placeName
        self.cityName = cityName
        self.regionName = regionName
        self.countryName = countryName
        self.continentName = continentName
        self.review = review
        self.weatherSummary = weatherSummary
        self.weatherConditionName = weatherConditionName
        self.temperatureCelsius = temperatureCelsius
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else {
            return nil
        }

        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var ratingLabel: String {
        String(repeating: "★", count: rating) + String(repeating: "☆", count: max(0, 5 - rating))
    }

    var displayLocationName: String {
        if let placeName, !placeName.isEmpty {
            return placeName
        }

        if let coordinate {
            return "\(coordinate.latitude.formatted(.number.precision(.fractionLength(4)))), \(coordinate.longitude.formatted(.number.precision(.fractionLength(4))))"
        }

        return "No location saved"
    }

    var displayReview: String {
        review ?? "A mysterious contribution awaits literary judgment."
    }

    var locationBadgeLine: String {
        [cityName, regionName, countryName, continentName]
            .compactMap { value in
                guard let value, !value.isEmpty else { return nil }
                return value
            }
            .removingDuplicates()
            .joined(separator: " • ")
    }

    var weatherLine: String? {
        guard
            let weatherSummary,
            !weatherSummary.isEmpty
        else {
            return nil
        }

        if let temperatureCelsius {
            return "\(weatherSummary) at \(temperatureCelsius.formatted(.number.precision(.fractionLength(0))))°C"
        }

        return weatherSummary
    }

    var weatherAddressLine: String {
        let weather = weatherLine

        switch (displayLocationName.isEmpty, weather?.isEmpty ?? true) {
        case (false, false):
            return "\(displayLocationName) • \(weather!)"
        case (false, true):
            return displayLocationName
        case (true, false):
            return weather!
        default:
            return "No location saved"
        }
    }
}

struct ArchivedPoopEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let dogID: String
    let entry: PoopEntry
    let deletedAt: Date
    let expiresAt: Date

    init(entry: PoopEntry, dogID: String, deletedAt: Date = .now, retention: TimeInterval = 86_400) {
        self.id = entry.id
        self.dogID = dogID
        self.entry = entry
        self.deletedAt = deletedAt
        self.expiresAt = deletedAt.addingTimeInterval(retention)
    }

    var isExpired: Bool {
        expiresAt <= .now
    }
}

private extension Array where Element == String {
    func removingDuplicates() -> [String] {
        var seen = Set<String>()
        return filter { seen.insert($0).inserted }
    }
}
