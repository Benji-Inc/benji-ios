//
//  ToastScheduler.swift
//  Jibber
//
//  Created by Benji Dodgson on 5/3/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine
import Localization

enum ToastType {
    case newContextCue(ContextCue)
    case newMessage(Messageable)
    case error(ClientError)
    case transaction(Transaction)
    case basic(identifier: String,
               displayable: ImageDisplayable,
               title: Localized,
               description: Localized,
               deepLink: DeepLinkable?)
}

protocol ToastSchedulerDelegate: AnyObject {
    func didInteractWith(type: ToastType, deeplink: DeepLinkable?)
}

class ToastScheduler {
    static let shared = ToastScheduler()

    private var cancellables = Set<AnyCancellable>()

    weak var delegate: ToastSchedulerDelegate?

    @MainActor
    func schedule(toastType: ToastType,
                  position: Toast.Position = .top,
                  duration: TimeInterval = 10) async {

        var toast: Toast? = nil

        switch toastType {
        case .error(let error):
            toast = self.createErrorToast(for: error,
                                             position: position,
                                             duration: duration)
        case .basic(let identifier, let displayable, let title, let description, let deepLink):
            toast = self.createBasicToast(for: identifier,
                                             position: position,
                                             duration: duration,
                                             displayable: displayable,
                                             title: title,
                                             description: description,
                                             deepLink: deepLink)
        case .newMessage(let message):
            toast = self.createMessageToast(for: message,
                                               position: position,
                                               duration: duration)
        case .transaction(let transaction):
            toast = try? await self.createTransactionToast(for: transaction,
                                                              position: position,
                                                              duration: duration)
        case .newContextCue(let contextCue):
            toast = try? await self.createContextCueToast(for: contextCue,
                                                             position: position,
                                                             duration: duration)
        }

        if let t = toast {
            ToastQueue.shared.add(toast: t)
        }
    }

    private func createErrorToast(for error: ClientError,
                                  position: Toast.Position,
                                  duration: TimeInterval) -> Toast? {
        guard let image = UIImage(systemName: "exclamationmark.triangle") else { return nil }

        let toast = Toast(id: UUID().uuidString,
                          priority: 1,
                          title: "",
                          description: error.localizedDescription,
                          displayable: image,
                          deeplink: nil,
                          type: .error,
                          position: position,
                          duration: duration,
                          didTap: { [unowned self] in
            self.delegate?.didInteractWith(type: .error(error), deeplink: nil)
        })

        return toast
    }

    private func createBasicToast(for identifier: String,
                                  position: Toast.Position,
                                  duration: TimeInterval,
                                  displayable: ImageDisplayable,
                                  title: Localized,
                                  description: Localized,
                                  deepLink: DeepLinkable?) -> Toast? {

        let toast = Toast(id: identifier,
                          priority: 1,
                          title: title,
                          description: description,
                          displayable: displayable,
                          deeplink: deepLink,
                          type: .banner,
                          position: position,
                          duration: duration,
                          didTap: { [unowned self] in
            self.delegate?.didInteractWith(type: .basic(identifier: identifier, displayable: displayable, title: title, description: description, deepLink: deepLink), deeplink: deepLink)
        })

        return toast
    }

    private func createMessageToast(for message: Messageable,
                                    position: Toast.Position,
                                    duration: TimeInterval) -> Toast? {

        guard case MessageKind.text(let text) = message.kind,
              !text.isEmpty,
              let author = PeopleStore.shared.usersArray.first(where: { person in
                  return person.personId == message.authorId
              }) else { return nil }

        let toast = Toast(id: message.id,
                          priority: 1,
                          title: author.fullName,
                          description: text,
                          displayable: author,
                          deeplink: DeepLinkObject(target: .conversation),
                          type: .banner,
                          position: position,
                          duration: duration,
                          didTap: { [unowned self] in

            let deeplink = DeepLinkObject(target: .conversation)
            deeplink.customMetadata["conversationId"] = message.conversationId
            deeplink.customMetadata["messageId"] = message.id
            self.delegate?.didInteractWith(type: .newMessage(message), deeplink: deeplink)
        })

        return toast
    }
    
    private func createTransactionToast(for transaction: Transaction,
                                        position: Toast.Position,
                                        duration: TimeInterval) async throws -> Toast? {
        guard let transaction = try? await transaction.retrieveDataIfNeeded(),
              let objectId = transaction.objectId,
              let from = transaction.from else { return nil }

        let toast = Toast(id: objectId,
                          priority: 1,
                          title: "\(transaction.amount) Jibs received",
                          description: transaction.note,
                          displayable: from,
                          deeplink: nil,
                          type: .banner,
                          position: position,
                          duration: duration,
                          didTap: { [unowned self] in
            self.delegate?.didInteractWith(type: .transaction(transaction), deeplink: nil)
        })

        return toast
    }
    
    private func createContextCueToast(for contextCue: ContextCue,
                                        position: Toast.Position,
                                        duration: TimeInterval) async throws -> Toast? {
        guard let contextCue = try? await contextCue.retrieveDataIfNeeded(),
              let current = User.current(),
              let objectId = contextCue.objectId else { return nil }

        let toast = Toast(id: objectId,
                          priority: 1,
                          title: "Context Updated",
                          description: contextCue.emojiString,
                          displayable: current,
                          deeplink: nil,
                          type: .banner,
                          position: position,
                          duration: duration,
                          didTap: { [unowned self] in
            self.delegate?.didInteractWith(type: .newContextCue(contextCue), deeplink: nil)
        })

        return toast
    }
}
