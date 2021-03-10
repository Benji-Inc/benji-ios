//
//  FeedMeditationView.swift
//  Benji
//
//  Created by Benji Dodgson on 4/11/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation

class PostMeditationViewController: PostViewController {

    override func initializeViews() {
        super.initializeViews()

        self.textView.set(localizedText: "Begin a mindful minute?")
        self.button.set(style: .rounded(color: .purple, text: "Yes"))
    }

    override func didTapButton() {
        self.didSelectPost?()
    }
}
