//
//  PhotoCellAttributesConfigurer.swift
//  Benji
//
//  Created by Benji Dodgson on 7/4/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation

class PhotoCellAttributesConfigurer: ChannelCellAttributesConfigurer {

    var avatarSize = CGSize(width: 30, height: 36)
    var horizontalPadding: CGFloat = Theme.contentOffset

    var textViewVerticalPadding: CGFloat = 10
    var textViewHorizontalPadding: CGFloat = 14
    var bubbleViewHorizontalPadding: CGFloat = 14
    private let widthRatio: CGFloat = 0.8

    override func configure(with message: Messageable,
                            previousMessage: Messageable?,
                            nextMessage: Messageable?,
                            for layout: ChannelCollectionViewFlowLayout,
                            attributes: ChannelCollectionViewLayoutAttributes) {

        let avatarFrame = self.getAvatarFrame(with: message, layout: layout)
        attributes.attributes.avatarFrame = avatarFrame

        let attachmentFrame = self.getAttachmentFrame(for: layout)

        attributes.attributes.attachmentFrame = attachmentFrame

        let textViewSize = self.getTextViewSize(with: message, for: layout)
        let bubbleViewFrame = self.getBubbleViewFrame(with: message,
                                                      textViewSize: textViewSize,
                                                      yOffset: attachmentFrame.minY,
                                                      for: layout)

        attributes.attributes.bubbleViewFrame = bubbleViewFrame
        attributes.attributes.textViewFrame = self.getTextViewFrame(with: bubbleViewFrame.size, textViewSize: textViewSize)
    }

    override func size(with message: Messageable?, for layout: ChannelCollectionViewFlowLayout) -> CGSize {
        guard let msg = message, let cv = layout.collectionView else { return .zero }
        let size = CGSize(width: cv.width, height: self.cellContentHeight(with: msg, for: layout))
        return size
    }

    private func cellContentHeight(with message: Messageable,
                                   for layout: ChannelCollectionViewFlowLayout) -> CGFloat {
        let attachmentFrame = self.getAttachmentFrame(for: layout)
        let size = self.getTextViewSize(with: message, for: layout)
        let bubbleFrame = self.getBubbleViewFrame(with: message, textViewSize: size, yOffset: attachmentFrame.minY, for: layout)

        let height = attachmentFrame.height + bubbleFrame.height
        return height
    }

    private func getAttachmentFrame(for layout: ChannelCollectionViewFlowLayout) -> CGRect {
        guard let cv = layout.collectionView else { return .zero }
        return CGRect(x: self.horizontalPadding,
                      y: 0,
                      width: cv.width - (self.horizontalPadding * 2),
                      height: cv.height * 0.3)
    }

    private func getAvatarFrame(with message: Messageable, layout: ChannelCollectionViewFlowLayout) -> CGRect {
        guard let cv = layout.collectionView else { return .zero }
        let xOffset: CGFloat = message.isFromCurrentUser ? cv.width - self.horizontalPadding - self.avatarSize.width - 5 : self.horizontalPadding
        return CGRect(x: xOffset,
                      y: 5,
                      width: self.avatarSize.width,
                      height: self.avatarSize.height)
    }

    private func getTextViewFrame(with bubbleViewSize: CGSize, textViewSize: CGSize) -> CGRect {
        return CGRect(x: self.bubbleViewHorizontalPadding,
                      y: self.textViewVerticalPadding,
                      width: textViewSize.width,
                      height: textViewSize.height)
    }

    private func getBubbleViewFrame(with message: Messageable,
                                    textViewSize: CGSize,
                                    yOffset: CGFloat,
                                    for layout: ChannelCollectionViewFlowLayout) -> CGRect {

        var xOffset: CGFloat = 0
        if message.isFromCurrentUser {
            xOffset = layout.itemWidth - textViewSize.width - (self.textViewHorizontalPadding * 2)
        } else {
            xOffset = Theme.contentOffset
        }

        return CGRect(x: xOffset - self.bubbleViewHorizontalPadding,
                      y: yOffset,
                      width: textViewSize.width + (self.bubbleViewHorizontalPadding * 2),
                      height: textViewSize.height + (self.textViewVerticalPadding * 2))
    }

    private func getTextViewSize(with message: Messageable,
                                 for layout: ChannelCollectionViewFlowLayout) -> CGSize {
        guard !message.kind.text.isEmpty else { return .zero }
        let attributed = AttributedString(message.kind.text,
                                          fontType: .smallBold,
                                          color: .white)

        let attributedString = attributed.string
        attributedString.linkItems()
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 2
        attributedString.addAttributes([NSAttributedString.Key.paragraphStyle: style])
        let maxWidth = (layout.itemWidth * self.widthRatio)
        let size = attributedString.getSize(withWidth: maxWidth)
        return size
    }
}
