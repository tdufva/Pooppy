import CoreLocation
import Foundation

struct PlaceSnapshot {
    let displayName: String?
    let cityName: String?
    let regionName: String?
    let countryName: String?
    let continentName: String?
}

final class PlaceNameResolver {
    private let geocoder = CLGeocoder()

    func resolveName(for latitude: Double, longitude: Double) async -> String? {
        await resolveSnapshot(for: latitude, longitude: longitude)?.displayName
    }

    func resolveSnapshot(for latitude: Double, longitude: Double) async -> PlaceSnapshot? {
        let location = CLLocation(latitude: latitude, longitude: longitude)

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else {
                return nil
            }

            let street = [placemark.thoroughfare, placemark.subThoroughfare]
                .compactMap { $0 }
                .joined(separator: " ")
                .trimmingCharacters(in: .whitespaces)

            let displayName: String?
            if !street.isEmpty, let locality = placemark.locality {
                displayName = "\(street), \(locality)"
            } else if !street.isEmpty {
                displayName = street
            } else if let name = placemark.name, let locality = placemark.locality, name != locality {
                displayName = "\(name), \(locality)"
            } else {
                displayName = placemark.locality ?? placemark.administrativeArea ?? placemark.country
            }

            return PlaceSnapshot(
                displayName: displayName,
                cityName: placemark.locality ?? placemark.subLocality,
                regionName: placemark.administrativeArea,
                countryName: placemark.country,
                continentName: continentName(for: placemark.isoCountryCode)
            )
        } catch {
            return nil
        }
    }

    private func continentName(for isoCountryCode: String?) -> String? {
        guard let isoCountryCode else { return nil }
        switch isoCountryCode.uppercased() {
        case "FI", "SE", "NO", "DK", "IS", "EE", "LV", "LT", "PL", "DE", "FR", "ES", "PT", "IT", "NL", "BE", "LU", "IE", "GB", "CH", "AT", "CZ", "SK", "HU", "RO", "BG", "GR", "HR", "SI", "RS", "BA", "ME", "AL", "MK", "MD", "UA":
            return "Europe"
        case "US", "CA", "MX", "GL":
            return "North America"
        case "BR", "AR", "CL", "PE", "CO", "UY", "PY", "BO", "EC", "VE", "GY", "SR":
            return "South America"
        case "CN", "JP", "KR", "IN", "TH", "VN", "SG", "MY", "ID", "PH", "NP", "PK", "BD", "LK", "AE", "SA", "IL", "JO", "QA", "KW", "OM", "BH", "TR", "KZ", "UZ", "MN":
            return "Asia"
        case "ZA", "NG", "KE", "TZ", "UG", "GH", "MA", "TN", "EG", "DZ", "ET", "RW":
            return "Africa"
        case "AU", "NZ", "FJ", "PG":
            return "Oceania"
        default:
            return nil
        }
    }
}
