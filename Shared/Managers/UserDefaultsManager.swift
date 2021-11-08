//
//  UserDefaultsManager.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/5/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class UserDefaultsManager {

    enum Key: String {
        case hasShownHomeSwipe
        case hasShownKeyboardInstructions
        case fullName
    }

    static func update(key: Key, with value: Any) {
        UserDefaults.standard.setValue(value, forKey: key.rawValue)
    }

    static func getBool(for key: Key) -> Bool {
        return UserDefaults.standard.bool(forKey: key.rawValue)
    }

    static func getString(for key: Key) -> String? {
        return UserDefaults.standard.string(forKey: key.rawValue)
    }
}
