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
    let label = Label(font: .largeThin, textColor: .background4)
    //let descriptionLabel = Label(font: .small, textColor: .background4)
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

        self.stackedAvatarView.itemHeight = 30

        self.addSubview(self.label)
        self.label.textAlignment = .left
        self.label.lineBreakMode = .byTruncatingTail

//        self.addSubview(self.descriptionLabel)
//        self.descriptionLabel.textAlignment = .left
//        self.descriptionLabel.lineBreakMode = .byTruncatingTail

        self.addSubview(self.button)
        self.button.set(style: .noborder(image: UIImage(systemName: "ellipsis.circle")!, color: .background4))

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
            //self.descriptionLabel.setText(conversation.description)
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

        guard let superview = self.superview else { return }

        self.pin(.top, padding: Theme.contentOffset.half)
        self.pin(.left, padding: Theme.contentOffset.half)

        self.stackedAvatarView.setSize()

        switch self.state {
        case .read:
            self.height = self.stackedAvatarView.itemHeight
            self.width = superview.width - Theme.contentOffset

            self.stackedAvatarView.pin(.left)
            self.stackedAvatarView.centerOnY()
        case .write:
            self.height = self.stackedAvatarView.height
            self.width = self.stackedAvatarView.width

            self.stackedAvatarView.pin(.left)
            self.stackedAvatarView.centerOnY()
        }


        let maxWidth = self.width - Theme.contentOffset - self.stackedAvatarView.width
        self.label.setSize(withWidth: maxWidth)

        self.label.centerY = self.stackedAvatarView.centerY 
        self.label.match(.left, to: .right, of: self.stackedAvatarView, offset: Theme.contentOffset.half)

//        self.descriptionLabel.setSize(withWidth: maxWidth)
//        self.descriptionLabel.match(.bottom, to: .bottom, of: self.stackedAvatarView)
//        self.descriptionLabel.match(.left, to: .left, of: self.label)

        self.button.squaredSize = self.height
        self.button.pin(.right)
        self.button.centerOnY()
    }

    func update(for state: ConversationUIState) {
        self.state = state

//        switch state {
//        case .read:
//            self.stackedAvatarView.itemHeight = 40
//        case .write:
//            self.stackedAvatarView.itemHeight = 30
//        }

        UIView.animate(withDuration: Theme.animationDuration) {
            switch state {
            case .read:
                self.label.alpha = 1.0
                //self.descriptionLabel.alpha = 1.0
                self.button.alpha = 1.0
            case .write:
                self.label.alpha = 0.0
                //self.descriptionLabel.alpha = 0.0
                self.button.alpha = 0.0
            }

            self.layoutNow()
        } completion: { completed in

        }
    }
}
