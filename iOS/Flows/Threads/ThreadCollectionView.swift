//
//  ConversationCollectionView.swift
//  Benji
//
//  Created by Benji Dodgson on 12/28/18.
//  Copyright © 2018 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ThreadCollectionView: CollectionView {

    var threadLayout: ThreadTimeMachineCollectionViewLayout {
        return self.collectionViewLayout as! ThreadTimeMachineCollectionViewLayout
    }

    init() {
        super.init(layout: ThreadTimeMachineCollectionViewLayout())

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

class ThreadTimeMachineCollectionViewLayout: MessagesTimeMachineCollectionViewLayout {
    
    override func getCenterPoint(for section: SectionIndex,
                        withYOffset yOffset: CGFloat,
                        scale: CGFloat) -> CGPoint {

        guard let collectionView = self.collectionView else { return .zero }

        let contentRect = CGRect(x: collectionView.contentOffset.x,
                                 y: collectionView.contentOffset.y,
                                 width: collectionView.bounds.size.width,
                                 height: collectionView.bounds.size.height)

        var centerPoint: CGPoint = .zero

        switch self.uiState {
        case .read:

            let centerY = contentRect.top + 100

            centerPoint = CGPoint(x: contentRect.midX, y: centerY)

            if section == 0 {
                centerPoint.y += self.itemHeight.half
                centerPoint.y += yOffset
                centerPoint.y += self.itemHeight.doubled * (1-scale)
                centerPoint.y -= 100 - Theme.ContentOffset.short.value
            } else {
                centerPoint.y += 50
                centerPoint.y += self.itemHeight.doubled - Theme.ContentOffset.short.value
                centerPoint.y -= yOffset
                centerPoint.y -= self.itemHeight.doubled * (1-scale)
            }

        case .write:

            let centerY = (contentRect.top + MessageContentView.standardHeight.doubled)
            centerPoint = CGPoint(x: contentRect.midX, y: centerY)

            if section == 0 {
                centerPoint.y += self.itemHeight.half
                centerPoint.y += yOffset
                centerPoint.y += self.itemHeight.half * (1-scale)
            } else {
                centerPoint.y += self.itemHeight.doubled - Theme.ContentOffset.short.value
                centerPoint.y -= yOffset
                centerPoint.y -= self.itemHeight.half * (1-scale)
            }
        }

        return centerPoint
    }
}


