import SwiftUI

enum PooppyTheme {
    static let espresso = Color(red: 0.21, green: 0.11, blue: 0.06)
    static let cocoa = Color(red: 0.40, green: 0.22, blue: 0.12)
    static let caramel = Color(red: 0.72, green: 0.44, blue: 0.21)
    static let sand = Color(red: 0.96, green: 0.90, blue: 0.81)
    static let cream = Color(red: 0.99, green: 0.96, blue: 0.92)
    static let moss = Color(red: 0.40, green: 0.52, blue: 0.26)
    static let gold = Color(red: 0.97, green: 0.79, blue: 0.27)
    static let sky = Color(red: 0.79, green: 0.90, blue: 0.93)
    static let nightIndigo = Color(red: 0.18, green: 0.21, blue: 0.52)
    static let midnight = Color(red: 0.03, green: 0.05, blue: 0.12)
    static let paper = Color(red: 0.995, green: 0.985, blue: 0.965)

    static let backgroundGradient = LinearGradient(
        colors: [cream, sand, Color.white],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct PooppyBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    PooppyTheme.backgroundGradient
                        .ignoresSafeArea()

                    Circle()
                        .fill(PooppyTheme.gold.opacity(0.15))
                        .frame(width: 260)
                        .offset(x: 120, y: -280)

                    Circle()
                        .fill(PooppyTheme.sky.opacity(0.18))
                        .frame(width: 220)
                        .offset(x: -150, y: 340)
                }
            }
    }
}

struct HappyDogFaceBadge: View {
    var size: CGFloat = 58
    var coatColorName: DogColorName = .white
    var earStyle: DogEarStyle = .floppy
    var leftEarColorName: DogColorName = .white
    var rightEarColorName: DogColorName = .white
    var noseColorName: DogColorName = .charcoal

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.white, PooppyTheme.sky.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            crown
                .offset(y: -size * 0.41)

            ear(isLeft: true)
            ear(isLeft: false)

            Circle()
                .fill(.white)
                .frame(width: size * 0.72, height: size * 0.68)
                .overlay {
                    Circle()
                        .stroke(coatColorName.color.opacity(0.35), lineWidth: size * 0.05)
                }
                .offset(y: size * 0.05)

            Circle()
                .fill(coatColorName.color.opacity(0.45))
                .frame(width: size * 0.48, height: size * 0.18)
                .offset(y: size * 0.20)

            VStack(spacing: size * 0.055) {
                HStack(spacing: size * 0.16) {
                    RoundedRectangle(cornerRadius: size * 0.05, style: .continuous)
                        .fill(PooppyTheme.espresso)
                        .frame(width: size * 0.08, height: size * 0.10)
                    RoundedRectangle(cornerRadius: size * 0.05, style: .continuous)
                        .fill(PooppyTheme.espresso)
                        .frame(width: size * 0.08, height: size * 0.10)
                }
                .padding(.top, size * 0.05)

                ZStack {
                    RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                        .fill(coatColorName.color.opacity(0.18))
                        .frame(width: size * 0.46, height: size * 0.28)
                    RoundedRectangle(cornerRadius: size * 0.08, style: .continuous)
                        .fill(noseColorName.color)
                        .frame(width: size * 0.22, height: size * 0.14)
                }

                SmileShape()
                    .stroke(PooppyTheme.espresso, style: StrokeStyle(lineWidth: size * 0.045, lineCap: .round))
                    .frame(width: size * 0.22, height: size * 0.11)

                HStack(spacing: size * 0.12) {
                    Circle()
                        .fill(PooppyTheme.rose.opacity(0.28))
                        .frame(width: size * 0.09, height: size * 0.09)
                    Circle()
                        .fill(PooppyTheme.rose.opacity(0.28))
                        .frame(width: size * 0.09, height: size * 0.09)
                }
                .offset(y: -size * 0.01)
            }
            .offset(y: size * 0.08)
        }
        .frame(width: size, height: size)
        .shadow(color: PooppyTheme.espresso.opacity(0.12), radius: 10, x: 0, y: 6)
    }

    private var crown: some View {
        ZStack(alignment: .bottom) {
            CrownShape()
                .fill(
                    LinearGradient(
                        colors: [PooppyTheme.gold, PooppyTheme.caramel],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    CrownShape()
                        .stroke(PooppyTheme.espresso.opacity(0.14), lineWidth: size * 0.015)
                }
                .frame(width: size * 0.42, height: size * 0.24)

            Circle()
                .fill(.white.opacity(0.72))
                .frame(width: size * 0.06, height: size * 0.06)
                .offset(y: -size * 0.02)
        }
    }

    @ViewBuilder
    private func ear(isLeft: Bool) -> some View {
        let direction: CGFloat = isLeft ? -1 : 1
        let earColorName = isLeft ? leftEarColorName : rightEarColorName
        let fillGradient = LinearGradient(
            colors: [earColorName.color, earColorName.color.opacity(0.78)],
            startPoint: .top,
            endPoint: .bottom
        )

        switch earStyle {
        case .floppy:
            DogEmojiEarShape()
                .fill(fillGradient)
                .frame(width: size * 0.44, height: size * 0.50)
                .overlay {
                    DogEmojiEarShape()
                        .fill(earColorName.color.opacity(0.18))
                        .padding(size * 0.05)
                }
                .overlay {
                    DogEmojiEarShape()
                        .stroke(Color.black.opacity(0.08), lineWidth: size * 0.012)
                }
                .rotationEffect(.degrees(direction < 0 ? -13 : 13))
                .scaleEffect(x: direction, y: 1)
                .offset(x: direction * size * 0.31, y: -size * 0.14)
        case .teddy:
            PointedEarShape()
                .fill(fillGradient)
                .frame(width: size * 0.40, height: size * 0.48)
                .overlay {
                    PointedEarShape()
                        .fill(earColorName.color.opacity(0.18))
                        .padding(size * 0.055)
                }
                .overlay {
                    PointedEarShape()
                        .stroke(Color.black.opacity(0.08), lineWidth: size * 0.012)
                }
                .rotationEffect(.degrees(direction < 0 ? -4 : 4))
                .offset(x: direction * size * 0.28, y: -size * 0.32)
        case .curly:
            CurlyEarShape()
                .fill(fillGradient)
                .frame(width: size * 0.52, height: size * 0.52)
                .overlay {
                    CurlyEarShape()
                        .fill(earColorName.color.opacity(0.18))
                        .padding(size * 0.06)
                }
                .overlay {
                    CurlyEarShape()
                        .stroke(Color.black.opacity(0.08), lineWidth: size * 0.010)
                }
                .scaleEffect(x: direction, y: 1)
                .offset(x: direction * size * 0.35, y: -size * 0.08)
        }
    }
}

struct PoopPostcardView: View {
    let entry: PoopEntry
    let previousEntry: PoopEntry?
    let dog: DogAccount?

    private var illustration: PoopIllustrationDescriptor {
        PoopIllustrationDescriptor(entry: entry, previousEntry: previousEntry)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(illustration.background)

            PoopSceneArtwork(illustration: illustration, dog: dog)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        }
        .frame(height: 152)
    }
}

private struct PoopIllustrationDescriptor {
    let caption: String
    let subtitle: String
    let background: LinearGradient
    let timeGapLine: String
    let skyTone: Color
    let groundTone: Color
    let poopTone: Color
    let accentTone: Color
    let horizonTone: Color
    let sceneStyle: SceneStyle
    let weatherStyle: WeatherStyle
    let sunStyle: SunStyle
    let featureCount: Int
    let clearNight: Bool
    let dogPose: DogPose
    let dogPlacement: DogPlacement
    let cityLightCount: Int
    let grassTuftCount: Int
    let rippleCount: Int

    init(entry: PoopEntry, previousEntry: PoopEntry?) {
        let hour = Calendar.current.component(.hour, from: entry.timestamp)
        let gap = previousEntry.map { entry.timestamp.timeIntervalSince($0.timestamp) }
        let location = entry.displayLocationName.lowercased()
        let weather = (entry.weatherSummary ?? "").lowercased()

        let isNight = hour < 6 || hour >= 21
        let isMorning = hour >= 6 && hour < 11
        let isPark = location.contains("park") || location.contains("trail") || location.contains("forest")
        let isCity = location.contains("street") || location.contains("road") || location.contains("avenue") || location.contains("boulevard")
        let isWater = location.contains("beach") || location.contains("lake") || location.contains("river") || location.contains("harbor")
        let isField = location.contains("field") || location.contains("meadow") || location.contains("farm") || location.contains("pasture")
        let isGarden = location.contains("garden") || location.contains("yard")
        let isRainy = weather.contains("rain") || weather.contains("drizzle") || weather.contains("shower")
        let isWindy = weather.contains("wind") || weather.contains("breez")
        let isSnowy = weather.contains("snow") || weather.contains("flurr")
        let isSunny = weather.contains("clear") || weather.contains("sun")
        let isCloudy = weather.contains("cloud")
        let clearNight = isNight && !isCloudy && !isRainy && !isSnowy

        sceneStyle = isWater ? .waterfront : (isPark ? .park : (isCity ? .city : (isField ? .field : (isGarden ? .garden : .open))))
        weatherStyle = isSnowy ? .snow : (isRainy ? .rain : (isWindy ? .wind : (isNight ? .night : .clear)))
        sunStyle = isMorning ? .sunrise : ((hour >= 17 && hour < 22) ? .sunset : ((isCloudy && !isNight) ? .cloud : ((isSunny && !isNight) ? .sun : .none)))
        dogPose = entry.rating >= 5 ? .prance : ((entry.rating <= 2 || (gap ?? 0) < 60 * 60) ? .poop : .walk)
        dogPlacement = (isCity || isWater || entry.rating >= 5) ? .rightThird : .leftThird

        caption = {
            if isRainy { return "Rain-Tested Drop" }
            if isSnowy { return "Snow Patrol Deposit" }
            if isPark { return "Park Performance" }
            if isWater { return "Waterfront Offering" }
            if isCity { return "Urban Relief" }
            if isField { return "Field Report" }
            if isGarden { return "Garden Incident" }
            if isMorning { return "Breakfast Dispatch" }
            if isNight { return "Bedtime Drop" }
            return "Roaming Masterpiece"
        }()

        subtitle = {
            if let gap, gap < 60 * 60 {
                return "This follow-up arrived so quickly it barely gave the grass time to recover."
            }
            if let gap, gap < 60 * 60 * 4 {
                return "A speedy second chapter. The route stayed surprisingly productive."
            }
            if let gap, gap > 60 * 60 * 24 {
                return "After a long dramatic pause, the next episode finally aired."
            }
            if isRainy {
                return "A damp setting, a steady stance, and a dog who would not be rushed."
            }
            if isSnowy {
                return "The weather tried to freeze the mood, but the mission pushed through."
            }
            if entry.rating >= 5 {
                return "This one carried itself like a five-star field event."
            }
            if entry.rating <= 2 {
                return "A scrappy little scene with questions, tension, and commitment."
            }
            return "A respectable contribution to the ongoing poop chronicle."
        }()

        background = {
            if isSnowy {
                return LinearGradient(colors: [Color(red: 0.80, green: 0.88, blue: 0.96), Color(red: 0.56, green: 0.70, blue: 0.86)], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
            if isRainy {
                return LinearGradient(colors: [Color(red: 0.41, green: 0.55, blue: 0.65), Color(red: 0.18, green: 0.27, blue: 0.33)], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
            if isNight {
                if clearNight {
                    return LinearGradient(colors: [PooppyTheme.nightIndigo, Color(red: 0.07, green: 0.08, blue: 0.24)], startPoint: .topLeading, endPoint: .bottomTrailing)
                }
                return LinearGradient(colors: [Color(red: 0.08, green: 0.11, blue: 0.24), PooppyTheme.midnight], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
            if isMorning {
                return LinearGradient(colors: [PooppyTheme.gold, PooppyTheme.caramel], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
            if isWater {
                return LinearGradient(colors: [PooppyTheme.sky, Color(red: 0.29, green: 0.63, blue: 0.78)], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
            if isPark {
                return LinearGradient(colors: [PooppyTheme.moss, Color(red: 0.24, green: 0.39, blue: 0.18)], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
            if isField {
                return LinearGradient(colors: [Color(red: 0.77, green: 0.59, blue: 0.29), Color(red: 0.56, green: 0.39, blue: 0.18)], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
            if isGarden {
                return LinearGradient(colors: [Color(red: 0.56, green: 0.72, blue: 0.39), Color(red: 0.30, green: 0.48, blue: 0.20)], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
            return LinearGradient(colors: [PooppyTheme.cocoa, PooppyTheme.espresso], startPoint: .topLeading, endPoint: .bottomTrailing)
        }()

        timeGapLine = {
            guard let gap else { return "Opening act" }
            if gap < 60 * 60 {
                return "Back-to-back"
            }
            if gap < 60 * 60 * 8 {
                return "Quick return"
            }
            if gap < 60 * 60 * 24 {
                return ""
            }
            return "After a long pause"
        }()

        skyTone = isNight ? Color(red: 0.89, green: 0.92, blue: 1.0) : Color.white.opacity(0.85)
        groundTone = isPark ? Color(red: 0.33, green: 0.45, blue: 0.23) : (isWater ? Color(red: 0.32, green: 0.47, blue: 0.45) : (isField ? Color(red: 0.63, green: 0.45, blue: 0.22) : (isGarden ? Color(red: 0.40, green: 0.56, blue: 0.26) : Color(red: 0.47, green: 0.33, blue: 0.24))))
        poopTone = entry.rating >= 4 ? Color(red: 0.31, green: 0.17, blue: 0.09) : (entry.rating >= 3 ? Color(red: 0.45, green: 0.28, blue: 0.16) : Color(red: 0.58, green: 0.42, blue: 0.26))
        accentTone = isRainy ? Color(red: 0.79, green: 0.89, blue: 0.98) : (isSnowy ? Color.white : (isMorning ? Color(red: 1.0, green: 0.95, blue: 0.76) : PooppyTheme.gold.opacity(0.75)))
        horizonTone = isNight ? Color.white.opacity(0.08) : Color.white.opacity(isSunny ? 0.34 : 0.22)
        featureCount = entry.rating >= 5 ? 4 : (entry.rating >= 3 ? 3 : 2)
        self.clearNight = clearNight
        cityLightCount = isNight ? max(4, entry.rating + 2) : max(2, entry.rating)
        grassTuftCount = isPark ? max(4, entry.rating + 2) : max(3, entry.rating + 1)
        rippleCount = isWater ? max(3, entry.rating + 1) : 0
    }
}

private enum SceneStyle {
    case park
    case waterfront
    case city
    case field
    case garden
    case open
}

private enum WeatherStyle {
    case clear
    case rain
    case wind
    case snow
    case night
}

private enum SunStyle {
    case sunrise
    case sunset
    case sun
    case cloud
    case none
}

private enum DogPose {
    case walk
    case poop
    case prance
}

private enum DogPlacement {
    case leftThird
    case rightThird
}

private struct PoopSceneArtwork: View {
    let illustration: PoopIllustrationDescriptor
    let dog: DogAccount?

    private let canvasWidth: CGFloat = 320
    private let canvasHeight: CGFloat = 152
    private var dogOffsetX: CGFloat { illustration.dogPlacement == .leftThird ? -58 : 58 }
    private var poopOffsetX: CGFloat { illustration.dogPlacement == .leftThird ? -12 : 60 }
    private var counterweightX: CGFloat { illustration.dogPlacement == .leftThird ? 92 : -92 }
    private var horizonShiftX: CGFloat { illustration.dogPlacement == .leftThird ? 16 : -16 }
    private var backdropShiftX: CGFloat { illustration.dogPlacement == .leftThird ? 38 : -38 }

    var body: some View {
        ZStack(alignment: .bottom) {
            atmosphericWash

            kleeConstellation

            compositionalWedge

            if illustration.clearNight {
                starField
                    .offset(y: -18)
            }

            sunFeature
                .offset(x: counterweightX, y: -28)

            horizonBand
                .offset(x: horizonShiftX, y: 12)

            sceneBackdrop
                .frame(width: canvasWidth, height: canvasHeight)
                .offset(x: backdropShiftX)

            middleGround
                .offset(x: backdropShiftX * 0.6, y: 10)

            ground
                .offset(y: 32)

            wittyPoopShape
                .offset(x: poopOffsetX, y: 20)

            weatherOverlay
                .frame(width: canvasWidth, height: canvasHeight)

            if let dog {
                MiniDogSceneFigure(dog: dog, pose: illustration.dogPose)
                    .frame(width: 98, height: 70)
                    .offset(x: dogOffsetX, y: 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var ground: some View {
        ZStack(alignment: .top) {
            Capsule(style: .continuous)
                .fill(illustration.groundTone.opacity(0.96))
                .frame(width: 340, height: 46)

            HStack(spacing: 12) {
                ForEach(0..<illustration.grassTuftCount, id: \.self) { index in
                    GrassTuftShape()
                        .fill(Color.white.opacity(index.isMultiple(of: 2) ? 0.14 : 0.08))
                        .frame(width: 18, height: 8 + CGFloat(index % 3) * 3)
                }
            }
            .offset(y: 4)
        }
    }

    private var atmosphericWash: some View {
        VStack(spacing: 18) {
            Ellipse()
                .fill(Color.white.opacity(0.12))
                .frame(width: 300, height: 56)
                .blur(radius: 8)
            Ellipse()
                .fill(illustration.accentTone.opacity(0.10))
                .frame(width: 240, height: 42)
                .blur(radius: 10)
        }
        .offset(y: -18)
    }

    private var compositionalWedge: some View {
        ZStack {
            TriangleShape()
                .fill(illustration.accentTone.opacity(0.10))
                .frame(width: 118, height: 70)
            TriangleShape()
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                .frame(width: 92, height: 52)
                .offset(y: 8)
        }
        .rotationEffect(.degrees(illustration.dogPlacement == .leftThird ? 0 : 180))
        .offset(x: illustration.dogPlacement == .leftThird ? -98 : 98, y: 10)
    }

    private var kleeConstellation: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.white.opacity(0.10))
                .frame(width: 54, height: 22)
                .offset(x: -92, y: -18)
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(illustration.accentTone.opacity(0.16))
                .frame(width: 34, height: 16)
                .offset(x: -18, y: -26)
            Circle()
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
                .frame(width: 24, height: 24)
                .offset(x: 26, y: -18)
            Capsule(style: .continuous)
                .fill(Color.black.opacity(0.08))
                .frame(width: 66, height: 6)
                .offset(x: 96, y: -8)
            Rectangle()
                .fill(illustration.accentTone.opacity(0.16))
                .frame(width: 18, height: 18)
                .rotationEffect(.degrees(8))
                .offset(x: counterweightX * 0.48, y: -38)
        }
    }

    private var wittyPoopShape: some View {
        ZStack(alignment: .bottom) {
            PoopBloomShape()
                .fill(
                    LinearGradient(
                        colors: [illustration.poopTone.opacity(0.92), illustration.poopTone],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 54, height: 52)
            PoopBloomShape()
                .stroke(illustration.accentTone.opacity(0.24), lineWidth: 1.4)
                .frame(width: 58, height: 56)
            Ellipse()
                .fill(illustration.accentTone.opacity(0.18))
                .frame(width: 54, height: 10)
                .offset(y: 20)
        }
    }

    private var horizonBand: some View {
        Capsule(style: .continuous)
            .fill(illustration.horizonTone)
            .frame(width: 240, height: 12)
    }

    private var starField: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(index.isMultiple(of: 3) ? 0.95 : 0.68))
                    .frame(width: index.isMultiple(of: 2) ? 3 : 2, height: index.isMultiple(of: 2) ? 3 : 2)
                    .offset(
                        x: [-118.0, -86.0, -62.0, -34.0, -8.0, 18.0, 52.0, 88.0, 112.0, 34.0, -18.0, 70.0][index],
                        y: [-48.0, -66.0, -38.0, -54.0, -28.0, -58.0, -32.0, -62.0, -40.0, -74.0, -84.0, -90.0][index]
                    )
            }
        }
        .frame(width: 300, height: 70)
    }

    @ViewBuilder
    private var sceneBackdrop: some View {
        switch illustration.sceneStyle {
        case .park:
            HStack(alignment: .bottom, spacing: 22) {
                ForEach(0..<illustration.featureCount + 1, id: \.self) { index in
                    miniTree(tall: index.isMultiple(of: 2))
                        .scaleEffect(index.isMultiple(of: 2) ? 1.0 : 0.82)
                }
            }
            .offset(x: 30, y: 14)
        case .waterfront:
            ZStack(alignment: .bottom) {
                VStack(spacing: 5) {
                    Spacer()
                    ForEach(0..<illustration.rippleCount, id: \.self) { index in
                        Capsule()
                            .fill(Color.white.opacity(index == 0 ? 0.30 : (index == 1 ? 0.22 : 0.14)))
                            .frame(width: 220 - CGFloat(index * 24), height: index == 0 ? 7 : 4)
                    }
                }

                HStack(spacing: 30) {
                    sailMarker(height: 26)
                    sailMarker(height: 20)
                }
            }
        case .city:
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(Array([40.0, 72.0, 58.0, 84.0, 48.0, 66.0, 54.0].enumerated()), id: \.offset) { offset, height in
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(offset.isMultiple(of: 2) ? Color.white.opacity(0.18) : illustration.accentTone.opacity(0.18))
                            .frame(width: 22, height: height * 0.65)
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .stroke(Color.black.opacity(0.10), lineWidth: 1)
                            .frame(width: 22, height: height * 0.65)
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(0..<max(2, illustration.cityLightCount - offset / 2), id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 1, style: .continuous)
                                    .fill(Color(red: 1.0, green: 0.90, blue: 0.68).opacity(0.78))
                                    .frame(width: 4, height: 3)
                            }
                        }
                        .padding(.top, 8)
                        .padding(.leading, 5)
                        TriangleShape()
                            .fill(Color.white.opacity(0.14))
                            .frame(width: 14, height: 8)
                            .offset(x: 4, y: -5)
                    }
                }
            }
            .offset(x: 44, y: 0)
        case .field:
            ZStack(alignment: .bottom) {
                HStack(spacing: 10) {
                    ForEach(0..<10, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(Color.white.opacity(index.isMultiple(of: 2) ? 0.28 : 0.16))
                            .frame(width: 5, height: CGFloat(12 + index * 4))
                            .rotationEffect(.degrees(index.isMultiple(of: 2) ? -8 : 8))
                            .offset(y: CGFloat(index))
                    }
                }

                HStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { index in
                        fieldPatch(width: index == 1 ? 34 : 22, height: index == 1 ? 16 : 12)
                    }
                }
            }
            .offset(x: 52, y: 10)
        case .garden:
            HStack(spacing: 16) {
                ForEach(0..<4, id: \.self) { index in
                    flowerStem(petalCount: index + 4)
                }
            }
            .offset(x: 48, y: 10)
        case .open:
            Circle()
                .fill(illustration.accentTone.opacity(0.75))
                .frame(width: 22, height: 22)
                .offset(x: 94, y: -16)
        }
    }

    @ViewBuilder
    private var middleGround: some View {
        switch illustration.sceneStyle {
        case .park, .garden:
            HStack(spacing: 14) {
                ForEach(0..<illustration.featureCount + 1, id: \.self) { index in
                    TriangleShape()
                        .fill((index.isMultiple(of: 2) ? illustration.accentTone : .white).opacity(index.isMultiple(of: 2) ? 0.12 : 0.08))
                        .frame(width: 36, height: 18 + CGFloat(index * 4))
                }
            }
            .offset(x: 54)
        case .waterfront:
            VStack(spacing: 8) {
                ForEach(0..<2, id: \.self) { index in
                    Capsule()
                        .fill(Color.white.opacity(index == 0 ? 0.10 : 0.06))
                        .frame(width: 250 - CGFloat(index * 40), height: 10 - CGFloat(index * 2))
                }
            }
        case .city:
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array([46.0, 52.0, 38.0, 60.0].enumerated()), id: \.offset) { offset, height in
                    VStack(spacing: 0) {
                        TriangleShape()
                            .fill(Color.white.opacity(offset.isMultiple(of: 2) ? 0.08 : 0.04))
                            .frame(width: 12, height: 8)
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.black.opacity(0.18))
                            .frame(width: 26, height: height * 0.58)
                    }
                }
            }
            .offset(x: 64, y: 0)
        case .field, .open:
            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { index in
                    VStack(spacing: -2) {
                        TriangleShape()
                            .fill((index.isMultiple(of: 2) ? Color.white : illustration.accentTone).opacity(index.isMultiple(of: 2) ? 0.10 : 0.12))
                            .frame(width: 26, height: 12 + CGFloat(index % 3) * 4)
                        Rectangle()
                            .fill(Color.black.opacity(0.05))
                            .frame(width: 20, height: 2)
                    }
                }
            }
            .offset(x: 36)
        }
    }

    @ViewBuilder
    private var sunFeature: some View {
        switch illustration.sunStyle {
        case .sunrise:
            RisingSunShape()
                .fill(Color(red: 1.0, green: 0.82, blue: 0.50))
                .frame(width: 46, height: 24)
        case .sunset:
            RisingSunShape()
                .fill(Color(red: 0.99, green: 0.68, blue: 0.34))
                .frame(width: 46, height: 24)
        case .sun:
            Circle()
                .fill(Color(red: 1.0, green: 0.90, blue: 0.56))
                .frame(width: 26, height: 26)
        case .cloud:
            CloudPuffShape()
                .fill(Color.white.opacity(0.78))
                .frame(width: 44, height: 24)
        case .none:
            EmptyView()
        }
    }

    private func miniTree(tall: Bool) -> some View {
        VStack(spacing: -1) {
            TriangleShape()
                .fill(illustration.accentTone.opacity(0.22))
                .frame(width: tall ? 20 : 16, height: tall ? 18 : 12)
            TriangleShape()
                .fill(Color.white.opacity(0.30))
                .frame(width: tall ? 28 : 22, height: tall ? 22 : 16)
            Circle()
                .fill(illustration.accentTone.opacity(0.08))
                .frame(width: tall ? 16 : 12, height: tall ? 10 : 8)
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color.white.opacity(0.35))
                .frame(width: 4, height: tall ? 14 : 11)
        }
        .rotationEffect(.degrees(-6))
    }

    private func sailMarker(height: CGFloat) -> some View {
        VStack(spacing: 2) {
            TriangleShape()
                .fill(Color.white.opacity(0.20))
                .frame(width: 14, height: height)
            Rectangle()
                .fill(Color.white.opacity(0.22))
                .frame(width: 1, height: 8)
        }
    }

    private func fieldPatch(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(illustration.accentTone.opacity(0.12))
            .frame(width: width, height: height)
            .overlay {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            }
            .rotationEffect(.degrees(-6))
    }

    private func flowerStem(petalCount: Int) -> some View {
        VStack(spacing: 0) {
            ZStack {
                ForEach(0..<petalCount, id: \.self) { index in
                    Circle()
                        .fill(Color.white.opacity(0.38))
                        .frame(width: 7, height: 7)
                        .offset(
                            x: cos(Double(index) / Double(petalCount) * .pi * 2) * 5,
                            y: sin(Double(index) / Double(petalCount) * .pi * 2) * 5
                        )
                }
                Circle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 5, height: 5)
            }
            .frame(width: 18, height: 18)
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color.white.opacity(0.28))
                .frame(width: 3, height: 14)
        }
    }

    @ViewBuilder
    private var weatherOverlay: some View {
        switch illustration.weatherStyle {
        case .clear:
            EmptyView()
        case .night:
            VStack(spacing: 5) {
                Capsule()
                    .fill(Color(red: 0.62, green: 0.71, blue: 0.98).opacity(0.20))
                    .frame(width: 100, height: 5)
                Capsule()
                    .fill(Color(red: 0.28, green: 0.36, blue: 0.61).opacity(0.22))
                    .frame(width: 72, height: 5)
            }
            .offset(x: 34, y: -18)
        case .rain:
            HStack(spacing: 9) {
                ForEach(0..<8, id: \.self) { _ in
                    Capsule()
                        .fill(Color.white.opacity(0.55))
                        .frame(width: 2, height: 14)
                        .rotationEffect(.degrees(18))
                }
            }
            .offset(y: -12)
        case .wind:
            VStack(spacing: 8) {
                Capsule().fill(Color.white.opacity(0.45)).frame(width: 72, height: 3)
                Capsule().fill(Color.white.opacity(0.32)).frame(width: 46, height: 3)
            }
            .offset(x: 26, y: -16)
        case .snow:
            HStack(spacing: 10) {
                ForEach(0..<8, id: \.self) { _ in
                    Circle()
                        .fill(Color.white.opacity(0.86))
                        .frame(width: 4, height: 4)
                }
            }
            .offset(y: -16)
        }
    }
}

private struct MiniDogSceneFigure: View {
    let dog: DogAccount
    let pose: DogPose

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Capsule(style: .continuous)
                .fill(dog.coatColorName.color.opacity(0.95))
                .frame(width: 56, height: pose == .poop ? 26 : 32)
                .offset(x: 26, y: pose == .poop ? 14 : 10)

            HappyDogFaceBadge(
                size: 44,
                coatColorName: dog.coatColorName,
                earStyle: dog.earStyle,
                leftEarColorName: dog.leftEarColorName,
                rightEarColorName: dog.rightEarColorName,
                noseColorName: dog.noseColorName
            )
            .offset(x: pose == .walk ? 2 : 6, y: pose == .prance ? -4 : -1)

            HStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { index in
                    Capsule(style: .continuous)
                        .fill((index.isMultiple(of: 2) ? dog.leftEarColorName : dog.rightEarColorName).color.opacity(0.88))
                        .frame(width: 5, height: pose == .poop && index > 1 ? 12 : 16)
                        .rotationEffect(.degrees(index.isMultiple(of: 2) ? -10 : 10))
                }
            }
            .offset(x: 34, y: 26)

            if pose == .walk {
                Capsule(style: .continuous)
                    .fill(dog.coatColorName.color.opacity(0.88))
                    .frame(width: 20, height: 6)
                    .rotationEffect(.degrees(-28))
                    .offset(x: 74, y: 10)
            }

            if pose == .prance {
                SparkleBurst()
                    .stroke(PooppyTheme.gold.opacity(0.72), lineWidth: 1.2)
                    .frame(width: 18, height: 18)
                    .offset(x: 6, y: -14)
            }
        }
        .frame(width: 96, height: 74)
    }
}

extension DogColorName {
    var color: Color {
        switch self {
        case .cloud:
            return Color(red: 0.98, green: 0.98, blue: 0.97)
        case .white:
            return PooppyTheme.paper
        case .black:
            return Color(red: 0.10, green: 0.10, blue: 0.12)
        case .caramel:
            return PooppyTheme.caramel
        case .cocoa:
            return PooppyTheme.cocoa
        case .rose:
            return Color(red: 0.82, green: 0.57, blue: 0.60)
        case .charcoal:
            return Color(red: 0.23, green: 0.23, blue: 0.26)
        case .honey:
            return Color(red: 0.86, green: 0.68, blue: 0.33)
        case .slate:
            return Color(red: 0.47, green: 0.52, blue: 0.60)
        }
    }
}

extension PooppyTheme {
    static let rose = Color(red: 0.90, green: 0.66, blue: 0.69)
}

private struct SmileShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.2))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.2),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        return path
    }
}

private struct CrownShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.16, y: rect.minY + rect.height * 0.42))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.36, y: rect.minY + rect.height * 0.65))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.64, y: rect.minY + rect.height * 0.65))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.84, y: rect.minY + rect.height * 0.42))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct SwirlShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.2, y: rect.maxY * 0.54),
            control1: CGPoint(x: rect.midX - rect.width * 0.04, y: rect.minY + rect.height * 0.18),
            control2: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.34)
        )
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control1: CGPoint(x: rect.minX + rect.width * 0.20, y: rect.maxY * 0.90),
            control2: CGPoint(x: rect.minX + rect.width * 0.32, y: rect.maxY)
        )
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY * 0.55),
            control1: CGPoint(x: rect.maxX - rect.width * 0.18, y: rect.maxY),
            control2: CGPoint(x: rect.maxX, y: rect.maxY * 0.84)
        )
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.minY),
            control1: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.24),
            control2: CGPoint(x: rect.maxX - rect.width * 0.18, y: rect.minY + rect.height * 0.04)
        )
        path.closeSubpath()
        return path
    }
}

private struct RisingSunShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.maxY),
            radius: rect.width * 0.5,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}

private struct CloudPuffShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRoundedRect(in: CGRect(x: rect.width * 0.16, y: rect.height * 0.42, width: rect.width * 0.68, height: rect.height * 0.34), cornerSize: CGSize(width: rect.height * 0.2, height: rect.height * 0.2))
        path.addEllipse(in: CGRect(x: rect.width * 0.08, y: rect.height * 0.36, width: rect.width * 0.32, height: rect.height * 0.34))
        path.addEllipse(in: CGRect(x: rect.width * 0.30, y: rect.height * 0.18, width: rect.width * 0.32, height: rect.height * 0.42))
        path.addEllipse(in: CGRect(x: rect.width * 0.54, y: rect.height * 0.30, width: rect.width * 0.28, height: rect.height * 0.32))
        return path
    }
}

private struct PointedEarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY),
            control: CGPoint(x: rect.minX + rect.width * 0.10, y: rect.height * 0.24)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.midX, y: rect.maxY * 0.80)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.minY),
            control: CGPoint(x: rect.maxX - rect.width * 0.10, y: rect.height * 0.24)
        )
        path.closeSubpath()
        return path
    }
}

private struct TriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct DogEmojiEarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width * 0.56, y: rect.height * 0.04))
        path.addCurve(
            to: CGPoint(x: rect.width * 0.18, y: rect.height * 0.34),
            control1: CGPoint(x: rect.width * 0.34, y: rect.height * 0.05),
            control2: CGPoint(x: rect.width * 0.18, y: rect.height * 0.18)
        )
        path.addCurve(
            to: CGPoint(x: rect.width * 0.38, y: rect.height * 0.96),
            control1: CGPoint(x: rect.width * 0.12, y: rect.height * 0.56),
            control2: CGPoint(x: rect.width * 0.16, y: rect.height * 0.94)
        )
        path.addCurve(
            to: CGPoint(x: rect.width * 0.84, y: rect.height * 0.66),
            control1: CGPoint(x: rect.width * 0.56, y: rect.height * 0.98),
            control2: CGPoint(x: rect.width * 0.76, y: rect.height * 0.84)
        )
        path.addCurve(
            to: CGPoint(x: rect.width * 0.72, y: rect.height * 0.18),
            control1: CGPoint(x: rect.width * 0.88, y: rect.height * 0.46),
            control2: CGPoint(x: rect.width * 0.88, y: rect.height * 0.24)
        )
        path.addCurve(
            to: CGPoint(x: rect.width * 0.56, y: rect.height * 0.04),
            control1: CGPoint(x: rect.width * 0.68, y: rect.height * 0.08),
            control2: CGPoint(x: rect.width * 0.60, y: rect.height * 0.04)
        )
        path.closeSubpath()
        return path
    }
}

private struct CurlyEarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let circles = [
            CGRect(x: rect.width * 0.08, y: rect.height * 0.10, width: rect.width * 0.46, height: rect.height * 0.46),
            CGRect(x: rect.width * 0.34, y: rect.height * 0.02, width: rect.width * 0.42, height: rect.height * 0.42),
            CGRect(x: rect.width * 0.20, y: rect.height * 0.34, width: rect.width * 0.42, height: rect.height * 0.42),
            CGRect(x: rect.width * 0.48, y: rect.height * 0.28, width: rect.width * 0.28, height: rect.height * 0.28),
            CGRect(x: rect.width * 0.02, y: rect.height * 0.42, width: rect.width * 0.28, height: rect.height * 0.28)
        ]

        for circle in circles {
            path.addEllipse(in: circle)
        }

        return path
    }
}

private struct GrassTuftShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.width * 0.32, y: rect.minY), control: CGPoint(x: rect.width * 0.14, y: rect.height * 0.30))
        path.addQuadCurve(to: CGPoint(x: rect.width * 0.56, y: rect.maxY), control: CGPoint(x: rect.width * 0.48, y: rect.height * 0.34))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.10), control: CGPoint(x: rect.width * 0.78, y: rect.height * 0.28))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.height * 0.62))
        path.closeSubpath()
        return path
    }
}

private struct PoopBloomShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.height * 0.04))
        path.addCurve(to: CGPoint(x: rect.width * 0.18, y: rect.height * 0.48), control1: CGPoint(x: rect.width * 0.36, y: rect.height * 0.10), control2: CGPoint(x: rect.width * 0.10, y: rect.height * 0.20))
        path.addCurve(to: CGPoint(x: rect.width * 0.30, y: rect.height * 0.92), control1: CGPoint(x: rect.width * 0.10, y: rect.height * 0.74), control2: CGPoint(x: rect.width * 0.14, y: rect.height * 0.94))
        path.addCurve(to: CGPoint(x: rect.width * 0.74, y: rect.height * 0.86), control1: CGPoint(x: rect.width * 0.46, y: rect.height * 0.84), control2: CGPoint(x: rect.width * 0.62, y: rect.height * 0.98))
        path.addCurve(to: CGPoint(x: rect.width * 0.86, y: rect.height * 0.44), control1: CGPoint(x: rect.width * 0.88, y: rect.height * 0.70), control2: CGPoint(x: rect.width * 0.92, y: rect.height * 0.52))
        path.addCurve(to: CGPoint(x: rect.midX, y: rect.height * 0.04), control1: CGPoint(x: rect.width * 0.82, y: rect.height * 0.18), control2: CGPoint(x: rect.width * 0.66, y: rect.height * 0.02))
        path.closeSubpath()
        return path
    }
}

private struct SparkleBurst: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.move(to: CGPoint(x: rect.width * 0.18, y: rect.height * 0.18))
        path.addLine(to: CGPoint(x: rect.width * 0.82, y: rect.height * 0.82))
        path.move(to: CGPoint(x: rect.width * 0.82, y: rect.height * 0.18))
        path.addLine(to: CGPoint(x: rect.width * 0.18, y: rect.height * 0.82))
        return path
    }
}

extension View {
    func pooppyBackground() -> some View {
        modifier(PooppyBackground())
    }

    func pooppyCardStyle() -> some View {
        padding(18)
            .background(.white.opacity(0.86))
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(PooppyTheme.caramel.opacity(0.12), lineWidth: 1)
            }
            .shadow(color: PooppyTheme.espresso.opacity(0.08), radius: 22, x: 0, y: 14)
    }
}
