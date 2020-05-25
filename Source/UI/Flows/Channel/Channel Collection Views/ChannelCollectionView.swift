//
//  ChannelCollectionView.swift
//  Benji
//
//  Created by Benji Dodgson on 12/28/18.
//  Copyright © 2018 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ChannelCollectionView: CollectionView {

    var channelLayout: ChannelCollectionViewFlowLayout {
        guard let layout = collectionViewLayout as? ChannelCollectionViewFlowLayout else {
            fatalError("ChannelCollectionViewFlowLayout NOT FOUND")
        }
        return layout
    }

    var isTypingIndicatorHidden: Bool {
        return self.channelLayout.isTypingIndicatorViewHidden
    }

    init() {
        super.init(layout: ChannelCollectionViewFlowLayout())
        self.registerReusableViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func registerReusableViews() {
        self.register(MessageCell.self)
        self.register(TypingIndicatorCell.self)
        self.register(ChannelIntroHeader.self,
                      forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader)
        self.register(ChannelSectionHeader.self,
                      forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader)
        self.register(LoadMoreSectionHeader.self,
                      forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader)
        self.register(ReadAllFooterView.self,
                      forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter)
    }

    // Subtracts the read all footer height
    override func scrollToEnd(animated: Bool = true, completion: CompletionOptional = nil) {
        var rect: CGRect = .zero
        
        if let flowLayout = self.collectionViewLayout as? ChannelCollectionViewFlowLayout,
            flowLayout.scrollDirection == .vertical {

            let contentHeight = flowLayout.collectionViewContentSize.height - flowLayout.readFooterHeight
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
