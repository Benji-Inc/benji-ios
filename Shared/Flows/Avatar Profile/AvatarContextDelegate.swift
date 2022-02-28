//
//  AvatarContextDelegate.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/18/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

protocol AvatarContextDelegate: UIContextMenuInteractionDelegate {
    func getMenu(for avatar: PersonType) -> UIMenu
}

private var avatarKey: UInt8 = 0
extension AvatarContextDelegate where Self: NSObject {

    var avatar: PersonType? {
        get {
            return self.getAssociatedObject(&avatarKey)
        }
        set {
            self.setAssociatedObject(key: &avatarKey, value: newValue)
        }
    }

    func getMenu(for avatar: PersonType) -> UIMenu {
        return UIMenu(title: "Menu", children: [])
    }
}
