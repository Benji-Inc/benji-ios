//
//  MembersViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/23/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat
import Combine

class MembersViewController: DiffableCollectionViewController<MembersCollectionViewDataSource.SectionType,
                             MembersCollectionViewDataSource.ItemType,
                             MembersCollectionViewDataSource>,
                             ActiveConversationable {

    var conversationController: ConversationController?

    init() {
        let cv = CollectionView(layout: MembersCollectionViewLayout())
        cv.isScrollEnabled = false
        cv.showsHorizontalScrollIndicator = false
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
            .mainSink { [unowned self] conversation in
                Task {
                    guard let cid = conversation?.cid else {
                        await self.dataSource.deleteAllItems()
                        return
                    }

                    let conversationController = ChatClient.shared.channelController(for: cid)
                    self.conversationController = conversationController

                    await self.loadData()

                    guard !Task.isCancelled else { return }

                    self.subscribeToUpdates(for: conversationController)
                }.add(to: self.autocancelTaskPool)
            }.store(in: &self.cancellables)
    }

    /// The subscriptions for the current conversation.
    private var conversationCancellables = Set<AnyCancellable>()

    func subscribeToUpdates(for conversationController: ConversationController) {
        // Clear out previous subscriptions.
        self.conversationCancellables.removeAll()

        conversationController
            .typingUsersPublisher
            .mainSink(receiveValue: { [unowned self] typingUsers in
                self.dataSource.reconfigureAllItems()
            }).store(in: &self.conversationCancellables)

        conversationController
            .memberEventPublisher
            .mainSink(receiveValue: { [unowned self] event in
                switch event as MemberEvent {
                case let event as MemberAddedEvent:
                    self.add(member: event.member)
                case let event as MemberRemovedEvent:
                    guard let conversationController = self.conversationController else { return }
                    let member = Member(displayable: AnyHashableDisplayable(event.user),
                                        conversationController: conversationController)
                    self.dataSource.deleteItems([.member(member)])
                case let event as MemberUpdatedEvent:
                    guard let conversationController = self.conversationController else { return }
                    let member = Member(displayable: AnyHashableDisplayable(event.member),
                                        conversationController: conversationController)
                    self.dataSource.reconfigureItems([.member(member)])
                default:
                    break
                }
            }).store(in: &self.conversationCancellables)
    }
    
    func add(member: ChatChannelMember) {
        guard let conversationController = self.conversationController else { return }

        let member = Member(displayable: AnyHashableDisplayable.init(member),
                            conversationController: conversationController)
        self.dataSource.appendItems([.member(member)], toSection: .members)
    }

    func scroll(to user: ChatUser) {
        guard let controller = self.conversationController else { return }

        let member = Member(displayable: AnyHashableDisplayable(user),
                            conversationController: controller)
        guard let ip = self.dataSource.indexPath(for: .member(member)) else { return }

        self.collectionView.scrollToItem(at: ip, at: .centeredHorizontally, animated: true)
    }

    // MARK: - Data Loading

    override func getAnimationCycle(with snapshot: NSDiffableDataSourceSnapshot<MembersSectionType, MembersItemType>)
    -> AnimationCycle? {
        return AnimationCycle(inFromPosition: nil,
                              outToPosition: nil,
                              shouldConcatenate: false,
                              scrollToIndexPath: nil)
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

        if !isRelease {
            data[.members]?.append(.add(conversation.cid))
        }

        return data
    }
}
