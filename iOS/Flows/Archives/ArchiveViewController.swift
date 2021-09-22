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

    lazy var segmentedControl: UISegmentedControl = {
        let actions: [UIAction] = Scope.allCases.map { scope in
            return UIAction.init(title: localized(scope.title)) { action in
                self.loadQuery(with: scope)
            }
        }

        let control = UISegmentedControl.init(frame: .zero, actions: actions)
        control.backgroundColor = Color.background2.color.withAlphaComponent(0.8)
        return control
    }()

    enum Scope: Int, CaseIterable {
        case recents
        case dms
        case groups

        var title: Localized {
            switch self {
            case .recents:
                return "Recents"
            case .dms:
                return "DMs"
            case .groups:
                return "Groups"
            }
        }
    }

    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.collectionView)
        self.collectionView.delegate = self

        self.view.addSubview(self.segmentedControl)
        self.segmentedControl.selectedSegmentIndex = 0
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.loadQuery(with: .recents)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.collectionView.expandToSuperviewSize()

        self.segmentedControl.width = self.view.width - Theme.contentOffset.doubled
        self.segmentedControl.centerOnX()
        self.segmentedControl.height = 44
        self.segmentedControl.pinToSafeArea(.bottom, padding: Theme.contentOffset)
    }

    // MARK: Data Loading

    func loadQuery(with scope: Scope) {
        guard let userId = User.current()?.objectId else { return }

        var query: ChannelListQuery? = nil

        switch scope {
        case .recents:
            query = ChannelListQuery(filter: .containMembers(userIds: [userId]),
                                         sort: [.init(key: .lastMessageAt, isAscending: false)],
                                         pageSize: 20)
        case .dms:
            query = ChannelListQuery(filter: .and([.containMembers(userIds: [userId]), .lessOrEqual(.memberCount, than: 2)]),
                                         sort: [.init(key: .lastMessageAt, isAscending: false)],
                                         pageSize: 20)
        case .groups:
            query = ChannelListQuery(filter: .and([.containMembers(userIds: [userId]), .greaterOrEqual(.memberCount, than: 3)]),
                                         sort: [.init(key: .lastMessageAt, isAscending: false)],
                                         pageSize: 20)
        }




        guard let q = query else { return }

        Task {
            await self.loadData(with: q)
        }.add(to: self.taskPool)
    }

    @MainActor
    func loadData(with query: ChannelListQuery) async {

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
                                                                          snapshot.deleteAllItems()
                                                                          
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
