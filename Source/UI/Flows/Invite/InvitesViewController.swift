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
    func invitesView(_ controller: InvitesViewController, didSelect reservation: Reservation)
}

class InvitesViewController: NavigationBarViewController {

    unowned let delegate: InvitesViewControllerDelegate

    lazy var inviteablVC = InviteableCollectionViewController()

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

        self.inviteablVC.collectionViewManager.allowMultipleSelection = true

        self.inviteablVC.collectionViewManager.onSelectedItem.signal.observeValues { [unowned self] (cellItem) in
            guard let cell = cellItem else { return }
            self.delegate.invitesView(self, didSelect: cell.item)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.inviteablVC.view.size = CGSize(width: self.view.width, height: self.view.height - self.lineView.bottom)
        self.inviteablVC.view.top = self.lineView.bottom
        self.inviteablVC.view.centerOnX()
    }

    override func getTitle() -> Localized {
        return "Invites"
    }

    override func getDescription() -> Localized {
        return "Select contacts you would like to invite."
    }

    func loadItems() {

    }
}
