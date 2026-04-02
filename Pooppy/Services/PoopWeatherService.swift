import CoreLocation
import Foundation
import WeatherKit

struct PoopWeatherSnapshot {
    let summary: String
    let conditionName: String
    let temperatureCelsius: Double
}

struct PoopWeatherService {
    func snapshot(latitude: Double, longitude: Double) async -> PoopWeatherSnapshot? {
        let location = CLLocation(latitude: latitude, longitude: longitude)

        do {
            let weather = try await WeatherService.shared.weather(for: location)
            let current = weather.currentWeather
            return PoopWeatherSnapshot(
                summary: summary(for: current.condition),
                conditionName: current.condition.rawValue,
                temperatureCelsius: current.temperature.converted(to: .celsius).value
            )
        } catch {
            return nil
        }
    }

    private func summary(for condition: WeatherCondition) -> String {
        switch condition {
        case .clear:
            return "Clear skies"
        case .mostlyClear:
            return "Mostly clear"
        case .cloudy:
            return "Cloudy"
        case .mostlyCloudy:
            return "Mostly cloudy"
        case .partlyCloudy:
            return "Partly cloudy"
        case .drizzle:
            return "Drizzly"
        case .rain:
            return "Rainy"
        case .heavyRain:
            return "Pouring rain"
        case .showers:
            return "Showery"
        case .snow:
            return "Snowy"
        case .heavySnow:
            return "Heavy snow"
        case .flurries:
            return "Flurries"
        case .sleet:
            return "Sleety"
        case .hail:
            return "Hailing"
        case .windy:
            return "Windy"
        case .foggy:
            return "Foggy"
        case .haze:
            return "Hazy"
        case .hot:
            return "Hot"
        case .blizzard:
            return "Blizzardy"
        case .blowingDust:
            return "Dusty"
        case .freezingDrizzle:
            return "Freezing drizzle"
        case .freezingRain:
            return "Freezing rain"
        case .frigid:
            return "Biting cold"
        case .smoky:
            return "Smoky"
        case .sunFlurries:
            return "Sun flurries"
        case .sunShowers:
            return "Sunshowers"
        case .thunderstorms:
            return "Thunderstorms"
        case .tropicalStorm:
            return "Tropical storm"
        case .hurricane:
            return "Hurricane mood"
        case .isolatedThunderstorms:
            return "Isolated thunder"
        case .strongStorms:
            return "Strong storms"
        case .breezy:
            return "Breezy"
        case .wintryMix:
            return "Wintry mix"
        case .scatteredThunderstorms:
            return "Scattered thunder"
        default:
            return "Weather with personality"
        }
    }
}
