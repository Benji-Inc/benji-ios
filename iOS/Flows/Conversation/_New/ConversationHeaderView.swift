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

class ConversationHeaderView: View {

    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
    let stackedAvatarView = StackedAvatarView()
    let label = Label(font: .mediumUnderlined, textColor: .background4)
    let button = Button()

    private var cancellables = Set<AnyCancellable>()
    private var currentItem: Conversation?

    deinit {
        self.cancellables.forEach { cancellable in
            cancellable.cancel()
        }
    }

    override func initializeSubviews() {
        super.initializeSubviews()

        self.set(backgroundColor: .background1)

        self.addSubview(self.blurView)
        self.addSubview(self.stackedAvatarView)
        self.stackedAvatarView.itemHeight = 40

        self.addSubview(self.label)
        self.label.textAlignment = .left
        self.label.lineBreakMode = .byTruncatingTail
        self.addSubview(self.button)
        self.button.set(style: .icon(image: UIImage(systemName: "plus")!, color: .background3))
    }

    func configure(with item: Conversation) {
        self.currentItem = item

        Task {
            await self.display(conversation: item)
        }
    }

    private func display(conversation: ChatChannel) async {
        Task.onMainActor {
            let members = conversation.lastActiveMembers.filter { member in
                return member.id != ChatClient.shared.currentUserId
            }

            guard self.currentItem?.cid == conversation.cid else { return }

            self.label.setText(conversation.title)

            self.stackedAvatarView.set(items: members)
            self.stackedAvatarView.layoutNow()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.blurView.expandToSuperviewSize()
        self.roundCorners()

        self.stackedAvatarView.setSize()
        self.stackedAvatarView.centerOnY()
        self.stackedAvatarView.pin(.left, padding: Theme.contentOffset.half)

        let maxWidth = self.width - Theme.contentOffset - self.stackedAvatarView.width
        self.label.setSize(withWidth: maxWidth)

        self.label.centerOnY()
        self.label.match(.left, to: .right, of: self.stackedAvatarView, offset: Theme.contentOffset.half)

        self.button.squaredSize = self.height - Theme.contentOffset
        self.button.pin(.right, padding: Theme.contentOffset.half)
        self.button.centerOnY()
    }
}
