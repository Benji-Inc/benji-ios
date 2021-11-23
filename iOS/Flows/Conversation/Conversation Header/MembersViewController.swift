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
        let cv = CollectionView(layout: MembersCollectionViewLayout())
        cv.isScrollEnabled = false
        super.init(with: cv)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        ConversationsManager.shared.$activeConversation
            .removeDuplicates()
            .mainSink { conversation in
            Task {
                await self.loadData()
            }.add(to: self.taskPool)
        }.store(in: &self.cancellables)
    }

    // MARK: Data Loading

    override func getAnimationCycle() -> AnimationCycle? {
        return AnimationCycle(inFromPosition: .inward,
                              outToPosition: .inward,
                              shouldConcatenate: true,
                              scrollToIndexPath: IndexPath(row: 0, section: 0))
    }

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
