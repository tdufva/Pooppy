import SwiftUI

struct PoopStatsView: View {
    @ObservedObject var store: PoopStore

    private let calendar = Calendar.current
    private var insights: PoopInsights { PoopInsightEngine.insights(for: store.entries) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Stats")
                            .font(.largeTitle.bold())
                            .foregroundStyle(PooppyTheme.espresso)

                        Text("A weekly leaderboard for your dog's finest contributions.")
                            .font(.headline)
                            .foregroundStyle(PooppyTheme.cocoa.opacity(0.85))
                    }
                    .padding(.horizontal)

                    HStack(spacing: 14) {
                        StatCard(title: "This Week", value: "\(weeklyEntries.count)", caption: "poops logged", tint: PooppyTheme.caramel)
                        StatCard(title: "Average", value: weeklyAverageString, caption: "star rating", tint: PooppyTheme.moss)
                    }
                    .padding(.horizontal)

                    HStack(spacing: 14) {
                        StatCard(title: "Best Score", value: "\(bestWeeklyRating)", caption: "stars this week", tint: PooppyTheme.gold)
                        StatCard(title: "All-Time", value: "\(store.entries.count)", caption: "total poops", tint: PooppyTheme.espresso)
                    }
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Best Poops This Week")
                            .font(.title3.bold())
                            .foregroundStyle(PooppyTheme.espresso)

                        if bestWeeklyEntries.isEmpty {
                            Text("No champion poops yet this week. Go make history.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(bestWeeklyEntries.prefix(3)) { entry in
                                WeeklyChampionRow(entry: entry)
                            }
                        }
                    }
                    .pooppyCardStyle()
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Current Chaos")
                            .font(.title3.bold())
                            .foregroundStyle(PooppyTheme.espresso)

                        Text(latestReview)
                            .font(.body)
                            .foregroundStyle(PooppyTheme.cocoa)
                    }
                    .pooppyCardStyle()
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Trend")
                            .font(.title3.bold())
                            .foregroundStyle(PooppyTheme.espresso)

                        if lastSevenDays.isEmpty {
                            Text("You need a few more poops before the chart gets interesting.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(lastSevenDays, id: \.date) { item in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(item.date.formatted(.dateTime.weekday(.wide)))
                                            .font(.headline)

                                        Spacer()

                                        Text("\(item.count) logged")
                                            .foregroundStyle(.secondary)
                                    }

                                    GeometryReader { proxy in
                                        Capsule()
                                            .fill(PooppyTheme.caramel.opacity(0.18))
                                            .overlay(alignment: .leading) {
                                                Capsule()
                                                    .fill(PooppyTheme.caramel)
                                                    .frame(width: max(proxy.size.width * item.ratio, 10))
                                            }
                                    }
                                    .frame(height: 10)
                                }
                            }
                        }
                    }
                    .pooppyCardStyle()
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Distance Records")
                            .font(.title3.bold())
                            .foregroundStyle(PooppyTheme.espresso)

                        recordRow(
                            title: "Nearest Poops",
                            value: insights.nearestPoops.map { Measurement(value: $0.value, unit: UnitLength.meters).formatted(.measurement(width: .abbreviated, usage: .road)) } ?? "Not enough mapped poops",
                            detail: insights.nearestPoops.map(pairDetail)
                        )

                        recordRow(
                            title: "Longest Trek",
                            value: insights.farthestPoops.map { Measurement(value: $0.value, unit: UnitLength.meters).formatted(.measurement(width: .abbreviated, usage: .road)) } ?? "Not enough mapped poops",
                            detail: insights.farthestPoops.map(pairDetail)
                        )
                    }
                    .pooppyCardStyle()
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Timing Records")
                            .font(.title3.bold())
                            .foregroundStyle(PooppyTheme.espresso)

                        recordRow(
                            title: "Shortest Gap",
                            value: insights.shortestGap.map(formatGap(_:)) ?? "Need at least two poops",
                            detail: insights.shortestGap.map(pairDetail)
                        )

                        recordRow(
                            title: "Longest Gap",
                            value: insights.longestGap.map(formatGap(_:)) ?? "Need at least two poops",
                            detail: insights.longestGap.map(pairDetail)
                        )
                    }
                    .pooppyCardStyle()
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Monthly Form")
                            .font(.title3.bold())
                            .foregroundStyle(PooppyTheme.espresso)

                        recordRow(
                            title: "Best Month",
                            value: insights.bestMonth.map(monthSummary(_:)) ?? "No monthly data yet",
                            detail: insights.bestMonth.map { "\($0.count) logged in \($0.month.formatted(.dateTime.month(.wide).year()))" }
                        )

                        recordRow(
                            title: "Worst Month",
                            value: insights.worstMonth.map(monthSummary(_:)) ?? "No monthly data yet",
                            detail: insights.worstMonth.map { "\($0.count) logged in \($0.month.formatted(.dateTime.month(.wide).year()))" }
                        )
                    }
                    .pooppyCardStyle()
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Weather Records")
                            .font(.title3.bold())
                            .foregroundStyle(PooppyTheme.espresso)

                        recordRow(
                            title: "Coldest Poop",
                            value: insights.coldestPoop.map(formatTemperature(_:)) ?? "No weather data yet",
                            detail: insights.coldestPoop.map(entryDetail(_:))
                        )

                        recordRow(
                            title: "Warmest Poop",
                            value: insights.warmestPoop.map(formatTemperature(_:)) ?? "No weather data yet",
                            detail: insights.warmestPoop.map(entryDetail(_:))
                        )
                    }
                    .pooppyCardStyle()
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Altitude Records")
                            .font(.title3.bold())
                            .foregroundStyle(PooppyTheme.espresso)

                        recordRow(
                            title: "Highest Poop",
                            value: insights.highestPoop.map(formatAltitude(_:)) ?? "No altitude data yet",
                            detail: insights.highestPoop.map(entryDetail(_:))
                        )

                        recordRow(
                            title: "Lowest Poop",
                            value: insights.lowestPoop.map(formatAltitude(_:)) ?? "No altitude data yet",
                            detail: insights.lowestPoop.map(entryDetail(_:))
                        )
                    }
                    .pooppyCardStyle()
                    .padding(.horizontal)
                }
                .padding(.vertical, 20)
            }
            .navigationTitle("Poop Stats")
            .navigationBarTitleDisplayMode(.inline)
            .pooppyBackground()
            .task {
                await store.refreshMissingPlaceNames()
            }
        }
    }

    private var weeklyEntries: [PoopEntry] {
        let interval = calendar.dateInterval(of: .weekOfYear, for: .now)
        return store.entries.filter { entry in
            guard let interval else { return false }
            return interval.contains(entry.timestamp)
        }
    }

    private var bestWeeklyEntries: [PoopEntry] {
        let topRating = weeklyEntries.map(\.rating).max() ?? 0
        return weeklyEntries
            .filter { $0.rating == topRating && topRating > 0 }
            .sorted { $0.timestamp > $1.timestamp }
    }

    private var bestWeeklyRating: Int {
        bestWeeklyEntries.first?.rating ?? 0
    }

    private var weeklyAverage: Double {
        guard !weeklyEntries.isEmpty else { return 0 }
        return Double(weeklyEntries.map(\.rating).reduce(0, +)) / Double(weeklyEntries.count)
    }

    private var weeklyAverageString: String {
        weeklyEntries.isEmpty ? "0.0" : weeklyAverage.formatted(.number.precision(.fractionLength(1)))
    }

    private var lastSevenDays: [(date: Date, count: Int, ratio: Double)] {
        let startOfToday = calendar.startOfDay(for: .now)
        let days = (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: startOfToday)
        }.reversed()

        let counts = days.map { day -> (date: Date, count: Int) in
            let nextDay = calendar.date(byAdding: .day, value: 1, to: day) ?? day
            let count = store.entries.filter { $0.timestamp >= day && $0.timestamp < nextDay }.count
            return (day, count)
        }

        let maxCount = counts.map(\.count).max() ?? 1
        return counts.map { item in
            let ratio = maxCount == 0 ? 0 : Double(item.count) / Double(maxCount)
            return (item.date, item.count, ratio)
        }
    }

    private var latestReview: String {
        store.entries.first?.displayReview ?? "No poop reviews yet. The critics remain seated."
    }

    private func formatGap(_ record: PoopPairRecord) -> String {
        let interval = record.value
        if interval < 3_600 {
            return "\(Int(interval / 60)) min"
        }
        if interval < 86_400 {
            return "\(String(format: "%.1f", interval / 3_600)) hr"
        }
        return "\(String(format: "%.1f", interval / 86_400)) days"
    }

    private func monthSummary(_ month: PoopMonthRecord) -> String {
        "\(month.month.formatted(.dateTime.month(.wide).year())) • \(month.averageRating.formatted(.number.precision(.fractionLength(1)))) avg"
    }

    private func formatTemperature(_ record: PoopEntryRecord) -> String {
        "\(record.value.formatted(.number.precision(.fractionLength(1))))°C"
    }

    private func formatAltitude(_ record: PoopEntryRecord) -> String {
        Measurement(value: record.value, unit: UnitLength.meters).formatted(.measurement(width: .abbreviated, usage: .general))
    }

    private func pairDetail(_ record: PoopPairRecord) -> String {
        "\(record.first.timestamp.formatted(date: .abbreviated, time: .shortened)) -> \(record.second.timestamp.formatted(date: .abbreviated, time: .shortened))"
    }

    private func entryDetail(_ record: PoopEntryRecord) -> String {
        "\(record.entry.timestamp.formatted(date: .abbreviated, time: .shortened)) • \(record.entry.weatherAddressLine)"
    }

    @ViewBuilder
    private func recordRow(title: String, value: String, detail: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(PooppyTheme.espresso)
                Spacer()
                Text(value)
                    .font(.subheadline.bold())
                    .foregroundStyle(PooppyTheme.caramel)
            }

            if let detail {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let caption: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)

            Text(value)
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(PooppyTheme.espresso)

            Text(caption)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .pooppyCardStyle()
    }
}

private struct WeeklyChampionRow: View {
    let entry: PoopEntry

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(PooppyTheme.gold.opacity(0.22))
                    .frame(width: 46, height: 46)

                Text("\(entry.rating)")
                    .font(.headline.bold())
                    .foregroundStyle(PooppyTheme.espresso)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(entry.ratingLabel)
                    .font(.headline)

                Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let coordinate = entry.coordinate {
                    Text(entry.placeName ?? "\(coordinate.latitude.formatted(.number.precision(.fractionLength(3)))), \(coordinate.longitude.formatted(.number.precision(.fractionLength(3))))")
                        .font(.caption)
                        .foregroundStyle(PooppyTheme.cocoa)
                }
            }

            Spacer()
        }
        .padding(14)
        .background(PooppyTheme.sand.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
