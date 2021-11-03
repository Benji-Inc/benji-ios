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

    let stackedAvatarView = StackedAvatarView()
    let label = Label(font: .regularBold, textColor: .textColor)
    let button = Button()

    private var cancellables = Set<AnyCancellable>()

    private var currentConversation: Conversation?
    private var state: ConversationUIState = .read

    var didTapAddPeople: CompletionOptional = nil

    deinit {
        self.cancellables.forEach { cancellable in
            cancellable.cancel()
        }
    }

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.stackedAvatarView)

        self.stackedAvatarView.itemHeight = 60

        self.addSubview(self.label)
        self.label.textAlignment = .left
        self.label.lineBreakMode = .byTruncatingTail

        self.addSubview(self.button)
        self.button.set(style: .noborder(image: UIImage(systemName: "ellipsis.circle")!, color: .textColor))

        let add = UIAction.init(title: "Add people", image: UIImage(systemName: "person.badge.plus")) { _ in
            self.didTapAddPeople?()
        }

        let menu = UIMenu(title: "Menu", image: UIImage(systemName: "ellipsis.circle"), identifier: nil, options: [], children: [add])
        self.button.showsMenuAsPrimaryAction = true
        self.button.menu = menu
    }

    func configure(with conversation: Conversation) {
        defer {
            self.currentConversation = conversation
        }

        if self.currentConversation?.title != conversation.title {
            self.label.setText(conversation.title)
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

        let maxWidth = self.width - Theme.contentOffset.doubled
        self.label.setSize(withWidth: maxWidth)
        self.label.pin(.top)
        self.label.centerOnX()

        self.stackedAvatarView.setSize()
        self.stackedAvatarView.centerOnX()

        switch self.state {
        case .read:
            self.stackedAvatarView.match(.top, to: .bottom, of: self.label, offset: Theme.contentOffset.half)
        case .write:
            self.stackedAvatarView.pin(.top)
        }

        self.button.squaredSize = 40
        self.button.pin(.right, padding: Theme.contentOffset)
        self.button.centerY = self.label.centerY
    }

    func update(for state: ConversationUIState) {
        self.state = state

        UIView.animate(withDuration: Theme.animationDuration) {
            switch state {
            case .read:
                self.label.alpha = 1.0
            case .write:
                self.label.alpha = 0.0
            }

            self.layoutNow()
        } completion: { completed in

        }
    }
}
