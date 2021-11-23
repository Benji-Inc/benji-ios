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

class ConversationHeaderViewController: ViewController {

    lazy var membersVC = MembersViewController()
    let label = Label(font: .mediumThin, textColor: .white)
    let button = Button()

    private var currentConversation: Conversation?
    private var state: ConversationUIState = .read

    var didTapAddPeople: CompletionOptional = nil
    var didTapUpdateTopic: CompletionOptional = nil

    override func initializeViews() {
        super.initializeViews()

        self.addChild(viewController: self.membersVC)
        //self.stackedAvatarView.itemHeight = 60

        self.view.addSubview(self.label)
        self.label.textAlignment = .left
        self.label.lineBreakMode = .byTruncatingTail

        if !isRelease {
            self.view.addSubview(self.button)
        }

        let add = UIAction.init(title: "Add people",
                                image: UIImage(systemName: "person.badge.plus")) { [unowned self] _ in
            self.didTapAddPeople?()
        }

        let topic = UIAction.init(title: "Update topic",
                                 image: UIImage(systemName: "pencil")) { [unowned self] _ in
             self.didTapUpdateTopic?()
        }

        let menu = UIMenu(title: "Menu",
                          image: UIImage(systemName: "ellipsis.circle"),
                          identifier: nil,
                          options: [],
                          children: [topic, add])

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
            //self.stackedAvatarView.set(items: members)
        } else {
            //self.stackedAvatarView.set(items: [User.current()!])
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let maxWidth = self.view.width - Theme.contentOffset.doubled
        self.label.setSize(withWidth: maxWidth)
        self.label.pin(.top)
        self.label.centerOnX()

        self.membersVC.view.height = 60
        self.membersVC.view.expandToSuperviewWidth()

        switch self.state {
        case .read:
            self.membersVC.view.match(.top, to: .bottom, of: self.label, offset: Theme.contentOffset.half)
        case .write:
            self.membersVC.view.pin(.top)
        }

        self.button.frame = self.label.frame
    }

    func update(for state: ConversationUIState) {
        self.state = state

        UIView.animate(withDuration: Theme.animationDurationStandard) {
            switch state {
            case .read:
                self.label.alpha = 1.0
            case .write:
                self.label.alpha = 0.0
            }

            self.view.layoutNow()
        } completion: { completed in

        }
    }
}
