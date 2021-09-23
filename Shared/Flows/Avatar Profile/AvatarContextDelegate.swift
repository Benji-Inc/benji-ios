//
//  AvatarContextDelegate.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/18/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

protocol AvatarContextDelegate: UIContextMenuInteractionDelegate {
    func getMenu(for avatar: Avatar) -> UIMenu
}

private var avatarKey: UInt8 = 0
extension AvatarContextDelegate where Self: NSObject {

    var avatar: Avatar? {
        get {
            return self.getAssociatedObject(&avatarKey)
        }
        set {
            self.setAssociatedObject(key: &avatarKey, value: newValue)
        }
    }

    func getMenu(for avatar: Avatar) -> UIMenu {
        return UIMenu(title: "Menu", children: [])
    }
}
