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
        case numberOfSwipeHints
        case localAchievements
    }

    static func update(key: Key, with value: Any) {
        UserDefaults.standard.setValue(value, forKey: key.rawValue)
    }
    
    static func getStrings(for key: Key, defaultValue: [String] = []) -> [String] {
        if UserDefaults.standard.value(forKey: key.rawValue).isNil {
            return defaultValue
        }
        return UserDefaults.standard.stringArray(forKey: key.rawValue) ?? defaultValue
    }
    
    static func getInt(for key: Key, defaultValue: Int = 0) -> Int {
        if UserDefaults.standard.value(forKey: key.rawValue).isNil {
            return defaultValue
        }
        return UserDefaults.standard.integer(forKey: key.rawValue)
    }

    static func getBool(for key: Key, defaultValue: Bool = true) -> Bool {
        if UserDefaults.standard.value(forKey: key.rawValue).isNil {
            return defaultValue
        }
        return UserDefaults.standard.bool(forKey: key.rawValue)
    }

    static func getString(for key: Key) -> String? {
        return UserDefaults.standard.string(forKey: key.rawValue)
    }
}
