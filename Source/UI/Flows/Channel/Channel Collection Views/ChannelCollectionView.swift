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

    func animateEmptyView(shouldShow: Bool) {
        UIView.animate(withDuration: Theme.animationDuration) {
            self.backgroundView?.alpha = shouldShow ? 1 : 0
        }
    }

    private func registerReusableViews() {
        self.activityIndicator.isHidden = true 
        self.register(MessageCell.self)
        self.register(TypingIndicatorCell.self)
        self.register(ChannelSectionHeader.self,
                      forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader)
        self.register(LoadMoreSectionHeader.self,
                      forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader)
    }
}
