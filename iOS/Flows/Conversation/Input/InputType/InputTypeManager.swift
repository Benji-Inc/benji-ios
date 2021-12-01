//
//  InputTypeManager.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/16/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class InputTypeManager: DiffableCollectionViewManager<InputTypeDataSource.SectionType,
                        InputType,
                        InputTypeDataSource> {

    override func initializeCollectionView() {
        super.initializeCollectionView()

        self.collectionView.allowsMultipleSelection = false 
        self.collectionView.isScrollEnabled = false
    }

    override func handleDataBeingLoaded() {
        guard let ip = self.dataSource.indexPath(for: .keyboard) else { return }

        // A little hack to get the keyboard centered and selected.
        self.collectionView.selectItem(at: ip, animated: true, scrollPosition: .centeredHorizontally)
        if let cell = collectionView.cellForItem(at: ip) as? CollectionViewManagerCell {
            cell.update(isSelected: true)
        }
    }

    // MARK: Overrides

    override func retrieveDataForSnapshot() async -> [InputTypeDataSource.SectionType: [InputType]] {
        let items: [InputType] = [.photo, .video, .keyboard, .calendar, .jibs]
        return [.types: items]
    }

    override func getAllSections() -> [InputTypeDataSource.SectionType] {
        return [.types]
    }

    override func getAnimationCycle() -> AnimationCycle? {
        guard let ip = self.dataSource.indexPath(for: .keyboard) else { return nil }
        return AnimationCycle(inFromPosition: .inward,
                              outToPosition: .inward,
                              shouldConcatenate: true,
                              scrollToIndexPath: ip)
    }
}

