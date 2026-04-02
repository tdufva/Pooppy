import Foundation

enum PoopBadgeEngine {
    static func badges(for entries: [PoopEntry]) -> [PoopBadge] {
        let calendar = Calendar.current
        let insights = PoopInsightEngine.insights(for: entries)
        let groupedByDay = Dictionary(grouping: entries) { calendar.startOfDay(for: $0.timestamp) }
        let dailyCounts = groupedByDay.mapValues(\.count)
        let uniqueLocationCount = Set<String>(entries.compactMap { entry in
            guard let lat = entry.latitude, let lon = entry.longitude else { return nil }
            return "\(lat.roundedTo(places: 3)):\(lon.roundedTo(places: 3))"
        }).count

        let morningCount = entries.filter {
            let hour = calendar.component(.hour, from: $0.timestamp)
            return hour >= 5 && hour < 11
        }.count

        let nightCount = entries.filter {
            let hour = calendar.component(.hour, from: $0.timestamp)
            return hour >= 21 || hour < 5
        }.count

        let fiveStarCount = entries.filter { $0.rating == 5 }.count
        let lowRatedCount = entries.filter { $0.rating <= 2 }.count
        let streak = longestDailyStreak(in: groupedByDay.keys.sorted(), calendar: calendar)
        let currentStreak = currentDailyStreak(in: groupedByDay.keys.sorted(), calendar: calendar)
        let weatherCounts = weatherCategoryCounts(entries)
        let locationCounts = locationCategoryCounts(entries)
        let weekdayCoverage = longestWeekdayCoverageRun(in: entries, calendar: calendar)
        let allWeatherVariety = ["rain", "sunny", "cloudy"].allSatisfy { weatherCounts[$0, default: 0] >= 5 }
        let allLocationVariety = ["park", "city", "field", "water", "garden"].allSatisfy { locationCounts[$0, default: 0] >= 1 }
        let altitudeSpread = altitudeSpread(in: entries)
        let uniqueCityCount = Set(entries.compactMap(\.cityName).filter { !$0.isEmpty }).count
        let uniqueRegionCount = Set(entries.compactMap(\.regionName).filter { !$0.isEmpty }).count
        let uniqueCountryCount = Set(entries.compactMap(\.countryName).filter { !$0.isEmpty }).count
        let uniqueContinentCount = Set(entries.compactMap(\.continentName).filter { !$0.isEmpty }).count
        let snowCount = entries.filter { ($0.weatherSummary ?? "").localizedCaseInsensitiveContains("snow") || ($0.weatherSummary ?? "").localizedCaseInsensitiveContains("flurr") }.count
        let windyCount = entries.filter { ($0.weatherSummary ?? "").localizedCaseInsensitiveContains("wind") || ($0.weatherSummary ?? "").localizedCaseInsensitiveContains("breez") }.count
        let freezingCount = entries.filter { ($0.temperatureCelsius ?? .greatestFiniteMagnitude) <= 0 }.count
        let hotCount = entries.filter { ($0.temperatureCelsius ?? -.greatestFiniteMagnitude) >= 25 }.count

        var definitions: [(String, String, String, Bool)] = [
            ("first-drop", "First Drop", "sparkles", entries.count >= 1),
            ("ten-club", "Ten-Turd Club", "rosette", entries.count >= 10),
            ("silver-scooper", "Silver Scooper", "figure.badminton", entries.count >= 25),
            ("centurion", "Poop Centurion", "trophy", entries.count >= 100),
            ("double-deuce", "Double Deuce", "medal.fill", entries.count >= 200),
            ("quarter-pounder", "Quarter-Pounder Ledger", "star.square.on.square.fill", entries.count >= 250),
            ("five-hundo", "Five-Hundo Heap", "laurel.leading", entries.count >= 500),
            ("tri-plopper", "Triple Plopper", "3.circle.fill", dailyCounts.values.contains(where: { $0 >= 3 })),
            ("quad-squad", "Quad Squad", "4.circle.fill", dailyCounts.values.contains(where: { $0 >= 4 })),
            ("too-much-poop", "Is That... Too Much Poop?", "5.circle.fill", dailyCounts.values.contains(where: { $0 >= 5 })),
            ("dawn-patrol", "Dawn Patrol", "sunrise.fill", morningCount >= 5),
            ("breakfast-committee", "Breakfast Committee", "sun.max.circle.fill", morningCount >= 15),
            ("midnight-runner", "Bedtime Bomber", "moon.stars.fill", nightCount >= 5),
            ("moonlight-madness", "Moonlight Madness", "moon.circle.fill", nightCount >= 15),
            ("critic-choice", "Critics' Choice", "star.circle.fill", fiveStarCount >= 10),
            ("standing-ovation", "Standing Ovation", "star.bubble.fill", fiveStarCount >= 25),
            ("mud-reviewer", "Mud Reviewer", "hand.thumbsdown.fill", lowRatedCount >= 10),
            ("map-explorer", "Neighborhood Explorer", "map.circle.fill", uniqueLocationCount >= 10),
            ("three-day", "Three-Day Streak", "flame.fill", streak >= 3),
            ("week-warrior", "Week-Long Streak", "flame.circle.fill", streak >= 7),
            ("fortnight-fanatic", "Fortnight Fanatic", "calendar.badge.clock", streak >= 14),
            ("thirty-dirty", "Thirty Dirty", "calendar.badge.exclamationmark", streak >= 30),
            ("right-now-hot", "Currently On A Heater", "bolt.heart.fill", currentStreak >= 5),
            ("weekend-specialist", "Weekend Specialist", "party.popper.fill", weekendEntries(entries, calendar: calendar) >= 6),
            ("rapid-repeat", "Back-To-Back Blast", "hare.fill", (insights.shortestGap?.value ?? .greatestFiniteMagnitude) <= 7_200),
            ("same-block", "Same-Block Specialist", "figure.walk.circle.fill", (insights.nearestPoops?.value ?? .greatestFiniteMagnitude) <= 50),
            ("long-haul", "Long-Haul Loafer", "figure.hiking", (insights.farthestPoops?.value ?? 0) >= 2_000),
            ("month-king", "Month Monarch", "crown.fill", (insights.bestMonth?.averageRating ?? 0) >= 4.5 && (insights.bestMonth?.count ?? 0) >= 3),
            ("weekday-hat-trick", "Weekday Hat Trick", "calendar", weekdayCoverage >= 3),
            ("weekday-marathon", "Weekday Marathon", "calendar.badge.plus", weekdayCoverage >= 5),
            ("full-week-sweep", "Seven-Day Sweep", "calendar.circle.fill", weekdayCoverage >= 7),
            ("forecast-completionist", "Forecast Completionist", "cloud.sun.rain.fill", allWeatherVariety),
            ("terrain-taster", "Terrain Taster", "globe.americas.fill", allLocationVariety),
            ("city-slicker", "City Slicker Sticker", "building.2.crop.circle.fill", uniqueCityCount >= 3),
            ("regional-manager", "Regional Manager", "map.fill", uniqueRegionCount >= 3),
            ("passport-plopper", "Passport Plopper", "airplane.circle.fill", uniqueCountryCount >= 2),
            ("continental-drifter", "Continental Drifter", "globe.europe.africa.fill", uniqueContinentCount >= 2),
            ("mount-poopsuvius", "Mount Poopsuvius", "mountain.2.fill", (insights.highestPoop?.value ?? -.greatestFiniteMagnitude) >= 500),
            ("hill-hound", "Hill Hound", "mountain.2.circle.fill", (insights.highestPoop?.value ?? -.greatestFiniteMagnitude) >= 100),
            ("deep-end-deputy", "Deep-End Deputy", "arrow.down.circle.fill", (insights.lowestPoop?.value ?? .greatestFiniteMagnitude) <= 5),
            ("frozen-assets", "Frozen Assets", "snowflake", (insights.coldestPoop?.value ?? .greatestFiniteMagnitude) <= 0),
            ("summer-bottom", "Summer Bottom", "thermometer.sun.fill", (insights.warmestPoop?.value ?? -.greatestFiniteMagnitude) >= 25),
            ("vertical-portfolio", "Vertical Portfolio", "arrow.up.and.down.circle.fill", altitudeSpread >= 250),
            ("snow-show", "Snow Show", "snowflake.circle.fill", snowCount >= 3),
            ("wind-breaker", "Wind Breaker", "wind", windyCount >= 5),
            ("cold-turkey", "Cold Turkey", "thermometer.snowflake", freezingCount >= 5),
            ("heat-seeker", "Heat Seeker", "thermometer.sun.circle.fill", hotCount >= 5)
        ]

        var blurbs: [String: String] = [
            "first-drop": "The logbook is officially open.",
            "ten-club": "Ten recorded masterpieces. The judges are paying attention.",
            "silver-scooper": "Twenty-five poops logged. This is no longer a hobby.",
            "centurion": "One hundred tracked dumps. Historians will study this run.",
            "double-deuce": "Two hundred logs deep. This operation now has middle management.",
            "quarter-pounder": "Two hundred fifty entries. The spreadsheet has gained sentience.",
            "five-hundo": "Five hundred poops tracked. This is a dynasty, not a diary.",
            "tri-plopper": "Three poops in one day. A hat trick of urgency.",
            "quad-squad": "Four in one day. The yard has concerns.",
            "too-much-poop": "Five in one day. Even the app is asking questions.",
            "dawn-patrol": "Five successful morning missions before brunch.",
            "breakfast-committee": "Fifteen morning deposits. Breakfast is now a board meeting.",
            "midnight-runner": "Five late-night rescue runs for the sake of sleep.",
            "moonlight-madness": "Fifteen night missions. The moon knows your schedule.",
            "critic-choice": "Ten five-star performances. The reviewers are moved.",
            "standing-ovation": "Twenty-five elite outings. The balcony crowd is on its feet.",
            "mud-reviewer": "Ten low-rated incidents. Someone in this relationship is a tough critic.",
            "map-explorer": "Ten distinct poop zones marked across the kingdom.",
            "three-day": "Three straight days of dependable output.",
            "week-warrior": "Seven days in a row. Routine has become religion.",
            "fortnight-fanatic": "Fourteen straight days. Consistency bordering on art.",
            "thirty-dirty": "Thirty straight days. The habit has become an institution.",
            "right-now-hot": "A current streak of five days and counting.",
            "weekend-specialist": "Weekends have become oddly productive.",
            "rapid-repeat": "Two poops landed within two hours. Respectfully, wow.",
            "same-block": "Two consecutive poops happened basically on the same patch of Earth.",
            "long-haul": "A truly dramatic distance separated one poop from the next.",
            "month-king": "One month averaged pure excellence and entered the royal archives.",
            "weekday-hat-trick": "Three weekday names in a row have all joined the poop ledger.",
            "weekday-marathon": "Five weekdays in sequence are now part of the routine.",
            "full-week-sweep": "Every day of the week has now carried its fair share of duty.",
            "forecast-completionist": "Rain, cloud, and sun all made the poop résumé.",
            "terrain-taster": "Park, city, field, water, and garden all entered the portfolio.",
            "city-slicker": "Three city names have entered the legend. Urban planning has opinions.",
            "regional-manager": "Three regions are now under active digestive supervision.",
            "passport-plopper": "Two countries have now hosted official deposits.",
            "continental-drifter": "Multiple continents are now part of the royal bowel map.",
            "mount-poopsuvius": "A genuinely lofty contribution now towers over the rest.",
            "hill-hound": "A hilltop performance proved gravity can be negotiated.",
            "deep-end-deputy": "One dump got suspiciously close to sea-level intrigue.",
            "frozen-assets": "A poop was logged at freezing or below. Character was built.",
            "summer-bottom": "A warm-weather masterpiece was delivered in serious heat.",
            "vertical-portfolio": "The altitude spread on this logbook now has dramatic range.",
            "snow-show": "At least three poops were staged in snow-globe conditions.",
            "wind-breaker": "Five windy missions. The cape was not optional.",
            "cold-turkey": "Five cold-weather outings. The paws and pride both held up.",
            "heat-seeker": "Five warm-weather logs. Summer did not slow the operation."
        ]

        let weatherMilestones = [3, 5, 10, 50, 100, 150, 200, 250, 500]
        let weatherDefinitions = [
            ("rain", "Rain Walker", "cloud.rain.fill"),
            ("sunny", "Sun Chaser", "sun.max.fill"),
            ("cloudy", "Cloud Collector", "cloud.fill")
        ]

        for (key, titlePrefix, symbol) in weatherDefinitions {
            let count = weatherCounts[key, default: 0]
            for milestone in weatherMilestones {
                let id = "\(key)-\(milestone)"
                definitions.append((id, "\(titlePrefix) \(milestone)", symbol, count >= milestone))
                blurbs[id] = "\(milestone) poops logged during \(titlePrefix.lowercased()) conditions."
            }
        }

        let locationDefinitions = [
            ("park", "Park Specialist", "tree.fill"),
            ("city", "City Specialist", "building.2.fill"),
            ("field", "Field Specialist", "leaf.fill"),
            ("water", "Waterfront Specialist", "water.waves"),
            ("garden", "Garden Specialist", "camera.macro")
        ]

        for (key, titlePrefix, symbol) in locationDefinitions {
            let count = locationCounts[key, default: 0]
            for milestone in [3, 5, 10, 25, 50, 100] {
                let id = "\(key)-\(milestone)"
                definitions.append((id, "\(titlePrefix) \(milestone)", symbol, count >= milestone))
                blurbs[id] = "\(milestone) poops have now landed in \(titlePrefix.lowercased()) territory."
            }
        }

        return definitions.map { id, title, symbol, earned in
            PoopBadge(id: id, title: title, symbol: symbol, blurb: blurbs[id] ?? "", earned: earned)
        }
    }

    static func badgeNarrative(previousEntries: [PoopEntry], updatedEntries: [PoopEntry]) -> String? {
        let previousBadges = Dictionary(uniqueKeysWithValues: badges(for: previousEntries).map { ($0.id, $0) })
        let updatedBadges = badges(for: updatedEntries)

        if let newlyUnlocked = updatedBadges.first(where: { badge in
            badge.earned && previousBadges[badge.id]?.earned != true
        }) {
            return "Badge unlocked: \(newlyUnlocked.title)."
        }

        return nearUnlockHint(for: updatedEntries)
    }

    private static func longestDailyStreak(in days: [Date], calendar: Calendar) -> Int {
        guard let first = days.first else { return 0 }
        var longest = 1
        var current = 1
        var previous = first

        for day in days.dropFirst() {
            let expected = calendar.date(byAdding: .day, value: 1, to: previous)
            if let expected, calendar.isDate(day, inSameDayAs: expected) {
                current += 1
            } else {
                current = 1
            }
            longest = max(longest, current)
            previous = day
        }

        return longest
    }

    private static func currentDailyStreak(in days: [Date], calendar: Calendar) -> Int {
        guard !days.isEmpty else { return 0 }
        let sorted = days.sorted()
        guard let last = sorted.last else { return 0 }
        let today = calendar.startOfDay(for: .now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        guard calendar.isDate(last, inSameDayAs: today) || calendar.isDate(last, inSameDayAs: yesterday) else {
            return 0
        }

        var streak = 1
        var current = last
        for day in sorted.dropLast().reversed() {
            let expected = calendar.date(byAdding: .day, value: -1, to: current)
            if let expected, calendar.isDate(day, inSameDayAs: expected) {
                streak += 1
                current = day
            } else if calendar.isDate(day, inSameDayAs: current) {
                continue
            } else {
                break
            }
        }
        return streak
    }

    private static func weekendEntries(_ entries: [PoopEntry], calendar: Calendar) -> Int {
        entries.filter {
            let weekday = calendar.component(.weekday, from: $0.timestamp)
            return weekday == 1 || weekday == 7
        }.count
    }

    private static func weatherCategoryCounts(_ entries: [PoopEntry]) -> [String: Int] {
        entries.reduce(into: [String: Int]()) { counts, entry in
            let weather = (entry.weatherSummary ?? "").lowercased()

            if weather.contains("rain") || weather.contains("drizzle") || weather.contains("shower") {
                counts["rain", default: 0] += 1
            }
            if weather.contains("clear") || weather.contains("sun") {
                counts["sunny", default: 0] += 1
            }
            if weather.contains("cloud") {
                counts["cloudy", default: 0] += 1
            }
        }
    }

    private static func locationCategoryCounts(_ entries: [PoopEntry]) -> [String: Int] {
        entries.reduce(into: [String: Int]()) { counts, entry in
            let location = entry.displayLocationName.lowercased()

            if location.contains("park") || location.contains("trail") || location.contains("forest") {
                counts["park", default: 0] += 1
            }
            if location.contains("street") || location.contains("road") || location.contains("avenue") || location.contains("boulevard") {
                counts["city", default: 0] += 1
            }
            if location.contains("field") || location.contains("meadow") || location.contains("farm") || location.contains("pasture") {
                counts["field", default: 0] += 1
            }
            if location.contains("beach") || location.contains("lake") || location.contains("river") || location.contains("harbor") || location.contains("sea") {
                counts["water", default: 0] += 1
            }
            if location.contains("garden") || location.contains("yard") {
                counts["garden", default: 0] += 1
            }
        }
    }

    private static func longestWeekdayCoverageRun(in entries: [PoopEntry], calendar: Calendar) -> Int {
        let weekdaySet = Set(entries.map { calendar.component(.weekday, from: $0.timestamp) })
        guard !weekdaySet.isEmpty else { return 0 }

        let doubled = Array(1...7) + Array(1...7)
        var best = 0
        var current = 0

        for weekday in doubled {
            if weekdaySet.contains(weekday) {
                current += 1
                best = max(best, current)
            } else {
                current = 0
            }
        }

        return min(best, 7)
    }

    private static func altitudeSpread(in entries: [PoopEntry]) -> Double {
        let altitudes = entries.compactMap(\.altitudeMeters)
        guard let min = altitudes.min(), let max = altitudes.max() else {
            return 0
        }
        return max - min
    }

    private static func nearUnlockHint(for entries: [PoopEntry]) -> String? {
        let totalCount = entries.count
        if let milestone = nextMilestone(after: totalCount, in: [10, 25, 100, 200, 250, 500]), milestone - totalCount <= 2 {
            return "\(milestone - totalCount) more log\(milestone - totalCount == 1 ? "" : "s") until \(title(for: milestone))."
        }

        let uniqueCountries = Set(entries.compactMap(\.countryName).filter { !$0.isEmpty }).count
        if uniqueCountries == 1 {
            return "One more country and Passport Plopper goes live."
        }

        let uniqueContinents = Set(entries.compactMap(\.continentName).filter { !$0.isEmpty }).count
        if uniqueContinents == 1 {
            return "A poop on one more continent would unlock Continental Drifter."
        }

        let rainyCount = entries.filter { ($0.weatherSummary ?? "").localizedCaseInsensitiveContains("rain") || ($0.weatherSummary ?? "").localizedCaseInsensitiveContains("drizzle") }.count
        if let milestone = nextMilestone(after: rainyCount, in: [3, 5, 10, 50]), milestone - rainyCount == 1 {
            return "One more rainy outing and Rain Walker \(milestone) joins the shelf."
        }

        let cityCount = Set(entries.compactMap(\.cityName).filter { !$0.isEmpty }).count
        if cityCount == 2 {
            return "One more city and the City Slicker Sticker is yours."
        }

        return nil
    }

    private static func nextMilestone(after count: Int, in milestones: [Int]) -> Int? {
        milestones.sorted().first(where: { count < $0 })
    }

    private static func title(for totalMilestone: Int) -> String {
        switch totalMilestone {
        case 10: return "Ten-Turd Club"
        case 25: return "Silver Scooper"
        case 100: return "Poop Centurion"
        case 200: return "Double Deuce"
        case 250: return "Quarter-Pounder Ledger"
        case 500: return "Five-Hundo Heap"
        default: return "the next trophy"
        }
    }
}

private extension Double {
    func roundedTo(places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
