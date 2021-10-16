//
//  ConversationHeaderView.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/27/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat
import Combine
import Lottie
import UIKit

class ConversationHeaderView: View {

    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
    let stackedAvatarView = StackedAvatarView()
    let label = Label(font: .medium, textColor: .background4)
    let descriptionLabel = Label(font: .small, textColor: .background3)
    let button = Button()

    private var cancellables = Set<AnyCancellable>()

    private var currentConversation: Conversation?
    private var state: ConversationUIState = .read

    deinit {
        self.cancellables.forEach { cancellable in
            cancellable.cancel()
        }
    }

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.blurView)

        self.blurView.contentView.addSubview(self.stackedAvatarView)
        self.stackedAvatarView.itemHeight = 50

        self.blurView.contentView.addSubview(self.label)
        self.label.textAlignment = .left
        self.label.lineBreakMode = .byTruncatingTail

        self.blurView.contentView.addSubview(self.descriptionLabel)
        self.descriptionLabel.textAlignment = .left
        self.descriptionLabel.lineBreakMode = .byTruncatingTail

        self.blurView.contentView.addSubview(self.button)
        self.button.set(style: .icon(image: UIImage(systemName: "plus")!, color: .background4))

        let menu = UIMenu.init(title: "Title", subtitle: "Subtitle", image: UIImage(systemName: "plus"), identifier: nil, options: [], children: [])

        self.button.menu = menu
    }

    func configure(with conversation: Conversation) {

        defer {
            self.currentConversation = conversation
        }

        if self.currentConversation?.title != conversation.title {
            self.label.setText(conversation.title)
            self.descriptionLabel.setText(conversation.description)
        }

        guard self.currentConversation?.lastActiveMembers != conversation.lastActiveMembers else { return }

        let members = conversation.lastActiveMembers.filter { member in
            return member.id != ChatClient.shared.currentUserId
        }

        if !members.isEmpty {
            self.stackedAvatarView.set(items: members)
        } else {
            self.stackedAvatarView.set(items: [User.current()!])
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.stackedAvatarView.setSize()

        switch self.state {
        case .read:
            self.stackedAvatarView.pin(.left, padding: Theme.contentOffset.half)
            self.blurView.expandToSuperviewSize()
            self.stackedAvatarView.centerOnY()
        case .write:
            self.blurView.height = self.stackedAvatarView.height + Theme.contentOffset.half
            self.blurView.width = self.stackedAvatarView.width + Theme.contentOffset.half
            self.blurView.pin(.left)
            self.blurView.pin(.top)

            self.stackedAvatarView.pin(.left, padding: Theme.contentOffset.half.half)
            self.stackedAvatarView.centerY = self.blurView.centerY
        }

        self.blurView.roundCorners()

        let maxWidth = self.blurView.contentView.width - Theme.contentOffset - self.stackedAvatarView.width
        self.label.setSize(withWidth: maxWidth)

        self.label.match(.top, to: .top, of: self.stackedAvatarView)
        self.label.match(.left, to: .right, of: self.stackedAvatarView, offset: Theme.contentOffset.half)

        self.descriptionLabel.setSize(withWidth: maxWidth)
        self.descriptionLabel.match(.bottom, to: .bottom, of: self.stackedAvatarView)
        self.descriptionLabel.match(.left, to: .left, of: self.label)

        self.button.squaredSize = self.blurView.contentView.height - Theme.contentOffset
        self.button.pin(.right, padding: Theme.contentOffset.half)
        self.button.centerOnY()
    }

    func update(for state: ConversationUIState) {
        self.state = state

        switch state {
        case .read:
            self.stackedAvatarView.itemHeight = 50
        case .write:
            self.stackedAvatarView.itemHeight = 40
        }

        UIView.animate(withDuration: Theme.animationDuration) {
            switch state {
            case .read:
                self.label.alpha = 1.0
                self.descriptionLabel.alpha = 1.0
                self.button.alpha = 1.0
            case .write:
                self.label.alpha = 0.0
                self.descriptionLabel.alpha = 0.0
                self.button.alpha = 0.0
            }

            self.layoutNow()
        } completion: { completed in

        }
    }
}
