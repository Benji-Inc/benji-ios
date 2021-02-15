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

    private let acceptButton = Button()
    private let declineButton = Button()
    private var connection: Connection?
    private let buttonContainer = View()

    override func initializeViews() {
        super.initializeViews()

        self.buttonContainer.addSubview(self.acceptButton)
        self.buttonContainer.addSubview(self.declineButton)

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

    override func getCenterContent() -> UIView {
        return self.buttonContainer
    }

    override func configurePost() {
        guard case PostType.connectionRequest(let connection) = self.type else { return }
        self.configure(connection: connection)
    }

    private func configure(connection: Connection) {
        self.connection = connection

        if let user = connection.nonMeUser {
            user.retrieveDataIfNeeded()
                .mainSink(receiveValue: { user in
                    self.avatarView.set(avatar: user)
                    let text = LocalizedString(id: "", arguments: [user.givenName], default: "@(first) would like to connect with you.")
                    self.textView.set(localizedText: text)
                    self.view.layoutNow()
                }).store(in: &self.cancellables)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.buttonContainer.expandToSuperviewSize()

        self.acceptButton.setSize(with: self.buttonContainer.width * 0.4)
        self.acceptButton.centerX = self.buttonContainer.width * 0.69
        self.acceptButton.pin(.bottom)

        self.declineButton.setSize(with: self.buttonContainer.width * 0.4)
        self.declineButton.centerX = self.buttonContainer.width * 0.3
        self.declineButton.pin(.bottom)
    }

    func updateConnection(with status: Connection.Status) {
        guard let connection = self.connection else { return }

        UpdateConnection(connection: connection, status: status)
            .makeRequest(andUpdate: [], viewsToIgnore: [])
            .mainSink(receiveValue: { (_) in },
                      receiveCompletion: { (_) in
                        self.didFinish?()
                      }).store(in: &self.cancellables)
    }
}
