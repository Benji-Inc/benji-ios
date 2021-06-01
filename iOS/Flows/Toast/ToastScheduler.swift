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
import Combine

enum ToastType {
    case newMessage(TCHMessage, TCHChannel)
    case error(ClientError)
    case basic(identifier: String, displayable: ImageDisplayable, title: Localized, description: Localized)
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
        case .basic(let identifier, let displayable, let title, let description):
            self.createBasicToast(for: identifier, displayable: displayable, title: title, description: description)
        case .newMessage(let msg, let channel):
            self.createMessageToast(for: msg, channel: channel)
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
                                  description: Localized) {

        let toast = Toast(id: Lorem.randomString(),
                          priority: 1,
                          title: title,
                          description: description,
                          displayable: displayable,
                          deeplink: nil,
                          didTap: { [unowned self] in
                            self.delegate?.didInteractWith(type: .basic(identifier: identifier, displayable: displayable, title: title, description: description), deeplink: nil)
                          })

        ToastQueue.shared.add(toast: toast)
    }

    private func createMessageToast(for message: TCHMessage, channel: TCHChannel) {
        guard let body = message.body, !body.isEmpty else { return }

        message.getAuthorAsUser()
            .mainSink { result in
                switch result {
                case .success(let user):
                    let toast = Toast(id: message.id,
                                      priority: 1,
                                      title: user.fullName,
                                      description: body,
                                      displayable: user,
                                      deeplink: DeepLinkObject(target: .channel),
                                      didTap: { [unowned self] in
                                        let deeplink = DeepLinkObject(target: .channel)
                                        deeplink.customMetadata["channelId"] = channel.sid
                                        self.delegate?.didInteractWith(type: .newMessage(message, channel), deeplink: deeplink)
                                      })

                    ToastQueue.shared.add(toast: toast)
                case .error(_):
                    break
                }
            }.store(in: &self.cancellables)
    }
}
