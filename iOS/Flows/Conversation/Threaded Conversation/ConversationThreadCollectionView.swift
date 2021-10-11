//
//  ConversationCollectionView.swift
//  Benji
//
//  Created by Benji Dodgson on 12/28/18.
//  Copyright © 2018 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ConversationThreadCollectionView: CollectionView {

    var conversationLayout: ConversationThreadCollectionViewLayout {
        guard let layout = collectionViewLayout as? ConversationThreadCollectionViewLayout else {
            fatalError("ConversationThreadCollectionViewLayout NOT FOUND")
        }
        return layout
    }

    init() {
        super.init(layout: ConversationThreadCollectionViewLayout())
        self.registerReusableViews()
        self.keyboardDismissMode = .interactive
        self.automaticallyAdjustsScrollIndicatorInsets = true 
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func registerReusableViews() {
        self.register(ReplyMessageCell.self)
        self.register(AudioMessageCell.self)
        self.register(LocationMessageCell.self)
        self.register(ContactMessageCell.self)
        self.register(EmojiMessageCell.self)
        self.register(VideoMessageCell.self)
        self.register(LinkCell.self)
    }

    // NOTE: It's possible for small content size this wouldn't work - https://github.com/MessageKit/MessageKit/issues/725
    func scrollToLastItem(at pos: UICollectionView.ScrollPosition = .bottom, animated: Bool = true) {
        guard self.numberOfSections > 0 else { return }

        let lastSection = self.numberOfSections - 1
        let lastItemIndex = self.numberOfItems(inSection: lastSection) - 1

        guard lastItemIndex >= 0 else { return }

        let indexPath = IndexPath(row: lastItemIndex, section: lastSection)
        self.scrollToItem(at: indexPath, at: pos, animated: animated)
    }

    // Subtracts the read all footer height
    override func scrollToEnd(animated: Bool = true, completion: CompletionOptional = nil) {
        var rect: CGRect = .zero
        
        if let flowLayout = self.collectionViewLayout as? ConversationThreadCollectionViewLayout {

            let contentHeight = flowLayout.collectionViewContentSize.height
            rect = CGRect(x: 0.0,
                          y: contentHeight - 1.0,
                          width: 1.0,
                          height: 1.0)
        } else {
            let contentWidth = self.collectionViewLayout.collectionViewContentSize.width
            rect = CGRect(x: contentWidth - 1.0,
                          y: 0,
                          width: 1.0,
                          height: 1.0)
        }

        self.performBatchUpdates({
            self.scrollRectToVisible(rect, animated: animated)
        }) { (completed) in
            completion?()
        }
    }
}
