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

private class SearchBar: UISearchBar {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initializeViews() {
        self.tintColor = ThemeColor.D6.color
        self.isTranslucent = false
    }
}

protocol PeopleViewControllerDelegate: AnyObject {
    func peopleView(_ controller: PeopleViewController, didSelect items: [PeopleCollectionViewDataSource.ItemType])
}

class PeopleViewController: DiffableCollectionViewController<PeopleCollectionViewDataSource.SectionType, PeopleCollectionViewDataSource.ItemType, PeopleCollectionViewDataSource> {

    weak var delegate: PeopleViewControllerDelegate?

    private let includeConnections: Bool
    private(set) var reservations: [Reservation] = []
    
    private let backgroundView = BackgroundGradientView()

    let button = ThemeButton()
    private let loadingView = InvitationLoadingView()
    private var showButton: Bool = false
    
    private let searchBar = SearchBar()

    init(includeConnections: Bool = true) {
        self.includeConnections = includeConnections
        let cv = CollectionView(layout: PeopleCollectionViewLayout())
        cv.keyboardDismissMode = .interactive
        super.init(with: cv)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(collectionView: UICollectionView) {
        fatalError("init(collectionView:) has not been implemented")
    }
    
    override func loadView() {
        self.view = self.backgroundView
    }

    override func initializeViews() {
        super.initializeViews()

        self.modalPresentationStyle = .popover
        if let pop = self.popoverPresentationController {
            let sheet = pop.adaptiveSheetPresentationController
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
    
        self.dataSource.headerTitle = self.getHeaderTitle()
        self.dataSource.headerDescription = self.getHeaderDescription()

        self.view.addSubview(self.button)
        
        self.view.addSubview(self.searchBar)
        self.searchBar.delegate = self

        self.button.didSelect { [unowned self] in
            self.delegate?.peopleView(self, didSelect: self.selectedItems)
        }

        self.$selectedItems.mainSink { _ in
            self.updateButton()
        }.store(in: &self.cancellables)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadInitialData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.searchBar.sizeToFit()
        self.searchBar.pin(.top)

        self.backgroundView.expandToSuperviewSize()
        self.loadingView.expandToSuperviewSize()

        self.button.setSize(with: self.view.width)
        self.button.centerOnX()
        
        if self.showButton {
            self.button.pinToSafeAreaBottom()
        } else {
            self.button.top = self.view.height
        }
    }

    func showLoading(for contact: Contact) async {

        if self.loadingView.superview.isNil {
            self.view.addSubview(self.loadingView)
            self.view.layoutNow()
            await self.loadingView.initiateLoading(with: contact)
        } else {
            await self.loadingView.update(contact: contact)
        }
    }

    @MainActor
    func finishInviting() async {
        await self.loadingView.hideAllViews()
        self.loadingView.removeFromSuperview()
    }

    func updateButton() {
        self.button.set(style: .normal(color: .B1, text: self.getButtonTitle()))
        UIView.animate(withDuration: Theme.animationDurationStandard) {
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
        return "Add \(self.selectedItems.count)"
    }

    // MARK: Data Loading

    override func getAllSections() -> [PeopleCollectionViewDataSource.SectionType] {
        return PeopleCollectionViewDataSource.SectionType.allCases
    }

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

        self.reservations = await Reservation.getAllUnclaimed()

        data[.contacts] = await ContactsManger.shared.fetchContacts().map({ contact in
            let reservation = self.reservations.first { reservation in
                return reservation.contactId == contact.identifier
            }

            let item = Contact(with: contact, reservation: reservation)
            return .contact(item)
        })

        return data
    }
}
