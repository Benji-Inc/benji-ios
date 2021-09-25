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
    func peopleView(_ controller: PeopleViewController, didSelect items: [PeopleCollectionViewDataSource.ItemType])
}

class PeopleViewController: BlurredViewController {

    weak var delegate: PeopleViewControllerDelegate?

    // MARK: - UI

    var collectionView = CollectionView(layout: PeopleCollectionViewLayout())
    lazy var dataSource = PeopleCollectionViewDataSource(collectionView: self.collectionView)

    var selectedItems: [PeopleCollectionViewDataSource.ItemType] {
        return self.collectionView.indexPathsForSelectedItems?.compactMap({ ip in
            return self.dataSource.itemIdentifier(for: ip)
        }) ?? []
    }

    private let includedSections: [PeopleCollectionViewDataSource.SectionType]

    let button = Button()

    init(includedSections: [PeopleCollectionViewDataSource.SectionType] = [.connections, .contacts]) {
        self.includedSections = includedSections
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.collectionView)
        self.collectionView.delegate = self

        self.view.addSubview(self.button)
        self.button.set(style: .normal(color: .purple, text: "Add"))

        self.button.didSelect { [unowned self] in
            self.delegate?.peopleView(self, didSelect: self.selectedItems)
        }

        self.collectionView.publisher(for: \.indexPathsForSelectedItems)
            .removeDuplicates()
            .mainSink { _ in
            self.updateButton()
        }.store(in: &self.cancellables)
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

        self.button.setSize(with: self.view.width)
        self.button.pinToSafeArea(.bottom, padding: Theme.contentOffset)
    }

    private func updateButton() {

        let transform: CGAffineTransform
        if self.selectedItems.count == 0 {
            transform = CGAffineTransform.init(translationX: 0, y: 100)
        } else {
            transform = .identity
        }

        self.button.set(style: .normal(color: .purple, text: "Add \(self.selectedItems.count)"))

        UIView.animate(withDuration: Theme.animationDuration) {
            self.button.transform = transform
        }
    }

    // MARK: Data Loading

    @MainActor
    func loadData() async {

        self.collectionView.animationView.play()

        guard !Task.isCancelled else {
            self.collectionView.animationView.stop()
            return
        }

        var connections: [Connection] = []
        if self.includedSections.contains(.connections) {
            do {
                connections = try await GetAllConnections().makeRequest(andUpdate: [], viewsToIgnore: []).filter { (connection) -> Bool in
                    return !connection.nonMeUser.isNil
                }
            } catch {
                print(error)
            }
        }

        var contacts: [CNContact] = []
        if self.includedSections.contains(.contacts) {
            contacts = await ContactsManger.shared.fetchContacts()
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


                                                                          snapshot.appendSections(self.includedSections)
                                                                          self.includedSections.forEach { (section) in
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
