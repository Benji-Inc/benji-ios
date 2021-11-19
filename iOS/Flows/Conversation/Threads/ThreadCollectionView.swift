//
//  ConversationCollectionView.swift
//  Benji
//
//  Created by Benji Dodgson on 12/28/18.
//  Copyright © 2018 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ThreadCollectionView: CollectionView {

    init() {
        super.init(layout: ThreadCollectionViewLayout())
        
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
}
