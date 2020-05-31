//
//  ChannelCell.swift
//  Benji
//
//  Created by Benji Dodgson on 12/27/18.
//  Copyright © 2018 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TwilioChatClient
import Lottie

class MessageCell: UICollectionViewCell {

    let avatarView = AvatarView()
    let bubbleView = MessageBubbleView()
    let textView = MessageTextView()
    var didTapMessage: () -> Void = {}
    private(set) var currentMessage: Messageable?
    private(set) var attributes: ChannelCollectionViewLayoutAttributes?
    private var animationView = AnimationView(name: "loading")

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.initializeViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.initializeViews()
    }

    private func initializeViews() {

        self.contentView.addSubview(self.animationView)
        self.animationView.contentMode = .scaleAspectFit
        self.animationView.loopMode = .loop

        self.contentView.addSubview(self.avatarView)
        self.contentView.addSubview(self.bubbleView)
        self.bubbleView.addSubview(self.textView)

        self.bubbleView.onTap { [unowned self] (tap) in
            self.didTapMessage()
        }
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)

        guard let attributes = layoutAttributes as? ChannelCollectionViewLayoutAttributes else { return }
        self.attributes = attributes
        self.layoutContent(with: attributes)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.currentMessage = nil 
        self.bubbleView.layer.borderColor = nil
        self.bubbleView.layer.borderWidth = 0
        self.attributes = nil 
        self.textView.text = nil
    }

    func configure(with message: Messageable) {
        self.currentMessage = message
        if !message.isFromCurrentUser {
            self.avatarView.set(avatar: message.avatar)
        }
        self.textView.set(text: message.text, messageContext: message.context)

        self.handleStatus(for: message)
        self.handleIsConsumed(for: message)
    }

    private func handleStatus(for message: Messageable) {

        if message.isFromCurrentUser {
            switch message.status {
            case .sent:
                break
            case .delivered:
                break
            case .unknown:
                break
            case .error:
                break
            }
        }
    }

    private func showError() {
        self.animationView.forceDisplayUpdate()
        self.animationView.play()
    }

    private func handleIsConsumed(for message: Messageable) {

        self.bubbleView.set(backgroundColor: message.color)

        if !message.isFromCurrentUser, !message.isConsumed, message.context != .status {

            if !message.isFromCurrentUser, message.context == .casual {
                self.bubbleView.layer.borderColor = Color.purple.color.cgColor
            } else {
                self.bubbleView.layer.borderColor = message.context.color.color.cgColor
            }

            self.bubbleView.layer.borderWidth = 2
        }
    }

    private func layoutContent(with attributes: ChannelCollectionViewLayoutAttributes) {

        self.avatarView.frame = attributes.attributes.avatarFrame
        self.textView.frame = attributes.attributes.textViewFrame
        self.bubbleView.frame = attributes.attributes.bubbleViewFrame
        self.bubbleView.layer.maskedCorners = attributes.attributes.maskedCorners
        self.bubbleView.roundCorners()
        self.bubbleView.indexPath = attributes.indexPath

        self.animationView.size = CGSize(width: 18, height: 18)
        self.animationView.match(.right, to: .left, of: self.bubbleView, offset: -5)
        self.animationView.match(.bottom, to: .bottom, of: self.bubbleView, offset: -8)
    }
}

class MessageBubbleView: View {
    var indexPath: IndexPath?
}
