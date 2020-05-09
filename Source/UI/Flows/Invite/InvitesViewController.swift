//
//  InviteViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 2/1/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization
import Contacts
import TMROFutures

protocol InvitesViewControllerDelegate: class {
    func invitesView(_ controller: InvitesViewController, didSelect contacts: [CNContact])
    func invitesView(_ controller: InvitesViewController, didGetAuthorization status: CNAuthorizationStatus)
}

class InvitesViewController: NavigationBarViewController, KeyboardObservable {

    unowned let delegate: InvitesViewControllerDelegate
    private let button = Button()
    private let gradientView = GradientView(with: .background2)
    var buttonOffset: CGFloat?

    lazy var inviteablVC = InviteableCollectionViewController()

    private var connections: [Connection] = []
    private var contacts: [CNContact] = []

    private let firstSyncQueue = DispatchQueue(label: "First.SyncQueue", attributes: [])
    private let secondSyncQueue = DispatchQueue(label: "Second.SyncQueue", attributes: [])

    private var selectedContacts: [CNContact] {
        return self.inviteablVC.collectionViewManager.selectedItems.compactMap { (inviteable) -> CNContact? in
            switch inviteable {
            case .contact(let contact, _):
                return contact
            case .connection(_):
                return nil
            }
        }
    }

    init(with delegate: InvitesViewControllerDelegate) {
        self.delegate = delegate
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        self.registerKeyboardEvents()
        self.showSearch = true 
        self.addChild(viewController: self.inviteablVC)
        self.view.addSubview(self.gradientView)
        self.view.addSubview(self.button)
        self.backButton.isVisible = false

        self.button.didSelect = { [unowned self] in
            self.delegate.invitesView(self, didSelect: self.selectedContacts)
        }

        self.inviteablVC.collectionViewManager.allowMultipleSelection = true

        self.inviteablVC.collectionViewManager.onSelectedItem.signal.observeValues { [unowned self] (_) in
            self.updateButtonForContacts()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        ContactsManager.shared.getAuthorizationStatus { [unowned self] (status) in
            self.delegate.invitesView(self, didGetAuthorization: status)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.inviteablVC.view.size = CGSize(width: self.view.width, height: self.view.height - self.lineView.bottom)
        self.inviteablVC.view.top = self.lineView.bottom
        self.inviteablVC.view.centerOnX()

        self.button.setSize(with: self.view.width)
        self.button.centerOnX()
        self.button.bottom = self.buttonOffset ?? self.view.height + 100

        let height = self.button.height + self.view.safeAreaInsets.bottom + 10
        self.gradientView.size = CGSize(width: self.view.width, height: height)
        self.gradientView.centerOnX()
        self.gradientView.top = self.button.top
    }

    override func getTitle() -> Localized {
        return "Invites"
    }

    override func getDescription() -> Localized {
        return "Select contacts you would like to invite."
    }

    private func updateButtonForContacts() {
        let buttonText: LocalizedString
        if self.selectedContacts.count > 1 {
            buttonText = LocalizedString(id: "",
                                         arguments: [String(self.selectedContacts.count)],
                                         default: "SEND @(count) INVITES")
        } else {
            buttonText = LocalizedString(id: "", default: "SEND INVITE")
        }

        self.button.set(style: .normal(color: .purple, text: buttonText))

        var newOffset: CGFloat
        if self.selectedContacts.count >= 1 {
            let keyboardHeight = self.keyboardHandler?.currentKeyboardHeight ?? 0
            newOffset = self.view.height - self.view.safeAreaInsets.bottom - keyboardHeight
        } else {
            newOffset = self.view.height + 100
        }

        self.animateButton(with: newOffset)
    }

    private func animateButton(with newOffset: CGFloat) {
        guard self.buttonOffset != newOffset else { return }

        self.buttonOffset = newOffset
        UIView.animate(withDuration: Theme.animationDuration,
                       delay: 0,
                       options: .curveEaseInOut,
                       animations: {
                        self.view.layoutNow()
        }) { (completed) in }
    }

    func loadItems() {

        self.connections = []
        self.contacts = []

        self.inviteablVC.collectionView.activityIndicator.startAnimating()
        let pendingPromise = self.loadPendingConnections()
        let contactsPromise = self.getContacts()

        waitForAll(futures: [pendingPromise, contactsPromise], queue: self.firstSyncQueue)
            .observeValue { (_) in

                self.replaceDuplicates(from: self.connections, and: self.contacts)
                    .observeValue { (allItems) in
                        runMain {
                            self.inviteablVC.collectionViewManager.allCache = allItems
                            self.inviteablVC.collectionViewManager.set(newItems: allItems)
                            self.inviteablVC.collectionView.activityIndicator.stopAnimating()
                        }
                }
        }
    }

    private func replaceDuplicates(from connections: [Connection], and contacts: [CNContact]) -> Future<[Inviteable]> {
        let promise = Promise<[Inviteable]>()

        var connectionPromises: [Future<User>] = []
        connections.forEach { (connection) in
            if let user = connection.nonMeUser {
                connectionPromises.append((user.retrieveDataIfNeeded()))
            }
        }

        waitForAll(futures: connectionPromises, queue: self.secondSyncQueue)
            .observeValue { (users) in
                var finalItems: [Inviteable] = contacts.compactMap { (contact) -> Inviteable? in
                    return .contact(contact, .pending)
                }

                for (i, contact) in contacts.enumerated() {
                    for (index, user) in users.enumerated() {
                        if self.shouldAddConneciton(from: user, contact: contact),
                            let connection = connections[safe: index] {
                            finalItems[i] = .contact(contact, connection.status!)
                        }
                    }
                }

                promise.resolve(with: finalItems)
        }

        return promise
    }

    func shouldAddConneciton(from user: User, contact: CNContact) -> Bool {
        guard let userPhone = user.phoneNumber?.formatPhoneNumber()?.removeAllNonNumbers(),
            var contactPhone = contact.primaryPhoneNumber?.formatPhoneNumber()?.removeAllNonNumbers() else { return false}

        if contactPhone.first != "1" {
            contactPhone.insert("1", at: contactPhone.startIndex)
        }

        return userPhone == contactPhone
    }
    
    private func loadPendingConnections() -> Future<Void> {
        let promise = Promise<Void>()
        GetAllConnections(direction: .all)
            .makeRequest()
            .observeValue(with: { [unowned self] (connections) in
                self.connections = connections
                promise.resolve(with: ())
            })

        return promise
    }

    private func getContacts() -> Future<Void> {
        let promise = Promise<Void>()

        ContactsManager.shared.getContacts { [unowned self] (contacts: [CNContact]) in
            self.contacts = contacts
            promise.resolve(with: ())
        }

        return promise
    }

    func didGetAuthorization(status: CNAuthorizationStatus) {
        switch status {
        case .notDetermined, .restricted, .denied:
            runMain {
                self.askForAuthorization(status: status)
            }
        case .authorized:
            runMain {
                self.loadItems()
            }
        @unknown default:
            runMain {
                self.askForAuthorization(status: status)
            }
        }
    }

    private func askForAuthorization(status: CNAuthorizationStatus) {

        let contactModal = ContactAuthorizationController(status: status)
        contactModal.onAuthorization = { (result) in
            switch result {
            case .denied:
                contactModal.dismiss(animated: true, completion: nil)
            case .authorized:
                contactModal.dismiss(animated: true) {
                    //source.getContacts()
                }
            }
        }
    }

    override func searchBarDidFinishEditing(_ searchBar: SearchBar) {
        super.searchBarDidFinishEditing(searchBar)
        self.loadItems()
    }

    override func searchBar(_ searchBar: SearchBar, didUpdate text: String?) {
        let searchText = String(optional: text)
        self.inviteablVC.collectionViewManager.contactFilter = SearchFilter(text: searchText)
    }

    func handleKeyboard(frame: CGRect, with animationDuration: TimeInterval, timingCurve: UIView.AnimationCurve) {
        self.updateButtonForContacts()
    }
}
