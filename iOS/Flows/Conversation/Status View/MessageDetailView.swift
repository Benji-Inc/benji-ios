//
//  TimeSentHeaderView.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/1/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat
import Combine

/// Layout attributes that can be used to configure a TimeSentView.
class MessageDetailViewLayoutAttributes: UICollectionViewLayoutAttributes {

    var message: Message?

    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! MessageDetailViewLayoutAttributes
        copy.message = self.message
        return copy
    }

    override func isEqual(_ object: Any?) -> Bool {
        if let layoutAttributes = object as? MessageDetailViewLayoutAttributes {
            return super.isEqual(object)
            && layoutAttributes.message == self.message
        }

        return false
    }
}

class MessageDetailView: UICollectionReusableView {

    private lazy var collectionView = ReactionsCollectionView()
    private lazy var manager = ReactionsManager(with: self.collectionView)

    let statusView = MessageStatusView()

    private var hasLoadedMessage: Message?

    private var cancellables = Set<AnyCancellable>()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        self.initializeSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.cancellables.forEach { cancellable in
            cancellable.cancel()
        }
    }

    private func initializeSubviews() {
        self.addSubview(self.collectionView)
        self.addSubview(self.statusView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.collectionView.expandToSuperviewHeight()
        self.collectionView.pin(.left, offset: .standard)
        self.collectionView.width = self.halfWidth

        self.statusView.width = self.halfWidth
        self.statusView.pin(.right, offset: .standard)
        self.statusView.expandToSuperviewHeight()
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)

        if let attributes = layoutAttributes as? MessageDetailViewLayoutAttributes {
            if self.hasLoadedMessage.isNil {
                if let msg = attributes.message, attributes.alpha == 0.0 {
                    self.manager.loadReactions(for: msg)
                    self.hasLoadedMessage = msg
                }
            } else if let msg = attributes.message,
                        msg != self.hasLoadedMessage,
                      attributes.alpha == 0.0 {
                self.manager.loadReactions(for: msg)
                self.hasLoadedMessage = msg
            }
            self.statusView.configure(for: attributes.message)
        }

        self.setNeedsLayout()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.hasLoadedMessage = nil
    }
}
