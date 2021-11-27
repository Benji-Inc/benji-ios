//
//  MessageContentView+Reactions.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/27/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

extension MessageContentView {

    func presentReactions() {
        let thumbsUp = UIMenuItem(title: "👍", action: #selector (self.didTapThumbsUp))
        UIMenuController.shared.menuItems = [thumbsUp]

        UIMenuController.shared.arrowDirection = .default
        UIMenuController.shared.showMenu(from: self, rect: self.reactionsView.frame)
    }

    @objc func didTapThumbsUp() {
        logDebug("did tap thumbs up")
    }

}
