//
//  ConversationCollectionView.swift
//  Benji
//
//  Created by Benji Dodgson on 12/28/18.
//  Copyright © 2018 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ThreadCollectionView: CollectionView {

    var threadLayout: MessagesTimeMachineCollectionViewLayout {
        return self.collectionViewLayout as! MessagesTimeMachineCollectionViewLayout
    }

    init() {
        super.init(layout: MessagesTimeMachineCollectionViewLayout())

        self.threadLayout.messageContentState = .thread 
        self.showsVerticalScrollIndicator = false
        self.automaticallyAdjustsScrollIndicatorInsets = true
        self.decelerationRate = .fast
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ThreadCollectionView: MessageSendingCollectionViewType {

    /// Returns the frame that a message drop zone should have, based on this cell's contents.
    /// The frame is in the coordinate space of the passed in view.
    func getMessageDropZoneFrame(convertedTo targetView: UIView) -> CGRect {
        let dropZoneFrame = self.threadLayout.getDropZoneFrame()

        return self.convert(dropZoneFrame, to: targetView)
    }

    func getNewConversationContentOffset() -> CGPoint {
        return .zero
    }
}
