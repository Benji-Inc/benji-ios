//
//  FeedConnectionRequest.swift
//  Benji
//
//  Created by Benji Dodgson on 3/30/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation

class FeedConnectionView: View {

    private let textView = FeedTextView()
    private let acceptButton = LoadingButton()
    private let declineButton = LoadingButton()
    var didComplete: () -> Void = {}

    var connection: Connection?

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.textView)
        self.addSubview(self.acceptButton)
        self.addSubview(self.declineButton)
        self.textView.set(localizedText: "Connection request.")
        self.acceptButton.set(style: .rounded(color: .blue, text: "Accept"))
        self.acceptButton.didSelect = { [unowned self] in
            self.updateConnection(with: .accepted)
        }

        self.declineButton.set(style: .rounded(color: .red, text: "Decline"))
        self.declineButton.didSelect = { [unowned self] in
            self.updateConnection(with: .declined)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.textView.setSize(withWidth: self.width)
        self.textView.bottom = self.centerY - 10
        self.textView.centerOnX()

        self.acceptButton.setSize(with: self.width * 0.4)
        self.acceptButton.centerX = self.width * 0.69
        self.acceptButton.bottom = self.height - Theme.contentOffset

        self.declineButton.setSize(with: self.width * 0.4)
        self.declineButton.centerX = self.width * 0.3
        self.declineButton.bottom = self.height - Theme.contentOffset
    }

    func updateConnection(with status: Connection.Status) {
        guard let connection = self.connection else { return }

        UpdateConnection(connection: connection, status: status)
            .makeRequest()
            .ignoreUserInteractionEventsUntilDone(for: self)
            .observeValue { (_) in
                self.didComplete()
        }
    }
}
