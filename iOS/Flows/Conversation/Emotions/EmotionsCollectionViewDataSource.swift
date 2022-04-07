//
//  EmotionCollectionViewDataSource.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/27/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class EmotionsCollectionViewDataSource: CollectionViewDataSource<EmotionsCollectionViewDataSource.SectionType,
                                        EmotionsCollectionViewDataSource.ItemType> {
    
    enum SectionType: Int, Hashable, CaseIterable {
        case content
        case categories
    }

    enum ItemType: Hashable {
        case emotion(EmotionContentModel)
        case category(EmotionCategoryModel)
    }

    private let config = ManageableCellRegistration<EmotionCategoryCell>().provider
    private let contentConfig = ManageableCellRegistration<EmotionContentCell>().provider
    private let headerConfig = ManageableHeaderRegistration<SectionHeaderView>().provider

    var didSelectEmotion: ((Emotion) -> Void)?
    var didSelectRemove: CompletionOptional = nil

    // MARK: - Cell Dequeueing

    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ItemType) -> UICollectionViewCell? {
        
        switch item {
        case .emotion(let emotion):
            return collectionView.dequeueConfiguredReusableCell(using: self.contentConfig,
                                                                for: indexPath,
                                                                item: emotion)
        case .category(let category):
            let cell = collectionView.dequeueConfiguredReusableCell(using: self.config,
                                                                    for: indexPath,
                                                                    item: category)
            cell.didSelectEmotion = { [unowned self] emotion in
                self.didSelectEmotion?(emotion)
            }
            return cell
        }
    }
    
    override func dequeueSupplementaryView(with collectionView: UICollectionView,
                                           kind: String,
                                           section: SectionType,
                                           indexPath: IndexPath) -> UICollectionReusableView? {
        
        switch section {
        case .categories:
            let header = collectionView.dequeueConfiguredReusableSupplementary(using: self.headerConfig, for: indexPath)
            header.leftLabel.setText("When...")
            header.rightLabel.setText("Remove")
            header.lineView.isHidden = true
            header.didSelectButton = { [unowned self] in
                self.didSelectRemove?()
            }
            
            return header
        default:
            return nil
        }
    }
}
