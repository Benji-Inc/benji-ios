//
//  User+Extensions.swift
//  Benji
//
//  Created by Benji Dodgson on 11/3/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import Combine

extension User: Avatar {

    var userObjectID: String? {
        self.objectId
    }

    var image: UIImage? {
        return nil
    }

    var isOnboarded: Bool {

        if self.fullName.isEmpty {
            return false
        } else if self.smallImage == nil {
            return false
        }

        return true 
    }

    var isCurrentUser: Bool {
        return self.objectId == User.current()?.objectId
    }
}

#if !APPCLIP
// Code you don't want to use in your App Clip.
extension User: ManageableCellItem {
    var id: String {
        return self.objectId!
    }
}
#endif

extension User {
    
    func formatName(from text: String) {
        let components = text.components(separatedBy: " ").filter { (component) -> Bool in
            return !component.isEmpty
        }
        if let first = components.first {
            self.givenName = first
        }
        if let last = components.last {
            self.familyName = last
        }
    }
}
