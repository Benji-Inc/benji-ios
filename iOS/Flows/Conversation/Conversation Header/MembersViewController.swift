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
    
    private var initialTopMostAuthor: ChatUser?

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
                guard let cid = conversation?.cid else {
                    await self.dataSource.deleteAllItems()
                    return
                }
                
                self.conversationController = ChatClient.shared.channelController(for: cid)

                await self.loadData()
                self.subscribeToUpdates(for: conversation)
                
            }.add(to: self.taskPool)
        }.store(in: &self.cancellables)
    }

    func subscribeToUpdates(for conversation: Conversation?) {
        self.conversationController?
            .typingUsersPublisher
            .mainSink(receiveValue: { [unowned self] typingUsers in
                self.dataSource.reconfigureAllItems()
            }).store(in: &self.cancellables)

        self.conversationController?.memberEventPublisher.mainSink(receiveValue: { [unowned self] event in
            switch event as MemberEvent {
            case let event as MemberAddedEvent:
                guard let conversationController = self.conversationController else { return }
                let member = Member(displayable: AnyHashableDisplayable.init(event.member),
                                    conversationController: conversationController)
                self.dataSource.appendItems([.member(member)], toSection: .members)
            case let event as MemberRemovedEvent:
                guard let conversationController = self.conversationController else { return }
                let member = Member(displayable: AnyHashableDisplayable.init(event.user),
                                    conversationController: conversationController)
                self.dataSource.deleteItems([.member(member)])
            case let event as MemberUpdatedEvent:
                guard let conversationController = self.conversationController else { return }
                let member = Member(displayable: AnyHashableDisplayable.init(event.member),
                                    conversationController: conversationController)
                self.dataSource.reconfigureItems([.member(member)])
            default:
                break
            }
        }).store(in: &self.cancellables)
    }

    // MARK: Data Loading

    override func getAnimationCycle(with snapshot: NSDiffableDataSourceSnapshot<MembersSectionType, MembersItemType>)
    -> AnimationCycle? {
        
        var index: Int = 0
        if let user = self.initialTopMostAuthor,
           let controller = self.conversationController {
            let member = Member(displayable: AnyHashableDisplayable.init(user),
                                conversationController: controller)
            index = snapshot.indexOfItem(.member(member)) ?? 0
        }

        return AnimationCycle(inFromPosition: .inward,
                              outToPosition: .inward,
                              shouldConcatenate: true,
                              scrollToIndexPath: IndexPath(row: index, section: 0))
    }

    override func getAllSections() -> [MembersCollectionViewDataSource.SectionType] {
        return MembersCollectionViewDataSource.SectionType.allCases
    }

    override func retrieveDataForSnapshot() async -> [MembersCollectionViewDataSource.SectionType: [MembersCollectionViewDataSource.ItemType]] {

        var data: [MembersCollectionViewDataSource.SectionType: [MembersCollectionViewDataSource.ItemType]] = [:]

        guard let conversation = self.conversationController?.conversation else { return data }

        let members = conversation.lastActiveMembers.filter { member in
            return member.id != ChatClient.shared.currentUserId
        }
        
        data[.members] = members.compactMap({ user in
            guard let conversationController = self.conversationController else { return nil }
            let member = Member(displayable: AnyHashableDisplayable.init(user),
                                conversationController: conversationController)
            return .member(member)
        })
                
        data[.members]?.append(.add(conversation.cid))
        
        for i in 0...20 {
            let cid = ChannelId(type: .messaging, id: "\(i)")
            data[.members]?.append(.add(cid))
        }

        return data
    }
    
    func updateAuthor(for conversation: Conversation, user: ChatUser) {
        guard let controller = self.conversationController,
              conversation == controller.conversation else {
            // If the conversation hasn't been set yet, store the user it should scroll too once it does. 
            self.initialTopMostAuthor = user
            return
        }
        
        self.initialTopMostAuthor = nil
        
        let member = Member(displayable: AnyHashableDisplayable.init(user),
                            conversationController: controller)
        if let ip = self.dataSource.indexPath(for: .member(member)) {
            self.collectionView.scrollToItem(at: ip, at: .centeredHorizontally, animated: true)
        }
    }
}
