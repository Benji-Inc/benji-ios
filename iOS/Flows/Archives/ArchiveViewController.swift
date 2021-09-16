//
//  ArchiveViewController.swift
//  ArchiveViewController
//
//  Created by Benji Dodgson on 9/16/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

protocol ArchiveViewControllerDelegate: class {
    func archiveView(_ controller: ArchiveViewController, didSelect item: ArchiveCollectionViewDataSource.ItemType)
}

class ArchiveViewController: ViewController {

    weak var delegate: ArchiveViewControllerDelegate?

    // MARK: - UI

    private var collectionView = CollectionView(layout: ArchiveCollectionViewLayout())
    lazy var dataSource = ArchiveCollectionViewDataSource(collectionView: self.collectionView)

    private var channelListController: ChatChannelListController?

    override func initializeViews() {
        super.initializeViews()

        self.view.set(backgroundColor: .background1)

        self.view.addSubview(self.collectionView)

        self.collectionView.delegate = self 
    }

    override func viewWasPresented() {
        super.viewWasPresented()

        Task {
            await self.loadData()
        }
    }

    // MARK: Data Loading

    @MainActor
    private func loadData() async {
        self.collectionView.animationView.play()

        let userID = User.current()!.userObjectID!
        let query = ChannelListQuery(filter: .containMembers(userIds: [userID]),
                                     sort: [.init(key: .lastMessageAt, isAscending: false)])

        self.channelListController = try? await ChatClient.shared.queryChannels(query: query)

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
            guard let channelListController = self.channelListController else { return [] }
            return channelListController.channels.map { chatChannel in
                return .conversation(DisplayableConversation(conversationType: .conversation(chatChannel)))
            }
        }
    }
}
