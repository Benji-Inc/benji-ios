//
//  DeeplinkTarget.swift
//  Benji
//
//  Created by Benji Dodgson on 6/22/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

enum DeepLinkTarget: String, CaseIterable {
    
    case home
    case login
    case conversation
    case thread
    case reservation
    case wallet
    case profile
    case waitlist
    case moment
    case comment
    case capture

    func diffIdentifier() -> NSObjectProtocol {
        return self.rawValue as NSObjectProtocol
    }
}
