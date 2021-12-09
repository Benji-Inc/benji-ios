//
//  MembersViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/23/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

class MembersViewController: DiffableCollectionViewController<MembersCollectionViewDataSource.SectionType,
                             MembersCollectionViewDataSource.ItemType,
                             MembersCollectionViewDataSource>,
                             ActiveConversationable {

    var conversationController: ConversationController?

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

        self.view.clipsToBounds = false
        self.collectionView.clipsToBounds = false 

        self.collectionView.animationView.isHidden = true 

        ConversationsManager.shared.$activeConversation
            .removeDuplicates()
            .mainSink { conversation in
            Task {
                await self.loadData()
                self.subscribeToUpdates(for: conversation)
            }.add(to: self.taskPool)
        }.store(in: &self.cancellables)
    }

    func subscribeToUpdates(for conversation: Conversation?) {
        guard let cid = conversation?.cid else { return }
        
        self.conversationController = ChatClient.shared.channelController(for: cid)

        self.conversationController?
            .typingUsersPublisher
            .mainSink(receiveValue: { [unowned self] typingUsers in
                Task {
                    let memberItems = self.getMemberItems(withTypingUsers: typingUsers)

                    var snapshot = self.dataSource.snapshot()

                    let currentMemberItems = snapshot.itemIdentifiers(inSection: .members)
                    snapshot.deleteItems(currentMemberItems)
                    snapshot.appendItems(memberItems, toSection: .members)
                    await self.dataSource.apply(snapshot)
                }
            }).store(in: &self.cancellables)
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

    override func retrieveDataForSnapshot() async
    -> [MembersCollectionViewDataSource.SectionType: [MembersCollectionViewDataSource.ItemType]] {

        var data: [MembersCollectionViewDataSource.SectionType: [MembersCollectionViewDataSource.ItemType]] = [:]

        data[.members] = self.getMemberItems(withTypingUsers: [])

        return data
    }

    private func getMemberItems(withTypingUsers typingUsers: Set<ChatUser>)
    -> [MembersCollectionViewDataSource.ItemType] {

        guard let conversation = self.activeConversation else { return [] }

        // Don't show the current user in the member array.
        let members = Array(conversation.lastActiveMembers.filter { member in
            return member.id != ChatClient.shared.currentUserId
        })

        let memberItems: [MembersCollectionViewDataSource.ItemType] = members.map({ user in
            let isTyping = typingUsers.contains { typingUser in
                typingUser.userObjectID == user.userObjectID
            }
            let member = Member(displayable: AnyHashableDisplayable(user), isTyping: isTyping)
            return .member(member)
        })

        return memberItems
    }
}
