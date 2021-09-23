//
//  ToastScheduler.swift
//  Jibber
//
//  Created by Benji Dodgson on 5/3/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization
import Combine

enum ToastType {
    #warning("Add associated values to newMessage")
    case newMessage
    case error(ClientError)
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

    func schedule(toastType: ToastType) {
        switch toastType {
        case .error(let error):
            self.createErrorToast(for: error)
        case .basic(let identifier, let displayable, let title, let description, let deepLink):
            self.createBasicToast(for: identifier,
                                     displayable: displayable,
                                     title: title,
                                     description: description,
                                     deepLink: deepLink)
        case .newMessage:
            #warning("Replace")
//            Task {
//                await self.createMessageToast(for: msg, conversation: conversation)
//            }
        }
    }

    private func createErrorToast(for error: ClientError) {
        guard let image = UIImage(systemName: "exclamationmark.triangle") else { return }

        let toast = Toast(id: error.localizedDescription + "error",
                          priority: 1,
                          title: "Oops!",
                          description: error.localizedDescription,
                          displayable: image,
                          deeplink: nil,
                          didTap: { [unowned self] in
            self.delegate?.didInteractWith(type: .error(error), deeplink: nil)
        })

        ToastQueue.shared.add(toast: toast)
    }

    private func createBasicToast(for identifier: String,
                                  displayable: ImageDisplayable,
                                  title: Localized,
                                  description: Localized,
                                  deepLink: DeepLinkable?) {

        let toast = Toast(id: identifier,
                          priority: 1,
                          title: title,
                          description: description,
                          displayable: displayable,
                          deeplink: deepLink,
                          didTap: { [unowned self] in
            self.delegate?.didInteractWith(type: .basic(identifier: identifier, displayable: displayable, title: title, description: description, deepLink: deepLink), deeplink: deepLink)
        })

        ToastQueue.shared.add(toast: toast)
    }

    #warning("Replace")
//    private func createMessageToast(for message: TCHMessage, conversation: TCHChannel) async {
//        guard let user = try? await message.getAuthorAsUser() else { return }
//
//        guard let body = message.body, !body.isEmpty else { return }
//
//        let toast = Toast(id: message.id,
//                          priority: 1,
//                          title: user.fullName,
//                          description: body,
//                          displayable: user,
//                          deeplink: DeepLinkObject(target: .conversation),
//                          didTap: { [unowned self] in
//
//            let deeplink = DeepLinkObject(target: .conversation)
//            deeplink.customMetadata["conversationId"] = conversation.sid
//            self.delegate?.didInteractWith(type: .newMessage(message, conversation), deeplink: deeplink)
//        })
//
//        ToastQueue.shared.add(toast: toast)
//    }
}
