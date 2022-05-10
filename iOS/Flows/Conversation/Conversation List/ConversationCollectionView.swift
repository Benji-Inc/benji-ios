//
//  ConversationCollectionView.swift
//  Jibber
//
//  Created by Martin Young on 1/10/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

/// A collection view that displays a single conversation.
class ConversationCollectionView: CollectionView {

    var conversationLayout: MessagesTimeMachineCollectionViewLayout {
        return self.collectionViewLayout as! MessagesTimeMachineCollectionViewLayout
    }

    init() {
        super.init(layout: MessagesTimeMachineCollectionViewLayout())

        // Allow message cells to scale in size without getting clipped.
        self.clipsToBounds = false
        self.set(backgroundColor: .clear)

        self.showsVerticalScrollIndicator = false
        self.automaticallyAdjustsScrollIndicatorInsets = true
        self.decelerationRate = .fast
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ConversationCollectionView: MessageSendingCollectionViewType {

    /// Returns the frame that a message drop zone should have, based on this cell's contents.
    /// The frame is in the coordinate space of the passed in view.
    func getMessageDropZoneFrame(convertedTo targetView: UIView) -> CGRect {
        let dropZoneFrame = self.conversationLayout.getDropZoneFrame()

        return self.convert(dropZoneFrame, to: targetView)
    }

    func getNewConversationContentOffset() -> CGPoint {
        return .zero
    }
}
