//
//  ConversationCollectionView.swift
//  Jibber
//
//  Created by Martin Young on 10/7/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

/// A collection view for displaying conversations.
/// Conversations are ordered right to left. So the first conversation in the data source is on the far right.
/// It automatically creates its own custom layout object.
class ConversationListCollectionView: CollectionView, MessageSendingCollectionViewType {

    let conversationLayout: ConversationListCollectionViewLayout

    init() {
        self.conversationLayout = ConversationListCollectionViewLayout()

        super.init(layout: self.conversationLayout)

        self.clipsToBounds = false
        self.keyboardDismissMode = .interactive
        self.decelerationRate = .fast
        self.showsHorizontalScrollIndicator = false
        self.semanticContentAttribute = .forceRightToLeft
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Returns the frame that a message drop zone should appear based on this collectionview's contents.
    /// The frame is in the coordinate space of the passed in view.
    func getMessageDropZoneFrame(convertedTo view: UIView) -> CGRect {
        guard let centerCell = self.getCentermostVisibleCell() as? ConversationMessagesCell else {
            let overlayFrame = CGRect(x: Theme.contentOffset,
                                      y: 100,
                                      width: self.width - Theme.contentOffset.doubled,
                                      height: 50)
            return self.convert(overlayFrame, to: view)
        }

        return centerCell.getMessageDropZoneFrame(convertedTo: view)
    }

    // MARK: - MessageSendingCollectionView

    func getDropZoneColor() -> Color? {
        guard let centerCell = self.getCentermostVisibleCell() as? ConversationMessagesCell else {
            return nil
        }

        return centerCell.getDropZoneColor()
    }

    func getBottomFrontmostCell() -> MessageSubcell? {
        guard let centerCell = self.getCentermostVisibleCell() as? ConversationMessagesCell else {
            return nil
        }
        return centerCell.getBottomFrontMostCell()
    }

    func getCurrentConversationID() -> ConversationID? {
        guard let centeredCell = self.getCentermostVisibleCell() as? ConversationMessagesCell,
              let cid = centeredCell.conversation?.conversationId else {
                  return nil
              }

        return try? ConversationID(cid: cid)
    }

    func getNewConversationContentOffset() -> CGPoint {
        let xOffset = -self.width + self.conversationLayout.minimumLineSpacing
        return CGPoint(x: xOffset, y: 0)
    }
}
