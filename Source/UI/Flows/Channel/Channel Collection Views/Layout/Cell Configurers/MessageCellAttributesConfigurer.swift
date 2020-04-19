//
//  MessageCellAttributesConfigurer.swift
//  Benji
//
//  Created by Benji Dodgson on 11/10/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MessageCellAttributesConfigurer: ChannelCellAttributesConfigurer {

    var avatarSize = CGSize(width: 30, height: 36)
    var textViewVerticalPadding: CGFloat = 10
    var textViewHorizontalPadding: CGFloat = 20
    var bubbleViewHorizontalPadding: CGFloat = 14
    private let widthRatio: CGFloat = 0.8

    override func configure(with message: Messageable,
                            previousMessage: Messageable?,
                            nextMessage: Messageable?,
                            for layout: ChannelCollectionViewFlowLayout,
                            attributes: ChannelCollectionViewLayoutAttributes) {


        let avatarFrame = self.getAvatarFrame(with: message, layout: layout)
        attributes.attributes.avatarFrame = avatarFrame

        let textViewFrame = self.getTextViewFrame(with: message, for: layout)
        attributes.attributes.textViewFrame = textViewFrame

        let bubbleHeight = textViewFrame.height + (self.textViewVerticalPadding * 2)
        let bubbleWidth = textViewFrame.width + (self.bubbleViewHorizontalPadding * 2)

        let bubbleXOffset = textViewFrame.minX - self.bubbleViewHorizontalPadding
        let bubbleYOffset = textViewFrame.minY - self.textViewVerticalPadding
        attributes.attributes.bubbleViewFrame = CGRect(x: bubbleXOffset,
                                                       y: bubbleYOffset,
                                                       width: bubbleWidth,
                                                       height: bubbleHeight)
        //Determine masked corners
        if message.isFromCurrentUser {
            if let previous = previousMessage, previous.authorID == message.authorID {
                attributes.attributes.maskedCorners = [.layerMinXMaxYCorner, .layerMinXMinYCorner]
            } else {
                attributes.attributes.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMinYCorner]
            }
        } else {

            if let next = nextMessage, next.authorID == message.authorID {
                attributes.attributes.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner]
            } else {
                attributes.attributes.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner]
            }
        }
    }

    override func size(with message: Messageable?, for layout: ChannelCollectionViewFlowLayout) -> CGSize {
        guard let msg = message else { return .zero }

        let itemHeight = self.cellContentHeight(with: msg, for: layout)
        return CGSize(width: layout.itemWidth, height: itemHeight)
    }

    // PRIVATE

    private func cellContentHeight(with message: Messageable,
                                   for layout: ChannelCollectionViewFlowLayout) -> CGFloat {

        return self.getTextViewSize(with: message, for: layout).height
            + (self.textViewVerticalPadding * 2)
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

    private func getTextViewFrame(with message: Messageable,
                                  for layout: ChannelCollectionViewFlowLayout) -> CGRect {
        let size = self.getTextViewSize(with: message, for: layout)
        var xOffset: CGFloat = 0
        if message.isFromCurrentUser {
            xOffset = layout.itemWidth - size.width - self.textViewHorizontalPadding - 6
        } else {
            xOffset = self.getAvatarFrame(with: message, layout: layout).width + (self.getAvatarPadding(for: layout) * 2) + Theme.contentOffset
        }
        return CGRect(x: xOffset,
                      y: self.textViewVerticalPadding,
                      width: size.width,
                      height: size.height)
    }

    private func getTextViewSize(with message: Messageable,
                                 for layout: ChannelCollectionViewFlowLayout) -> CGSize {

        let attributed = AttributedString(message.text,
                                          fontType: .smallBold,
                                          color: .white)

        let attributedString = attributed.string
        let maxWidth = (layout.itemWidth * self.widthRatio) - self.getAvatarPadding(for: layout) - self.avatarSize.width
        let size = attributedString.getSize(withWidth: maxWidth)
        return size
    }

    private func getAvatarPadding(for layout: ChannelCollectionViewFlowLayout) -> CGFloat {
        guard let dataSource = layout.dataSource else { return .zero }
        return dataSource.numberOfMembers > 2 ? .zero : 8
    }
}
