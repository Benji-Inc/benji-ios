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
        case swipeAnimationViewCount
        case keyboardInstructionsCount
    }

    func update(key: Key, with value: Bool) {
        UserDefaults.standard.setValue(value, forKey: key.rawValue)
    }

    func getValue(for key: Key) -> Bool {
        return UserDefaults.standard.bool(forKey: key.rawValue)
    }
}
