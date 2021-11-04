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
    case newMessage(Messageable)
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

    @MainActor
    func schedule(toastType: ToastType) async {
        
        switch toastType {
        case .error(let error):
            self.createErrorToast(for: error)
        case .basic(let identifier, let displayable, let title, let description, let deepLink):
            self.createBasicToast(for: identifier,
                                     displayable: displayable,
                                     title: title,
                                     description: description,
                                     deepLink: deepLink)
        case .newMessage(let message):
            self.createMessageToast(for: message)
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

    private func createMessageToast(for message: Messageable) {

        guard case MessageKind.text(let text) = message.kind,
                !text.isEmpty,
        let author = UserStore.shared.users.first(where: { user in
            return user.userObjectID == message.authorID
        }) else { return }

        let toast = Toast(id: message.id,
                          priority: 1,
                          title: author.fullName,
                          description: text,
                          displayable: author,
                          deeplink: DeepLinkObject(target: .conversation),
                          didTap: { [unowned self] in

            let deeplink = DeepLinkObject(target: .conversation)
            deeplink.customMetadata["conversationId"] = message.conversationId
            deeplink.customMetadata["messageId"] = message.id
            self.delegate?.didInteractWith(type: .newMessage(message), deeplink: deeplink)
        })

        ToastQueue.shared.add(toast: toast)
    }
}
