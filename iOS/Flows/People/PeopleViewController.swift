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

    private let includeConnections: Bool
    private(set) var reservations: [Reservation] = []

    let blurView = BlurView()

    let gradientView = GradientView(with: [ThemeColor.black.color.withAlphaComponent(1.0).cgColor,
                                           ThemeColor.black.color.withAlphaComponent(0.0).cgColor],
                                    startPoint: .bottomCenter,
                                    endPoint: .topCenter)
    let button = ThemeButton()
    private let loadingView = InvitationLoadingView()
    private var showButton: Bool = false

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

        self.modalPresentationStyle = .popover
        if let pop = self.popoverPresentationController {
            let sheet = pop.adaptiveSheetPresentationController
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }

        self.view.insertSubview(self.blurView, belowSubview: self.collectionView)

        self.dataSource.headerTitle = self.getHeaderTitle()
        self.dataSource.headerDescription = self.getHeaderDescription()

        self.view.addSubview(self.gradientView)
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
        self.loadingView.expandToSuperviewSize()

        self.button.setSize(with: self.view.width)
        self.button.centerOnX()
        
        if self.showButton {
            self.button.pinToSafeAreaBottom()
        } else {
            self.button.top = self.view.height
        }
        
        self.gradientView.expandToSuperviewWidth()
        self.gradientView.height = (self.view.height - self.button.top) + Theme.ContentOffset.xtraLong.value
        self.gradientView.pin(.bottom)
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
        self.button.set(style: .normal(color: .white, text: self.getButtonTitle()))
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
