//
//  FeedMeditationView.swift
//  Benji
//
//  Created by Benji Dodgson on 4/11/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation

class PostMeditationViewController: PostViewController {

    let textView = FeedTextView()
    let button = Button()

    override func initializeViews() {
        super.initializeViews()

        self.container.addSubview(self.textView)
        self.container.addSubview(self.button)
        self.textView.set(localizedText: "Begin a mindful minute?")
        self.button.set(style: .rounded(color: .purple, text: "Yes"))
        self.button.isEnabled = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.textView.setSize(withWidth: self.container.width)
        self.textView.bottom = self.container.centerY - 10
        self.textView.centerOnX()

        self.button.setSize(with: self.container.width)
        self.button.centerOnX()
        self.button.bottom = self.container.height - Theme.contentOffset
    }
}
