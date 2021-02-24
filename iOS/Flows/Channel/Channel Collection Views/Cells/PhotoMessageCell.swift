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
    let blurView = BlurView(effect: UIBlurEffect(style: .light))
    let imageView = IndexImageView()
    let bubbleView = MessageBubbleView()
    let textView = MessageTextView()

    override func initializeViews() {
        super.initializeViews()

        self.contentView.addSubview(self.bubbleView)
        self.bubbleView.addSubview(self.textView)

        self.contentView.insertSubview(self.imageView, belowSubview: self.avatarView)
        self.contentView.insertSubview(self.blurView, aboveSubview: self.imageView)
        self.imageView.imageView.contentMode = .scaleAspectFill
        self.imageView.imageView.clipsToBounds = true
        self.imageView.layer.cornerRadius = 5
        self.imageView.layer.masksToBounds = true

        self.blurView.clipsToBounds = true
        self.blurView.layer.cornerRadius = 5
        self.blurView.layer.masksToBounds = true

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
            self.load(url: url)
        } else {
            message.getMediaContentURL()
                .mainSink(receivedResult: { (result) in
                    switch result {
                    case .success(let urlString):
                        if let url = URL(string: urlString) {
                            self.load(url: url)
                        }
                    case .error(_):
                        break
                    }
                }).store(in: &self.cancellables)
        }
    }

    private func load(url: URL) {
        self.cachedURL = url

        SDWebImageManager.shared.loadImage(with: url,
                                           options: [],
                                           progress: { (received, expected, url) in
                                            //let diff: CGFloat = CGFloat(received) / CGFloat(expected)
                                            //let progress = clamp(diff, 0.0, 1.0)

                                           }, completed: { (image, data, error, cacheType, finished, url) in
                                            self.imageView.displayable = image
                                            UIView.animate(withDuration: 0.5) {
                                                self.blurView.effect = nil
                                            }
                                           })
    }

    override func handleIsConsumed(for message: Messageable) {
        super.handleIsConsumed(for: message)

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

    override func layoutContent(with attributes: ChannelCollectionViewLayoutAttributes) {
        super.layoutContent(with: attributes)

        self.imageView.frame = attributes.attributes.attachmentFrame
        self.blurView.frame = attributes.attributes.attachmentFrame
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

class BlurView: UIVisualEffectView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return false
    }
}

class IndexImageView: DisplayableImageView, Indexable {
    var indexPath: IndexPath?
}
