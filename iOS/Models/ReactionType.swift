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

enum EmotionCategory: Int {
    case uncertain
    case compare
    case unplanned
    case beyondUs
    case areNotWhatTheySeem
    case hurting
    case others
    case fallShort
    case connection
    case heartOpen
    case good
    case wronged
    case selfAsses
    
    var title: Localized {
        switch self {
        case .uncertain:
            return LocalizedString(id: "", default: "Things are uncertain or too much")
        case .compare:
            return LocalizedString(id: "", default: "We compare")
        case .unplanned:
            return LocalizedString(id: "", default: "Things don't go as planned")
        case .beyondUs:
            return LocalizedString(id: "", default: "It's beyond us")
        case .areNotWhatTheySeem:
            return LocalizedString(id: "", default: "Things aren't what they seem")
        case .hurting:
            return LocalizedString(id: "", default: "We're hurting")
        case .others:
            return LocalizedString(id: "", default: "With others")
        case .fallShort:
            return LocalizedString(id: "", default: "We fall short")
        case .connection:
            return LocalizedString(id: "", default: "We search for connection")
        case .heartOpen:
            return LocalizedString(id: "", default: "The heart is open")
        case .good:
            return LocalizedString(id: "", default: "Life is good")
        case .wronged:
            return LocalizedString(id: "", default: "We feel wronged")
        case .selfAsses:
            return LocalizedString(id: "", default: "To self-asses")
        }
    }
    
    var color: UIColor {
        switch self {
        case .uncertain:
            return #colorLiteral(red: 1, green: 0.9215686275, blue: 0.9333333333, alpha: 1)
        case .compare:
            return #colorLiteral(red: 0.9882352941, green: 0.8941176471, blue: 0.9254901961, alpha: 1)
        case .unplanned:
            return #colorLiteral(red: 0.9529411765, green: 0.8980392157, blue: 0.9607843137, alpha: 1)
        case .beyondUs:
            return #colorLiteral(red: 0.9294117647, green: 0.9058823529, blue: 0.9647058824, alpha: 1)
        case .areNotWhatTheySeem:
            return #colorLiteral(red: 0.9098039216, green: 0.9176470588, blue: 0.9647058824, alpha: 1)
        case .hurting:
            return #colorLiteral(red: 0.8901960784, green: 0.9490196078, blue: 0.9921568627, alpha: 1)
        case .others:
            return #colorLiteral(red: 0.8823529412, green: 0.9607843137, blue: 0.9960784314, alpha: 1)
        case .fallShort:
            return #colorLiteral(red: 0.8784313725, green: 0.968627451, blue: 0.9803921569, alpha: 1)
        case .connection:
            return #colorLiteral(red: 0.8784313725, green: 0.9490196078, blue: 0.9450980392, alpha: 1)
        case .heartOpen:
            return #colorLiteral(red: 0.9098039216, green: 0.9607843137, blue: 0.9137254902, alpha: 1)
        case .good:
            return #colorLiteral(red: 0.9450980392, green: 0.9725490196, blue: 0.9137254902, alpha: 1)
        case .wronged:
            return #colorLiteral(red: 0.9764705882, green: 0.9843137255, blue: 0.9058823529, alpha: 1)
        case .selfAsses:
            return #colorLiteral(red: 1, green: 0.9921568627, blue: 0.9058823529, alpha: 1)
        }
    }
    
    var emotions: [Emotion] {
        switch self {
        case .uncertain:
            return [.stressed, .overwhelmed, .anxious, .worried, .avoidance, .excited, .dread, .fear, .vulnerable]
        case .compare:
            return [.comparison, .admired, .revered, .envious, .jealous, .resentment, .schadenfreude, .freudenfreude]
        case .unplanned:
            return [.bored, .dissapointed, .expecting, .regret, .discouraged, .resigned, .frustrated]
        case .beyondUs:
            return [.awe, .wonder, .confused, .curious, .interested, .suprised]
        case .areNotWhatTheySeem:
            return [.amused, .bittersweetness, .nostalgic, .cognitiveDissonance, .paradoxical, .ironic, .sarcastic]
        case .hurting:
            return [.anguish, .hopeless, .despair, .sad, .grief]
        case .others:
            return [.compassion, .pity, .empathy, .sympathy, .boundaries, .comparativeSuffering]
        case .fallShort:
            return [.shame, .selfCompassion, .perfectionism, .guilty, .humiliated, .embarrased]
        case .connection:
            return [.belonging, .fittingIn, .connected, .disconnected, .insecure, .invisible, .lonely]
        case .heartOpen:
            return [.loved, .lovelessness, .heartbroken, .trusted, .selfTrust, .betrayed, .defensive, .flooded, .hurt]
        case .good:
            return [.joyful, .happy, .calm, .content, .grateful, .forebodingJoy, .relieved, .tranquil]
        case .wronged:
            return [.angry, .contempt, .disgusted, .dehumanized, .hated, .selfRighteous]
        case .selfAsses:
            return [.proud, .hubris, .humble]
        }
    }
}

// Brene Brown Atlas of the Heart

enum Emotion: String, CaseIterable, Identifiable {
    
    case stressed
    case overwhelmed
    case anxious
    case worried
    case avoidance
    case excited
    case dread
    case fear
    case vulnerable
    
    case comparison
    case admired
    case revered
    case envious
    case jealous
    case resentment
    case schadenfreude
    case freudenfreude
    
    case bored
    case dissapointed
    case expecting
    case regret
    case discouraged
    case resigned
    case frustrated
    
    case awe
    case wonder
    case confused
    case curious
    case interested
    case suprised
    
    case amused
    case bittersweetness
    case nostalgic
    case cognitiveDissonance = "cognitive dissonance"
    case paradoxical
    case ironic
    case sarcastic
    
    case anguish
    case hopeless
    case despair
    case sad
    case grief
    
    case compassion
    case pity
    case empathy
    case sympathy
    case boundaries
    case comparativeSuffering = "comparative suffering"
    
    case shame
    case selfCompassion = "self-compassion"
    case perfectionism
    case guilty
    case humiliated
    case embarrased
    
    case belonging
    case fittingIn = "fitting in"
    case connected
    case disconnected
    case insecure
    case invisible
    case lonely
    
    case loved
    case lovelessness
    case heartbroken
    case trusted
    case selfTrust = "self-trust"
    case betrayed
    case defensive
    case flooded
    case hurt
    
    case joyful
    case happy
    case calm
    case content
    case grateful
    case forebodingJoy = "forbodeing joy"
    case relieved
    case tranquil
    
    case angry
    case contempt
    case disgusted
    case dehumanized
    case hated
    case selfRighteous = "self-righteous"
    
    case proud
    case hubris
    case humble
    
    var emoji: String {
        return "😮"
    }
    
    var reaction: MessageReactionType {
        return MessageReactionType.init(stringLiteral: self.rawValue)
    }
    
    var id: Emotion { self }
    
    var definition: Localized {
        switch self {
        case .stressed:
            return LocalizedString(id: "", default: "a state of mental or emotional strain or tension resulting from adverse or very demanding circumstances")
        case .overwhelmed:
            return LocalizedString(id: "", default: "have a strong emotional effect on")
        case .anxious:
            return LocalizedString(id: "", default: "a feeling of worry, nervousness, or unease, typically about an imminent event or something with an uncertain outcome")
        case .worried:
            return LocalizedString(id: "", default: "allow one's mind to dwell on difficulty or troubles.")
        case .avoidance:
            return LocalizedString(id: "", default: "keep away from or stop oneself from doing (something)")
        case .excited:
            return LocalizedString(id: "", default: "very enthusiastic and eager")
        case .dread:
            return LocalizedString(id: "", default: "anticipate with great apprehension or fear")
        case .fear:
            return LocalizedString(id: "", default: "an unpleasant emotion caused by the belief that someone or something is dangerous, likely to cause pain, or a threat")
        case .vulnerable:
            return LocalizedString(id: "", default: "susceptible to physical or emotional attack or harm")
        case .comparison:
            return LocalizedString(id: "", default: "a consideration or estimate of the similarities or dissimilarities between two things or people")
        case .admired:
            return LocalizedString(id: "", default: "regard (an object, quality, or person) with respect or warm approval")
        case .revered:
            return LocalizedString(id: "", default: "feel deep respect or admiration for (something)")
        case .envious:
            return LocalizedString(id: "", default: "a feeling of discontented or resentful longing aroused by someone else's possessions, qualities, or luck")
        case .jealous:
            return LocalizedString(id: "", default: "feeling or showing envy of someone or their achievements and advantages")
        case .resentment:
            return LocalizedString(id: "", default: "bitter indignation at having been treated unfairly")
        case .schadenfreude:
            return LocalizedString(id: "", default: "pleasure derived by someone from another person's misfortune")
        case .freudenfreude:
            return LocalizedString(id: "", default: "he lovely enjoyment of another person's success")
        case .bored:
            return LocalizedString(id: "", default: "feeling weary because one is unoccupied or lacks interest in one's current activity")
        case .dissapointed:
            return LocalizedString(id: "", default: "(of a person) sad or displeased because someone or something has failed to fulfill one's hopes or expectations")
        case .expecting:
            return LocalizedString(id: "", default: "having or showing an excited feeling that something is about to happen, especially something pleasant and interesting")
        case .regret:
            return LocalizedString(id: "", default: "feel sad, repentant, or disappointed over (something that has happened or been done, especially a loss or missed opportunity)")
        case .discouraged:
            return LocalizedString(id: "", default: "having lost confidence or enthusiasm; disheartened")
        case .resigned:
            return LocalizedString(id: "", default: "having accepted something unpleasant that one cannot do anything about")
        case .frustrated:
            return LocalizedString(id: "", default: "feeling or expressing distress and annoyance, especially because of inability to change or achieve something")
        case .awe:
            return LocalizedString(id: "", default: "a feeling of reverential respect mixed with fear or wonder")
        case .wonder:
            return LocalizedString(id: "", default: "a feeling of surprise mingled with admiration, caused by something beautiful, unexpected, unfamiliar, or inexplicable")
        case .confused:
            return LocalizedString(id: "", default: "(of a person) unable to think clearly; bewildered")
        case .curious:
            return LocalizedString(id: "", default: "eager to know or learn something")
        case .interested:
            return LocalizedString(id: "", default: "showing curiosity or concern about something or someone; having a feeling of interest")
        case .suprised:
            return LocalizedString(id: "", default: "an unexpected or astonishing event, fact, or thing")
        case .amused:
            return LocalizedString(id: "", default: "inding something funny or entertaining")
        case .bittersweetness:
            return LocalizedString(id: "", default: "(of food, drink, or flavor) sweet with a bitter aftertaste")
        case .nostalgic:
            return LocalizedString(id: "", default: "a sentimental longing or wistful affection for the past, typically for a period or place with happy personal associations")
        case .cognitiveDissonance:
            return LocalizedString(id: "", default: "the state of having inconsistent thoughts, beliefs, or attitudes, especially as relating to behavioral decisions and attitude change")
        case .paradoxical:
            return LocalizedString(id: "", default: "seemingly absurd or self-contradictory")
        case .ironic:
            return LocalizedString(id: "", default: "the expression of one's meaning by using language that normally signifies the opposite, typically for humorous or emphatic effect")
        case .sarcastic:
            return LocalizedString(id: "", default: "the use of irony to mock or convey contempt.")
        case .anguish:
            return LocalizedString(id: "", default: "severe mental or physical pain or suffering")
        case .hopeless:
            return LocalizedString(id: "", default: "feeling or causing despair about something")
        case .despair:
            return LocalizedString(id: "", default: "the complete loss or absence of hope")
        case .sad:
            return LocalizedString(id: "", default: "feeling or showing sorrow; unhappy")
        case .grief:
            return LocalizedString(id: "", default: "deep sorrow, especially that caused by someone's death")
        case .compassion:
            return LocalizedString(id: "", default: "sympathetic pity and concern for the sufferings or misfortunes of others")
        case .pity:
            return LocalizedString(id: "", default: "the feeling of sorrow and compassion caused by the suffering and misfortunes of others")
        case .empathy:
            return LocalizedString(id: "", default: "the ability to understand and share the feelings of another")
        case .sympathy:
            return LocalizedString(id: "", default: "feelings of pity and sorrow for someone else's misfortune")
        case .boundaries:
            return LocalizedString(id: "", default: "a line that marks the limits of an area; a dividing line")
        case .comparativeSuffering:
            return LocalizedString(id: "", default: "feeling the need to see our own suffering in light of other people's pain")
        case .shame:
            return LocalizedString(id: "", default: "a painful feeling of humiliation or distress caused by the consciousness of wrong or foolish behavior")
        case .selfCompassion:
            return LocalizedString(id: "", default: "acting the same way towards yourself when you are having a difficult time, fail, or notice something you don't like about yourself")
        case .perfectionism:
            return LocalizedString(id: "", default: "refusal to accept any standard short of perfection")
        case .guilty:
            return LocalizedString(id: "", default: "the fact of having committed a specified or implied offense or crime")
        case .humiliated:
            return LocalizedString(id: "", default: "make (someone) feel ashamed and foolish by injuring their dignity and self-respect, especially publicly")
        case .embarrased:
            return LocalizedString(id: "", default: "cause (someone) to feel awkward, self-conscious, or ashamed")
        case .belonging:
            return LocalizedString(id: "", default: "an affinity for a place or situation")
        case .fittingIn:
            return LocalizedString(id: "", default: "be socially compatible with other members of a group")
        case .connected:
            return LocalizedString(id: "", default: "brought together or into contact so that a real or notional link is established")
        case .disconnected:
            return LocalizedString(id: "", default: "having a connection broken")
        case .insecure:
            return LocalizedString(id: "", default: "not firmly fixed; liable to give way or break")
        case .invisible:
            return LocalizedString(id: "", default: "unable to be seen; not visible to the eye")
        case .lonely:
            return LocalizedString(id: "", default: "sad because one has no friends or company")
        case .loved:
            return LocalizedString(id: "", default: "feel deep affection for (someone)")
        case .lovelessness:
            return LocalizedString(id: "", default: "having no feelings of love")
        case .heartbroken:
            return LocalizedString(id: "", default: "(of a person) suffering from overwhelming distress; very upset")
        case .trusted:
            return LocalizedString(id: "", default: "firm belief in the reliability, truth, ability, or strength of someone or something")
        case .selfTrust:
            return LocalizedString(id: "", default: "the firm reliance on the integrity of yourself")
        case .betrayed:
            return LocalizedString(id: "", default: "be disloyal to")
        case .defensive:
            return LocalizedString(id: "", default: "the action of defending from or resisting attack")
        case .flooded:
            return LocalizedString(id: "", default: "when you become so overwhelmed by your feelings that it triggers a physiological or fight-or-flight response")
        case .hurt:
            return LocalizedString(id: "", default: "cause physical pain or injury to")
        case .joyful:
            return LocalizedString(id: "", default: "a feeling of great pleasure and happiness")
        case .happy:
            return LocalizedString(id: "", default: "feeling or showing pleasure or contentment")
        case .calm:
            return LocalizedString(id: "", default: "not showing or feeling nervousness, anger, or other strong emotions")
        case .content:
            return LocalizedString(id: "", default: "in a state of peaceful happiness")
        case .grateful:
            return LocalizedString(id: "", default: "feeling or showing an appreciation of kindness; thankful")
        case .forebodingJoy:
            return LocalizedString(id: "", default: "a common way that we try to fend off our human-ness, our susceptibility")
        case .relieved:
            return LocalizedString(id: "", default: "no longer feeling distressed or anxious; reassured")
        case .tranquil:
            return LocalizedString(id: "", default: "free from disturbance; calm")
        case .angry:
            return LocalizedString(id: "", default: "feeling or showing strong annoyance, displeasure, or hostility")
        case .contempt:
            return LocalizedString(id: "", default: "the feeling that a person or a thing is beneath consideration, worthless, or deserving scorn")
        case .disgusted:
            return LocalizedString(id: "", default: "a feeling of revulsion or strong disapproval aroused by something unpleasant or offensive")
        case .dehumanized:
            return LocalizedString(id: "", default: "deprive of positive human qualities")
        case .hated:
            return LocalizedString(id: "", default: "eel intense or passionate dislike for (someone)")
        case .selfRighteous:
            return LocalizedString(id: "", default: "having or characterized by a certainty, especially an unfounded one, that one is totally correct or morally superior")
        case .proud:
            return LocalizedString(id: "", default: "feeling deep pleasure or satisfaction as a result of one's own achievements, qualities, or possessions or those of someone with whom one is closely associated")
        case .hubris:
            return LocalizedString(id: "", default: "excessive pride or self-confidence")
        case .humble:
            return LocalizedString(id: "", default: "having or showing a modest or low estimate of one's own importance")
        }
    }
    
    // https://materialui.co/colors/
    var color: UIColor {
        switch self {
        case .stressed:
            return #colorLiteral(red: 1, green: 0.8039215686, blue: 0.8235294118, alpha: 1)
        case .overwhelmed:
            return #colorLiteral(red: 0.937254902, green: 0.6039215686, blue: 0.6039215686, alpha: 1)
        case .anxious:
            return #colorLiteral(red: 0.8980392157, green: 0.4509803922, blue: 0.4509803922, alpha: 1)
        case .worried:
            return #colorLiteral(red: 0.937254902, green: 0.3254901961, blue: 0.3137254902, alpha: 1)
        case .avoidance:
            return #colorLiteral(red: 0.9568627451, green: 0.262745098, blue: 0.2117647059, alpha: 1)
        case .excited:
            return #colorLiteral(red: 0.8980392157, green: 0.2235294118, blue: 0.2078431373, alpha: 1)
        case .dread:
            return #colorLiteral(red: 0.8274509804, green: 0.1843137255, blue: 0.1843137255, alpha: 1)
        case .fear:
            return #colorLiteral(red: 0.7764705882, green: 0.1568627451, blue: 0.1568627451, alpha: 1)
        case .vulnerable:
            return #colorLiteral(red: 0.7176470588, green: 0.1098039216, blue: 0.1098039216, alpha: 1)
            
        case .comparison:
            return #colorLiteral(red: 0.9725490196, green: 0.7333333333, blue: 0.8156862745, alpha: 1)
        case .admired:
            return #colorLiteral(red: 0.9568627451, green: 0.5607843137, blue: 0.6941176471, alpha: 1)
        case .revered:
            return #colorLiteral(red: 0.9411764706, green: 0.3843137255, blue: 0.5725490196, alpha: 1)
        case .envious:
            return #colorLiteral(red: 0.9254901961, green: 0.2509803922, blue: 0.4784313725, alpha: 1)
        case .jealous:
            return #colorLiteral(red: 0.9137254902, green: 0.1176470588, blue: 0.3882352941, alpha: 1)
        case .resentment:
            return #colorLiteral(red: 0.8470588235, green: 0.1058823529, blue: 0.3764705882, alpha: 1)
        case .schadenfreude:
            return #colorLiteral(red: 0.7607843137, green: 0.09411764706, blue: 0.3568627451, alpha: 1)
        case .freudenfreude:
            return #colorLiteral(red: 0.6784313725, green: 0.07843137255, blue: 0.3411764706, alpha: 1)
            
        case .bored:
            return #colorLiteral(red: 0.8823529412, green: 0.7450980392, blue: 0.9058823529, alpha: 1)
        case .dissapointed:
            return #colorLiteral(red: 0.8078431373, green: 0.5764705882, blue: 0.8470588235, alpha: 1)
        case .expecting:
            return #colorLiteral(red: 0.7294117647, green: 0.4078431373, blue: 0.7843137255, alpha: 1)
        case .regret:
            return #colorLiteral(red: 0.6705882353, green: 0.2784313725, blue: 0.737254902, alpha: 1)
        case .discouraged:
            return #colorLiteral(red: 0.6117647059, green: 0.1529411765, blue: 0.6901960784, alpha: 1)
        case .resigned:
            return #colorLiteral(red: 0.5568627451, green: 0.1411764706, blue: 0.6666666667, alpha: 1)
        case .frustrated:
            return #colorLiteral(red: 0.4823529412, green: 0.1215686275, blue: 0.6352941176, alpha: 1)
            
        case .awe:
            return #colorLiteral(red: 0.8196078431, green: 0.768627451, blue: 0.9137254902, alpha: 1)
        case .wonder:
            return #colorLiteral(red: 0.7019607843, green: 0.6156862745, blue: 0.8588235294, alpha: 1)
        case .confused:
            return #colorLiteral(red: 0.5843137255, green: 0.4588235294, blue: 0.8039215686, alpha: 1)
        case .curious:
            return #colorLiteral(red: 0.4941176471, green: 0.3411764706, blue: 0.7607843137, alpha: 1)
        case .interested:
            return #colorLiteral(red: 0.4039215686, green: 0.2274509804, blue: 0.7176470588, alpha: 1)
        case .suprised:
            return #colorLiteral(red: 0.368627451, green: 0.2078431373, blue: 0.6941176471, alpha: 1)
            
        case .amused:
            return #colorLiteral(red: 0.6235294118, green: 0.6588235294, blue: 0.8549019608, alpha: 1)
        case .bittersweetness:
            return #colorLiteral(red: 0.4745098039, green: 0.5254901961, blue: 0.7960784314, alpha: 1)
        case .nostalgic:
            return #colorLiteral(red: 0.4745098039, green: 0.5254901961, blue: 0.7960784314, alpha: 1)
        case .cognitiveDissonance:
            return #colorLiteral(red: 0.3607843137, green: 0.4196078431, blue: 0.7529411765, alpha: 1)
        case .paradoxical:
            return #colorLiteral(red: 0.2470588235, green: 0.3176470588, blue: 0.7098039216, alpha: 1)
        case .ironic:
            return #colorLiteral(red: 0.2235294118, green: 0.2862745098, blue: 0.6705882353, alpha: 1)
        case .sarcastic:
            return #colorLiteral(red: 0.1882352941, green: 0.2470588235, blue: 0.6235294118, alpha: 1)
            
        case .anguish:
            return #colorLiteral(red: 0.7333333333, green: 0.8705882353, blue: 0.9843137255, alpha: 1)
        case .hopeless:
            return #colorLiteral(red: 0.5647058824, green: 0.7921568627, blue: 0.9764705882, alpha: 1)
        case .despair:
            return #colorLiteral(red: 0.3921568627, green: 0.7098039216, blue: 0.9647058824, alpha: 1)
        case .sad:
            return #colorLiteral(red: 0.2588235294, green: 0.6470588235, blue: 0.9607843137, alpha: 1)
        case .grief:
            return #colorLiteral(red: 0.1294117647, green: 0.5882352941, blue: 0.9529411765, alpha: 1)
            
        case .compassion:
            return #colorLiteral(red: 0.7019607843, green: 0.8980392157, blue: 0.9882352941, alpha: 1)
        case .pity:
            return #colorLiteral(red: 0.5058823529, green: 0.831372549, blue: 0.9803921569, alpha: 1)
        case .empathy:
            return #colorLiteral(red: 0.3098039216, green: 0.7647058824, blue: 0.968627451, alpha: 1)
        case .sympathy:
            return #colorLiteral(red: 0.1607843137, green: 0.7137254902, blue: 0.9647058824, alpha: 1)
        case .boundaries:
            return #colorLiteral(red: 0.01176470588, green: 0.662745098, blue: 0.9568627451, alpha: 1)
        case .comparativeSuffering:
            return #colorLiteral(red: 0.01176470588, green: 0.6078431373, blue: 0.8980392157, alpha: 1)
            
        case .shame:
            return #colorLiteral(red: 0.6980392157, green: 0.9215686275, blue: 0.9490196078, alpha: 1)
        case .selfCompassion:
            return #colorLiteral(red: 0.5019607843, green: 0.8705882353, blue: 0.9176470588, alpha: 1)
        case .perfectionism:
            return #colorLiteral(red: 0.3019607843, green: 0.8156862745, blue: 0.8823529412, alpha: 1)
        case .guilty:
            return #colorLiteral(red: 0.1490196078, green: 0.7764705882, blue: 0.8549019608, alpha: 1)
        case .humiliated:
            return #colorLiteral(red: 0, green: 0.737254902, blue: 0.831372549, alpha: 1)
        case .embarrased:
            return #colorLiteral(red: 0, green: 0.6745098039, blue: 0.7568627451, alpha: 1)
            
        case .belonging:
            return #colorLiteral(red: 0.6980392157, green: 0.8745098039, blue: 0.8588235294, alpha: 1)
        case .fittingIn:
            return #colorLiteral(red: 0.5019607843, green: 0.7960784314, blue: 0.768627451, alpha: 1)
        case .connected:
            return #colorLiteral(red: 0.3019607843, green: 0.7137254902, blue: 0.6745098039, alpha: 1)
        case .disconnected:
            return #colorLiteral(red: 0.1490196078, green: 0.6509803922, blue: 0.6039215686, alpha: 1)
        case .insecure:
            return #colorLiteral(red: 0, green: 0.5882352941, blue: 0.5333333333, alpha: 1)
        case .invisible:
            return #colorLiteral(red: 0, green: 0.537254902, blue: 0.4823529412, alpha: 1)
        case .lonely:
            return #colorLiteral(red: 0, green: 0.4745098039, blue: 0.4196078431, alpha: 1)
            
        case .loved:
            return #colorLiteral(red: 0.7843137255, green: 0.9019607843, blue: 0.7882352941, alpha: 1)
        case .lovelessness:
            return #colorLiteral(red: 0.6470588235, green: 0.8392156863, blue: 0.6549019608, alpha: 1)
        case .heartbroken:
            return #colorLiteral(red: 0.5058823529, green: 0.7803921569, blue: 0.5176470588, alpha: 1)
        case .trusted:
            return #colorLiteral(red: 0.4, green: 0.7333333333, blue: 0.4156862745, alpha: 1)
        case .selfTrust:
            return #colorLiteral(red: 0.2980392157, green: 0.6862745098, blue: 0.3137254902, alpha: 1)
        case .betrayed:
            return #colorLiteral(red: 0.262745098, green: 0.6274509804, blue: 0.2784313725, alpha: 1)
        case .defensive:
            return #colorLiteral(red: 0.2196078431, green: 0.5568627451, blue: 0.2352941176, alpha: 1)
        case .flooded:
            return #colorLiteral(red: 0.1803921569, green: 0.4901960784, blue: 0.1960784314, alpha: 1)
        case .hurt:
            return #colorLiteral(red: 0.1058823529, green: 0.368627451, blue: 0.1254901961, alpha: 1)
            
        case .joyful:
            return #colorLiteral(red: 0.862745098, green: 0.9294117647, blue: 0.7843137255, alpha: 1)
        case .happy:
            return #colorLiteral(red: 0.7725490196, green: 0.8823529412, blue: 0.6470588235, alpha: 1)
        case .calm:
            return #colorLiteral(red: 0.6823529412, green: 0.8352941176, blue: 0.5058823529, alpha: 1)
        case .content:
            return #colorLiteral(red: 0.6117647059, green: 0.8, blue: 0.3960784314, alpha: 1)
        case .grateful:
            return #colorLiteral(red: 0.5450980392, green: 0.7647058824, blue: 0.2901960784, alpha: 1)
        case .forebodingJoy:
            return #colorLiteral(red: 0.4862745098, green: 0.7019607843, blue: 0.2588235294, alpha: 1)
        case .relieved:
            return #colorLiteral(red: 0.4078431373, green: 0.6235294118, blue: 0.2196078431, alpha: 1)
        case .tranquil:
            return #colorLiteral(red: 0.3333333333, green: 0.5450980392, blue: 0.1843137255, alpha: 1)
            
        case .angry:
            return #colorLiteral(red: 0.9411764706, green: 0.9568627451, blue: 0.7647058824, alpha: 1)
        case .contempt:
            return #colorLiteral(red: 0.9019607843, green: 0.9333333333, blue: 0.6117647059, alpha: 1)
        case .disgusted:
            return #colorLiteral(red: 1, green: 0.9450980392, blue: 0.462745098, alpha: 1)
        case .dehumanized:
            return #colorLiteral(red: 0.831372549, green: 0.8823529412, blue: 0.3411764706, alpha: 1)
        case .hated:
            return #colorLiteral(red: 0.8039215686, green: 0.862745098, blue: 0.2235294118, alpha: 1)
        case .selfRighteous:
            return #colorLiteral(red: 0.7529411765, green: 0.7921568627, blue: 0.2, alpha: 1)
            
        case .proud:
            return #colorLiteral(red: 1, green: 0.9764705882, blue: 0.768627451, alpha: 1)
        case .hubris:
            return #colorLiteral(red: 1, green: 0.9607843137, blue: 0.6156862745, alpha: 1)
        case .humble:
            return #colorLiteral(red: 1, green: 0.9450980392, blue: 0.462745098, alpha: 1)
        }
    }
}
