//
//  ToastScheduler.swift
//  Ours
//
//  Created by Benji Dodgson on 5/3/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TwilioChatClient
import TMROLocalization

enum ToastType {
    case newMessage(TCHMessage, TCHChannel)
    case error(ClientError)
    case basic(displayable: ImageDisplayable, title: Localized, description: Localized)
}

protocol ToastSchedulerDelegate: AnyObject {
    func didInteractWith(type: ToastType, deeplink: DeepLinkable?)
}

class ToastScheduler {
    static let shared = ToastScheduler()

    weak var delegate: ToastSchedulerDelegate?

    func schedule(toastType: ToastType) {

        var toast: Toast?
        switch toastType {
        case .error(let error):
            toast = self.createErrorToast(for: error)
        case .basic(let displayable, let title, let description):
            toast = self.createBasicToast(for: displayable, title: title, description: description)
        case .newMessage(let msg, let channel):
            toast = self.createMessageToast(for: msg, channel: channel)
        }

        if let t = toast {
            runMain {
                ToastQueue.shared.add(toast: t)
            }
        }
    }

    private func createErrorToast(for error: ClientError) -> Toast? {
        guard let image = UIImage(systemName: "exclamationmark.triangle") else { return nil }

        return Toast(id: error.localizedDescription + "error",
                     priority: 1,
                     title: "Oops!",
                     description: error.localizedDescription,
                     displayable: image,
                     deeplink: nil,
                     didTap: { [unowned self] in 
                        self.delegate?.didInteractWith(type: .error(error), deeplink: nil)
        })
    }

    private func createBasicToast(for displayable: ImageDisplayable,
                                  title: Localized,
                                  description: Localized) -> Toast? {

        return Toast(id: Lorem.randomString(),
                     priority: 1,
                     title: title,
                     description: description,
                     displayable: displayable,
                     deeplink: nil,
                     didTap: { [unowned self] in
                        self.delegate?.didInteractWith(type: .basic(displayable: displayable, title: title, description: description), deeplink: nil)
        })
    }

    private func createMessageToast(for message: TCHMessage, channel: TCHChannel) -> Toast? {
        guard let body = message.body, !body.isEmpty else { return nil }

        return Toast(id: message.id,
                     priority: 1,
                     title: message.avatar.fullName,
                     description: body,
                     displayable: message.avatar,
                     deeplink: DeepLinkObject(target: .channel),
                     didTap: { [unowned self] in
                        let deeplink = DeepLinkObject(target: .channel)
                        deeplink.customMetadata["channelId"] = channel.sid
                        self.delegate?.didInteractWith(type: .newMessage(message, channel), deeplink: deeplink)
        })
    }
}
