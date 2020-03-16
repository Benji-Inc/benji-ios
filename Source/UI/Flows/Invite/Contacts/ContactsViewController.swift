//
//  ContactsViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 6/30/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Contacts

protocol ContactsViewControllerDelegate: class {
    func contactsView(_ controller: ContactsViewController, didGetAuthorization status: CNAuthorizationStatus)
}

class ContactsViewController: CollectionViewController<ContactCell, ContactsCollectionViewManager>, KeyboardObservable, Sizeable {

    unowned let delegate: ContactsViewControllerDelegate

    init(with delegate: ContactsViewControllerDelegate) {
        self.delegate = delegate
        let collectionView = ContactsCollectionView()
        super.init(with: collectionView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        self.collectionViewManager.allowMultipleSelection = true
        self.registerKeyboardEvents()

        self.view.set(backgroundColor: .background2)
    }

    func getAuthorizationStatus() {
        ContactsManager.shared.getAuthorizationStatus { [unowned self] (authorizationStatus) in
            self.delegate.contactsView(self, didGetAuthorization: authorizationStatus)
        }
    }

    func getContacts() {
        runMain {
            self.collectionView.activityIndicator.startAnimating()
        }

        ContactsManager.shared.getContacts { [weak self] (contacts: [CNContact]) in
            guard let `self` = self else { return }

            self.collectionView.activityIndicator.stopAnimating()
            self.sort(contacts: contacts)
            self.collectionView.reloadDataAndKeepOffset()
        }
    }

    private func sort(contacts: [CNContact]) {
        self.collectionViewManager.set(newItems: contacts)
    }

    func handleKeyboard(frame: CGRect,
                        with animationDuration: TimeInterval,
                        timingCurve: UIView.AnimationCurve) {}
}
