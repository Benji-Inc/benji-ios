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
import UIKit
import Localization

class PeopleViewController: DiffableCollectionViewController<PeopleCollectionViewDataSource.SectionType,
                            PeopleCollectionViewDataSource.ItemType,
                            PeopleCollectionViewDataSource> {

    typealias PeopleSection = PeopleCollectionViewDataSource.SectionType
    typealias PersonItem = PeopleCollectionViewDataSource.ItemType

    let leftItem = UIBarButtonItem(title: "Invites Left", image: nil, primaryAction: nil, menu: nil)

    private(set) var reservations: [Reservation] = []
    
    let button = ThemeButton()
    private let loadingView = InvitationLoadingView()
    private var showButton: Bool = true
    
    private(set) var allPeople: [Person] = []
    
    @Published var selectedPeople: [Person] = []
    
    init() {
        let cv = CollectionView(layout: PeopleCollectionViewLayout())
        cv.keyboardDismissMode = .interactive
        cv.isScrollEnabled = true
        cv.allowsMultipleSelection = true
        super.init(with: cv)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(collectionView: UICollectionView) {
        fatalError("init(collectionView:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()
        
        self.view.set(backgroundColor: .B0)
                
        self.setupNavigationBar()

        self.view.addSubview(self.button)
        
        KeyboardManager.shared.$cachedKeyboardEndFrame.mainSink { [unowned self]  _ in
            self.view.setNeedsLayout()
        }.store(in: &self.cancellables)
    }
    
    private func setupNavigationBar() {
        self.navigationItem.title = "Contacts"

        self.leftItem.tintColor = ThemeColor.D1.color
        
        let cancel = UIAction { _ in
            self.dismiss(animated: true, completion: nil)
        }
        let rightItem = UIBarButtonItem(title: "Cancel", image: nil, primaryAction: cancel, menu: nil)
        rightItem.tintColor = ThemeColor.D1.color
        let search = UISearchController(searchResultsController: nil)
        search.searchBar.delegate = self
        search.searchBar.tintColor = ThemeColor.D1.color
        self.navigationItem.searchController = search
        
        self.leftItem.title = ""
        
        self.navigationItem.leftBarButtonItem = self.leftItem
        self.navigationItem.rightBarButtonItem = rightItem
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadInitialData()
        
        self.dataSource.didSelectAddContacts = { [unowned self] in
            self.loadContacts()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.loadingView.expandToSuperviewSize()

        self.button.setSize(with: self.view.width)
        self.button.centerOnX()
        
        if self.showButton {
            if KeyboardManager.shared.isKeyboardShowing {
                let keyboardHeight = KeyboardManager.shared.cachedKeyboardEndFrame.height
                self.button.bottom = self.view.height - keyboardHeight - Theme.ContentOffset.standard.value
            } else {
                self.button.pinToSafeAreaBottom()
            }
        } else {
            self.button.top = self.view.height
        }
    }
    
    func updateSelectedPeopleItems() {
         let updatedItems: [PersonItem] = self.dataSource.itemIdentifiers(in: .people).compactMap { item in
            switch item {
            case .person(let person):
                var copy = person
                copy.isSelected = self.selectedPeople.contains(where: { current in
                    return current.identifier == person.identifier
                })

                return .person(copy)
            }
        }
        
        var snapshot = self.dataSource.snapshot()
        snapshot.setItems(updatedItems, in: .people)
        self.dataSource.apply(snapshot)
    }

    func showLoading(for person: Person) async {
        if self.loadingView.superview.isNil {
            self.view.addSubview(self.loadingView)
            self.view.layoutNow()
            await self.loadingView.initiateLoading(with: person)
        } else {
            await self.loadingView.update(person: person)
        }
    }

    @MainActor
    func finishInviting() async {
        await self.loadingView.hideAllViews()
        self.loadingView.removeFromSuperview()
    }

    func updateButton() {
        self.button.set(style: .custom(color: .B5, textColor: .T4, text: self.getButtonTitle()))
        UIView.animate(withDuration: Theme.animationDurationFast) {
            self.showButton = self.selectedItems.count > 0
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
        let text = self.selectedPeople.count == 1 ? "person" : "people"
        return "Add \(self.selectedPeople.count) \(text)"
    }

    // MARK: Data Loading

    override func retrieveDataForSnapshot() async -> [PeopleSection : [PersonItem]] {

        var data: [PeopleSection: [PersonItem]] = [:]

        if let connections = try? await GetAllConnections().makeRequest(andUpdate: [],
                                                                        viewsToIgnore: []).filter({ (connection) -> Bool in
            return !connection.nonMeUser.isNil
        }), let _ = try? await connections.asyncMap({ connection in
            return try await connection.nonMeUser!.retrieveDataIfNeeded()
        }) {
            let connectedPeople = connections.map { connection in
                return Person(withConnection: connection)
            }

            self.allPeople.append(contentsOf: connectedPeople)
        }

        data[.people] = self.allPeople.sorted().compactMap({ person in
            return .person(person)
        })

        return data
    }

    override func getAllSections() -> [PeopleSection] {
        return PeopleSection.allCases
    }
    
    override func collectionViewDataWasLoaded() {
        super.collectionViewDataWasLoaded()
        
        if ContactsManager.shared.hasPermissions {
            self.loadContacts()
        }

        self.$selectedPeople.mainSink { [unowned self] items in
            self.updateSelectedPeopleItems()
            self.updateButton()
        }.store(in: &self.cancellables)
    }
    
    private func loadContacts() {
        Task {
            self.reservations = await Reservation.getAllUnclaimed()
            self.updateNavLeftItem()
            
            let contacts = await ContactsManager.shared.fetchContacts().compactMap({ contact in
                return Person(withContact: contact)
            })
            
            self.allPeople.append(contentsOf: contacts)

            let contactItems: [PersonItem] = contacts.map { person in
                return .person(person)
            }

            await self.dataSource.appendItems(contactItems, toSection: .people)
        }.add(to: self.autocancelTaskPool)
    }
    
    private func updateNavLeftItem() {
        if self.reservations.count == 0 {
            self.leftItem.title = "0 Invites"
        } else if self.reservations.count == 1 {
            self.leftItem.title = "1 Invite"
        } else {
            self.leftItem.title = "\(self.reservations.count) Invites"
        }
    }

    // MARK: - UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        super.collectionView(collectionView, didSelectItemAt: indexPath)
        guard let person: Person = self.dataSource.itemIdentifier(for: indexPath).map({ item in
            switch item {
            case .person(let person):
                return person
            }
        }), !self.selectedPeople.contains(person) else { return }
        
        self.selectedPeople.append(person)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        super.collectionView(collectionView, didDeselectItemAt: indexPath)
        guard let person: Person = self.dataSource.itemIdentifier(for: indexPath).map({ item in
            switch item {
            case .person(let person):
                return person
            }
        }), self.selectedPeople.contains(person) else { return }
        
        self.selectedPeople.remove(object: person)
    }
}
