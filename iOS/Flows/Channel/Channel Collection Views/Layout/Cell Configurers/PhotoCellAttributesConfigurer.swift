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

    override func configure(with message: Messageable,
                            previousMessage: Messageable?,
                            nextMessage: Messageable?,
                            for layout: ChannelCollectionViewFlowLayout,
                            attributes: ChannelCollectionViewLayoutAttributes) {

        guard let cv = layout.collectionView else { return }

        let avatarFrame = self.getAvatarFrame(with: message, layout: layout)
        attributes.attributes.avatarFrame = avatarFrame

        let imageFrame = CGRect(x: self.horizontalPadding,
                                y: 0,
                                width: cv.width - (self.horizontalPadding * 2),
                                height: cv.height * 0.3)

        attributes.attributes.imageFrame = imageFrame
    }

    override func size(with message: Messageable?, for layout: ChannelCollectionViewFlowLayout) -> CGSize {
        guard let cv = layout.collectionView else { return .zero }

        let size = CGSize(width: cv.width, height: (cv.height * 0.3))
        return size
    }

    private func getAvatarFrame(with message: Messageable, layout: ChannelCollectionViewFlowLayout) -> CGRect {
        guard let cv = layout.collectionView else { return .zero }
        let xOffset: CGFloat = message.isFromCurrentUser ? cv.width - self.horizontalPadding - self.avatarSize.width - 5 : self.horizontalPadding
        return CGRect(x: xOffset,
                      y: 5,
                      width: self.avatarSize.width,
                      height: self.avatarSize.height)
    }
}
