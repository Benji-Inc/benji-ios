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
}

class InvitesViewController: NavigationBarViewController {

    unowned let delegate: InvitesViewControllerDelegate
    private let button = Button()
    private let gradientView = GradientView(with: .background2)
    var buttonOffset: CGFloat?

    lazy var inviteablVC = InviteableCollectionViewController()

    private var connections: [Connection] = []
    private var contacts: [CNContact] = []

    init(with delegate: InvitesViewControllerDelegate) {
        self.delegate = delegate
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        self.addChild(viewController: self.inviteablVC)
        self.view.addSubview(self.gradientView)
        self.view.addSubview(self.button)
        self.backButton.isVisible = false


        self.button.didSelect = { [unowned self] in
            //            switch self.currentContent.value {
            //            case .contacts(_):
            //                self.delegate.invitesView(self, didSelect: self.selectedContacts)
            //            case .pending(_):
            //                self.currentContent.value = .contacts(self.contactsVC)
            //            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.loadItems()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.contacts = []
        self.connections = []
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.inviteablVC.view.size = CGSize(width: self.view.width, height: self.view.height - self.lineView.bottom)
        self.inviteablVC.view.top = self.lineView.bottom
        self.inviteablVC.view.centerOnX()

        self.button.setSize(with: self.view.width)
        self.button.centerOnX()
        self.button.bottom = self.buttonOffset ?? self.view.height + 100

        let height = self.view.height - self.button.top + 10
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

    private func updateButton() {
        //        switch self.currentContent.value {
        //        case .contacts(_):
        //            self.updateButtonForContacts()
        //        case .pending(_):
        //            self.updateButtonForPending()
        //        }
    }

    private func updateButtonForPending() {
        self.button.set(style: .normal(color: .purple, text: "Invite Others"))
        let offset = self.view.height - self.view.safeAreaInsets.bottom
        self.animateButton(with: offset)
    }

    private func updateButtonForContacts() {
        //        let buttonText: LocalizedString
        //        if self.selectedContacts.count > 1 {
        //            buttonText = LocalizedString(id: "",
        //                                         arguments: [String(self.selectedContacts.count)],
        //                                         default: "SEND @(count) INVITES")
        //        } else {
        //            buttonText = LocalizedString(id: "", default: "SEND INVITE")
        //        }
        //
        //        self.button.set(style: .normal(color: .purple, text: buttonText))
        //
        //        var newOffset: CGFloat
        //        if self.selectedContacts.count >= 1 {
        //            newOffset = self.view.height - self.view.safeAreaInsets.bottom
        //        } else {
        //            newOffset = self.view.height + 100
        //        }
        //
        //        self.animateButton(with: newOffset)
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

        self.inviteablVC.collectionView.activityIndicator.startAnimating()
        let pendingPromise = self.loadPendingConnections()
        let contactsPromise = self.getContacts()

        waitForAll(futures: [pendingPromise, contactsPromise])
            .observeValue { (_) in

                self.replaceDuplicates(from: self.connections, and: self.contacts)
                    .observeValue { (allItems) in
                        runMain {
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
                connectionPromises.append(user.fetchUserIfNeeded())
            }
        }

        waitForAll(futures: connectionPromises)
            .observeValue { (users) in
                var finalItems: [Inviteable] = []

                for (index, user) in users.enumerated() {
                    if let phone = user.phoneNumber?.formatPhoneNumber() {
                        for contact in contacts {
                            if let contactPhone = contact.primaryPhoneNumber?.formatPhoneNumber(),
                                phone == contactPhone,
                                let connection = connections[safe: index] {
                                finalItems.append(.connection(connection))
                            } else {
                                finalItems.append(.contact(contact))
                            }
                        }
                    }
                }

                promise.resolve(with: finalItems)
        }

        return promise
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
}
