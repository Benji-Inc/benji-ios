//
//  PhotoMessageCell.swift
//  Benji
//
//  Created by Benji Dodgson on 7/4/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TwilioChatClient
import SDWebImage

class PhotoMessageCell: BaseMessageCell {

    private var cachedURL: URL?
    let imageView = IndexImageView()
    let bubbleView = MessageBubbleView()
    let textView = MessageTextView()

    override func initializeViews() {
        super.initializeViews()

        self.contentView.addSubview(self.bubbleView)
        self.bubbleView.addSubview(self.textView)

        self.contentView.insertSubview(self.imageView, belowSubview: self.avatarView)
        self.imageView.imageView.contentMode = .scaleAspectFill
        self.imageView.imageView.clipsToBounds = true
        self.imageView.layer.cornerRadius = 5
        self.imageView.layer.masksToBounds = true

        self.bubbleView.didSelect { [unowned self] in
            self.didTapMessage()
        }

        self.imageView.didSelect { [unowned self] in
            self.didTapMessage()
        }
    }

    override func configure(with message: Messageable) {
        super.configure(with: message)

        guard case MessageKind.photo(let photo, let body) = message.kind else { return }

        self.textView.set(text: body, messageContext: message.context)

        self.avatarView.set(avatar: message.avatar)
        if let image = photo.image {
            self.imageView.displayable = image
        } else if let tchMessage = message as? TCHMessage {
            self.loadImage(from: tchMessage)
        }

        self.imageView.displayable = photo.image
    }

    private func loadImage(from message: TCHMessage) {
        guard message.hasMedia() else { return }

        if let url = self.cachedURL {
            self.imageView.displayable = url
        } else {
            Task {
                do {
                    let urlString = try await message.getMediaContentURL()
                    if let url = URL(string: urlString) {
                        self.cachedURL = url
                        self.imageView.displayable = url
                    }
                } catch {
                    logDebug(error)
                }
            }
        }
    }

    override func handleIsConsumed(for message: Messageable) {
        super.handleIsConsumed(for: message)

        self.bubbleView.set(backgroundColor: message.color)

        if !message.isFromCurrentUser, !message.isConsumed, message.context != .status {

            if !message.isFromCurrentUser, message.context == .passive {
                self.bubbleView.layer.borderColor = Color.purple.color.cgColor
            } else {
                self.bubbleView.layer.borderColor = message.context.color.color.cgColor
            }
            self.bubbleView.layer.borderWidth = 2
        }
    }

    override func layoutContent(with attributes: ConversationCollectionViewLayoutAttributes) {
        super.layoutContent(with: attributes)

        self.imageView.frame = attributes.attributes.attachmentFrame
        self.textView.frame = attributes.attributes.textViewFrame
        self.bubbleView.frame = attributes.attributes.bubbleViewFrame
        self.bubbleView.layer.maskedCorners = attributes.attributes.maskedCorners
        self.imageView.indexPath = attributes.indexPath
        self.bubbleView.roundCorners()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.bubbleView.layer.borderColor = nil
        self.bubbleView.layer.borderWidth = 0
        self.textView.text = nil
        self.cachedURL = nil
    }
}

class IndexImageView: DisplayableImageView, Indexable {
    var indexPath: IndexPath?
}
