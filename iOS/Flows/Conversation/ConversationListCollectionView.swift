//
//  ConversationCollectionView.swift
//  Jibber
//
//  Created by Martin Young on 10/7/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

/// A collection view for displaying conversations.
/// Conversations are ordered right to left. So the first conversation in the data source is on the far right.
/// It automatically creates its own custom layout object.
class ConversationListCollectionView: CollectionView {

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
}

extension ConversationListCollectionView: MessageSendingCollectionViewType {

    // MARK: - MessageSendingCollectionView

    func getDropZoneColor() -> ThemeColor? {
        guard let centerCell = self.getCentermostVisibleCell() as? ConversationMessagesCell else {
            return nil
        }

        return centerCell.getDropZoneColor()
    }

    func getBottomFrontmostCell() -> MessageSubcell? {
        guard let centerCell = self.getCentermostVisibleCell() as? ConversationMessagesCell else {
            return nil
        }
        return centerCell.getBottomFrontmostCell()
    }

    func getNewConversationContentOffset() -> CGPoint {
        let xOffset = -self.width + self.conversationLayout.minimumLineSpacing
        return CGPoint(x: xOffset, y: 0)
    }
}
