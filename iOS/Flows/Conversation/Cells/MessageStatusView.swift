//
//  TimeSentHeaderView.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/1/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

struct ChatMessageStatus: Equatable {

    let read: ChatChannelRead
    let message: Message

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

    let dateLabel = MessageDateLabel()
    let statusLabel = Label(font: .small)

    override init(frame: CGRect) {
        super.init(frame: .zero)
        self.initializeSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initializeSubviews() {
        self.addSubview(self.dateLabel)
        self.addSubview(self.statusLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.dateLabel.setSize(withWidth: self.width)
        self.dateLabel.pin(.left, padding: Theme.contentOffset.half)
        self.dateLabel.centerOnY()

        self.statusLabel.setSize(withWidth: self.width)
        self.statusLabel.pin(.right, padding: Theme.contentOffset.half)
        self.statusLabel.centerOnY()
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)

        if let attributes = layoutAttributes as? MessageStatusViewLayoutAttributes {
            self.dateLabel.set(date: attributes.status?.message.createdAt)
            //self.daysAgoLabel.set(date: timeSentAttributes.timeSent)
        }

        self.setNeedsLayout()
    }
}
