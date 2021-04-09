//
//  CommentsCollectionViewManager.swift
//  Ours
//
//  Created by Benji Dodgson on 4/9/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class CommentsCollectionViewManager: CollectionViewManager<CommentsCollectionViewManager.SectionType> {

    enum SectionType: Int, ManagerSectionType {
        case comments = 0
    }

    private let commentsConfig = ManageableCellRegistration<CommentCell>().cellProvider

    lazy var layout = UICollectionViewCompositionalLayout() { sectionIndex, layoutEnvironment in

        var listConfig = UICollectionLayoutListConfiguration(appearance: .grouped)

        listConfig.backgroundColor = .clear
        listConfig.showsSeparators = false

        let section = NSCollectionLayoutSection.list(using: listConfig, layoutEnvironment: layoutEnvironment)
        return section
    }

    override func initialize() {
        super.initialize()

        self.collectionView.collectionViewLayout = self.layout
        self.collectionView.animationView.play()

        // Load comments
    }

    override func getItems(for section: SectionType) -> [AnyHashable] {
        switch section {
        case .comments:
            return []
        }
    }

    override func getCell(for section: SectionType, indexPath: IndexPath, item: AnyHashable?) -> CollectionViewManagerCell? {
        switch section {
        case .comments:
            return self.collectionView.dequeueManageableCell(using: self.commentsConfig,
                                                             for: indexPath,
                                                             item: item as? Comment)
        }
    }
}
