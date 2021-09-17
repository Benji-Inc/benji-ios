//
//  CicleViewController.swift
//  CicleViewController
//
//  Created by Benji Dodgson on 9/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

protocol CircleViewControllerDelegate: AnyObject {
    func circleView(_ controller: CircleViewController, didSelect item: CircleCollectionViewDataSource.ItemType)
}

class CircleViewController: ViewController {

    weak var delegate: CircleViewControllerDelegate?

    // MARK: - UI

    private var collectionView = CollectionView(layout: CircleCollectionViewLayout())
    lazy var dataSource = CircleCollectionViewDataSource(collectionView: self.collectionView)

    override func initializeViews() {
        super.initializeViews()

        self.view.set(backgroundColor: .background1)

        self.view.addSubview(self.collectionView)

        self.collectionView.delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        Task {
            await self.loadData()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.collectionView.expandToSuperviewSize()
    }

    // MARK: Data Loading

    @MainActor
    private func loadData() async {
        self.collectionView.animationView.play()

        //Query users

        let cycle = AnimationCycle(inFromPosition: .inward,
                                   outToPosition: .inward,
                                   shouldConcatenate: true,
                                   scrollToEnd: false)

        let snapshot = self.getInitialSnapshot()
        await self.dataSource.apply(snapshot, collectionView: self.collectionView, animationCycle: cycle)

        self.collectionView.animationView.stop()
    }

    private func getInitialSnapshot() -> NSDiffableDataSourceSnapshot<CircleCollectionViewDataSource.SectionType,
                                                                      CircleCollectionViewDataSource.ItemType> {
        var snapshot = self.dataSource.snapshot()

        let allCases = CircleCollectionViewDataSource.SectionType.allCases
        snapshot.appendSections(allCases)
        allCases.forEach { (section) in
            snapshot.appendItems(self.getItems(for: section), toSection: section)
        }

        return snapshot
    }

    private func getItems(for section: CircleCollectionViewDataSource.SectionType)
    -> [CircleCollectionViewDataSource.ItemType] {
        return []
    }
}
