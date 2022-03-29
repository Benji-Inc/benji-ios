//
//  ReactionType.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/27/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat
import Localization

struct ReactionSummary: Hashable, Comparable {

    let type: ReactionType
    let count: Int

    static func < (lhs: ReactionSummary, rhs: ReactionSummary) -> Bool {
        return lhs.type.priority > rhs.type.priority
    }
}

enum ReactionType: String, CaseIterable {

    case like
    case love
    case dislike
    case read

    var priority: Int {
        switch self {
        case .like:
            return 0
        case .love:
            return 1
        case .dislike:
            return 2
        case .read:
            return 3
        }
    }

    var reaction: MessageReactionType {
        return MessageReactionType.init(stringLiteral: self.rawValue)
    }

    var emoji: String {
        switch self {
        case .like:
            return "👍"
        case .love:
            return "😍"
        case .dislike:
            return "👎"
        case .read:
            return ""
        }
    }
}

// https://www.pnas.org/doi/10.1073/pnas.1702247114

enum Emotion: String, CaseIterable, Identifiable {
            
    case admired
    case adored
    case treasured
    case amused
    case angry
    case anxious
    case awe
    case awkward
    case bored
    case calm
    case confused
    case craving
    case disgusted
    case empathetic
    case entranced
    case excited
    case fearful
    case horrorified
    case interested
    case joyful
    case nostalgic
    case relieved
    case romantic
    case sad
    case satisfied
    case desired
    case suprised
    
    var emoji: String {
        return "😮"
    }
    
    var reaction: MessageReactionType {
        return MessageReactionType.init(stringLiteral: self.rawValue)
    }
    
    var id: Emotion { self }
    
    // https://materialui.co/colors/
    var color: UIColor {
        switch self {
        case .admired:
            return #colorLiteral(red: 0.937254902, green: 0.3254901961, blue: 0.3137254902, alpha: 1)
        case .adored:
            return #colorLiteral(red: 0.9568627451, green: 0.262745098, blue: 0.2117647059, alpha: 1)
        case .treasured:
            return #colorLiteral(red: 0.8980392157, green: 0.2235294118, blue: 0.2078431373, alpha: 1)
        case .amused:
            return #colorLiteral(red: 0.9254901961, green: 0.2509803922, blue: 0.4784313725, alpha: 1)
        case .angry:
            return #colorLiteral(red: 0.9137254902, green: 0.1176470588, blue: 0.3882352941, alpha: 1)
        case .anxious:
            return #colorLiteral(red: 0.8470588235, green: 0.1058823529, blue: 0.3764705882, alpha: 1)
        case .awe:
            return #colorLiteral(red: 0.6705882353, green: 0.2784313725, blue: 0.737254902, alpha: 1)
        case .awkward:
            return #colorLiteral(red: 0.6117647059, green: 0.1529411765, blue: 0.6901960784, alpha: 1)
        case .bored:
            return #colorLiteral(red: 0.5568627451, green: 0.1411764706, blue: 0.6666666667, alpha: 1)
        case .calm:
            return #colorLiteral(red: 0.4941176471, green: 0.3411764706, blue: 0.7607843137, alpha: 1)
        case .confused:
            return #colorLiteral(red: 0.4039215686, green: 0.2274509804, blue: 0.7176470588, alpha: 1)
        case .craving:
            return #colorLiteral(red: 0.368627451, green: 0.2078431373, blue: 0.6941176471, alpha: 1)
        case .disgusted:
            return #colorLiteral(red: 0.6117647059, green: 0.8, blue: 0.3960784314, alpha: 1)
        case .empathetic:
            return #colorLiteral(red: 0.5450980392, green: 0.7647058824, blue: 0.2901960784, alpha: 1)
        case .entranced:
            return #colorLiteral(red: 0.4862745098, green: 0.7019607843, blue: 0.2588235294, alpha: 1)
        case .excited:
            return #colorLiteral(red: 1, green: 0.9333333333, blue: 0.3450980392, alpha: 1)
        case .fearful:
            return #colorLiteral(red: 1, green: 0.9215686275, blue: 0.231372549, alpha: 1)
        case .horrorified:
            return #colorLiteral(red: 0.9921568627, green: 0.8470588235, blue: 0.2078431373, alpha: 1)
        case .interested:
            return #colorLiteral(red: 0.1490196078, green: 0.7764705882, blue: 0.8549019608, alpha: 1)
        case .joyful:
            return #colorLiteral(red: 0.01176470588, green: 0.662745098, blue: 0.9568627451, alpha: 1)
        case .nostalgic:
            return #colorLiteral(red: 0.01176470588, green: 0.6078431373, blue: 0.8980392157, alpha: 1)
        case .relieved:
            return #colorLiteral(red: 0.1490196078, green: 0.6509803922, blue: 0.6039215686, alpha: 1)
        case .romantic:
            return #colorLiteral(red: 0, green: 0.5882352941, blue: 0.5333333333, alpha: 1)
        case .sad:
            return #colorLiteral(red: 0, green: 0.537254902, blue: 0.4823529412, alpha: 1)
        case .satisfied:
            return #colorLiteral(red: 1, green: 0.4392156863, blue: 0.262745098, alpha: 1)
        case .desired:
            return #colorLiteral(red: 1, green: 0.3411764706, blue: 0.1333333333, alpha: 1)
        case .suprised:
            return #colorLiteral(red: 0.9568627451, green: 0.3176470588, blue: 0.1176470588, alpha: 1)
        }
    }
}
