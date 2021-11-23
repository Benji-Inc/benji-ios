//
//  MembersViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/23/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

class MembersViewController: DiffableCollectionViewController<MembersCollectionViewDataSource.SectionType, MembersCollectionViewDataSource.ItemType, MembersCollectionViewDataSource> {

    init() {
        super.init(with: CollectionView(layout: MembersCollectionViewLayout()))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

    }

    func configure(with conversation: Conversation) {

        let members = conversation.lastActiveMembers.filter { member in
            return member.id != ChatClient.shared.currentUserId
        }

        if !members.isEmpty {
            //self.stackedAvatarView.set(items: members)
        } else {
            //self.stackedAvatarView.set(items: [User.current()!])
        }
    }

    // MARK: Data Loading

    override func getAllSections() -> [MembersCollectionViewDataSource.SectionType] {
        return MembersCollectionViewDataSource.SectionType.allCases
    }

    override func retrieveDataForSnapshot() async -> [MembersCollectionViewDataSource.SectionType: [MembersCollectionViewDataSource.ItemType]] {

        var data: [MembersCollectionViewDataSource.SectionType: [MembersCollectionViewDataSource.ItemType]] = [:]


        data[.members] = []

        return data
    }
}
