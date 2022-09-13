//
//  FocusStatusIntentHandler.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/18/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Intents
import Parse
import Combine
import StreamChat

class FocusIntentHandler: NSObject, INShareFocusStatusIntentHandling {
    
    private var cancellables = Set<AnyCancellable>()
    private var client: ChatClient?
    
    override init() {
        super.init()
        self.initializeParse()
    }
    
    private func initializeParse() {
        // Initialize Parse if necessary
        Config.shared.initializeParseIfNeeded()
    }
    
    func handle(intent: INShareFocusStatusIntent, completion: @escaping (INShareFocusStatusIntentResponse) -> Void) {
        guard let isFocused = intent.focusStatus?.isFocused, let currentUser = User.current() else { return }
        
        let newStatus: FocusStatus = isFocused ? .focused : .available
        
        Task {
            do {
                if currentUser.focusStatus != newStatus, !isFocused {
                    self.client = await self.initializeChatClient()
                    self.getUnreadMessagesNotice()
                }
                
                currentUser.focusStatus = newStatus
                try await currentUser.saveLocalThenServer()
                
                let response = INShareFocusStatusIntentResponse(code: .success, userActivity: nil)
                completion(response)
            } catch {
                let response = INShareFocusStatusIntentResponse(code: .failure, userActivity: nil)
                completion(response)
            }
        }
    }
    
    private func initializeChatClient() async -> ChatClient? {
        
        var config = ChatClientConfig(apiKey: .init(Config.shared.environment.chatAPIKey))
        config.isLocalStorageEnabled = true
        config.applicationGroupIdentifier = Config.shared.environment.groupId
        let client = ChatClient(config: config)

        do {
            // Get the app token and then apply it to the chat client.
            let result: String = try await withCheckedThrowingContinuation { continuation in
                PFCloud.callFunction(inBackground: "getChatToken",
                                     withParameters: [:]) { (object, error) in
                    
                    if let error = error {
                        if error.code == 209 {
                            continuation.resume(throwing: ClientError.apiError(detail: "Invalid Session"))
                        } else {
                            continuation.resume(throwing: error)
                        }
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
    
    private func getUnreadMessagesNotice() {
        guard let query = Notice.query() else { return }
        query.whereKey("type", equalTo: Notice.NoticeType.unreadMessages.rawValue)
        do {
            if let notice = try? query.getFirstObject() as? Notice {
                self.scheduleUnreadMessagesNote(with: notice)
            }
        }
    }
    
    private func scheduleUnreadMessagesNote(with notice: Notice) {
    
        Task {
            let messages: [ChatMessage?] = await notice.unreadMessages.asyncMap { dict in
                if let messageId = dict.keys.first,
                   let cidValue = dict[messageId],
                   let message = await self.findMessage(with: messageId, cid: cidValue) {
                    return message
                }
                
                return nil
            }
            
            await messages.asyncForEach { message in
                if let msg = message, msg.author.id != User.current()?.personId {
                    await self.scheduleNotification(with: msg)
                }
            }
        }
    }
    
    private func findMessage(with messageId: String, cid: String) async -> ChatMessage? {
        guard let client = self.client,
              let cid = try? ChannelId(cid: cid) else { return nil }
        
        let controller = client.messageController(cid: cid, messageId: messageId)
        
        return await withCheckedContinuation({ continuation in
            controller.synchronize { error in
                continuation.resume(returning: controller.message)
            }
        })
    }
    
    private func scheduleNotification(with message: ChatMessage) async {
        guard let user = try? await User.getObject(with: message.author.id),
        let author = try? await user.retrieveDataIfNeeded() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "While you were away..."
        content.subtitle = "\(self.getTimeAgoString(for: message.createdAt))" 
        content.body = "\(author.givenName) said: \(message.text)"
        content.setData(value: DeepLinkTarget.conversation.rawValue, for: .target)
        content.setData(value: message.author.id, for: .author)
        content.setData(value: message.id, for: .messageId)
        content.setData(value: message.cid?.description ?? "", for: .conversationId)
        content.setStreamData(value: message.cid?.id ?? "", for: .cid)
        content.setStreamData(value: message.id, for: .messageId)
        content.setStreamData(value: "message.new", for: .type)
        content.setStreamData(value: message.author.id, for: .author)
        content.interruptionLevel = .active
        
        let request = UNNotificationRequest(identifier: message.id,
                                            content: content,
                                            trigger: nil)

        try? await UNUserNotificationCenter.current().add(request)
    }
    
    private func getTimeAgoString(for date: Date) -> String {

        let now = Date()
        let aMinuteAgo = now.subtract(component: .minute, amount: 1)
        let anHourAgo = now.subtract(component: .hour, amount: 1)
        let aDayAgo = now.subtract(component: .day, amount: 1)
        let aWeekAgo = now.subtract(component: .weekOfYear, amount: 1)
        let aMonthAgo = now.subtract(component: .month, amount: 1)
        let aYearAgo = now.subtract(component: .year, amount: 1)

        if date.isBetween(now, and: aMinuteAgo!) {
            return "Just now"

            // If less than hour - show # minutes
        } else if date.isBetween(now, and: anHourAgo!), let diff = date.minutes(from: now) {
            if abs(diff) == 1 {
                return "\(abs(diff)) min ago @ \(Date.hourMinuteTimeOfDay.string(from: date))"
            } else {
                return "\(abs(diff)) mins ago @ \(Date.hourMinuteTimeOfDay.string(from: date))"
            }
            // If greater than an hour AND less than a day - show # hours
        } else if date.isBetween(anHourAgo!, and: aDayAgo!), let diff = date.hours(from: now) {
            if abs(diff) == 1 {
                return "\(abs(diff)) hour ago @ \(Date.hourMinuteTimeOfDay.string(from: date))"
            } else {
                return "\(abs(diff)) hours ago @ \(Date.hourMinuteTimeOfDay.string(from: date))"
            }
            // If greater than a day AND less than a week - show # of days
        } else if date.isBetween(aDayAgo!, and: aWeekAgo!), let diff = date.days(from: now) {
            if abs(diff) == 1 {
                return "\(abs(diff)) day ago @ \(Date.hourMinuteTimeOfDay.string(from: date))"
            } else {
                return "\(abs(diff)) days ago @ \(Date.hourMinuteTimeOfDay.string(from: date))"
            }
            // If greater than a week AND less than a month - show # of weeks
        } else if date.isBetween(aWeekAgo!, and: aMonthAgo!), let diff = date.weeks(from: now) {
            if abs(diff) == 1 {
                return "\(abs(diff)) week ago @ \(Date.hourMinuteTimeOfDay.string(from: date))"
            } else {
                return "\(abs(diff)) weeks ago @ \(Date.hourMinuteTimeOfDay.string(from: date))"
            }
            // If greater than a month AND less than a year - show # of months
        } else if date.isBetween(aMonthAgo!, and: aYearAgo!), let diff = date.months(from: now) {
            if abs(diff) == 1 {
                return "\(abs(diff)) month ago @ \(Date.hourMinuteTimeOfDay.string(from: date))"
            } else {
                return "\(abs(diff)) months ago @ \(Date.hourMinuteTimeOfDay.string(from: date))"
            }
        } else {
            return "A very long time ago..."
        }
    }
}
