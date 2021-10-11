//
//  AudioCellAttributesConfigurer.swift
//  Benji
//
//  Created by Benji Dodgson on 7/4/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation

class AudioCellAttributesConfigurer: ConversationCellAttributesConfigurer {

    override func configure(with message: Messageable, previousMessage: Messageable?, nextMessage: Messageable?, for layout: ConversationThreadCollectionViewLayout, attributes: ConversationCollectionViewLayoutAttributes) {

    }

    override func size(with message: Messageable?, for layout: ConversationThreadCollectionViewLayout) -> CGSize {
        guard let msg = message, case MessageKind.audio(let item) = msg.kind else { return .zero }
        return item.size
    }
}
