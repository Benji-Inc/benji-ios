//
//  ReservationsViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 4/19/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Localization

class ReservationsViewController: NavigationBarViewController {

    let contactsButton = ThemeButton()
    var didSelectShowContacts: CompletionOptional = nil

    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.contactsButton)
        self.contactsButton.set(style: .normal(color: .darkGray, text: "Invite Contacts"))
        self.contactsButton.didSelect { [unowned self] in
            self.didSelectShowContacts?()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.contactsButton.setSize(with: self.view.width)
        self.contactsButton.centerOnX()
        self.contactsButton.pinToSafeAreaBottom()
    }

    override func getTitle() -> Localized {
        return "Friends don't send, they swipe."
    }

    override func getDescription() -> Localized {
        return "Jibber is an exclusive community that cares about quality over quantity, especially with its users, so invite the people you are most social with. (iOS only)"
    }

    override func shouldShowBackButton() -> Bool {
        return false
    }
}
