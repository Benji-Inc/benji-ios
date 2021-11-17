//
//  InputTypeManager.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/16/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class InputTypeManager: NSObject, UICollectionViewDelegate {

    lazy var dataSource = InputTypeDataSource.init(collectionView: self.collectionView)

    @Published var selectedItems: [InputType] = []

    private var __selectedItems: [InputType] {
        return self.collectionView.indexPathsForSelectedItems?.compactMap({ ip in
            return self.dataSource.itemIdentifier(for: ip)
        }) ?? []
    }

    let collectionView: CollectionView

    init(with collectionView: CollectionView) {
        self.collectionView = collectionView
        super.init()

        self.initialize()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func initialize() {
        self.collectionView.allowsMultipleSelection = false
        self.collectionView.delegate = self
        self.collectionView.isScrollEnabled = false 

        Task {
            await self.loadData()
            guard let ip = self.dataSource.indexPath(for: .keyboard) else { return }
            self.collectionView.selectItem(at: ip, animated: false, scrollPosition: .centeredHorizontally)
            self.collectionView.scrollToItem(at: ip, at: .centeredHorizontally, animated: true)
        }
    }

    @MainActor
    func loadData() async {
        self.collectionView.animationView.play()

        guard !Task.isCancelled else {
            self.collectionView.animationView.stop()
            return
        }

        let dataDictionary =  await self.retrieveDataForSnapshot()

        let snapshot = self.getInitialSnapshot(with: dataDictionary)

        if let animationCycle = self.getAnimationCycle() {
            await self.dataSource.apply(snapshot,
                                        collectionView: self.collectionView,
                                        animationCycle: animationCycle)
        } else {
            await self.dataSource.apply(snapshot)
        }

        self.collectionView.animationView.stop()
    }

    func getInitialSnapshot(with dictionary: [InputTypeDataSource.SectionType: [InputType]]) -> NSDiffableDataSourceSnapshot<InputTypeDataSource.SectionType, InputType> {

        var snapshot = self.dataSource.snapshot()
        snapshot.deleteAllItems()

        let allSections: [InputTypeDataSource.SectionType] = self.getAllSections()

        snapshot.appendSections(allSections)

        allSections.forEach { section in
            if let items = dictionary[section] {
                snapshot.appendItems(items, toSection: section)
            }
        }

        return snapshot
    }

    // MARK: Overrides

    // Used to capture and store any data needed for the snapshot
    // Dictionary must include all SectionType's in order to be properly displayed
    // Empty array may be returned for sections that dont have items.
    func retrieveDataForSnapshot() async -> [InputTypeDataSource.SectionType: [InputType]] {
        let items: [InputType] = [.photo, .video, .keyboard, .calendar, .jibs]
        return [.types: items]
    }

    func getAllSections() -> [InputTypeDataSource.SectionType] {
        return [.types]
    }

    func getAnimationCycle() -> AnimationCycle? {
        guard let ip = self.dataSource.indexPath(for: .keyboard) else { return nil }
        return AnimationCycle(inFromPosition: .inward,
                              outToPosition: .inward,
                              shouldConcatenate: true,
                              scrollToIndexPath: ip)
    }

    //MARK: CollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewManagerCell {
            cell.update(isSelected: true )
        }

        self.selectedItems = __selectedItems
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewManagerCell {
            cell.update(isSelected: false)
        }

        self.selectedItems = __selectedItems
    }

    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? {
        return nil
    }
}

