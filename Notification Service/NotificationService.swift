//
//  NotificationService.swift
//  NotificationService
//
//  Created by Benji Dodgson on 6/18/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import UserNotifications
import Intents
import StreamChat
import Parse
import Combine

class NotificationService: UNNotificationServiceExtension {

    private var cancellables = Set<AnyCancellable>()
    var contentHandler: ((UNNotificationContent) -> Void)?
    var request: UNNotificationRequest?

    private var recipients: [INPerson] = []
    private var conversation: ChatChannel?
    private var message: ChatMessage?
    private var author: INPerson?
    private var conversationId: String?

    private var chatHandler: ChatRemoteNotificationHandler?

    override func didReceive(_ request: UNNotificationRequest,
                             withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {

        self.contentHandler = contentHandler
        self.request = request

        Task {
            await self.initializeParse()

            EventLogger.trackRemoteNotification(userInfo: request.content.userInfo)
            
            if let client = self.getChatClient() {
                await self.updateContent(with: request,
                                         client: client,
                                         contentHandler: contentHandler)
            }
        }
    }

    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = self.contentHandler,
           let content = self.request?.content {
            Task {
                await self.finalizeContent(content: content, contentHandler: contentHandler)
            }
        }
    }

    private func initializeParse() async {
        return await withCheckedContinuation { continuation in
            if Parse.currentConfiguration.isNil  {
                let config = ParseClientConfiguration { configuration in
                    configuration.applicationGroupIdentifier = Config.shared.environment.groupId
                    configuration.containingApplicationBundleIdentifier = "com.Jibber-iOS"
                    configuration.server = Config.shared.environment.url
                    configuration.applicationId = Config.shared.environment.appId
                    configuration.isLocalDatastoreEnabled = true
                }

                Parse.initialize(with: config)
            }

            continuation.resume(returning: ())
        }
    }

    private func getChatClient() -> ChatClient? {
        guard let user = User.current() else { return nil }

        var config = ChatClientConfig(apiKey: .init("hvmd2mhxcres"))
        config.isLocalStorageEnabled = true
        config.applicationGroupIdentifier = Config.shared.environment.groupId

        let client = ChatClient(config: config)
        let token = Token.development(userId: user.objectId!)
        client.setToken(token: token)

        return client
    }

    private func updateContent(with request: UNNotificationRequest,
                               client: ChatClient,
                               contentHandler: @escaping (UNNotificationContent) -> Void) async {

        /// Ensure we have the data we need
        guard let authorId = request.content.author,
              let author = try? await User.getObject(with: authorId).iNPerson,
              let content = request.content.mutableCopy() as? UNMutableNotificationContent else {
                  await self.finalizeContent(content: request.content, contentHandler: contentHandler)
            return
        }

        self.author = author

        self.chatHandler = ChatRemoteNotificationHandler(client: client, content: content)

        let notification = self.chatHandler?.handleNotification { pushContentType in
            Task {
                switch pushContentType {
                case .message(let msg):
                    if let conversation = msg.channel {
                        self.conversation = conversation
                        self.message = msg.message

                        await self.applyMessageData(content: content, contentHandler: contentHandler)
                    }
                case .reaction(let reaction):
                    if let conversation = reaction.channel {

                        self.conversation = conversation
                        self.message = reaction.message

                        await self.applyMessageData(content: content, contentHandler: contentHandler)
                    }
                case .unknown(_):
                    break
                }
            }
        } ?? false

        if !notification {
            logDebug("chat handler failed to update notification content")
           await self.finalizeContent(content: content, contentHandler: contentHandler)
        }
    }

    private func applyMessageData(content: UNMutableNotificationContent,
                                  contentHandler: @escaping (UNNotificationContent) -> Void) async {

        let memberIds = self.conversation?.lastActiveMembers.compactMap { member in
            return member.id
        } ?? []

        // Map members to recipients
        if let recipients = try? await User.fetchAndUpdateLocalContainer(where: memberIds,
                                                                              container: .users)
            .compactMap({ user in
                return user.iNPerson
            }) {
            self.recipients = recipients
        }

        /// Update the interruption level
        if let value = self.message?.extraData["context"],
           case RawJSON.string(let string) = value,
           let context = MessageContext.init(rawValue: string) {
            
            content.interruptionLevel = context.interruptionLevel
            content.badge = self.getBadge(with: context)
        }

        await self.finalizeContent(content: content, contentHandler: contentHandler)
    }
    
    func getBadge(with context: MessageContext) -> NSNumber {
        guard let defaults = UserDefaults(suiteName: Config.shared.environment.groupId),
              var count = defaults.value(forKey: "badgeNumber") as? Int else { return 0 }
        
        count += 1
        defaults.set(count, forKey: "badgeNumber")
        return count as NSNumber
    }

    private func finalizeContent(content: UNNotificationContent,
                                 contentHandler: @escaping (UNNotificationContent) -> Void) async {
        /// Create the intent
        let incomingMessageIntent = INSendMessageIntent(recipients: recipients,
                                                        outgoingMessageType: .outgoingMessageText,
                                                        content: content.body,
                                                        speakableGroupName: self.conversation?.speakableGroupName,
                                                        conversationIdentifier: self.conversationId,
                                                        serviceName: nil,
                                                        sender: self.author,
                                                        attachments: nil)

        let interaction = INInteraction(intent: incomingMessageIntent, response: nil)
        interaction.direction = .incoming

        do {
            try await interaction.donate()
            // Update the content with the intent
            let messageContent = try content.updating(from: incomingMessageIntent)
            self.contentHandler?(messageContent)
        } catch {
            print(error)
        }
    }
}
