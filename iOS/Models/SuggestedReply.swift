//
//  SuggestedReply.swift
//  Jibber
//
//  Created by Benji Dodgson on 4/24/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

enum SuggestedReply: CaseIterable {
    
    case yes
    case noThanks
    case ok
    case onMyWay
    case what
    case thanks
    case great
    case busy
    case other
    
    var text: String {
        switch self {
            
        case .yes:
            return "Yes"
        case .noThanks:
            return "No thanks."
        case .ok:
            return "Ok"
        case .onMyWay:
            return "On my way!"
        case .what:
            return "What?"
        case .thanks:
            return "Thanks"
        case .great:
            return "Great!"
        case .busy:
            return "I'm busy"
        case .other:
            return "Other"
        }
    }
}
