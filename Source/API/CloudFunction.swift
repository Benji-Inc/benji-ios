//
//  CloudCalls.swift
//  Benji
//
//  Created by Benji Dodgson on 9/10/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import TMROFutures

protocol CloudFunction: StatusableRequest {
    func makeRequest(andUpdate statusables: [Statusable], viewsToIgnore: [UIView]) -> Future<ReturnType>
}

extension CloudFunction {

    func makeRequest(andUpdate statusables: [Statusable],
                        params: [String: Any],
                        callName: String,
                        viewsToIgnore: [UIView]) -> Future<Any> {

        let promise = Promise<Any>()

        // Trigger the loading event for all statusables
        for statusable in statusables {
            statusable.handleEvent(status: .loading)
        }

        // Reference the statusables weakly in case they are deallocated before the signal finishes.
        let weakStatusables: [WeakAnyStatusable] = statusables.map { (statusable)  in
            return WeakAnyStatusable(statusable)
        }

        PFCloud.callFunction(inBackground: callName,
                             withParameters: params) { (object, error) in

            if let error = error {
                SessionManager.shared.handleParse(error: error)
                weakStatusables.forEach { (statusable) in
                    statusable.value?.handleEvent(status: .error(error.localizedDescription))
                }
                promise.reject(with: error)
            } else if let value = object {
                weakStatusables.forEach { (statusable) in
                    statusable.value?.handleEvent(status: .saved)
                }
                // A saved status is temporary so we set it to complete after a short delay
                delay(2.0) {
                    weakStatusables.forEach { (statusable) in
                        statusable.value?.handleEvent(status: .complete)
                    }

                    promise.resolve(with: value)
                }
            } else {
                weakStatusables.forEach { (statusable) in
                    statusable.value?.handleEvent(status: .error("Request failed"))
                }
                promise.reject(with: ClientError.apiError(detail: "Request failed"))
            }
        }            

        return promise.ignoreUserInteractionEventsUntilDone(for: viewsToIgnore)
    }
}
