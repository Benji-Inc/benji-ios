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

        self.container.addSubview(self.textView)

        self.buttonContainer.addSubview(self.acceptButton)
        self.buttonContainer.addSubview(self.declineButton)

        self.acceptButton.set(style: .rounded(color: .purple, text: "Accept"))
        self.acceptButton.didSelect { [unowned self] in
            self.updateConnection(with: .accepted, for: self.acceptButton)
        }

        self.declineButton.set(style: .rounded(color: .red, text: "Decline"))
        self.declineButton.didSelect { [unowned self] in
            self.updateConnection(with: .declined, for: self.declineButton)
        }
    }

    override func getBottomContent() -> UIView {
        return self.buttonContainer
    }

    override func configurePost() {
        guard let connection = self.post.connection else { return }
        self.configure(connection: connection)
    }

    private func configure(connection: Connection) {
        self.connection = connection
        if let user = connection.nonMeUser, let status = connection.status {
            user.retrieveDataIfNeeded()
                .mainSink(receiveValue: { user in

                    let text: Localized
                    switch status {
                    case .created, .pending:
                        text = ""
                    case .invited:
                        text = LocalizedString(id: "", arguments: [user.givenName], default: "@(first) would like to connect with you.")
                    case .accepted:
                        text = LocalizedString(id: "", arguments: [user.givenName], default: "You are now connected to @(first).")
                        self.buttonContainer.alpha = 0
                    case .declined:
                        text = LocalizedString(id: "", arguments: [user.givenName], default: "You declined to connect to @(first).")
                        self.buttonContainer.alpha = 0
                    }

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

    func updateConnection(with status: Connection.Status, for button: Button) {
        guard let connection = self.connection else { return }

        self.didPause?()
        self.button.handleEvent(status: .loading)
        UpdateConnection(connectionId: connection.objectId!, status: status)
            .makeRequest(andUpdate: [], viewsToIgnore: [])
            .mainSink(receiveValue: { updatedConnection in
                self.button.handleEvent(status: .complete)
                self.didFinish?()
            }).store(in: &self.cancellables)
    }
}
