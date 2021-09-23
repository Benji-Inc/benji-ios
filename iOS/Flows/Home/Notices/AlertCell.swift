//
//  AlertCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 5/31/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class AlertCell: NoticeCell {

    private let avatarView = AvatarView()
    let bubbleView = MessageBubbleView()
    let textView = MessageTextView()


    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.addSubview(self.avatarView)
        self.contentView.addSubview(self.bubbleView)
        self.bubbleView.addSubview(self.textView)

        self.bubbleView.layer.borderWidth = 2
        self.bubbleView.layer.borderColor = Color.red.color.cgColor
        self.bubbleView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner]
    }

    override func configure(with item: SystemNotice) {
        super.configure(with: item)

        // TODO: Add message lookup, And add message date. 

        guard let body = item.body,
              let author = item.attributes?["author"] as? String else { return }

        self.textView.set(text: body, messageContext: MessageContext.timeSensitive)

        Task {
            do {
                let user = try await User.getObject(with: author)
                self.avatarView.set(avatar: user)
                self.setNeedsLayout()
            } catch {
                print(error)
            }
        }

        self.setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.avatarView.setSize(for: self.contentView.halfHeight)
        self.avatarView.pin(.left, padding: Theme.contentOffset.half)
        self.avatarView.pin(.top, padding: Theme.contentOffset.half)

        let maxWidth = self.contentView.width - self.avatarView.right - Theme.contentOffset.doubled
        self.textView.setSize(withWidth: maxWidth, height: self.contentView.height - Theme.contentOffset.doubled)

        self.bubbleView.height = self.textView.height + Theme.contentOffset
        self.bubbleView.width = self.textView.width + Theme.contentOffset
        self.bubbleView.match(.left, to: .right, of: self.avatarView, offset: Theme.contentOffset.half)
        self.bubbleView.match(.top, to: .top, of: self.avatarView)
        self.bubbleView.roundCorners()

        self.textView.centerOnXAndY()
    }
}
