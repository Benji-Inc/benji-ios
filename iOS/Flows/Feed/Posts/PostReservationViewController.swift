//
//  FeedInviteView.swift
//  Benji
//
//  Created by Benji Dodgson on 12/7/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

class PostReservationViewController: PostViewController {

    var reservation: Reservation?

    override func initializeViews() {
        super.initializeViews()

        self.textView.set(localizedText: "Who would you like to share Ours with?")
        self.button.set(style: .rounded(color: .purple, text: "SHARE"))
    }

    override func didTapButton() {
        self.didFinish?()
    }
}
