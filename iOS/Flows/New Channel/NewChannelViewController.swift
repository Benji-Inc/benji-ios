//
//  NewChannelViewController.swift
//  Ours
//
//  Created by Benji Dodgson on 2/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class NewChannelViewController: CollectionViewController<NewChannelCollectionViewManger.SectionType, NewChannelCollectionViewManger> {

    var didCreateChannel: CompletionOptional = nil

    init() {
        super.init(with: NewChannelCollectionView())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
