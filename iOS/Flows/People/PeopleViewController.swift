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

protocol PeopleViewControllerDelegate: AnyObject {
    func peopleView(_ controller: PeopleViewController, didSelect items: [PeopleCollectionViewDataSource.ItemType])
}

class PeopleViewController: DiffableCollectionViewController<PeopleCollectionViewDataSource.SectionType, PeopleCollectionViewDataSource.ItemType, PeopleCollectionViewDataSource> {

    weak var delegate: PeopleViewControllerDelegate?

    private(set) var reservations: [Reservation] = []
    
    let button = ThemeButton()
    private let loadingView = InvitationLoadingView()
    private var showButton: Bool = true
    
    private let backgroundView = BackgroundGradientView()
    private(set) var allPeople: [Person] = []
    
    @Published var selectedPeople: [Person] = []

    override func loadView() {
        self.view = self.backgroundView
    }
    
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
                
        self.setupNavigationBar()

        self.view.addSubview(self.button)

        self.button.didSelect { [unowned self] in
            self.delegate?.peopleView(self, didSelect: self.selectedItems)
        }
        
        KeyboardManager.shared.$cachedKeyboardEndFrame.mainSink { [unowned self]  _ in
            self.view.setNeedsLayout()
        }.store(in: &self.cancellables)
    }
    
    private func setupNavigationBar() {
        self.navigationItem.title = "Contacts"

        let leftItem = UIBarButtonItem(title: "Groups", image: nil, primaryAction: nil, menu: nil)
        leftItem.tintColor = ThemeColor.D1.color
        
        let cancel = UIAction { _ in
            self.dismiss(animated: true, completion: nil)
        }
        let rightItem = UIBarButtonItem(title: "Cancel", image: nil, primaryAction: cancel, menu: nil)
        rightItem.tintColor = ThemeColor.D1.color
        let search = UISearchController(searchResultsController: nil)
        search.searchBar.delegate = self
        search.searchBar.tintColor = ThemeColor.D1.color
        self.navigationItem.searchController = search
        
        self.navigationItem.leftBarButtonItem = leftItem
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
         let updatedItems: [PeopleCollectionViewDataSource.ItemType] = self.dataSource.itemIdentifiers(in: .people).compactMap { item in
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
        return "Add \(self.selectedPeople.count) people"
    }

    // MARK: Data Loading

    override func getAllSections() -> [PeopleCollectionViewDataSource.SectionType] {
        return PeopleCollectionViewDataSource.SectionType.allCases
    }
    
    override func collectionViewDataWasLoaded() {
        super.collectionViewDataWasLoaded()
        
        if ContactsManger.shared.hasPermissions {
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
            
            let contacts = await ContactsManger.shared.fetchContacts().compactMap({ contact in
                return Person(withContact: contact)
            })
            
            self.allPeople.append(contentsOf: contacts)

            let contactItems: [PeopleCollectionViewDataSource.ItemType] = contacts.map { person in
                return .person(person)
            }

            await self.dataSource.appendItems(contactItems, toSection: .people)
            
        }.add(to: self.autoreleaseTaskPool)
    }

    override func retrieveDataForSnapshot() async -> [PeopleCollectionViewDataSource.SectionType: [PeopleCollectionViewDataSource.ItemType]] {

        var data: [PeopleCollectionViewDataSource.SectionType: [PeopleCollectionViewDataSource.ItemType]] = [:]

        if let connections = try? await GetAllConnections().makeRequest(andUpdate: [], viewsToIgnore: []).filter({ (connection) -> Bool in
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
