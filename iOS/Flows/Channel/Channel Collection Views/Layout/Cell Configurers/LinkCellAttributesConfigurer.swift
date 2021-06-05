//
//  LinkCellAttributesConfigurer.swift
//  Ours
//
//  Created by Benji Dodgson on 6/4/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class LinkCellAttributesConfigurer: ChannelCellAttributesConfigurer {

    var avatarSize = CGSize(width: 30, height: 36)
    private let widthRatio: CGFloat = 0.8

    override func configure(with message: Messageable,
                            previousMessage: Messageable?,
                            nextMessage: Messageable?,
                            for layout: ChannelCollectionViewFlowLayout,
                            attributes: ChannelCollectionViewLayoutAttributes) {

        attributes.attributes.avatarFrame = self.getAvatarFrame(with: message, layout: layout)
        attributes.attributes.attachmentFrame = self.getAttachmentFrame(with: message, layout: layout)
    }

    override func size(with message: Messageable?, for layout: ChannelCollectionViewFlowLayout) -> CGSize {
        guard let msg = message else { return .zero }

        return CGSize(width: layout.itemWidth, height: self.getAttachmentFrame(with: msg, layout: layout).height)
    }

    private func getAttachmentFrame(with message: Messageable, layout: ChannelCollectionViewFlowLayout) -> CGRect {

        let attachmentWidth = layout.itemWidth * 0.8

        var xOffset: CGFloat = 0
        if message.isFromCurrentUser {
            xOffset = layout.itemWidth - attachmentWidth - Theme.contentOffset.half
        } else {
            xOffset = self.getAvatarFrame(with: message, layout: layout).width + (self.getAvatarPadding(for: layout) * 2) + Theme.contentOffset.half
        }

        let rect = CGRect(x: xOffset,
                          y: 0,
                          width: attachmentWidth,
                          height: attachmentWidth * 1.1)
        return rect
    }

    private func getAvatarFrame(with message: Messageable, layout: ChannelCollectionViewFlowLayout) -> CGRect {
        guard let dataSource = layout.dataSource else { return .zero }

        var size: CGSize = .zero
        if !message.isFromCurrentUser, dataSource.numberOfMembers > 2 {
            size = self.avatarSize
        }
        let xOffset: CGFloat = self.getAvatarPadding(for: layout)
        return CGRect(x: xOffset,
                      y: 0,
                      width: size.width,
                      height: size.height)
    }

    private func getAvatarPadding(for layout: ChannelCollectionViewFlowLayout) -> CGFloat {
        guard let dataSource = layout.dataSource else { return .zero }
        return dataSource.numberOfMembers > 2 ? 8 : 8
    }
}
