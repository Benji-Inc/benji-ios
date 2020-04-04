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

typealias InvitesViewControllerDelegates = InvitesViewControllerDelegate & ContactsViewControllerDelegate

protocol InvitesViewControllerDelegate: class {
    func invitesView(_ controller: InvitesViewController, didSelect contacts: [CNContact])
}

class InvitesViewController: NavigationBarViewController {

    unowned let delegate: InvitesViewControllerDelegates
    private let button = Button()
    private let gradientView = GradientView(with: .background2)
    var buttonOffset: CGFloat?


    init(with delegate: InvitesViewControllerDelegates) {
        self.delegate = delegate
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.gradientView)
        self.view.addSubview(self.button)
        self.button.didSelect = { [unowned self] in
//            switch self.currentContent.value {
//            case .contacts(_):
//                self.delegate.invitesView(self, didSelect: self.selectedContacts)
//            case .pending(_):
//                self.currentContent.value = .contacts(self.contactsVC)
//            }
        }

    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.button.setSize(with: self.view.width)
        self.button.centerOnX()
        self.button.bottom = self.buttonOffset ?? self.view.height + 100

        let height = self.view.height - self.button.top + 10
        self.gradientView.size = CGSize(width: self.view.width, height: height)
        self.gradientView.centerOnX()
        self.gradientView.top = self.button.top
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

    func loadPendingConnections() {
        GetAllConnections(direction: .all)
            .makeRequest()
            .observeValue(with: { (connections) in
                let items = connections.compactMap { (connection) -> Inviteable? in
                    if let status = connection.status, status == .invited {
                        return .connection(connection)
                    }

                    return nil
                }

                //self.collectionViewManager.set(newItems: items)
            })
    }
}
