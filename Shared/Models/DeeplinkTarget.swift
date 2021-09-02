//
//  DeeplinkTarget.swift
//  Benji
//
//  Created by Benji Dodgson on 6/22/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

enum DeepLinkTarget : String, CaseIterable {
    
    case home
    case login
    case conversation
    case conversations
    case reservation

    func diffIdentifier() -> NSObjectProtocol {
        return self.rawValue as NSObjectProtocol
    }
}
