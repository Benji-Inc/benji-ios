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

struct ChatMessageStatus: Equatable {

    let read: ChatChannelRead
    let message: Message

    var isRead: Bool {
        return self.read.lastReadAt >= self.message.createdAt && self.isDelivered
    }

    var isDelivered: Bool {
        return self.state.isNil
    }

    var state: LocalMessageState? {
        return self.message.localState
    }

    static func == (lhs: ChatMessageStatus, rhs: ChatMessageStatus) -> Bool {
        return lhs.message == rhs.message &&
        lhs.read.lastReadAt == rhs.read.lastReadAt &&
        lhs.read.user == rhs.read.user
    }
}

/// Layout attributes that can be used to configure a TimeSentView.
class MessageStatusViewLayoutAttributes: UICollectionViewLayoutAttributes {

    var status: ChatMessageStatus?

    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! MessageStatusViewLayoutAttributes
        copy.status = self.status
        return copy
    }

    override func isEqual(_ object: Any?) -> Bool {
        if let layoutAttributes = object as? MessageStatusViewLayoutAttributes {
            return super.isEqual(object)
            && layoutAttributes.status == self.status
        }

        return false
    }
}

class MessageStatusView: UICollectionReusableView {

    private lazy var collectionView = CollectionView(layout: ReactionsCollectionViewLayout())
    private lazy var manager = ReactionsManager(with: self.collectionView)

    let statusLabel = MessageStatusLabel()

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
        self.addSubview(self.statusLabel)

        self.statusLabel.publisher(for: \.text).mainSink { [unowned self] _ in
            self.layoutNow()
        }.store(in: &self.cancellables)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.collectionView.expandToSuperviewHeight()
        self.collectionView.pin(.left, offset: .standard)
        self.collectionView.width = 200

        self.statusLabel.setSize(withWidth: self.width)
        self.statusLabel.pin(.right, offset: .standard)
        self.statusLabel.centerOnY()
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)

        if let attributes = layoutAttributes as? MessageStatusViewLayoutAttributes {
            if let msg = attributes.status?.message {
                self.manager.loadReactions(for: msg)
            }
            self.statusLabel.set(status: attributes.status)
        }

        self.setNeedsLayout()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.statusLabel.text = nil
    }
}
