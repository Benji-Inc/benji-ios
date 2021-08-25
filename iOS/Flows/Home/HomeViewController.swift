//
//  CenterViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 12/27/18.
//  Copyright © 2018 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse

protocol HomeViewControllerDelegate: AnyObject {
    func homeViewControllerDidTapAdd(_ controller: HomeViewController)
    func homeViewControllerDidSelectReservations(_ controller: HomeViewController)
    func homeViewControllerDidSelect(section: HomeCollectionViewManager.SectionType, item: AnyHashable)
}

class HomeViewController: ViewController, TransitionableViewController {

    weak var delegate: HomeViewControllerDelegate?

    // MARK: - TransitionableViewController

    var receivingPresentationType: TransitionType {
        return .home
    }

    var transitionColor: Color {
        return .background1
    }

    // MARK: - UI

    private var unclaimedCount: Int = 0

    let dataCreator = HomeCollectionViewDataSourceCreator()
    private lazy var dataSource = self.dataCreator.createDataSource(for: self.collectionView)
    private var collectionView = CollectionView(layout: HomeCollectionViewLayout.layout)

    let addButton = Button()

    // MARK: - Lifecycle

    override func initializeViews() {
        super.initializeViews()

        self.view.set(backgroundColor: .background1)

        self.view.addSubview(self.collectionView)

        self.view.addSubview(self.addButton)
        self.addButton.set(style: .icon(image: UIImage(systemName: "plus")!, color: .lightPurple))
    }

    override func viewWasPresented() {
        super.viewWasPresented()

        Task {
            await self.loadData()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.collectionView.expandToSuperviewSize()

        self.addButton.squaredSize = 60
        self.addButton.makeRound()
        self.addButton.centerOnX()
        self.addButton.pinToSafeArea(.bottom, padding: Theme.contentOffset)
    }

    // MARK: Data Loading

    @MainActor
    private func loadData() async {
        self.collectionView.animationView.play()

        async let unclaimedReservationCount = Reservation.getUnclaimedReservationCount(for: User.current()!)
        async let initialSyncFinished: Void = ChannelSupplier.shared.waitForInitialSync()
        async let noticesLoaded: Void = NoticeSupplier.shared.loadNotices()

        let _ = await (initialSyncFinished, noticesLoaded)

        self.unclaimedCount = await unclaimedReservationCount
        let cycle = AnimationCycle(inFromPosition: .inward,
                                   outToPosition: .inward,
                                   shouldConcatenate: true,
                                   scrollToEnd: false)

        await self.loadSnapshot(animationCycle: cycle)

        self.collectionView.animationView.stop()

        await Task.sleep(seconds: 1)
    }

    private func loadSnapshot(animationCycle: AnimationCycle? = nil, animatingDifferences: Bool = false) async {
        let snapshot = self.getInitialSnapshot()

        if let cycle = animationCycle {
            await self.collectionView.animateOut(position: cycle.outToPosition, concatenate: cycle.shouldConcatenate)

            await self.dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
            await self.collectionView.animateIn(position: cycle.inFromPosition,
                                                concatenate: cycle.shouldConcatenate)
        } else {
            await self.dataSource.apply(snapshot, animatingDifferences: false)
        }
    }

    private func getInitialSnapshot() -> NSDiffableDataSourceSnapshot<HomeCollectionViewManager.SectionType, AnyHashable> {
        var snapshot = self.dataSource.snapshot()

        let allCases = HomeCollectionViewManager.SectionType.allCases
        snapshot.appendSections(allCases)
        allCases.forEach { (section) in
            snapshot.appendItems(self.getItems(for: section), toSection: section)
        }

        return snapshot
    }

    private func getItems(for section: HomeCollectionViewManager.SectionType) -> [AnyHashable] {
        switch section {
        case .notices:
            return NoticeSupplier.shared.notices
        case .channels:
            return ChannelSupplier.shared.allChannelsSorted
        }
    }
}
