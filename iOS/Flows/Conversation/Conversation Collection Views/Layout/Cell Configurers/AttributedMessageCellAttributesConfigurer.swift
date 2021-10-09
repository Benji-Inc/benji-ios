//
//  AttributedMessageCellAttributesConfigurer.swift
//  Benji
//
//  Created by Benji Dodgson on 7/4/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation

class AttributedMessageCellAttributesConfigurer: ConversationCellAttributesConfigurer {
    override func configure(with message: Messageable, previousMessage: Messageable?, nextMessage: Messageable?, for layout: ConversationThreadCollectionViewFlowLayout, attributes: ConversationCollectionViewLayoutAttributes) {

    }

    override func size(with message: Messageable?, for layout: ConversationThreadCollectionViewFlowLayout) -> CGSize {
        return .zero
    }
}
