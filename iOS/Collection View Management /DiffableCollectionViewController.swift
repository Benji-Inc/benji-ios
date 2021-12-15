//
//  DiffableCollectionViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/25/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class DiffableCollectionViewController<SectionType: Hashable,
                                       ItemType: Hashable,
                                       DataSource: CollectionViewDataSource<SectionType, ItemType>>:
                                        ViewController, UICollectionViewDelegate {
    
    lazy var dataSource = DataSource(collectionView: self.collectionView)

    @Published var selectedItems: [ItemType] = []

    private var selectionImapact = UIImpactFeedbackGenerator.init(style: .light)

    private var __selectedItems: [ItemType] {
        return self.collectionView.indexPathsForSelectedItems?.compactMap({ ip in
            return self.dataSource.itemIdentifier(for: ip)
        }) ?? []
    }

    let collectionView: CollectionView

    init(with collectionView: CollectionView) {
        self.collectionView = collectionView
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        self.collectionView.allowsMultipleSelection = true

        self.view.addSubview(self.collectionView)
        self.collectionView.delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        Task {
            await self.loadData()
        }.add(to: self.taskPool)
    }

    func dataWasLoaded() {}

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.collectionView.expandToSuperviewSize()
    }

    @MainActor
    func loadData() async {
        self.collectionView.layoutNow()
        self.collectionView.animationView.play()

        guard !Task.isCancelled else {
            self.collectionView.animationView.stop()
            return
        }

        let dataDictionary = await self.retrieveDataForSnapshot()

        let snapshot = self.getInitialSnapshot(with: dataDictionary)

        if let animationCycle = self.getAnimationCycle(withData: dataDictionary) {
            await self.dataSource.apply(snapshot,
                                        collectionView: self.collectionView,
                                        animationCycle: animationCycle)
        } else {
            await self.dataSource.apply(snapshot)
        }

        self.collectionView.animationView.stop()
        self.dataWasLoaded()
    }

    func getInitialSnapshot(with dictionary: [SectionType : [ItemType]])
    -> NSDiffableDataSourceSnapshot<SectionType, ItemType> {
        
        var snapshot = self.dataSource.snapshot()
        snapshot.deleteAllItems()

        let allSections: [SectionType] = self.getAllSections()

        snapshot.appendSections(allSections)

        allSections.forEach { section in
            if let items = dictionary[section] {
                snapshot.appendItems(items, toSection: section)
            }
        }

        return snapshot
    }

    // MARK: Overrides

    /// Used to capture and store any data needed for the snapshot
    /// Dictionary must include all SectionType's in order to be properly displayed
    /// Empty array may be returned for sections that dont have items.
    func retrieveDataForSnapshot() async -> [SectionType: [ItemType]] {
        fatalError("retrieveDataForSnapshot NOT IMPLEMENTED")
    }

    func getAllSections() -> [SectionType] {
        fatalError("getAllSections NOT IMPLEMENTED")
    }

    func getAnimationCycle(withData data: [SectionType : [ItemType]]) -> AnimationCycle? {
        return AnimationCycle(inFromPosition: .inward,
                              outToPosition: .inward,
                              shouldConcatenate: true,
                              scrollToIndexPath: nil)
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

        self.selectionImapact.impactOccurred()
        self.selectedItems = __selectedItems
    }

    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? {
        return nil
    }
}
