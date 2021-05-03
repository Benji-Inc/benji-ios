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
    case regular(Toast)
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
        case .regular(let t):
            toast = t
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
                     didTap: {
                        self.delegate?.didInteractWith(type: .error(error))
        })
    }
}
