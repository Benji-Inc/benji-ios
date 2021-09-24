//
//  NewConversationViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat
import Contacts

protocol PeopleViewControllerDelegate: AnyObject {
    func peopleView(_ controller: PeopleViewController, didSelect item: PeopleCollectionViewDataSource.ItemType)
}

class PeopleViewController: BlurredViewController {

    weak var delegate: PeopleViewControllerDelegate?

    // MARK: - UI

    private var collectionView = CollectionView(layout: PeopleCollectionViewLayout())
    lazy var dataSource = PeopleCollectionViewDataSource(collectionView: self.collectionView)

    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.collectionView)
        self.collectionView.delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        Task {
            await self.loadData()
        }.add(to: self.taskPool)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.collectionView.expandToSuperviewSize()
    }

    // MARK: Data Loading

    @MainActor
    func loadData() async {

        self.collectionView.animationView.play()

        // load connections
        // load contacts

        //let controller = try? await ChatClient.shared.queryChannels(query: query)

        guard !Task.isCancelled else {
            self.collectionView.animationView.stop()
            return
        }

        //self.channelListController = controller

        let cycle = AnimationCycle(inFromPosition: .inward,
                                   outToPosition: .inward,
                                   shouldConcatenate: true,
                                   scrollToEnd: false)

        let snapshot = self.getInitialSnapshot()
        await self.dataSource.apply(snapshot, collectionView: self.collectionView, animationCycle: cycle)

        self.collectionView.animationView.stop()
    }

    private func getInitialSnapshot() -> NSDiffableDataSourceSnapshot<PeopleCollectionViewDataSource.SectionType,
                                                                      PeopleCollectionViewDataSource.ItemType> {
        var snapshot = self.dataSource.snapshot()
                                                                          snapshot.deleteAllItems()

        let allCases = PeopleCollectionViewDataSource.SectionType.allCases
        snapshot.appendSections(allCases)
        allCases.forEach { (section) in
            snapshot.appendItems(self.getItems(for: section), toSection: section)
        }

        return snapshot
    }

    private func getItems(for section: PeopleCollectionViewDataSource.SectionType)
    -> [PeopleCollectionViewDataSource.ItemType] {

        switch section {
        case .connections:
            return []
        case .contacts:
            return []
        }
    }
}
