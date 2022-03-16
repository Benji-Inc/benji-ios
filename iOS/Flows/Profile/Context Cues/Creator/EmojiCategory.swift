//
//  EmojiCategory.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/15/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

struct Emoji: Decodable, Hashable {
    var id: Int
    var emoji: String
    var isSelected: Bool = false
}

enum EmojiCategory: Int, CaseIterable {
    
    case emoticons
    case miscSymbols
    case transportAndMap
    case flags
    case misc
    case dingbats
    
    var emojis: [Emoji] {
        switch self {
        case .emoticons:
            var emojis: [Emoji] = []
            for i in 0x1F601...0x1F64F {
                let c = String(UnicodeScalar(i) ?? "-")
                emojis.append(Emoji(id: i, emoji: c))
            }
            return emojis
        case .miscSymbols:
            var emojis: [Emoji] = []
            for i in 0x1F300...0x1F5FF {
                let c = String(UnicodeScalar(i) ?? "-")
                emojis.append(Emoji(id: i, emoji: c))
            }
            return emojis
        case .transportAndMap:
            var emojis: [Emoji] = []
            for i in 0x1F680...0x1F6FF {
                let c = String(UnicodeScalar(i) ?? "-")
                emojis.append(Emoji(id: i, emoji: c))
            }
            return emojis
        case .flags:
            var emojis: [Emoji] = []
            for i in 0x1F1E6...0x1F1FF {
                let c = String(UnicodeScalar(i) ?? "-")
                emojis.append(Emoji(id: i, emoji: c))
            }
            return emojis
        case .misc:
            var emojis: [Emoji] = []
            for i in 0x2600...0x26FF {
                let c = String(UnicodeScalar(i) ?? "-")
                emojis.append(Emoji(id: i, emoji: c))
            }
            return emojis
        case .dingbats:
            var emojis: [Emoji] = []
            for i in 0x2700...0x27BF {
                let c = String(UnicodeScalar(i) ?? "-")
                emojis.append(Emoji(id: i, emoji: c))
            }
            return emojis
        }
    }
    
    func unicodeAvailable() -> Bool {
        if let refUnicodePng = Character.refUnicodePng,
            let myPng = self.png(ofSize: Character.refUnicodeSize) {
            return refUnicodePng != myPng
        }
        return false
    }
    
    var image: UIImage? {
        switch self {
        case .emoticons:
            return UIImage(systemName: "face.smiling")?.withTintColor(ThemeColor.T1.color.withAlphaComponent(0.6))
        case .miscSymbols:
            return UIImage(systemName: "hare")?.withTintColor(ThemeColor.T1.color.withAlphaComponent(0.6))
        case .transportAndMap:
            return UIImage(systemName: "airplane")?.withTintColor(ThemeColor.T1.color.withAlphaComponent(0.6))
        case .dingbats:
            return UIImage(systemName: "figure.walk")?.withTintColor(ThemeColor.T1.color.withAlphaComponent(0.6))
        case .misc:
            return UIImage(systemName: "asterisk")
        case .flags:
            return UIImage(systemName: "flag")
        }
    }
}
