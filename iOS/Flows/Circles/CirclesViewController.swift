//
//  CirclesViewController.swift
//  CirclesViewController
//
//  Created by Benji Dodgson on 9/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

protocol CirclesViewControllerDelegate: AnyObject {
    func circlesView(_ controller: CirclesViewController, didSelect item: CirclesCollectionViewDataSource.ItemType)
}

class CirclesViewController: ViewController {

    weak var delegate: CirclesViewControllerDelegate?

    // MARK: - UI

    private var collectionView = CollectionView(layout: CirclesCollectionViewLayout())
    lazy var dataSource = CirclesCollectionViewDataSource(collectionView: self.collectionView)

    var circles: [CircleGroup] = []

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

    private func getInitialSnapshot(with circles: [CircleGroup]) -> NSDiffableDataSourceSnapshot<CirclesCollectionViewDataSource.SectionType,
                                                                      CirclesCollectionViewDataSource.ItemType> {
        var snapshot = self.dataSource.snapshot()

        let allCases = CirclesCollectionViewDataSource.SectionType.allCases
        snapshot.appendSections(allCases)
        allCases.forEach { (section) in
            let items: [CirclesCollectionViewDataSource.ItemType] = circles.map { group in
                return .circles(group)
            }
            snapshot.appendItems(items, toSection: section)
        }

        return snapshot
    }
}

extension CirclesViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let identifier = self.dataSource.itemIdentifier(for: indexPath) else { return }

        self.delegate?.circlesView(self, didSelect: identifier)
    }
}
