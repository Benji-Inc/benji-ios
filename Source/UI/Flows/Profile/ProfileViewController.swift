//
//  ProfileViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 7/22/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import TwilioChatClient
import TMROLocalization

protocol ProfileViewControllerDelegate: class {
    func profileView(_ controller: ProfileViewController, didSelect item: ProfileItem, for user: User)
}

class ProfileViewController: ViewController {

    private let user: User
    lazy var collectionView = ProfileCollectionView()
    lazy var manager = ProfileCollectionViewManager(with: self.collectionView, user: self.user)
    weak var delegate: ProfileViewControllerDelegate?

    init(with user: User) {
        self.user = user
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = self.collectionView
    }

    override func initializeViews() {
        super.initializeViews()

        self.view.set(backgroundColor: .background1)

        self.collectionView.delegate = self.manager
        self.collectionView.dataSource = self.manager

        self.manager.didTapButtonAt = { [unowned self] item in
            self.delegate?.profileView(self, didSelect: item, for: self.user)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.createItems()
    }

    private func createItems() {
        var items: [ProfileItem] = []

        items.append(.picture)
        items.append(.name)
        items.append(.localTime)
        items.append(.routine)
        items.append(.invites)
        self.manager.items = items
        self.collectionView.reloadData()
    }
}
