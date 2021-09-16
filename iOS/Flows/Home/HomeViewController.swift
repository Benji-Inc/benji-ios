//
//  CenterViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 12/27/18.
//  Copyright © 2018 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import StreamChat

protocol HomeViewControllerDelegate: AnyObject {
    func homeViewControllerDidSelect(item: HomeCollectionViewDataSource.ItemType)
}

class HomeViewController: ViewController {

    weak var delegate: HomeViewControllerDelegate?

    // MARK: - UI

    private lazy var dataSource = HomeCollectionViewDataSource(collectionView: self.collectionView)
    private var collectionView = CollectionView(layout: HomeCollectionViewLayout())

    let addButton = Button()
    let circlesButton = Button()
    let archiveButton = Button()

    var didTapAdd: CompletionOptional = nil
    var didTapCircles: CompletionOptional = nil
    var didTapArchive: CompletionOptional = nil

    // MARK: - Lifecycle

    override func initializeViews() {
        super.initializeViews()

        self.view.set(backgroundColor: .background1)

        self.view.addSubview(self.collectionView)

        self.view.addSubview(self.addButton)
        self.addButton.set(style: .icon(image: UIImage(systemName: "plus")!, color: .lightPurple))
        self.addButton.addAction(for: .touchUpInside) { [unowned self] in
            self.didTapAdd?()
        }

        self.view.addSubview(self.circlesButton)
        self.circlesButton.set(style: .icon(image: UIImage(systemName: "circles.hexagongrid")!, color: .lightPurple))
        self.circlesButton.addAction(for: .touchUpInside) { [unowned self] in
            self.didTapCircles?()
        }

        self.view.addSubview(self.archiveButton)
        self.archiveButton.set(style: .icon(image: UIImage(systemName: "message")!, color: .lightPurple))
        self.archiveButton.addAction(for: .touchUpInside) { [unowned self] in
            self.didTapArchive?()
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

        self.addButton.squaredSize = 60
        self.addButton.makeRound()
        self.addButton.centerOnX()
        self.addButton.pinToSafeArea(.bottom, padding: Theme.contentOffset)

        self.circlesButton.squaredSize = 60
        self.circlesButton.makeRound()
        self.circlesButton.match(.right, to: .left, of: self.addButton, offset: -Theme.contentOffset.doubled)
        self.circlesButton.pinToSafeArea(.bottom, padding: Theme.contentOffset)

        self.archiveButton.squaredSize = 60
        self.archiveButton.makeRound()
        self.archiveButton.match(.left, to: .right, of: self.addButton, offset: Theme.contentOffset.doubled)
        self.archiveButton.pinToSafeArea(.bottom, padding: Theme.contentOffset)

        self.collectionView.expandToSuperviewSize()
        self.collectionView.match(.bottom, to: .top, of: self.circlesButton, offset: -Theme.contentOffset)
    }

    // MARK: Data Loading

    @MainActor
    private func loadData() async {
        self.collectionView.animationView.play()

//        let userID = User.current()!.userObjectID!
//        let query = ChannelListQuery(filter: .containMembers(userIds: [userID]),
//                                     sort: [.init(key: .lastMessageAt, isAscending: false)])
//
//        self.channelListController = try? await ChatClient.shared.queryChannels(query: query)

        await NoticeSupplier.shared.loadNotices()

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
        }
    }
}

extension HomeViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let identifier = self.dataSource.itemIdentifier(for: indexPath) else { return }

        self.delegate?.homeViewControllerDidSelect(item: identifier)
    }

//    func collectionView(_ collectionView: UICollectionView,
//                        contextMenuConfigurationForItemAt indexPath: IndexPath,
//                        point: CGPoint) -> UIContextMenuConfiguration? {
//
//        return nil
////        let conversation = chatClient.channelListController(query: )
////        guard let conversation = ConversationSupplier.shared.allConversationsSorted[safe: indexPath.row],
////              let cell = collectionView.cellForItem(at: indexPath) as? ConversationCell else { return nil }
////
////        return UIContextMenuConfiguration(identifier: nil, previewProvider: {
////            return ConversationPreviewViewController(with: conversation, size: cell.size)
////        }, actionProvider: { suggestedActions in
////            if conversation.isFromCurrentUser {
////                return self.makeCurrentUserMenu(for: conversation, at: indexPath)
////            } else {
////                return self.makeNonCurrentUserMenu(for: conversation, at: indexPath)
////            }
////        })
//    }
//
//    func makeCurrentUserMenu(for conversation: DisplayableConversation, at indexPath: IndexPath) -> UIMenu {
//        let neverMind = UIAction(title: "Never Mind", image: UIImage(systemName: "nosign")) { _ in }
//
//        let confirm = UIAction(title: "Confirm",
//                               image: UIImage(systemName: "trash"),
//                               attributes: .destructive) { action in
//
//            switch conversation.conversationType {
//            case .system(_):
//                break
//            case .conversation(let conversation):
//                Task {
//                    do {
//                        try await ChatClient.shared.deleteChannel(conversation)
//                    } catch {
//                        logDebug(error)
//                    }
//                }
//            }
//        }
//
//        let deleteMenu = UIMenu(title: "Delete",
//                                image: UIImage(systemName: "trash"),
//                                options: .destructive,
//                                children: [confirm, neverMind])
//
//        let open = UIAction(title: "Open", image: UIImage(systemName: "arrowshape.turn.up.right")) { [unowned self] _ in
//            guard let identifier = self.dataSource.itemIdentifier(for: indexPath) else { return }
//            self.delegate?.homeViewControllerDidSelect(item: identifier)
//        }
//
//        // Create and return a UIMenu with the share action
//        return UIMenu(title: "Options", children: [open, deleteMenu])
//    }
//
//    func makeNonCurrentUserMenu(for conversation: DisplayableConversation, at indexPath: IndexPath) -> UIMenu {
//
//        let neverMind = UIAction(title: "Never Mind", image: UIImage(systemName: "nosign")) { _ in }
//
//        let confirm = UIAction(title: "Confirm",
//                               image: UIImage(systemName: "clear"),
//                               attributes: .destructive) { action in
//
//            switch conversation.conversationType {
//            case .system(_):
//                break
//            case .conversation(let conversation):
//                Task {
//                    do {
//                        try await ChatClient.shared.deleteChannel(conversation)
//                    } catch {
//                        logDebug(error)
//                    }
//                }
//            }
//        }
//
//        let deleteMenu = UIMenu(title: "Leave",
//                                image: UIImage(systemName: "clear"),
//                                options: .destructive,
//                                children: [confirm, neverMind])
//
//        let open = UIAction(title: "Open", image: UIImage(systemName: "arrowshape.turn.up.right")) { [unowned self] _ in
//            guard let item = self.dataSource.itemIdentifier(for: indexPath) else { return }
//            self.delegate?.homeViewControllerDidSelect(item: item)
//        }
//
//        // Create and return a UIMenu with the share action
//        return UIMenu(title: "Options", children: [open, deleteMenu])
//    }
}

extension HomeViewController: TransitionableViewController {
    var receivingPresentationType: TransitionType {
        return .home
    }

    var transitionColor: Color {
        return .background1
    }
}
