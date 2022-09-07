//
//  CalendarDataSource.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/5/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

struct CalendarRange: Hashable {
    let components: DateComponents
    let startOfMonth: Date 
    let numberOfDays: Int
    let total: Int
}

class CalendarDataSource: CollectionViewDataSource<CalendarRange, CalendarDataSource.ItemType> {
    
    enum ItemType: Hashable {
        case moment(MomentViewModel)
    }
    
    let momentConfig = ManageableCellRegistration<MomentCell>().provider
    
    private let headerConfig = ManageableHeaderRegistration<CalendarHeaderView>().provider
    
    weak var momentDelegate: MomentCellDelegate?
    
    override func dequeueCell(with collectionView: UICollectionView, indexPath: IndexPath, section: CalendarRange, item: ItemType) -> UICollectionViewCell? {
                
        switch item {
        case .moment(let model):
            let cell = collectionView.dequeueConfiguredReusableCell(using: self.momentConfig,
                                                                    for: indexPath,
                                                                    item: model)
            cell.delegate = self.momentDelegate
            return cell 
        }
    }
    
    override func dequeueSupplementaryView(with collectionView: UICollectionView,
                                           kind: String,
                                           section: CalendarRange,
                                           indexPath: IndexPath) -> UICollectionReusableView? {
                        
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let header = collectionView.dequeueConfiguredReusableSupplementary(using: self.headerConfig, for: indexPath)
            header.configure(with: section.startOfMonth)
            header.animate()
            return header
        default:
            return nil
        }
    }
}
