//
//  LinkCellAttributesConfigurer.swift
//  Ours
//
//  Created by Benji Dodgson on 6/4/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class LinkCellAttributesConfigurer: ChannelCellAttributesConfigurer {

    override func configure(with message: Messageable,
                            previousMessage: Messageable?,
                            nextMessage: Messageable?,
                            for layout: ChannelCollectionViewFlowLayout,
                            attributes: ChannelCollectionViewLayoutAttributes) {



    }

    override func size(with message: Messageable?, for layout: ChannelCollectionViewFlowLayout) -> CGSize {
        return .zero
    }
}
