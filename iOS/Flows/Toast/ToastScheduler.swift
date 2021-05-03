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
    case error(Error)
    case basic(displayable: ImageDisplayable, title: Localized, description: Localized)
}

protocol ToastSchedulerDelegate: AnyObject {
    func didInteractWith(type: ToastType)
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
        }

        if let t = toast {
            runMain {
                ToastQueue.shared.add(toast: t)
            }
        }
    }

    private func createErrorToast(for error: Error) -> Toast? {
        guard let image = UIImage(systemName: "error") else { return nil }

        return Toast(id: error.localizedDescription + "error",
                     priority: 1,
                     title: "Error",
                     description: error.localizedDescription,
                     displayable: image,
                     deeplink: nil,
                     didTap: { [unowned self] in 
                        self.delegate?.didInteractWith(type: .error(error))
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
                        self.delegate?.didInteractWith(type: .basic(displayable: displayable, title: title, description: description))
        })
    }
}
