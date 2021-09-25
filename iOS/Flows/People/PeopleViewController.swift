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
import TMROLocalization

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

    private let includeConnections: Bool
    private(set) var reservations: [Reservation] = []
    let button = Button()

    init(includeConnections: Bool = true) {
        self.includeConnections = includeConnections
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        self.dataSource.headerTitle = self.getHeaderTitle()
        self.dataSource.headerDescription = self.getHeaderDescription()

        self.collectionView.allowsMultipleSelection = true

        self.view.addSubview(self.collectionView)
        self.collectionView.delegate = self

        self.view.addSubview(self.button)

        self.button.didSelect { [unowned self] in
            self.delegate?.peopleView(self, didSelect: self.selectedItems)
        }
        self.updateButton()
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
        self.button.centerOnX()
    }

    func updateButton() {

        self.button.set(style: .normal(color: .purple, text: self.getButtonTitle()))

        UIView.animate(withDuration: Theme.animationDuration) {

            if self.selectedItems.count == 0 {
                self.button.top = self.view.height
            } else {
                self.button.pinToSafeArea(.bottom, padding: Theme.contentOffset)
            }

            self.view.layoutNow()
        }
    }

    func getHeaderTitle() -> Localized {
        return "Add People"
    }

    func getHeaderDescription() -> Localized {
        return "Tap anyone below to add/invite them to the conversation."
    }

    func getButtonTitle() -> Localized {
        return "Add \(self.selectedItems.count)"
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
        if self.includeConnections {
            do {
                connections = try await GetAllConnections().makeRequest(andUpdate: [], viewsToIgnore: []).filter { (connection) -> Bool in
                    return !connection.nonMeUser.isNil
                }
            } catch {
                print(error)
            }
        }

        let contacts = await ContactsManger.shared.fetchContacts()
        await self.loadUnclaimedReservations()

        let cycle = AnimationCycle(inFromPosition: .inward,
                                   outToPosition: .inward,
                                   shouldConcatenate: true,
                                   scrollToEnd: false)

        let snapshot = self.getInitialSnapshot(withConnecitons: connections, and: contacts)
        await self.dataSource.apply(snapshot, collectionView: self.collectionView, animationCycle: cycle)

        self.collectionView.animationView.stop()
    }

    private func loadUnclaimedReservations() async {

        let query = Reservation.query()
        query?.whereKey(ReservationKey.createdBy.rawValue, equalTo: User.current()!)
        query?.whereKey(ReservationKey.isClaimed.rawValue, equalTo: false)
        do {
            let objects = try await query?.findObjectsInBackground()
            if let reservations = objects as? [Reservation] {
                self.reservations = reservations
            }
        } catch {
            logDebug(error)
        }
    }

    private func getInitialSnapshot(withConnecitons connections: [Connection],
                                    and contacts: [CNContact]) -> NSDiffableDataSourceSnapshot<PeopleCollectionViewDataSource.SectionType,
                                                                      PeopleCollectionViewDataSource.ItemType> {
        var snapshot = self.dataSource.snapshot()
                                                                          snapshot.deleteAllItems()
                                                                          let allSections = PeopleCollectionViewDataSource.SectionType.allCases


                                                                          snapshot.appendSections(allSections)
                                                                          allSections.forEach { (section) in
            switch section {
            case .connections:
                guard self.includeConnections else { return }
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
