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
    func homeViewControllerDidSelect(item: HomeCollectionViewDataSource.ItemType)
}

class HomeViewController: ViewController {

    weak var delegate: HomeViewControllerDelegate?

    // MARK: - UI

    private lazy var dataSource = HomeCollectionViewDataSource(collectionView: self.collectionView)
    private var collectionView = CollectionView(layout: HomeCollectionViewLayout())

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

        self.collectionView.delegate = self
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
        async let initialSyncFinished: Void = ConversationSupplier.shared.waitForInitialSync()
        async let noticesLoaded: Void = NoticeSupplier.shared.loadNotices()

        let _ = await (initialSyncFinished, noticesLoaded)

        self.dataSource.unclaimedCount = await unclaimedReservationCount
        
        let cycle = AnimationCycle(inFromPosition: .inward,
                                   outToPosition: .inward,
                                   shouldConcatenate: true,
                                   scrollToEnd: false)

        let snapshot = self.getInitialSnapshot()
        await self.dataSource.apply(snapshot, collectionView: self.collectionView, animationCycle: cycle)

        self.collectionView.animationView.stop()
    }

    private func getInitialSnapshot() -> NSDiffableDataSourceSnapshot<HomeCollectionViewDataSource.SectionType,
                                                                      HomeCollectionViewDataSource.ItemType> {
        var snapshot = self.dataSource.snapshot()

        let allCases = HomeCollectionViewDataSource.SectionType.allCases
        snapshot.appendSections(allCases)
        allCases.forEach { (section) in
            snapshot.appendItems(self.getItems(for: section), toSection: section)
        }

        return snapshot
    }

    private func getItems(for section: HomeCollectionViewDataSource.SectionType)
    -> [HomeCollectionViewDataSource.ItemType] {

        switch section {
        case .notices:
            return NoticeSupplier.shared.notices.map { notice in
                return .notice(notice)
            }
        case .channels:
            return ConversationSupplier.shared.allConversationsSorted.map { channel in
                return .channel(channel)
            }
        }
    }
}

extension HomeViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let identifier = self.dataSource.itemIdentifier(for: indexPath) else { return }

        self.delegate?.homeViewControllerDidSelect(item: identifier)
    }

    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? {

        guard let channel = ConversationSupplier.shared.allConversationsSorted[safe: indexPath.row],
              let cell = collectionView.cellForItem(at: indexPath) as? ConversationCell else { return nil }

        return UIContextMenuConfiguration(identifier: nil, previewProvider: {
            return ConversationPreviewViewController(with: channel, size: cell.size)
        }, actionProvider: { suggestedActions in
            if channel.isFromCurrentUser {
                return self.makeCurrentUserMenu(for: channel, at: indexPath)
            } else {
                return self.makeNonCurrentUserMenu(for: channel, at: indexPath)
            }
        })
    }

    func makeCurrentUserMenu(for channel: DisplayableConversation, at indexPath: IndexPath) -> UIMenu {
        let neverMind = UIAction(title: "Never Mind", image: UIImage(systemName: "nosign")) { _ in }

        let confirm = UIAction(title: "Confirm",
                               image: UIImage(systemName: "trash"),
                               attributes: .destructive) { action in

            switch channel.channelType {
            case .system(_):
                break
            case .pending(_):
                break
            case .channel(let tchConversation):
                Task {
                    do {
                        try await ConversationSupplier.shared.delete(channel: tchConversation)
                    } catch {
                        logDebug(error)
                    }
                }
            }
        }

        let deleteMenu = UIMenu(title: "Delete",
                                image: UIImage(systemName: "trash"),
                                options: .destructive,
                                children: [confirm, neverMind])

        let open = UIAction(title: "Open", image: UIImage(systemName: "arrowshape.turn.up.right")) { [unowned self] _ in
            guard let identifier = self.dataSource.itemIdentifier(for: indexPath) else { return }
            self.delegate?.homeViewControllerDidSelect(item: identifier)
        }

        // Create and return a UIMenu with the share action
        return UIMenu(title: "Options", children: [open, deleteMenu])
    }

    func makeNonCurrentUserMenu(for channel: DisplayableConversation, at indexPath: IndexPath) -> UIMenu {

        let neverMind = UIAction(title: "Never Mind", image: UIImage(systemName: "nosign")) { _ in }

        let confirm = UIAction(title: "Confirm",
                               image: UIImage(systemName: "clear"),
                               attributes: .destructive) { action in

            switch channel.channelType {
            case .system(_):
                break
            case .pending(_):
                break
            case .channel(let tchConversation):
                Task {
                    do {
                        try await ConversationSupplier.shared.delete(channel: tchConversation)
                    } catch {
                        logDebug(error)
                    }
                }
            }
        }

        let deleteMenu = UIMenu(title: "Leave",
                                image: UIImage(systemName: "clear"),
                                options: .destructive,
                                children: [confirm, neverMind])

        let open = UIAction(title: "Open", image: UIImage(systemName: "arrowshape.turn.up.right")) { [unowned self] _ in
            guard let item = self.dataSource.itemIdentifier(for: indexPath) else { return }
            self.delegate?.homeViewControllerDidSelect(item: item)
        }

        // Create and return a UIMenu with the share action
        return UIMenu(title: "Options", children: [open, deleteMenu])
    }
}

extension HomeViewController: TransitionableViewController {
    var receivingPresentationType: TransitionType {
        return .home
    }

    var transitionColor: Color {
        return .background1
    }
}
