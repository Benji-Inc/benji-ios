//
//  CalendarDataSource.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/5/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

struct CalendarRange {
    let month: Int
    let year: Int
    let daysInMonth: Int
}

class CalendarDataSource: CollectionViewDataSource<CalendarDataSource.SectionType, CalendarDataSource.ItemType> {
    
    enum SectionType: Int, CaseIterable {
        case conversations
        case moments
    }
    
    enum ItemType: Hashable {
        case moment(MomentViewModel)
    }
    
    let momentConfig = ManageableCellRegistration<MomentCell>().provider
    
    private let headerConfig = ManageableHeaderRegistration<MomentsHeaderView>().provider
    
    weak var messageContentDelegate: MessageContentDelegate?
    
    override func dequeueCell(with collectionView: UICollectionView, indexPath: IndexPath, section: SectionType, item: ItemType) -> UICollectionViewCell? {
                
        switch item {
        case .moment(let model):
            return collectionView.dequeueConfiguredReusableCell(using: self.momentConfig,
                                                                for: indexPath,
                                                                item: model)
        }
    }
    
    override func dequeueSupplementaryView(with collectionView: UICollectionView,
                                           kind: String,
                                           section: SectionType,
                                           indexPath: IndexPath) -> UICollectionReusableView? {
                        
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let header = collectionView.dequeueConfiguredReusableSupplementary(using: self.headerConfig, for: indexPath)
            header.animate()
            return header
        default:
            return nil
        }
    }
}
