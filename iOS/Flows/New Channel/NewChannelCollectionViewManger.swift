//
//  NewChannelCollectionViewManger.swift
//  Ours
//
//  Created by Benji Dodgson on 2/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class NewChannelCollectionViewManger: CollectionViewManager<NewChannelCollectionViewManger.SectionType> {

    enum SectionType: Int, ManagerSectionType {
        case users
    }
}
