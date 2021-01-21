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

    private let imageView = DisplayableImageView()
    private var cachedURL: URL?
    private var blurView = UIVisualEffectView(effect: UIBlurEffect(style: .light))

    override func initializeViews() {
        super.initializeViews()

        self.contentView.insertSubview(self.imageView, belowSubview: self.avatarView)
        self.contentView.insertSubview(self.blurView, aboveSubview: self.imageView)
        self.imageView.imageView.contentMode = .scaleAspectFill
        self.imageView.imageView.clipsToBounds = true
        self.imageView.layer.cornerRadius = 5
        self.imageView.layer.masksToBounds = true

        self.blurView.clipsToBounds = true
        self.blurView.layer.cornerRadius = 5
        self.blurView.layer.masksToBounds = true
    }

    override func configure(with message: Messageable) {
        super.configure(with: message)

        guard case MessageKind.photo(let item) = message.kind else { return }

        self.avatarView.set(avatar: message.avatar)
        if let image = item.image {
            self.imageView.displayable = image
        } else if let tchMessage = message as? TCHMessage {
            self.loadImage(from: tchMessage)
        }

        self.imageView.displayable = item.image
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
                                            let diff: CGFloat = CGFloat(received) / CGFloat(expected)
                                            let progress = clamp(diff, 0.0, 1.0)
                                            print("Progress: \(progress)")

                                           }, completed: { (image, data, error, cacheType, finished, url) in
                                            self.imageView.displayable = image
                                            UIView.animate(withDuration: 0.5) {
                                                self.blurView.effect = nil
                                            }
                                           })
    }

    override func layoutContent(with attributes: ChannelCollectionViewLayoutAttributes) {
        super.layoutContent(with: attributes)

        self.imageView.frame = attributes.attributes.imageFrame
        self.blurView.frame = attributes.attributes.imageFrame
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.cachedURL = nil
    }
}
