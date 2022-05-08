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

extension ChatMessage {
    var inAttachments: [INSendMessageAttachment] {
        return self.imageAttachments.compactMap { attachment in
            let file = INFile(fileURL: attachment.imagePreviewURL, filename: attachment.title, typeIdentifier: "public.png")
            return INSendMessageAttachment.init(audioMessageFile: file)
        }
    }
}

class NotificationService: UNNotificationServiceExtension {

    /// The current notification request that we're processing.
    private var request: UNNotificationRequest?
    /// The content handler we received for the notification request we're processing.
    private var contentHandler: ((UNNotificationContent) -> Void)?

    private var author: INPerson?
    private var conversation: ChatChannel?
    private var message: ChatMessage?
    private var messageDeliveryType: MessageDeliveryType? {
        guard let value = self.message?.extraData["context"],
              case RawJSON.string(let string) = value else { return nil }
        return MessageDeliveryType(rawValue: string)
    }
    private var recipients: [INPerson] = []

    // MARK: - UNNotificationServiceExtension

    override func didReceive(_ request: UNNotificationRequest,
                             withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {

        // Save the request and content handler in case we need to finish early.
        self.request = request
        self.contentHandler = contentHandler

        // Reset the member vars so new notifications don't get polluted with old data.
        self.author = nil
        self.conversation = nil
        self.message = nil
        self.recipients = []

        Task {
            await self.initializeParse()

            guard let chatClient = await self.getConfiguredChatClient(),
                  let mutableContent = request.content.mutableCopy() as? UNMutableNotificationContent else {

                      contentHandler(request.content)
                      return
                  }


            await self.initializeNotificationService(with: mutableContent, client: chatClient)
            await self.updateInterruptionLevel(of: mutableContent)
            await self.updateBadgeCount(of: mutableContent)

            let finalContent = await self.finalizeContent(mutableContent)
            contentHandler(finalContent)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        guard let content = self.request?.content.mutableCopy() as? UNMutableNotificationContent,
                let contentHandler = self.contentHandler else { return }

        Task {
            let content = await self.finalizeContent(content)
            contentHandler(content)
        }
    }

    // MARK: - Parse/Chat Initialization

    private func initializeParse() async {
        return await withCheckedContinuation { continuation in
            if Parse.currentConfiguration.isNil  {
                let config = ParseClientConfiguration { configuration in
                    configuration.applicationGroupIdentifier = Config.shared.environment.groupId
                    // Allow parse to access the data from the main app bundle.
                    configuration.containingApplicationBundleIdentifier = Config.shared.environment.bundleId
                    configuration.server = Config.shared.environment.url
                    configuration.applicationId = Config.shared.environment.appId
                    configuration.isLocalDatastoreEnabled = true
                }

                Parse.initialize(with: config)
            }

            continuation.resume(returning: ())
        }
    }

    private func getConfiguredChatClient() async -> ChatClient? {
        guard let user = User.current(), user.isAuthenticated  else { return nil }

        var config = ChatClientConfig(apiKey: .init(Config.shared.environment.chatAPIKey))
        config.isLocalStorageEnabled = true
        config.applicationGroupIdentifier = Config.shared.environment.groupId
        let client = ChatClient(config: config, tokenProvider: nil)

        do {
            // Get the app token and then apply it to the chat client.
            let result: String = try await withCheckedThrowingContinuation { continuation in
                PFCloud.callFunction(inBackground: "getChatToken",
                                     withParameters: [:]) { (object, error) in

                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let value = object as? String {
                        continuation.resume(returning: value)
                    } else {
                        continuation.resume(throwing: ClientError.apiError(detail: "Request failed"))
                    }
                }
            }

            let token = try Token(rawValue: result)
            client.setToken(token: token)

            return client
        } catch {
            logError(error)
            return nil
        }
    }

    // MARK: - Notification Content Updates

    /// Initializes all of the member variables on the notification service that are needed to update the notification content.
    private func initializeNotificationService(with content: UNNotificationContent,
                                               client: ChatClient) async {
        // Ensure we have the data we need
        guard let authorId = content.author,
              let author = try? await User.getObject(with: authorId).iNPerson else {
                  return
              }

        self.author = author
        // Creat a notification handler so we can retrieve the relevant message data.
        // (This is needed because the ChatClient can't be put in the connected state from an extension).
        // See: https://getstream.io/chat/docs/sdk/ios/guides/push-notifications/
        let chatHandler = ChatRemoteNotificationHandler(client: client, content: content)

        let notificationContent = await chatHandler.handleNotification()

        switch notificationContent {
        case .message(let msg):
            guard let conversation = msg.channel else { break }

            self.conversation = conversation
            self.message = msg.message
        case .reaction(let reaction):
            guard let conversation = reaction.channel else { break }

            self.conversation = conversation
            self.message = reaction.message
        case .unknown(_):
            logDebug("unknown notification content received")
            break
        }

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
    }

    private func updateInterruptionLevel(of content: UNMutableNotificationContent) async {
        // Update the interruption level
        guard let messageDeliveryType = self.messageDeliveryType else { return }

        switch messageDeliveryType {
        case .timeSensitive:
            // Time-sensitive messages are always delivered with a time-sensitive interruption level
            // regardless of the user's current focus state
            content.interruptionLevel = .timeSensitive
        case .conversational:
            // Conversational messages will show on the lock screen if a users focus status allows
            content.interruptionLevel = .active
        case .respectful:
            // Respectful messages are delivered passively for focused users, and actively for
            // for non-focused users.
            if INFocusStatusCenter.default.focusStatus.isFocused == true {
                content.interruptionLevel = .passive
            } else {
                content.interruptionLevel = .active
            }
        }
    }

    private func updateBadgeCount(of content: UNMutableNotificationContent) async {
        // Only increment the badge count for time sensitive messages.
        guard self.messageDeliveryType == .timeSensitive else { return }

        let badgeNumber = self.getUserDefaultsBadgeNumber() + 1
        content.badge = badgeNumber as NSNumber
        self.setUserDefaultsBadgeNumber(to: badgeNumber)
    }

    private func finalizeContent(_ content: UNMutableNotificationContent) async -> UNNotificationContent {
        // Create the intent
        let incomingMessageIntent
        = INSendMessageIntent(recipients: self.recipients,
                              outgoingMessageType: .outgoingMessageText,
                              content: content.body,
                              speakableGroupName: self.conversation?.speakableGroupName,
                              conversationIdentifier: self.conversation?.cid.description,
                              serviceName: "Jibber",
                              sender: self.author,
                              attachments: self.message?.inAttachments)

        let interaction = INInteraction(intent: incomingMessageIntent, response: nil)
        interaction.direction = .incoming

        do {
            try await interaction.donate()
            // Update the content with the intent
            let messageContent = try content.updating(from: incomingMessageIntent)
            return messageContent
        } catch {
            logError(error)
            return content
        }
    }

    // MARK: - Helper Functions

    /// Gets the app badge number stored in user defaults.
    private func getUserDefaultsBadgeNumber() -> Int {
        guard let defaults = UserDefaults(suiteName: Config.shared.environment.groupId),
              let count = defaults.value(forKey: "badgeNumber") as? Int else { return 0 }

        return count
    }

    /// Sets the badge number stored in user defaults.
    private func setUserDefaultsBadgeNumber(to number: Int) {
        guard let defaults = UserDefaults(suiteName: Config.shared.environment.groupId) else {
            logDebug("Failed to update badge number")
            return
        }

        defaults.set(number as NSNumber, forKey: "badgeNumber")
    }
}

extension ChatRemoteNotificationHandler {

    func handleNotification() async -> ChatPushNotificationContent {
        let content: ChatPushNotificationContent = await withCheckedContinuation { continuation in
            _ = self.handleNotification { content in
                continuation.resume(returning: content)
            }
        }

        return content
    }
}
