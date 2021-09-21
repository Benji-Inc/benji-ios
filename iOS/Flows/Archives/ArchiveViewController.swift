//
//  ArchiveViewController.swift
//  ArchiveViewController
//
//  Created by Benji Dodgson on 9/16/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat
import TMROLocalization

protocol ArchiveViewControllerDelegate: AnyObject {
    func archiveView(_ controller: ArchiveViewController, didSelect item: ArchiveCollectionViewDataSource.ItemType)
}

class ArchiveViewController: BlurredViewController {

    weak var delegate: ArchiveViewControllerDelegate?

    // MARK: - UI

    private var collectionView = CollectionView(layout: ArchiveCollectionViewLayout())
    lazy var dataSource = ArchiveCollectionViewDataSource(collectionView: self.collectionView)

    private(set) var channelListController: ChatChannelListController?

    // Custom Input Accessory View
    lazy var searchInputAccessoryView = SearchInputAccessoryView()

    lazy var initialQuery: ChannelListQuery = {
        let userID = User.current()!.userObjectID!
        let query = ChannelListQuery(filter: .containMembers(userIds: [userID]),
                                     sort: [.init(key: .lastMessageAt, isAscending: false)],
                                     pageSize: 20)
        return query
    }()

    override var inputAccessoryView: UIView? {
        return self.searchInputAccessoryView
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.collectionView)

        self.collectionView.delegate = self
        self.searchInputAccessoryView.searchBar.delegate = self 
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        Task {
            await self.loadData(with: self.initialQuery)
        }.add(to: self.taskPool)

        self.collectionView.onDoubleTap { [unowned self] _ in
            if self.searchInputAccessoryView.searchBar.isFirstResponder {
                self.searchInputAccessoryView.searchBar.resignFirstResponder()
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.resignFirstResponder()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.collectionView.expandToSuperviewSize()
    }

    // MARK: Data Loading

    @MainActor
    func loadData(with query: ChannelListQuery) async {

        await self.taskPool.cancelAndRemoveAll()

        self.collectionView.animationView.play()

        let controller = try? await ChatClient.shared.queryChannels(query: query)

        guard !Task.isCancelled else {
            self.collectionView.animationView.stop()
            return
        }

        self.channelListController = controller

        let cycle = AnimationCycle(inFromPosition: .inward,
                                   outToPosition: .inward,
                                   shouldConcatenate: true,
                                   scrollToEnd: false)

        let snapshot = self.getInitialSnapshot()
        await self.dataSource.apply(snapshot, collectionView: self.collectionView, animationCycle: cycle)

        self.collectionView.animationView.stop()
    }

    private func getInitialSnapshot() -> NSDiffableDataSourceSnapshot<ArchiveCollectionViewDataSource.SectionType,
                                                                      ArchiveCollectionViewDataSource.ItemType> {
        var snapshot = self.dataSource.snapshot()

        let allCases = ArchiveCollectionViewDataSource.SectionType.allCases
        snapshot.appendSections(allCases)
        allCases.forEach { (section) in
            snapshot.appendItems(self.getItems(for: section), toSection: section)
        }

        return snapshot
    }

    private func getItems(for section: ArchiveCollectionViewDataSource.SectionType)
    -> [ArchiveCollectionViewDataSource.ItemType] {

        switch section {
        case .conversations:
            guard let channels = self.channelListController?.channels else { return [] }
            return channels.map { conversation in
                return .conversation(conversation)
            }
        }
    }
}
