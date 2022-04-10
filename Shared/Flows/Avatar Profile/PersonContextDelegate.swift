//
//  AvatarContextDelegate.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/18/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

protocol PersonContextDelegate: UIContextMenuInteractionDelegate {
    func getMenu(for person: PersonType) -> UIMenu
}

private var personKey: UInt8 = 0
extension PersonContextDelegate where Self: NSObject {

    var person: PersonType? {
        get {
            return self.getAssociatedObject(&personKey)
        }
        set {
            self.setAssociatedObject(key: &personKey, value: newValue)
        }
    }

    func getMenu(for person: PersonType) -> UIMenu {
        return UIMenu(title: "Menu", children: [])
    }
}
