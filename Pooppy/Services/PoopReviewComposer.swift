import Foundation

enum PoopReviewComposer {
    static func review(
        for rating: Int,
        at timestamp: Date,
        placeName: String?,
        cityName: String?,
        regionName: String?,
        countryName: String?,
        continentName: String?,
        weatherSummary: String?,
        temperatureCelsius: Double?,
        altitudeMeters: Double?,
        gapSincePrevious: TimeInterval?
        ,
        badgeHint: String?
    ) -> String {
        let hour = Calendar.current.component(.hour, from: timestamp)
        let dayPart = dayPartPhrase(for: hour)
        let ratingLine = ratingPhrase(for: rating)
        let setting = settingPhrase(
            placeName: placeName,
            cityName: cityName,
            regionName: regionName,
            countryName: countryName,
            continentName: continentName,
            weatherSummary: weatherSummary
        )
        let thermalLine = temperaturePhrase(temperatureCelsius)
        let altitudeLine = altitudePhrase(altitudeMeters)
        let gapLine = gapPhrase(gapSincePrevious)
        let closer = closerPhrase(for: rating, hour: hour, weatherSummary: weatherSummary)
        return [dayPart, ratingLine, setting, thermalLine, altitudeLine, gapLine, badgeHint, closer]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private static func dayPartPhrase(for hour: Int) -> String {
        switch hour {
        case 5..<11:
            return [
                "Morning poops are a relief in many ways.",
                "Breakfast has barely settled and already the day has structure.",
                "A sunrise deposit is the dog equivalent of inbox zero."
            ].randomElement()!
        case 11..<16:
            return [
                "This midday maneuver kept the afternoon honest.",
                "A lunchtime drop like this says the schedule is working.",
                "Noon patrol reports a tidy field operation."
            ].randomElement()!
        case 16..<21:
            return [
                "An evening performance like this takes the pressure off dinner.",
                "Sunset strolls were made for confident closures like this.",
                "The after-work shift just got a little lighter."
            ].randomElement()!
        default:
            return [
                "Night poops make for better sleeps.",
                "A late-night drop can tuck the whole household in.",
                "Moonlight missions like this are the quiet heroes of bedtime."
            ].randomElement()!
        }
    }

    private static func ratingPhrase(for rating: Int) -> String {
        switch rating {
        case 5:
            return [
                "This was an all-timer with clean execution and championship intent.",
                "Five stars. Strong form, strong confidence, no notes.",
                "An elite specimen. Captain Plop salutes with both hands."
            ].randomElement()!
        case 4:
            return [
                "A highly respectable outing with solid technique.",
                "This had veteran composure and very little drama.",
                "Not quite hall-of-fame material, but absolutely playoff ready."
            ].randomElement()!
        case 3:
            return [
                "A workmanlike poop that got the job done.",
                "Middle-of-the-table, but dependable when it mattered.",
                "No fireworks, just sound fundamentals from a seasoned professional."
            ].randomElement()!
        case 2:
            return [
                "A slightly awkward chapter, though still a meaningful contribution.",
                "There were questions, but the mission did conclude.",
                "Not the cleanest shift on record, yet the effort deserves mention."
            ].randomElement()!
        default:
            return [
                "This one raised eyebrows, concerns, and possibly follow-up questions.",
                "A chaotic performance, best filed under character-building.",
                "Not the dog's finest review, but every legend has a rough patch."
            ].randomElement()!
        }
    }

    private static func settingPhrase(
        placeName: String?,
        cityName: String?,
        regionName: String?,
        countryName: String?,
        continentName: String?,
        weatherSummary: String?
    ) -> String {
        let lowercasedPlace = placeName?.lowercased() ?? ""

        if lowercasedPlace.contains("park") || lowercasedPlace.contains("trail") || lowercasedPlace.contains("forest") {
            return "\(cityName ?? "The park") offered a proper green-room stage for this outdoor production."
        }
        if lowercasedPlace.contains("beach") || lowercasedPlace.contains("lake") || lowercasedPlace.contains("river") || lowercasedPlace.contains("harbor") {
            return "A waterside audience was forced to respect the confidence."
        }
        if lowercasedPlace.contains("street") || lowercasedPlace.contains("road") || lowercasedPlace.contains("avenue") {
            return "\(cityName ?? "The city") logged a bold bit of civic participation curbside."
        }
        if let cityName, let countryName {
            return "\(cityName), \(countryName) has now contributed another footnote to the global pooppy atlas."
        }
        if let regionName, let countryName {
            return "\(regionName) in \(countryName) witnessed the latest royal deposit."
        }
        if let continentName {
            return "\(continentName) continues to host serious digestive diplomacy."
        }
        if let weatherSummary {
            return "\(weatherSummary) added useful dramatic lighting."
        }
        return ""
    }

    private static func gapPhrase(_ gap: TimeInterval?) -> String {
        guard let gap else {
            return "An opening statement from the royal digestive office."
        }

        switch gap {
        case ..<3600.0:
            return "This was an audaciously fast encore."
        case ..<(6.0 * 3600.0):
            return "A same-shift sequel arrived with real urgency."
        case ..<(18.0 * 3600.0):
            return "The follow-up chapter landed before the day got stale."
        case ..<(36.0 * 3600.0):
            return "There was just enough suspense before the next installment."
        default:
            return "After a long silence, the plot returned with conviction."
        }
    }

    private static func temperaturePhrase(_ temperatureCelsius: Double?) -> String {
        guard let temperatureCelsius else { return "" }
        switch temperatureCelsius {
        case ..<0:
            return "The air was properly freezing, which adds real character to the paperwork."
        case ..<8:
            return "It was brisk enough to keep both hands moving with purpose."
        case ..<18:
            return "Cool-weather conditions kept the whole affair pleasantly businesslike."
        case ..<26:
            return "Mild temperatures made this feel like a professionally scheduled outing."
        default:
            return "Warm air turned the whole event into a summer logistics exercise."
        }
    }

    private static func altitudePhrase(_ altitudeMeters: Double?) -> String {
        guard let altitudeMeters else { return "" }
        switch altitudeMeters {
        case ..<10:
            return "This one happened practically at sea-level, right down where the drama collects."
        case ..<100:
            return "A lowland contribution, grounded and humble."
        case ..<300:
            return "Slight elevation gave the moment a hilltop confidence."
        case ..<800:
            return "This climbed high enough to feel faintly alpine."
        default:
            return "At this altitude, even the poop had panoramic ambitions."
        }
    }

    private static func closerPhrase(for rating: Int, hour: Int, weatherSummary: String?) -> String {
        if hour < 11 && rating >= 4 {
            return "Coffee for you, emotional closure for the dog."
        }
        if hour >= 21 && rating >= 4 {
            return "Bedtime should now proceed with uncommon confidence."
        }
        if let weatherSummary, weatherSummary.localizedCaseInsensitiveContains("rain") {
            return "Even the weather had to admit the timing was bold."
        }
        if rating == 5 {
            return "Somewhere, a tiny parade should be forming."
        }
        if rating <= 2 {
            return "Monitor vibes, trust your instincts, and maybe keep the pace gentle."
        }
        return "The route may continue with heads held high."
    }
}
