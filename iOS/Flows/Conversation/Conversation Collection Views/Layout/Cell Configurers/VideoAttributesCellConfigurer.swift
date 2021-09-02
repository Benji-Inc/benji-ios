//
//  VideoAttributesCellConfigurer.swift
//  Benji
//
//  Created by Benji Dodgson on 7/4/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation

class VideoAttributesCellConfigurer: ConversationCellAttributesConfigurer {

    override func configure(with message: Messageable, previousMessage: Messageable?, nextMessage: Messageable?, for layout: ConversationCollectionViewFlowLayout, attributes: ConversationCollectionViewLayoutAttributes) {

    }

    override func size(with message: Messageable?, for layout: ConversationCollectionViewFlowLayout) -> CGSize {
        guard let msg = message, case MessageKind.video(let video, _) = msg.kind else { return .zero }
        return video.size
    }
}

