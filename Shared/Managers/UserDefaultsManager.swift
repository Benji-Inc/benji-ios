//
//  UserDefaultsManager.swift
//  Ours
//
//  Created by Benji Dodgson on 6/5/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class UserDefaultsManager {

    enum Key: String {
        case hasShownHomeSwipe
        case hasShownKeyboardInstructions
    }

    static func update(key: Key, with value: Bool) {
        UserDefaults.standard.setValue(value, forKey: key.rawValue)
    }

    static func getValue(for key: Key) -> Bool {
        return UserDefaults.standard.bool(forKey: key.rawValue)
    }
}
