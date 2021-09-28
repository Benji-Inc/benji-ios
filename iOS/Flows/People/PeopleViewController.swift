//
//  PeopleViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat
import Contacts
import TMROLocalization

// Create contactItem
// Implement contactItem
// Show contacts that have/have not been invited
// Combine reservations/people coordinator
// Cycle through invites then connections when adding to channel

protocol PeopleViewControllerDelegate: AnyObject {
    func peopleView(_ controller: PeopleViewController, didSelect items: [PeopleCollectionViewDataSource.ItemType])
}

class PeopleViewController: DiffableCollectionViewController<PeopleCollectionViewDataSource.SectionType, PeopleCollectionViewDataSource.ItemType, PeopleCollectionViewDataSource> {

    weak var delegate: PeopleViewControllerDelegate?

    private let includeConnections: Bool
    private(set) var reservations: [Reservation] = []

    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))

    let button = Button()

    init(includeConnections: Bool = true) {
        self.includeConnections = includeConnections
        super.init(with: CollectionView(layout: PeopleCollectionViewLayout()))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(collectionView: UICollectionView) {
        fatalError("init(collectionView:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        self.view.insertSubview(self.blurView, belowSubview: self.collectionView)

        self.dataSource.headerTitle = self.getHeaderTitle()
        self.dataSource.headerDescription = self.getHeaderDescription()

        self.view.addSubview(self.button)

        self.button.didSelect { [unowned self] in
            self.delegate?.peopleView(self, didSelect: self.selectedItems)
        }

        self.$selectedItems.mainSink { _ in
            self.updateButton()
        }.store(in: &self.cancellables)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.blurView.expandToSuperviewSize()

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

    override func retrieveDataForSnapshot() async -> [PeopleCollectionViewDataSource.SectionType: [PeopleCollectionViewDataSource.ItemType]] {

        var data: [PeopleCollectionViewDataSource.SectionType: [PeopleCollectionViewDataSource.ItemType]] = [:]

        if self.includeConnections {
            do {
                data[.connections] = try await GetAllConnections().makeRequest(andUpdate: [], viewsToIgnore: []).filter { (connection) -> Bool in
                    return !connection.nonMeUser.isNil
                }.map({ connection in
                    return .connection(connection)
                })
            } catch {
                print(error)
            }
        } else {
            data[.connections] = []
        }

        await self.loadUnclaimedReservations()

        data[.contacts] = await ContactsManger.shared.fetchContacts().map({ contact in
            let reservation = self.reservations.first { reservation in
                return reservation.contactId == contact.identifier
            }

            let item = Contact(with: contact, reservation: reservation)
            return .contact(item)
        })

        return data
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
}
