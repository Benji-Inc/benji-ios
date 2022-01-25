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

class PeopleSearchViewController: NavigationController {
    
    lazy var peopleVC = PeopleViewController(includeConnections: true)
    
    override func initializeViews() {
        super.initializeViews()
                
        self.modalPresentationStyle = .popover
        if let pop = self.popoverPresentationController {
            let sheet = pop.adaptiveSheetPresentationController
            sheet.detents = [.medium(), .large()]
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }
                
        self.setViewControllers([self.peopleVC], animated: false)
    }
}

protocol PeopleViewControllerDelegate: AnyObject {
    func peopleView(_ controller: PeopleViewController, didSelect items: [PeopleCollectionViewDataSource.ItemType])
}

class PeopleViewController: DiffableCollectionViewController<PeopleCollectionViewDataSource.SectionType, PeopleCollectionViewDataSource.ItemType, PeopleCollectionViewDataSource> {

    weak var delegate: PeopleViewControllerDelegate?

    private let includeConnections: Bool
    private(set) var reservations: [Reservation] = []
    
    let button = ThemeButton()
    private let loadingView = InvitationLoadingView()
    private var showButton: Bool = true
    
    private let backgroundView = BackgroundGradientView()
    private(set) var allPeople: [Person] = []

    override func loadView() {
        self.view = self.backgroundView
    }
    
    init(includeConnections: Bool = true) {
        self.includeConnections = includeConnections
        let cv = CollectionView(layout: PeopleCollectionViewLayout())
        cv.keyboardDismissMode = .interactive
        cv.isScrollEnabled = true 
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

        self.$selectedItems.mainSink { _ in
            self.updateButton()
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
            self.button.pinToSafeAreaBottom()
        } else {
            self.button.top = self.view.height
        }
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
        self.button.set(style: .custom(color: .white, textColor: .B3, text: self.getButtonTitle()))
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
        return "Add \(self.selectedItems.count) people"
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
    }
    
    private func loadContacts() {
        Task {
            self.reservations = await Reservation.getAllUnclaimed()
            
            let contacts: [Person] = await ContactsManger.shared.fetchContacts().map({ contact in
                let reservation = self.reservations.first { reservation in
                    return reservation.contactId == contact.identifier
                }
                
                return Person(withContact: contact, reservation: reservation)
            })
            
            self.allPeople.append(contentsOf: contacts)
            
            let contactItems: [PeopleCollectionViewDataSource.ItemType] = contacts.map { person in
                return .person(person)
            }
            
            await self.dataSource.appendItems(contactItems, toSection: .people)
            
        }.add(to: self.taskPool)
    }

    override func retrieveDataForSnapshot() async -> [PeopleCollectionViewDataSource.SectionType: [PeopleCollectionViewDataSource.ItemType]] {

        var data: [PeopleCollectionViewDataSource.SectionType: [PeopleCollectionViewDataSource.ItemType]] = [:]

        if self.includeConnections {
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
        }
        
        data[.people] = self.allPeople.compactMap({ person in
            return .person(person)
        })

        return data
    }
}
