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

class CircleViewController: BlurredViewController {

    unowned let delegate: CircleViewControllerDelegate

    // MARK: - UI

    private var collectionView = CollectionView(layout: CircleCollectionViewLayout())
    lazy var dataSource = CircleCollectionViewDataSource(collectionView: self.collectionView)

    private let circleGroup: CircleGroup

    init(with circleGroup: CircleGroup, delegate: CircleViewControllerDelegate) {
        self.circleGroup = circleGroup
        self.delegate = delegate
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

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

        let snapshot = self.getInitialSnapshot()

        let cycle = AnimationCycle(inFromPosition: .inward,
                                   outToPosition: .inward,
                                   shouldConcatenate: true,
                                   scrollToEnd: false)

        await self.dataSource.apply(snapshot, collectionView: self.collectionView, animationCycle: cycle)

        self.collectionView.animationView.stop()
    }

    private func getInitialSnapshot() -> NSDiffableDataSourceSnapshot<CircleCollectionViewDataSource.SectionType,
                                                                      CircleCollectionViewDataSource.ItemType> {
        var snapshot = self.dataSource.snapshot()

        let allCases = CircleCollectionViewDataSource.SectionType.allCases
        snapshot.appendSections(allCases)
        allCases.forEach { (section) in
            let items: [CircleCollectionViewDataSource.ItemType] = self.circleGroup.circles?.first?.users?.compactMap { user in
                return .user(user)
            } ?? []
            snapshot.appendItems(items, toSection: section)
        }

        return snapshot
    }
}
