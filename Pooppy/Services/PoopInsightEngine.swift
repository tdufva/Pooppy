import CoreLocation
import Foundation

struct PoopPairRecord {
    let first: PoopEntry
    let second: PoopEntry
    let value: Double
}

struct PoopMonthRecord {
    let month: Date
    let averageRating: Double
    let count: Int
}

struct PoopEntryRecord {
    let entry: PoopEntry
    let value: Double
}

struct PoopInsights {
    let nearestPoops: PoopPairRecord?
    let farthestPoops: PoopPairRecord?
    let shortestGap: PoopPairRecord?
    let longestGap: PoopPairRecord?
    let bestMonth: PoopMonthRecord?
    let worstMonth: PoopMonthRecord?
    let coldestPoop: PoopEntryRecord?
    let warmestPoop: PoopEntryRecord?
    let highestPoop: PoopEntryRecord?
    let lowestPoop: PoopEntryRecord?
}

enum PoopInsightEngine {
    static func insights(for entries: [PoopEntry]) -> PoopInsights {
        let sortedEntries = entries.sorted { $0.timestamp < $1.timestamp }
        let consecutivePairs = zip(sortedEntries, sortedEntries.dropFirst()).map { ($0, $1) }

        let distancePairs = consecutivePairs.compactMap { first, second -> PoopPairRecord? in
            guard let firstCoordinate = first.coordinate, let secondCoordinate = second.coordinate else {
                return nil
            }

            let firstLocation = CLLocation(latitude: firstCoordinate.latitude, longitude: firstCoordinate.longitude)
            let secondLocation = CLLocation(latitude: secondCoordinate.latitude, longitude: secondCoordinate.longitude)
            return PoopPairRecord(first: first, second: second, value: firstLocation.distance(from: secondLocation))
        }

        let timePairs = consecutivePairs.map { first, second in
            PoopPairRecord(first: first, second: second, value: second.timestamp.timeIntervalSince(first.timestamp))
        }

        let monthRecords = monthlyRecords(from: entries)
        let temperatureEntries = entries.compactMap { entry in
            entry.temperatureCelsius.map { PoopEntryRecord(entry: entry, value: $0) }
        }
        let altitudeEntries = entries.compactMap { entry in
            entry.altitudeMeters.map { PoopEntryRecord(entry: entry, value: $0) }
        }

        return PoopInsights(
            nearestPoops: distancePairs.min(by: { $0.value < $1.value }),
            farthestPoops: distancePairs.max(by: { $0.value < $1.value }),
            shortestGap: timePairs.min(by: { $0.value < $1.value }),
            longestGap: timePairs.max(by: { $0.value < $1.value }),
            bestMonth: monthRecords.max(by: { $0.averageRating < $1.averageRating }),
            worstMonth: monthRecords.min(by: { $0.averageRating < $1.averageRating }),
            coldestPoop: temperatureEntries.min(by: { $0.value < $1.value }),
            warmestPoop: temperatureEntries.max(by: { $0.value < $1.value }),
            highestPoop: altitudeEntries.max(by: { $0.value < $1.value }),
            lowestPoop: altitudeEntries.min(by: { $0.value < $1.value })
        )
    }

    private static func monthlyRecords(from entries: [PoopEntry]) -> [PoopMonthRecord] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) { entry in
            calendar.date(from: calendar.dateComponents([.year, .month], from: entry.timestamp)) ?? entry.timestamp
        }

        return grouped.map { month, entries in
            let total = entries.map(\.rating).reduce(0, +)
            return PoopMonthRecord(
                month: month,
                averageRating: Double(total) / Double(entries.count),
                count: entries.count
            )
        }
    }
}
