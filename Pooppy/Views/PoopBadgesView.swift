import SwiftUI

struct PoopBadgesView: View {
    @ObservedObject var store: PoopStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Badges")
                            .font(.largeTitle.bold())
                            .foregroundStyle(PooppyTheme.espresso)

                        Text("Rewarding consistency, chaos, and all the strange little milestones in between.")
                            .font(.headline)
                            .foregroundStyle(PooppyTheme.cocoa.opacity(0.85))
                    }
                    .padding(.horizontal)

                    HStack(spacing: 14) {
                        badgeSummaryCard(title: "Unlocked", value: "\(earnedBadges.count)", tint: PooppyTheme.moss)
                        badgeSummaryCard(title: "Total", value: "\(badges.count)", tint: PooppyTheme.caramel)
                    }
                    .padding(.horizontal)

                    if !earnedBadges.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Top Shelf")
                                .font(.title3.bold())
                                .foregroundStyle(PooppyTheme.espresso)

                            Text("The finest trophies in the royal poop cabinet.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(alignment: .bottom, spacing: 18) {
                                    ForEach(earnedBadges) { badge in
                                        VStack(spacing: 12) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                    .fill(
                                                        LinearGradient(
                                                            colors: [PooppyTheme.gold.opacity(0.95), PooppyTheme.sand.opacity(0.85)],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                                    .frame(width: 118, height: 118)

                                                Image(systemName: badge.symbol)
                                                    .font(.system(size: 42, weight: .black))
                                                    .foregroundStyle(PooppyTheme.espresso)
                                            }
                                            .overlay(alignment: .topTrailing) {
                                                Circle()
                                                    .fill(PooppyTheme.moss)
                                                    .frame(width: 16, height: 16)
                                                    .overlay {
                                                        Image(systemName: "checkmark")
                                                            .font(.system(size: 8, weight: .black))
                                                            .foregroundStyle(.white)
                                                    }
                                                    .offset(x: 6, y: -6)
                                            }

                                            Text(badge.title)
                                                .font(.subheadline.bold())
                                                .multilineTextAlignment(.center)
                                                .foregroundStyle(PooppyTheme.espresso)
                                                .frame(width: 124)
                                        }
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 12)
                            }
                            .scrollClipDisabled()
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 28, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [PooppyTheme.cream, PooppyTheme.sand.opacity(0.8)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            )
                            .overlay(alignment: .bottom) {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(PooppyTheme.cocoa.opacity(0.16))
                                    .frame(height: 20)
                                    .padding(.horizontal, 26)
                                    .offset(y: 24)
                            }
                        }
                        .padding(.horizontal)
                    }

                    LazyVStack(spacing: 14) {
                        ForEach(badges) { badge in
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill((badge.earned ? PooppyTheme.gold : PooppyTheme.sand).opacity(0.35))
                                        .frame(width: 54, height: 54)

                                    Image(systemName: badge.symbol)
                                        .font(.title3.bold())
                                        .foregroundStyle(badge.earned ? PooppyTheme.espresso : .secondary)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(badge.title)
                                            .font(.headline)
                                            .foregroundStyle(PooppyTheme.espresso)
                                        Spacer()
                                        Text(badge.earned ? "Earned" : "Locked")
                                            .font(.caption.bold())
                                            .foregroundStyle(badge.earned ? PooppyTheme.moss : .secondary)
                                    }

                                    Text(badge.blurb)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .opacity(badge.earned ? 1 : 0.7)
                            .pooppyCardStyle()
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 20)
            }
            .navigationTitle("Poop Badges")
            .navigationBarTitleDisplayMode(.inline)
            .pooppyBackground()
        }
    }

    private var badges: [PoopBadge] {
        PoopBadgeEngine.badges(for: store.entries)
    }

    private var earnedBadges: [PoopBadge] {
        badges.filter(\.earned)
    }

    private func badgeSummaryCard(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption.bold())
                .foregroundStyle(tint)
            Text(value)
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(PooppyTheme.espresso)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .pooppyCardStyle()
    }
}
