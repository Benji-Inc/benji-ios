//
//  TCHChannel+Extensions.swift
//  Benji
//
//  Created by Benji Dodgson on 2/3/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TwilioChatClient
import Parse
import TMROFutures
import ReactiveSwift

extension TCHChannel: Diffable, ManageableCellItem {

    var id: String {
        return self.sid!
    }
    
    var backgroundColor: Color {
        return .blue
    }

    var context: ConversationContext? {
        guard let dict = self.attributes()?.dictionary,
            let contextString = dict[ChannelKey.context.rawValue] as? String,
            let context = ConversationContext(rawValue: contextString) else { return nil }
        return context
    }

    func diffIdentifier() -> NSObjectProtocol {
        return String(optional: self.sid) as NSObjectProtocol
    }

    func joinIfNeeded() -> Future<TCHChannel> {
        let promise = Promise<TCHChannel>(value: self)
        return promise.joinIfNeeded().then(with: { (channel) in
            return Promise<TCHChannel>(value: channel)
        }).then(with: { (channel) in
            return Promise<TCHChannel>(value: channel)
        })
    }

    func getNonMeMembers() -> Future<[TCHMember]> {

        let promise = Promise<[TCHMember]>()
        if let members = self.members {
            members.members { (result, paginator) in
                if let error = result.error {
                    promise.reject(with: error)
                } else if let pag = paginator {
                    var nonMeMembers: [TCHMember] = []
                    pag.items().forEach { (member) in
                        if member.identity != User.current()?.objectId {
                            nonMeMembers.append(member)
                        }
                    }
                    promise.resolve(with: nonMeMembers)
                } else {
                    promise.reject(with: ClientError.message(detail: "There was a problem fetching other members."))
                }
            }
        }

        return promise.withResultToast()
    }

    func getAuthorAsUser() -> Future<User> {
        let promise = Promise<TCHChannel>(value: self)
        return promise.getAuthorAsUser()
    }

    func getMembersAsUsers() -> Future<[User]> {
        let promise = Promise<TCHChannel>(value: self)
        return promise.getUsers()
    }

    var channelDescription: String {
        guard let attributes = self.attributes(),
            let text = attributes.dictionary?[ChannelKey.description.rawValue] as? String else { return String() }
        return text
    }

    func getUnconsumedCount() -> SignalProducer<FeedType, Error> {
        var totalUnread: Int = 0

        return SignalProducer { [weak self] observer, lifetime in
            guard let `self` = self else { return }

            if let messagesObject = self.messages {
                self.getMessagesCount { (result, count) in
                    if result.isSuccessful() {
                        messagesObject.getLastWithCount(count) { (messageResult, messages) in

                            if messageResult.isSuccessful(), let msgs = messages {
                                msgs.forEach { (message) in
                                    if !message.isFromCurrentUser, !message.isConsumed, message.canBeConsumed {
                                        totalUnread += 1
                                    }
                                }
                                observer.send(value: .unreadMessages(self, totalUnread))
                                observer.sendCompleted()
                            } else {
                                observer.send(error: ClientError.message(detail: "Unable to get messages."))
                            }
                        }
                    } else {
                        observer.send(error: ClientError.message(detail: "Failed to get message count."))
                    }
                }
            } else {
                observer.send(error: ClientError.message(detail: "There were no messages."))
            }
        }
    }
}

extension Future where Value == TCHChannel {

    func joinIfNeeded() -> Future<TCHChannel> {

        return self.then(with: { (channel) in

            // There's no need to join the channel if the current user is already a member
            guard let id = PFUser.current()?.objectId, channel.member(withIdentity: id) == nil else {
                return Promise<TCHChannel>(value: channel)
            }

            let promise = Promise<TCHChannel>()
            channel.join(completion: { (result) in
                if let error = result.error {
                    promise.reject(with: error)
                } else {
                     promise.resolve(with: channel)
                }
            })

            return promise
        })
    }

    func invite(users: [User]) -> Future<TCHChannel> {
        var promises: [Future<TCHChannel>] = []

        users.forEach { (user) in
            promises.append(self.invite(user: user))
        }

        return waitForAll(futures: promises)
            .transform { (channels) -> TCHChannel in
                return channels.first!
        }
    }

    func invite(user: User) -> Future<TCHChannel> {

        return self.then(with: { (channel) in

            let promise = Promise<TCHChannel>()
            let identity = String(optional: user.objectId)
            channel.members!.invite(byIdentity: identity) { (result) in
                if let error = result.error {
                    promise.reject(with: error)
                } else {
                    promise.resolve(with: channel)
                }
            }

            return promise
        })
    }

    func getAuthorAsUser() -> Future<User> {
        return self.then(with: { (channel) in
            let promise = Promise<User>()
            if let authorID = channel.createdBy {
                User.localThenNetworkQuery(for: authorID)
                    .observeValue(with: { (user) in
                        promise.resolve(with: user)
                    })
            } else {
                promise.reject(with: ClientError.message(detail: "This channel has no author ID."))
            }

            return promise
        })
    }

    func getUsers() -> Future<[User]> {
        return self.then { (channel) in
            let promise = Promise<[User]>()
            if let members = channel.members {
                members.members { (result, paginator) in
                    if result.isSuccessful(), let pag = paginator {
                        var identifiers: [String] = []
                        pag.items().forEach { (member) in
                            if let identifier = member.identity {
                                identifiers.append(identifier)
                            }
                        }

                        User.localThenNetworkArrayQuery(where: identifiers,
                                                        isEqual: true, 
                                                        container: .channel(identifier: channel.sid!))
                            .observeValue(with: { (users) in
                                promise.resolve(with: users)
                            })
                    } else {
                        promise.reject(with: ClientError.message(detail: "Failed to retrieve channel members."))
                    }
                }
            }

            return promise
        }
    }
}

extension TCHChannel: ImageDisplayable {

    var user: User? {
        return nil
    }

    var image: UIImage? {
        return UIImage(systemName: "text.bubble.fill")
    }
    
    var userObjectID: String? {
        return self.createdBy
    }
}
