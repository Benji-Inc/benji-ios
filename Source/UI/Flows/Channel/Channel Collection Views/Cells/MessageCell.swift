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
    private var animationView = AnimationView(name: "error")

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
        self.animationView.alpha = 0
    }

    func configure(with message: Messageable) {
        self.currentMessage = message
        if !message.isFromCurrentUser {
            self.avatarView.set(avatar: message.avatar)
        }

        if case MessageKind.text(let text) = message.kind {
            self.textView.set(text: text, messageContext: message.context)
        }

        self.handleIsConsumed(for: message)
        self.handleStatus(for: message)
    }

    private func handleStatus(for message: Messageable) {
        self.animationView.alpha = 0

        if message.isFromCurrentUser {
            switch message.status {
            case .error:
                self.showError()
            default:
                break
            }
        }
    }

    func showError() {
        self.animationView.forceDisplayUpdate()

        UIView.animate(withDuration: 0.2) {
            self.animationView.alpha = 1
        }

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

        self.animationView.size = CGSize(width: 22, height: 22)
        self.animationView.match(.right, to: .left, of: self.bubbleView, offset: -6)
        self.animationView.match(.bottom, to: .bottom, of: self.bubbleView, offset: -8)
    }
}

class MessageBubbleView: View {
    var indexPath: IndexPath?
}
