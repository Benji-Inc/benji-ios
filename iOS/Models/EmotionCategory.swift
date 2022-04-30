//
//  ReactionType.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/27/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Localization
import UIKit

enum EmotionCategory: Int, CaseIterable {

    case heartOpen
    case good
    case connection
    case others
    case uncertain
    case compare
    case unplanned
    case beyondUs
    case areNotWhatTheySeem
    case hurting
    case fallShort
    case wronged
    case selfAssess
    
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
        case .selfAssess:
            return LocalizedString(id: "", default: "We self-assess")
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
        case .selfAssess:
            return #colorLiteral(red: 1, green: 0.9921568627, blue: 0.9058823529, alpha: 1)
        }
    }
    
    var emotions: [Emotion] {
        switch self {
        case .uncertain:
            return [.stressed, .overwhelmed, .anxious, .worried, .avoidance, .excited, .dread, .afraid, .vulnerable]
        case .compare:
            return [.comparison, .admiration, .reverence, .envy, .jealous, .resentment, .schadenfreude, .freudenfreude]
        case .unplanned:
            return [.bored, .disappointment, .expecting, .regret, .discouraged, .resigned, .frustrated]
        case .beyondUs:
            return [.awe, .wonder, .confused, .curious, .interested, .surprised]
        case .areNotWhatTheySeem:
            return [.amused, .bittersweetness, .nostalgia, .cognitiveDissonance, .paradoxical, .ironic, .sarcastic]
        case .hurting:
            return [.anguish, .hopeless, .despair, .sad, .grief]
        case .others:
            return [.compassion, .pity, .empathy, .sympathy, .boundaries, .comparativeSuffering]
        case .fallShort:
            return [.shame, .selfCompassion, .perfectionism, .guilty, .humiliated, .embarrased]
        case .connection:
            return [.belonging, .fittingIn, .connected, .disconnected, .insecure, .invisible, .loneliness]
        case .heartOpen:
            return [.love, .lovelessness, .heartbroken, .trust, .selfTrust, .betrayal, .defensive, .flooded, .hurt]
        case .good:
            return [.joy, .happy, .calm, .contentment, .gratitude, .forebodingJoy, .relief, .tranquil]
        case .wronged:
            return [.angry, .contempt, .disgust, .dehumanized, .hated, .selfRighteous]
        case .selfAssess:
            return [.pride, .hubris, .humility]
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
    case afraid
    case vulnerable
    
    case comparison
    case admiration
    case reverence
    case envy
    case jealous
    case resentment
    case schadenfreude
    case freudenfreude
    
    case bored
    case disappointment
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
    case surprised
    
    case amused
    case bittersweetness
    case nostalgia
    case cognitiveDissonance
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
    case comparativeSuffering
    
    case shame
    case selfCompassion
    case perfectionism
    case guilty
    case humiliated
    case embarrased
    
    case belonging
    case fittingIn
    case connected
    case disconnected
    case insecure
    case invisible
    case loneliness
    
    case love
    case lovelessness
    case heartbroken
    case trust
    case selfTrust
    case betrayal
    case defensive
    case flooded
    case hurt
    
    case joy
    case happy
    case calm
    case contentment
    case gratitude
    case forebodingJoy
    case relief
    case tranquil
    
    case angry
    case contempt
    case disgust
    case dehumanized
    case hated
    case selfRighteous
    
    case pride
    case hubris
    case humility

    var id: String {
        return self.rawValue
    }

    var description: String {
        switch self {
        case .cognitiveDissonance:
            return "cognitive dissonance"
        case .comparativeSuffering:
            return "comparative suffering"
        case .selfCompassion:
            return "self-compassion"
        case .fittingIn:
            return "fitting in"
        case .selfTrust:
            return "self-trust"
        case .forebodingJoy:
            return "forboding joy"
        case .selfRighteous:
            return "self-righteous"
        default:
            return self.rawValue
        }
    }
    
    var definition: Localized {
        switch self {
        case .stressed:
            return LocalizedString(id: "", default: "We feel stressed when we evaluate environmental demand as beyond our ability to cope successfully. This includes elements of unpredictability, uncontrollability, and feeling overloaded")
        case .overwhelmed:
            return LocalizedString(id: "", default: "An extreme level of stress, an emotional and/or cognitive intensity to the point of feeling unable to function")
        case .anxious:
            return LocalizedString(id: "", default: "An emotion characterized by feelings of tension, worried thoughts and physical changes like increased blood pressure")
        case .worried:
            return LocalizedString(id: "", default: "A chain of negative thoughts about bad things that might happen in the future")
        case .avoidance:
            return LocalizedString(id: "", default: "Is not showing up and often spending a lot of energy zigzagging around and away from that thing that already feels like it’s consuming us")
        case .excited:
            return LocalizedString(id: "", default: "An energized state of enthusiasm leading up to or during an enjoyable activity")
        case .dread:
            return LocalizedString(id: "", default: "Occurs frequently in response to high-probability negative events; its magnitude increases as the dreaded event draws nearer")
        case .afraid:
            return LocalizedString(id: "", default: "a negative, short-lasting, high-alert emotion in response to a perceived threat, and, like anxiety, it can be measured as a state or trait")
        case .vulnerable:
            return LocalizedString(id: "", default: "is the emotion that we experience during times of uncertainty, risk, and emotional exposure")
        case .comparison:
            return LocalizedString(id: "", default: "Comparison is the crush of conformity from one side and competition from the other—it’s trying to simultaneously fit in and stand out")
        case .admiration:
            return LocalizedString(id: "", default: "We feel this when someone’s abilities, accomplishments, or character inspires us, or when we see something else that inspires us, like art or nature")
        case .reverence:
            return LocalizedString(id: "", default: "Sometimes called adoration, worship, or veneration, is a deeper form of admiration or respect and is often combined with a sense of meaningful connection with something greater than ourselves")
        case .envy:
            return LocalizedString(id: "", default: "Occurs when we want something that another person has")
        case .jealous:
            return LocalizedString(id: "", default: "When we fear losing a relationship or a valued part of a relationship that we already have")
        case .resentment:
            return LocalizedString(id: "", default: "The feeling of frustration, judgment, anger, “better than,” and/or hidden envy related to perceived unfairness or injustice")
        case .schadenfreude:
            return LocalizedString(id: "", default: "Pleasure or joy derived from someone else’s suffering or misfortune")
        case .freudenfreude:
            return LocalizedString(id: "", default: "The enjoyment of another’s success and a subset of empathy")
        case .bored:
            return LocalizedString(id: "", default: "The uncomfortable state of wanting to engage in satisfying activity, but being unable to do it")
        case .disappointment:
            return LocalizedString(id: "", default: "Is unmet expectations. The more significant the expectations, the more significant the disappointment copyright.")
        case .expecting:
            return LocalizedString(id: "", default: "A picture in our head of how things are going to be and how they’re going to look")
        case .regret:
            return LocalizedString(id: "", default: "The belief that an outcome was caused by our decisions or action")
        case .discouraged:
            return LocalizedString(id: "", default: "Losing the motivation and confidence to persist")
        case .resigned:
            return LocalizedString(id: "", default: "Lost the motivation and confidence to persist")
        case .frustrated:
            return LocalizedString(id: "", default: "Something that feels out of my control is preventing me from achieving my desired outcome")
        case .awe:
            return LocalizedString(id: "", default: "Inspires the wish to understand")
        case .wonder:
            return LocalizedString(id: "", default: "Inspires the wish to let shine, to acknowledge and to unite")
        case .confused:
            return LocalizedString(id: "", default: "Unable to think clearly; bewildered")
        case .curious:
            return LocalizedString(id: "", default: "Is recognizing a gap in our knowledge about something that interests us, and becoming emotionally and cognitively invested in closing that gap through exploration and learning")
        case .interested:
            return LocalizedString(id: "", default: "Is a cognitive openness to engaging with a topic or experience")
        case .surprised:
            return LocalizedString(id: "", default: "An interruption caused by information that doesn’t fit with our current understanding or expectations")
        case .amused:
            return LocalizedString(id: "", default: "Is “pleasurable, relaxed excitation")
        case .bittersweetness:
            return LocalizedString(id: "", default: "Is a mixed feeling of happiness and sadness")
        case .nostalgia:
            return LocalizedString(id: "", default: "A yearning for the way things used to be in our often idealized and self-protective version of the past")
        case .cognitiveDissonance:
            return LocalizedString(id: "", default: "Is a state of tension that occurs when a person holds two cognitions (ideas, attitudes, beliefs, opinions) that are psychologically inconsistent with each other")
        case .paradoxical:
            return LocalizedString(id: "", default: "Is the appearance of contradiction between two related components")
        case .ironic:
            return LocalizedString(id: "", default: "Is a form of communication in which the literal meaning of the words is different, often opposite, from the intended message")
        case .sarcastic:
            return LocalizedString(id: "", default: "Is a particular type of irony in which the underlying message is normally meant to ridicule, tease, or criticize")
        case .anguish:
            return LocalizedString(id: "", default: "Is an almost unbearable and traumatic swirl of shock, incredulity, grief, and powerlessness")
        case .hopeless:
            return LocalizedString(id: "", default: "Is being crushed by the belief that there is no way out of what is holding us back, no way to get to what we desperately need")
        case .despair:
            return LocalizedString(id: "", default: "Is a sense of hopelessness about a person’s entire life and future")
        case .sad:
            return LocalizedString(id: "", default: "Is a feeling or showing sorrow; unhappy")
        case .grief:
            return LocalizedString(id: "", default: "Is a deep sorrow, especially that caused by someone's death")
        case .compassion:
            return LocalizedString(id: "", default: "Is the daily practice of recognizing and accepting our shared humanity so that we treat ourselves and others with loving-kindness, and we take action in the face of suffering")
        case .pity:
            return LocalizedString(id: "", default: "A belief that the suffering person is inferior; a passive, self-focused reaction that does not include providing help; a desire to maintain emotional distance; and avoidance of sharing in the other person’s suffering")
        case .empathy:
            return LocalizedString(id: "", default: "Is an emotional skill set that allows us to understand what someone is experiencing and to reflect back that understanding")
        case .sympathy:
            return LocalizedString(id: "", default: "Feelings of pity and sorrow for someone else's misfortune")
        case .boundaries:
            return LocalizedString(id: "", default: "Are the distance I can love you and me simultaneously")
        case .comparativeSuffering:
            return LocalizedString(id: "", default: "Feeling the need to see our own suffering in light of other people's pain")
        case .shame:
            return LocalizedString(id: "", default: "Is the intensely painful feeling or experience of believing that we are flawed and therefore unworthy of love, belonging, and connection")
        case .selfCompassion:
            return LocalizedString(id: "", default: "Acting the same way towards yourself when you are having a difficult time, fail, or notice something you don't like about yourself")
        case .perfectionism:
            return LocalizedString(id: "", default: "Is a self-destructive and addictive belief system that fuels this primary thought: If I do everything perfectly, I can avoid or minimize the painful feelings of shame, judgment, and blame")
        case .guilty:
            return LocalizedString(id: "", default: "Is an emotion that we experience when we fall short of our own expectations or standards")
        case .humiliated:
            return LocalizedString(id: "", default: "The intensely painful feeling that we’ve been unjustly degraded, ridiculed, or put down and that our identity has been demeaned or devalued")
        case .embarrased:
            return LocalizedString(id: "", default: "Is a fleeting feeling of self-conscious discomfort in response to a minor incident that was witnessed by others")
        case .belonging:
            return LocalizedString(id: "", default: "Is a practice that requires us to be vulnerable, get uncomfortable, and learn how to be present with people without sacrificing who we are")
        case .fittingIn:
            return LocalizedString(id: "", default: "Is being somewhere where you want to be, but they don't care one way or the other")
        case .connected:
            return LocalizedString(id: "", default: "The energy that exists between people when they feel seen, heard, and valued; when they can give and receive without judgment; and when they derive sustenance and strength from the relationship")
        case .disconnected:
            return LocalizedString(id: "", default: "Is often equated with social rejection, social exclusion, and/or social isolation, and these feelings of disconnection actually share the same neural pathways with feelings of physical pain")
        case .insecure:
            return LocalizedString(id: "", default: "The open and nonjudgmental acceptance of one’s own weaknesses")
        case .invisible:
            return LocalizedString(id: "", default: "A function of disconnection and dehumanization, where an individual or group’s humanity and relevance are unacknowledged, ignored, and/or diminished in value or importance")
        case .loneliness:
            return LocalizedString(id: "", default: "Is the absence of meaningful social interaction—an intimate relationship, friendships, family gatherings, or even community or work group connections")
        case .love:
            return LocalizedString(id: "", default: "Is something that we nurture and grow, a connection that can be cultivated between two people only when it exists within each one of them—we can love others only as much as we love ourselves")
        case .lovelessness:
            return LocalizedString(id: "", default: "Is having no feelings of love")
        case .heartbroken:
            return LocalizedString(id: "", default: "Is what happens when love is lost")
        case .trust:
            return LocalizedString(id: "", default: "Choosing to risk making something you value vulnerable to another person’s actions")
        case .selfTrust:
            return LocalizedString(id: "", default: "the firm reliance on the integrity of yourself")
        case .betrayal:
            return LocalizedString(id: "", default: "Is so painful because, at its core, it is a violation of trust")
        case .defensive:
            return LocalizedString(id: "", default: "Is a way to protect our ego and a fragile self-esteem")
        case .flooded:
            return LocalizedString(id: "", default: "A sensation of feeling psychologically and physically overwhelmed during conflict, making it virtually impossible to have a productive, problem-solving discussion")
        case .hurt:
            return LocalizedString(id: "", default: "Experiencing a combination of sadness at having been emotionally wounded and fear of being vulnerable to harm")
        case .joy:
            return LocalizedString(id: "", default: "An intense feeling of deep spiritual connection, pleasure, and appreciation")
        case .happy:
            return LocalizedString(id: "", default: "Feeling pleasure often related to the immediate environment or current circumstances")
        case .calm:
            return LocalizedString(id: "", default: "Creating perspective and mindfulness while managing emotional reactivity")
        case .contentment:
            return LocalizedString(id: "", default: "The feeling of completeness, appreciation, and “enoughness” that we experience when our needs are satisfied")
        case .gratitude:
            return LocalizedString(id: "", default: "Is an emotion that reflects our deep appreciation for what we value, what brings meaning to our lives, and what makes us feel connected to ourselves and others")
        case .forebodingJoy:
            return LocalizedString(id: "", default: "Feeling afraid to lean into good news, wonderful moments, and joy or if you find yourself waiting for the other shoe to drop")
        case .relief:
            return LocalizedString(id: "", default: "Feelings of tension leaving the body and being able to breathe more easily, thoughts of the worst being over and being safe for the moment, resting, and wanting to get on to something else")
        case .tranquil:
            return LocalizedString(id: "", default: "Is associated with the absence of demand” and “no pressure to do anything")
        case .angry:
            return LocalizedString(id: "", default: "Is an emotion felt when something gets in the way of a desired outcome or when we believe there’s a violation of the way things should be")
        case .contempt:
            return LocalizedString(id: "", default: "Is a way of saying “I’m better than you. And you are lesser than me.”")
        case .disgust:
            return LocalizedString(id: "", default: "A feeling of aversion towards something offensive")
        case .dehumanized:
            return LocalizedString(id: "", default: "The psychological process of demonizing the enemy, making them seem less than human and hence not worthy of humane treatment")
        case .hated:
            return LocalizedString(id: "", default: "Is a combination of various negative emotions including repulsion, disgust, anger, fear, and contempt")
        case .selfRighteous:
            return LocalizedString(id: "", default: "Is the conviction that one’s beliefs and behaviors are the most correct")
        case .pride:
            return LocalizedString(id: "", default: "Is a feeling of pleasure or celebration related to our accomplishments or efforts")
        case .hubris:
            return LocalizedString(id: "", default: "Is an inflated sense of one’s own innate abilities that is tied more to the need for dominance than to actual accomplishments")
        case .humility:
            return LocalizedString(id: "", default: "Is openness to new learning combined with a balanced and accurate assessment of our contributions, including our strengths, imperfections, and opportunities for growth")
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
        case .afraid:
            return #colorLiteral(red: 0.7764705882, green: 0.1568627451, blue: 0.1568627451, alpha: 1)
        case .vulnerable:
            return #colorLiteral(red: 0.7176470588, green: 0.1098039216, blue: 0.1098039216, alpha: 1)
            
        case .comparison:
            return #colorLiteral(red: 0.9725490196, green: 0.7333333333, blue: 0.8156862745, alpha: 1)
        case .admiration:
            return #colorLiteral(red: 0.9568627451, green: 0.5607843137, blue: 0.6941176471, alpha: 1)
        case .reverence:
            return #colorLiteral(red: 0.9411764706, green: 0.3843137255, blue: 0.5725490196, alpha: 1)
        case .envy:
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
        case .disappointment:
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
        case .surprised:
            return #colorLiteral(red: 0.368627451, green: 0.2078431373, blue: 0.6941176471, alpha: 1)
            
        case .amused:
            return #colorLiteral(red: 0.6235294118, green: 0.6588235294, blue: 0.8549019608, alpha: 1)
        case .bittersweetness:
            return #colorLiteral(red: 0.4745098039, green: 0.5254901961, blue: 0.7960784314, alpha: 1)
        case .nostalgia:
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
        case .loneliness:
            return #colorLiteral(red: 0, green: 0.4745098039, blue: 0.4196078431, alpha: 1)
            
        case .love:
            return #colorLiteral(red: 0.7843137255, green: 0.9019607843, blue: 0.7882352941, alpha: 1)
        case .lovelessness:
            return #colorLiteral(red: 0.6470588235, green: 0.8392156863, blue: 0.6549019608, alpha: 1)
        case .heartbroken:
            return #colorLiteral(red: 0.5058823529, green: 0.7803921569, blue: 0.5176470588, alpha: 1)
        case .trust:
            return #colorLiteral(red: 0.4, green: 0.7333333333, blue: 0.4156862745, alpha: 1)
        case .selfTrust:
            return #colorLiteral(red: 0.2980392157, green: 0.6862745098, blue: 0.3137254902, alpha: 1)
        case .betrayal:
            return #colorLiteral(red: 0.262745098, green: 0.6274509804, blue: 0.2784313725, alpha: 1)
        case .defensive:
            return #colorLiteral(red: 0.2196078431, green: 0.5568627451, blue: 0.2352941176, alpha: 1)
        case .flooded:
            return #colorLiteral(red: 0.1803921569, green: 0.4901960784, blue: 0.1960784314, alpha: 1)
        case .hurt:
            return #colorLiteral(red: 0.1058823529, green: 0.368627451, blue: 0.1254901961, alpha: 1)
            
        case .joy:
            return #colorLiteral(red: 0.862745098, green: 0.9294117647, blue: 0.7843137255, alpha: 1)
        case .happy:
            return #colorLiteral(red: 0.7725490196, green: 0.8823529412, blue: 0.6470588235, alpha: 1)
        case .calm:
            return #colorLiteral(red: 0.6823529412, green: 0.8352941176, blue: 0.5058823529, alpha: 1)
        case .contentment:
            return #colorLiteral(red: 0.6117647059, green: 0.8, blue: 0.3960784314, alpha: 1)
        case .gratitude:
            return #colorLiteral(red: 0.5450980392, green: 0.7647058824, blue: 0.2901960784, alpha: 1)
        case .forebodingJoy:
            return #colorLiteral(red: 0.4862745098, green: 0.7019607843, blue: 0.2588235294, alpha: 1)
        case .relief:
            return #colorLiteral(red: 0.4078431373, green: 0.6235294118, blue: 0.2196078431, alpha: 1)
        case .tranquil:
            return #colorLiteral(red: 0.3333333333, green: 0.5450980392, blue: 0.1843137255, alpha: 1)
            
        case .angry:
            return #colorLiteral(red: 0.9411764706, green: 0.9568627451, blue: 0.7647058824, alpha: 1)
        case .contempt:
            return #colorLiteral(red: 0.9019607843, green: 0.9333333333, blue: 0.6117647059, alpha: 1)
        case .disgust:
            return #colorLiteral(red: 1, green: 0.9450980392, blue: 0.462745098, alpha: 1)
        case .dehumanized:
            return #colorLiteral(red: 0.831372549, green: 0.8823529412, blue: 0.3411764706, alpha: 1)
        case .hated:
            return #colorLiteral(red: 0.8039215686, green: 0.862745098, blue: 0.2235294118, alpha: 1)
        case .selfRighteous:
            return #colorLiteral(red: 0.7529411765, green: 0.7921568627, blue: 0.2, alpha: 1)
            
        case .pride:
            return #colorLiteral(red: 1, green: 0.9764705882, blue: 0.768627451, alpha: 1)
        case .hubris:
            return #colorLiteral(red: 1, green: 0.9607843137, blue: 0.6156862745, alpha: 1)
        case .humility:
            return #colorLiteral(red: 1, green: 0.9450980392, blue: 0.462745098, alpha: 1)
        }
    }
}

extension Emotion: Comparable {

    private static let sortValues: [Emotion : Int] = {
        let allCases = Emotion.allCases
        var values: [Emotion : Int] = [:]
        for (index, emotion) in allCases.enumerated() {
            values[emotion] = index
        }
        return values
    }()

    static func < (lhs: Emotion, rhs: Emotion) -> Bool {
        return lhs.sortIndex < rhs.sortIndex
    }

    private var sortIndex: Int {
        return Emotion.sortValues[self] ?? 0
    }
}
