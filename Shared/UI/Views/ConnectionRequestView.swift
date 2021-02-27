//
//  ConnectionRequestView.swift
//  Ours
//
//  Created by Benji Dodgson on 2/27/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization
import Combine

class ConnectionRequestView: View {

    private let containerView = View()

    private let avatarView = AvatarView()
    private let textView = TextView()

    private let acceptButton = Button()
    private let declineButton = Button()
    private let confettiView = ConfettiView()
    private let successLabel = Label(font: .display)

    var currentItem: Connection?
    var didUpdateConnection: ((Connection) -> Void)? = nil

    private var cancellables = Set<AnyCancellable>()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.confettiView)
        self.addSubview(self.successLabel)
        self.addSubview(self.containerView)

        self.containerView.addSubview(self.textView)
        self.containerView.addSubview(self.avatarView)
        self.containerView.addSubview(self.acceptButton)
        self.acceptButton.set(style: .normal(color: .purple, text: "Accept"))
        self.acceptButton.didSelect { [unowned self] in
            self.updateConnection(with: .accepted, button: self.acceptButton)
        }
        self.containerView.addSubview(self.declineButton)
        self.declineButton.set(style: .normal(color: .red, text: "Decline"))
        self.declineButton.didSelect { [unowned self] in
            self.updateConnection(with: .declined, button: self.declineButton)
        }

        self.successLabel.setText("Success! 🥳")
        self.successLabel.alpha = 0

        self.set(backgroundColor: .clear)
        self.containerView.roundCorners()
    }

    func configure(with item: Connection) {
        guard let status = item.status, status == .invited, let user = item.from else { return }
        self.currentItem = item
        user.retrieveDataIfNeeded()
            .mainSink { result in
                switch result {
                case .success(let userWithData):
                    let text = LocalizedString(id: "", arguments: [userWithData.handle], default: "[@(handle)](link) has invited you to connect.")
                    let attributedString = AttributedString(text,
                                                            fontType: .regular,
                                                            color: .white)
                    self.textView.set(attributed: attributedString, linkColor: .lightPurple)
                    self.avatarView.set(avatar: userWithData)
                    self.layoutNow()
                case .error(_):
                    break
                }
            }.store(in: &self.cancellables)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.containerView.expandToSuperviewSize()
        self.confettiView.expandToSuperviewSize()

        self.avatarView.left = Theme.contentOffset
        self.avatarView.top = Theme.contentOffset
        self.avatarView.setSize(for: 100)

        let maxLabelWidth = self.containerView.width - Theme.contentOffset.doubled
        self.textView.setSize(withWidth: maxLabelWidth)
        self.textView.match(.top, to: .bottom, of: self.avatarView, offset: Theme.contentOffset)
        self.textView.match(.left, to: .left, of: self.avatarView)

        let buttonWidth = self.containerView.halfWidth - Theme.contentOffset.doubled

        self.acceptButton.size = CGSize(width: buttonWidth, height: 40)
        self.acceptButton.pin(.right, padding: Theme.contentOffset)
        self.acceptButton.pin(.bottom, padding: Theme.contentOffset)

        self.declineButton.size = CGSize(width: buttonWidth, height: 40)
        self.declineButton.pin(.left, padding: Theme.contentOffset)
        self.declineButton.pin(.bottom, padding: Theme.contentOffset)
    }

    private func updateConnection(with status: Connection.Status, button: Button) {
        button.handleEvent(status: .loading)
        if let connection = self.currentItem {
            UpdateConnection(connectionId: connection.objectId!, status: status).makeRequest(andUpdate: [], viewsToIgnore: [self])
                .mainSink { (result) in
                    switch result {
                    case .success(let item):
                        button.handleEvent(status: .complete)
                        if let updatedConnection = item as? Connection {
                            self.showSuccess(for: updatedConnection)
                        }
                    case .error(let e):
                        button.handleEvent(status: .error(e.localizedDescription))
                    }
                }.store(in: &self.cancellables)
        }
    }

    private func showSuccess(for connection: Connection) {
        UIView.animate(withDuration: Theme.animationDuration) {
            self.containerView.alpha = 0
            self.successLabel.alpha = 1
        } completion: { completed in
            self.confettiView.startConfetti(with: 3.0)
            self.didUpdateConnection?(connection)

        }
    }
}

