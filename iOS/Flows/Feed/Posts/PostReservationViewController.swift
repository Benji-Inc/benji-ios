//
//  FeedInviteView.swift
//  Benji
//
//  Created by Benji Dodgson on 12/7/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

class PostReservationViewController: PostViewController {

    let textView = FeedTextView()
    let button = Button()
    var reservation: Reservation?

    override func initializeViews() {
        super.initializeViews()

        self.container.addSubview(self.textView)
        self.container.addSubview(self.button)
        self.textView.set(localizedText: "Who would you like to share Ours with?")
        self.button.set(style: .rounded(color: .purple, text: "SHARE"))
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
