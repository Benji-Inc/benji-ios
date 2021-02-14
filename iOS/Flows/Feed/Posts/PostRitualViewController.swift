//
//  FeedRitualView.swift
//  Benji
//
//  Created by Benji Dodgson on 12/7/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

class PostRitualViewController: PostViewController {

    let textView = FeedTextView()
    let button = Button()

    override func initializeViews() {
        super.initializeViews()

        self.container.addSubview(self.textView)
        self.container.addSubview(self.button)
        self.textView.set(localizedText: "Set a time each day to check your Daily Feed.")
        self.button.set(style: .rounded(color: .purple, text: "SET"))
        self.button.didSelect { [unowned self] in
            self.didSelect?()
        }
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
