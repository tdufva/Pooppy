import Foundation

struct DogAccount: Identifiable, Hashable {
    let id: String
    var name: String
    var inviteCode: String
    var ownerIDs: [String]
    var ownerDisplayNames: [String]
    var createdAt: Date
    var coatColorName: DogColorName
    var earStyle: DogEarStyle
    var leftEarColorName: DogColorName
    var rightEarColorName: DogColorName
    var noseColorName: DogColorName
}

enum DogEarStyle: String, CaseIterable, Codable, Identifiable {
    case floppy
    case teddy
    case curly

    var id: String { rawValue }

    var label: String {
        switch self {
        case .floppy: return "Floppy"
        case .teddy: return "Teddy"
        case .curly: return "Curly"
        }
    }
}

enum DogColorName: String, Codable, Identifiable {
    case cloud
    case white
    case black
    case caramel
    case cocoa
    case rose
    case charcoal
    case honey
    case slate

    var id: String { rawValue }

    static var allCases: [DogColorName] {
        [.white, .black, .caramel, .cocoa, .rose, .charcoal, .honey, .slate]
    }

    var label: String {
        switch self {
        case .cloud: return "White"
        case .white: return "White"
        case .black: return "Black"
        case .caramel: return "Caramel"
        case .cocoa: return "Cocoa"
        case .rose: return "Rose"
        case .charcoal: return "Charcoal"
        case .honey: return "Honey"
        case .slate: return "Slate"
        }
    }
}
