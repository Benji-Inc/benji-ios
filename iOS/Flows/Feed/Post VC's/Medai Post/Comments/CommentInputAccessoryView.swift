//
//  CommentInputAccessoryView.swift
//  Ours
//
//  Created by Benji Dodgson on 4/13/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class CommentInputAccessoryView: SwipeableInputAccessoryView {

    override func initializeSubviews() {
        super.initializeSubviews()

        self.borderColor = Color.lightPurple.color.cgColor
        self.textView.set(placeholder: "Add Comment", color: .lightPurple)
    }

    override func shouldShowPlusButton() -> Bool {
        return false
    }
}
