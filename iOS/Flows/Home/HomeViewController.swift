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

    private lazy var dataSource = HomeCollectionViewDataSource(collectionView: self.collectionView)
    private var collectionView = CollectionView(layout: HomeCollectionViewLayout.layout)

    let addButton = Button()

    // MARK: - Lifecycle

    override func initializeViews() {
        super.initializeViews()

        self.view.set(backgroundColor: .background1)

        self.view.addSubview(self.collectionView)

        self.view.addSubview(self.addButton)
        self.addButton.set(style: .icon(image: UIImage(systemName: "plus")!, color: .lightPurple))
        self.addButton.addAction(for: .touchUpInside) { [unowned self] in
            self.delegate?.homeViewControllerDidTapAdd(self)
        }

        self.dataSource.didSelectReservations = { [unowned self] in
            self.delegate?.homeViewControllerDidTapAdd(self)
        }
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

        self.dataSource.unclaimedCount = await unclaimedReservationCount
        
        let cycle = AnimationCycle(inFromPosition: .inward,
                                   outToPosition: .inward,
                                   shouldConcatenate: true,
                                   scrollToEnd: false)

        let snapshot = self.getInitialSnapshot()
        await self.dataSource.apply(snapshot, animationCycle: cycle)

        self.collectionView.animationView.stop()
    }

    private func getInitialSnapshot() -> NSDiffableDataSourceSnapshot<HomeCollectionViewDataSource.SectionType,
                                                                      AnyHashable> {
        var snapshot = self.dataSource.snapshot()

        let allCases = HomeCollectionViewDataSource.SectionType.allCases
        snapshot.appendSections(allCases)
        allCases.forEach { (section) in
            snapshot.appendItems(self.getItems(for: section), toSection: section)
        }

        return snapshot
    }

    private func getItems(for section: HomeCollectionViewDataSource.SectionType) -> [AnyHashable] {
        switch section {
        case .notices:
            return NoticeSupplier.shared.notices
        case .channels:
            return ChannelSupplier.shared.allChannelsSorted
        }
    }
}
