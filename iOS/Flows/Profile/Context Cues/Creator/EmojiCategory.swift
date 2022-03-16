//
//  EmojiCategory.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/15/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

struct Emoji: Decodable, Hashable {
    var id: String
    var emoji: String
    var isSelected: Bool = false
}

enum EmojiCategory: Int, CaseIterable {
    
    case smileysAndPeople
    case animalsAndNature
    case foodAndDrink
    case activity
    case travelAndPlaces
    case objects
    case symbols
    case flags
    
    var emojis: [Emoji] {
        return self.getEmojis()
    }
    
    var image: UIImage? {
        switch self {
        case .smileysAndPeople:
            return UIImage(systemName: "face.smiling")
        case .animalsAndNature:
            return UIImage(systemName: "hare")
        case .travelAndPlaces:
            return UIImage(systemName: "airplane")
        case .activity:
            return UIImage(systemName: "globe.americas")
        case .symbols:
            return UIImage(systemName: "asterisk")
        case .flags:
            return UIImage(systemName: "flag")
        case .foodAndDrink:
            return UIImage(systemName: "cup.and.saucer")
        case .objects:
            return UIImage(systemName: "book")
        }
    }
    
    private func getEmojis() -> [Emoji] {
        guard let res = self.loadJson(filename:"emoji", model: [CategoryModel].self),
              let category = res[safe: self.rawValue] else { return [] }
    
        let emojis = category.emojis.compactMap { model in
            return Emoji(id: model.code, emoji: model.emoji)
        }
        
        return emojis
    }
    
    private func loadJson<E: Decodable>(filename: String, model: E.Type) -> E? {
        
        guard let path = Bundle.main.url(forResource: filename, withExtension: "json") else { return nil }

        let decoder = JSONDecoder()

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path.path))
          let res = try decoder.decode(model,
                                      from: data)
          return res
        } catch {
          logError(error)
        }

        return nil
      }
}

struct CategoryModel: Hashable, Identifiable, Decodable {
    var id = UUID()
    let title: String
    let emojis: [EmojiModel]
    
    enum CodingKeys: CodingKey {
        case title, emojis
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decode(String.self, forKey: .title)
        self.emojis = try container.decode([EmojiModel].self, forKey: .emojis)
    }
}

extension EmojiCategory {
    var displayString: String {
        switch self {
        case .smileysAndPeople:
            return "smileys and people"
        case .animalsAndNature:
            return "animals and nature"
        case .foodAndDrink:
            return "food and drink"
        case .activity:
            return "activity"
        case .travelAndPlaces:
            return "travel and places"
        case .objects:
            return "objects"
        case .symbols:
            return "symbols"
        case .flags:
            return "flags"
        }
    }
}

extension EmojiCategory: Decodable {
    enum CodingKeys: String, CodingKey {
        case smileyAndPeople = "smileys and people"
        case animalAndNature = "animals and nature"
        case foodAndDrink = "food and drink"
        case activity = "activity"
        case travelAndPlaces = "travel and places"
        case objects = "objects"
        case symbols = "symbols"
        case flags = "flags"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let _ = try? container.decode(String.self, forKey: .activity) {
            self = .activity
        } else if let _ = try? container.decode(String.self, forKey: .animalAndNature) {
            self = .animalsAndNature
        } else if let _ = try? container.decode(String.self, forKey: .flags) {
            self = .flags
        } else if let _ = try? container.decode(String.self, forKey: .foodAndDrink) {
            self = .foodAndDrink
        } else if let _ = try? container.decode(String.self, forKey: .objects) {
            self = .objects
        } else if let _ = try? container.decode(String.self, forKey: .smileyAndPeople) {
            self = .smileysAndPeople
        } else if let _ = try? container.decode(String.self, forKey: .symbols) {
            self = .symbols
        } else if let _ = try? container.decode(String.self, forKey: .travelAndPlaces) {
            self = .travelAndPlaces
        }
        throw ClientError.message(detail: "Failed")
    }
}

struct EmojiModel: Decodable, Hashable {
    let no: Int
    let code: String
    let emoji: String
    let description: String
    let flagged: Bool
    let keywords: [String]
    let types: [String]?
}
