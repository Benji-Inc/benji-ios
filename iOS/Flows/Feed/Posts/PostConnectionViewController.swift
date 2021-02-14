//
//  FeedConnectionRequest.swift
//  Benji
//
//  Created by Benji Dodgson on 3/30/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization
import Combine

class PostConnectionViewController: PostViewController {

    private let avatarView = AvatarView()
    private let textView = FeedTextView()
    private let acceptButton = Button()
    private let declineButton = Button()
    var didComplete: () -> Void = {}

    private var connection: Connection?

    override func initializeViews() {
        super.initializeViews()

        self.container.addSubview(self.avatarView)
        self.container.addSubview(self.textView)
        self.container.addSubview(self.acceptButton)
        self.container.addSubview(self.declineButton)

        self.textView.set(localizedText: "Connection request.")
        self.acceptButton.set(style: .rounded(color: .purple, text: "Accept"))
        self.acceptButton.didSelect { [unowned self] in
            self.updateConnection(with: .accepted)
        }

        self.declineButton.set(style: .rounded(color: .red, text: "Decline"))
        self.declineButton.didSelect { [unowned self] in
            self.updateConnection(with: .declined)
        }
    }

    func configure(connection: Connection) {
        self.connection = connection

        if let user = connection.nonMeUser {
            user.fetchIfNeededInBackground { (object, error) in
                guard let nonMeUser = object as? User else { return }
                self.avatarView.set(avatar: nonMeUser)

                let text = LocalizedString(id: "", arguments: [nonMeUser.givenName], default: "@(first) would like to connect with you.")
                self.textView.set(localizedText: text)
                self.container.layoutNow()
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.avatarView.setSize(for: 100)
        self.avatarView.centerOnX()
        self.avatarView.top = self.container.height * 0.3

        self.textView.setSize(withWidth: self.container.width)
        self.textView.top = self.avatarView.bottom + 10
        self.textView.centerOnX()

        self.acceptButton.setSize(with: self.container.width * 0.4)
        self.acceptButton.centerX = self.container.width * 0.69
        self.acceptButton.bottom = self.container.height - Theme.contentOffset

        self.declineButton.setSize(with: self.container.width * 0.4)
        self.declineButton.centerX = self.container.width * 0.3
        self.declineButton.bottom = self.container.height - Theme.contentOffset
    }

    func updateConnection(with status: Connection.Status) {
        guard let connection = self.connection else { return }

        UpdateConnection(connection: connection, status: status)
            .makeRequest(andUpdate: [], viewsToIgnore: [])
            .mainSink(receiveValue: { (_) in },
                      receiveCompletion: { (_) in
                        self.didComplete()
                      }).store(in: &self.cancellables)
    }
}
