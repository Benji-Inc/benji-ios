//
//  ConversationCollectionView.swift
//  Benji
//
//  Created by Benji Dodgson on 12/28/18.
//  Copyright © 2018 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ThreadCollectionView: CollectionView {

    let threadLayout = MessagesTimeMachineCollectionViewLayout()

    init() {
        super.init(layout: self.threadLayout)

        self.showsVerticalScrollIndicator = false
        self.keyboardDismissMode = .interactive
        self.automaticallyAdjustsScrollIndicatorInsets = true 
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func getBottomFrontMostCell() -> MessageSubcell? {
        return self.threadLayout.getBottomFrontMostCell()
    }
}

extension ThreadCollectionView: MessageSendingCollectionViewType {

    /// Returns the frame that a message drop zone should have, based on this cell's contents.
    /// The frame is in the coordinate space of the passed in view.
    func getMessageDropZoneFrame(convertedTo targetView: UIView) -> CGRect {
        let dropZoneFrame = self.threadLayout.getDropZoneFrame()

        return self.convert(dropZoneFrame, to: targetView)
    }

    func getDropZoneColor() -> Color? {
        if self.visibleCells.count > 0 {
            return .darkGray
        }

        return .white
    }

    func getNewConversationContentOffset() -> CGPoint {
        return .zero
    }
}
