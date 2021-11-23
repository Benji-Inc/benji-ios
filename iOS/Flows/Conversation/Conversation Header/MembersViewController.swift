//
//  MembersViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/23/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

class MembersViewController: DiffableCollectionViewController<MembersCollectionViewDataSource.SectionType, MembersCollectionViewDataSource.ItemType, MembersCollectionViewDataSource>, ActiveConversationable {

    init() {
        super.init(with: CollectionView(layout: MembersCollectionViewLayout()))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        ConversationsManager.shared.$activeConversation.mainSink { conversation in
            Task {
                await self.loadData()
            }.add(to: self.taskPool)
        }.store(in: &self.cancellables)
    }

    // MARK: Data Loading

    override func getAllSections() -> [MembersCollectionViewDataSource.SectionType] {
        return MembersCollectionViewDataSource.SectionType.allCases
    }

    override func retrieveDataForSnapshot() async -> [MembersCollectionViewDataSource.SectionType: [MembersCollectionViewDataSource.ItemType]] {

        var data: [MembersCollectionViewDataSource.SectionType: [MembersCollectionViewDataSource.ItemType]] = [:]

        guard let conversation = self.activeConversation else { return data }

        let members = conversation.lastActiveMembers.filter { member in
            return member.id != ChatClient.shared.currentUserId
        }

        if !members.isEmpty {
            data[.members] = members.compactMap({ member in
                return .member(AnyHashableDisplayable.init(member))
            })
        } else {
            data[.members] = [.member(AnyHashableDisplayable.init(User.current()!))]
        }

        return data
    }
}
