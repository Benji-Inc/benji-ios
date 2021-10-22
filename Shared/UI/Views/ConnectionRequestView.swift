//
//  ConnectionRequestView.swift
//  Jibber
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
    private let successLabel = Label(font: .mediumBold)

    var currentItem: Connection?
    var didUpdateConnection: ((Connection) -> Void)? = nil

    private var cancellables = Set<AnyCancellable>()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.confettiView)
        self.addSubview(self.successLabel)
        self.successLabel.textAlignment = .center
        self.addSubview(self.containerView)
        self.containerView.set(backgroundColor: .lightGray)

        self.containerView.addSubview(self.textView)
        self.containerView.addSubview(self.avatarView)
        self.containerView.addSubview(self.acceptButton)
        self.acceptButton.set(style: .normal(color: .darkGray, text: "Accept"))
        self.acceptButton.didSelect { [unowned self] in
            guard let from = self.currentItem?.from else { return }
            Task {
                await self.updateConnection(with: .accepted, user: from, button: self.acceptButton)
            }
        }
        self.containerView.addSubview(self.declineButton)
        self.declineButton.set(style: .normal(color: .white, text: "Decline"))
        self.declineButton.didSelect { [unowned self] in
            guard let from = self.currentItem?.from else { return }
            Task {
                await self.updateConnection(with: .declined, user: from, button: self.declineButton)
            }
        }

        self.successLabel.alpha = 0

        self.set(backgroundColor: .clear)
        self.containerView.roundCorners()
        self.confettiView.clipsToBounds = true
    }

    @MainActor
    func configure(with item: Connection) async {
        self.currentItem = item

        guard let user = item.from else { return }

        do {
            let userWithData = try await user.retrieveDataIfNeeded()
            if let status = item.status, status == .invited {
                let text = LocalizedString(id: "", arguments: [userWithData.fullName], default: "[@(name)](\(user.objectId!)) has invited you to connect.")
                let attributedString = AttributedString(text,
                                                        fontType: .regular,
                                                        color: .white)
                self.textView.set(attributed: attributedString, linkColor: .lightGray)
                self.avatarView.set(avatar: userWithData)
                self.layoutNow()
            } else {
                self.showSuccess(for: item, user: userWithData)
            }
        } catch {
            logDebug(error)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.containerView.expandToSuperviewSize()
        self.confettiView.expandToSuperviewSize()

        self.avatarView.left = Theme.contentOffset.half
        self.avatarView.top = Theme.contentOffset.half
        self.avatarView.setSize(for: self.containerView.height - Theme.contentOffset)

        let maxLabelWidth = self.containerView.width - self.avatarView.right - Theme.contentOffset
        self.textView.setSize(withWidth: maxLabelWidth)
        self.textView.match(.top, to: .top, of: self.avatarView)
        self.textView.match(.left, to: .right, of: self.avatarView, offset: Theme.contentOffset.half)

        let buttonWidth = (self.containerView.width - self.avatarView.right - Theme.contentOffset - Theme.contentOffset.half) * 0.5

        self.acceptButton.size = CGSize(width: buttonWidth, height: 40)
        self.acceptButton.match(.right, to: .right, of: self.containerView, offset: -Theme.contentOffset.half)
        self.acceptButton.pin(.bottom, padding: Theme.contentOffset.half)

        self.declineButton.size = CGSize(width: buttonWidth, height: 40)
        self.declineButton.match(.right, to: .left, of: self.acceptButton, offset: -Theme.contentOffset.half)
        self.declineButton.pin(.bottom, padding: Theme.contentOffset.half)

        self.successLabel.setSize(withWidth: self.containerView.width * 0.8)
        self.successLabel.centerOnXAndY()
    }

    private func updateConnection(with status: Connection.Status,
                                  user: User,
                                  button: Button) async {

        await button.handleEvent(status: .loading)

        do {
            guard let connection = self.currentItem else {
                throw ClientError.apiError(detail: "Unable to update connection.")
            }

            let updatedConnection = try await UpdateConnection(connectionId: connection.objectId!, status: status)
                .makeRequest(andUpdate: [], viewsToIgnore: [self])

            await button.handleEvent(status: .complete)
            if let updated = updatedConnection as? Connection {
                self.showSuccess(for: updated, user: user, shouldComplete: true)
            }
        } catch {
            await button.handleEvent(status: .error(error.localizedDescription))
        }
    }

    private func showSuccess(for connection: Connection,
                             user: User,
                             shouldComplete: Bool = false) {
        let text = LocalizedString(id: "", arguments: [user.givenName], default: "Success! 🥳\n You are now connected with @(name)")
        self.successLabel.setText(text)
        self.layoutNow()

        UIView.animate(withDuration: Theme.animationDuration) {
            self.containerView.alpha = 0
            self.successLabel.alpha = 1
        } completion: { completed in
            self.confettiView.startConfetti(with: 3.0)
            if shouldComplete {
                self.didUpdateConnection?(connection)
            }
        }
    }
}
