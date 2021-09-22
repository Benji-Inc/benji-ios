//
//  CirclesViewController.swift
//  CirclesViewController
//
//  Created by Benji Dodgson on 9/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

protocol CircleGroupViewControllerDelegate: AnyObject {
    func circleGroupView(_ controller: CircleGroupViewController, didSelect item: CircleGroupCollectionViewDataSource.ItemType)
}

class CircleGroupViewController: BlurredViewController {

    weak var delegate: CircleGroupViewControllerDelegate?

    // MARK: - UI

    private var collectionView = CollectionView(layout: CircleGroupCollectionViewLayout())
    lazy var dataSource = CircleGroupCollectionViewDataSource(collectionView: self.collectionView)

    var circles: [CircleGroup] = []

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

        do {
            self.collectionView.animationView.play()

            guard let circles = try await CircleGroup.query()?.findObjectsInBackground() as? [CircleGroup], !circles.isEmpty else {
                self.collectionView.animationView.stop()
                return
            }

            let snapshot = self.getInitialSnapshot(with: circles)

            let cycle = AnimationCycle(inFromPosition: .inward,
                                       outToPosition: .inward,
                                       shouldConcatenate: true,
                                       scrollToEnd: false)

            await self.dataSource.apply(snapshot, collectionView: self.collectionView, animationCycle: cycle)

            self.collectionView.animationView.stop()
        } catch {
            print(error)
        }
    }

    private func getInitialSnapshot(with circles: [CircleGroup]) -> NSDiffableDataSourceSnapshot<CircleGroupCollectionViewDataSource.SectionType,
                                                                      CircleGroupCollectionViewDataSource.ItemType> {
        var snapshot = self.dataSource.snapshot()

        let allCases = CircleGroupCollectionViewDataSource.SectionType.allCases
        snapshot.appendSections(allCases)
        allCases.forEach { (section) in
            let items: [CircleGroupCollectionViewDataSource.ItemType] = circles.map { group in
                return .circles(group)
            }
            snapshot.appendItems(items, toSection: section)
        }

        return snapshot
    }
}

extension CircleGroupViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let identifier = self.dataSource.itemIdentifier(for: indexPath) else { return }

        self.delegate?.circleGroupView(self, didSelect: identifier)
    }
}
