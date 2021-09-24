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

        guard !Task.isCancelled else {
            self.collectionView.animationView.stop()
            return
        }

        let contacts = await ContactsManger.shared.fetchContacts()
        var connections: [Connection] = []
        do {
            connections = try await GetAllConnections().makeRequest(andUpdate: [], viewsToIgnore: []).filter { (connection) -> Bool in
                return !connection.nonMeUser.isNil
            }
        } catch {
            print(error)
        }

        let cycle = AnimationCycle(inFromPosition: .inward,
                                   outToPosition: .inward,
                                   shouldConcatenate: true,
                                   scrollToEnd: false)

        let snapshot = self.getInitialSnapshot(withConnecitons: connections, and: contacts)
        await self.dataSource.apply(snapshot, collectionView: self.collectionView, animationCycle: cycle)

        self.collectionView.animationView.stop()
    }

    private func getInitialSnapshot(withConnecitons connections: [Connection],
                                    and contacts: [CNContact]) -> NSDiffableDataSourceSnapshot<PeopleCollectionViewDataSource.SectionType,
                                                                      PeopleCollectionViewDataSource.ItemType> {
        var snapshot = self.dataSource.snapshot()
                                                                          snapshot.deleteAllItems()

        let allCases = PeopleCollectionViewDataSource.SectionType.allCases
        snapshot.appendSections(allCases)
        allCases.forEach { (section) in
            switch section {
            case .connections:
                let items: [PeopleCollectionViewDataSource.ItemType] = connections.map { connection in
                    return .connection(connection)
                }
                snapshot.appendItems(items, toSection: section)
            case .contacts:
                let items: [PeopleCollectionViewDataSource.ItemType] = contacts.map { contact in
                    return .contact(contact)
                }
                snapshot.appendItems(items, toSection: section)
            }
        }

        return snapshot
    }
}
