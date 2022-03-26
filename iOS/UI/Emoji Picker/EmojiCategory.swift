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
    var keywords: [String]
    var types: [String]?
    
    func contains(_ filter: String?) -> Bool {
        guard let filterText = filter else { return true }
        if filterText.isEmpty { return true }
        let lowercasedFilter = filterText.lowercased()
        return self.keywords.contains { element in
            return element.contains(lowercasedFilter)
        }
    }
    
    init(id: String,
         emoji: String,
         isSelected: Bool = false,
         keywords: [String],
         types: [String]?) {
        
        self.id = id
        self.emoji = emoji
        self.isSelected = isSelected
        self.keywords = keywords
        self.types = types
    }
    
    init?(with string: String) {
        if let value = EmojiCategory.allEmojis.first(where: { emoji in
            return emoji.emoji == string
        }) {
            self = value
        } else {
            return nil
        }
    }
}

enum EmojiCategory: Int, CaseIterable {
    
    case smileysAndPeople
    case animalsAndNature
    case foodAndDrink
    case travelAndPlaces
    case activity
    case objects
    case symbols
    case flags
    
    static var allEmojis: [Emoji] {
        var all: [Emoji] = []
        
        self.allCases.forEach { category in
            all.append(contentsOf: category.emojis)
        }
        
        return all
    }
    
    var emojis: [Emoji] {
        return self.getEmojis()
    }
    
    var scopeTitle: String {
        switch self {
        case .smileysAndPeople:
            return "😀"
        case .animalsAndNature:
            return "🐻‍❄️"
        case .travelAndPlaces:
            return "✈️"
        case .activity:
            return "⚾️"
        case .symbols:
            return "❗️"
        case .flags:
            return "🏳️"
        case .foodAndDrink:
            return "☕️"
        case .objects:
            return "💡"
        }
    }
    
    private func getEmojis() -> [Emoji] {
        guard let res = self.loadJson(filename:"emoji", model: [CategoryModel].self),
              let category = res[safe: self.rawValue] else { return [] }
    
        let emojis = category.emojis.compactMap { model in
            return Emoji(id: model.code,
                         emoji: model.emoji,
                         keywords: model.keywords,
                         types: model.types)
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
