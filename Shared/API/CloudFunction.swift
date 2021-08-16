//
//  CloudCalls.swift
//  Benji
//
//  Created by Benji Dodgson on 9/10/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import Combine

protocol CloudFunction: StatusableRequest {
    @available(*, deprecated, message: "Use async instead.")
    func makeSynchronousRequest(andUpdate statusables: [Statusable],
                                viewsToIgnore: [UIView]) -> AnyPublisher<ReturnType, Error>
    func makeAsyncRequest(andUpdate statusables: [Statusable],
                          viewsToIgnore: [UIView]) async throws -> ReturnType
}

extension CloudFunction {

    func makeSynchronousRequest(andUpdate statusables: [Statusable],
                                params: [String: Any],
                                callName: String,
                                delayInterval: TimeInterval = 2.0,
                                viewsToIgnore: [UIView]) -> Future<Any, Error> {

        return Future { promise in

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
                    promise(.failure(error))
                } else if let value = object {
                    weakStatusables.forEach { (statusable) in
                        statusable.value?.handleEvent(status: .saved)
                    }
                    // A saved status is temporary so we set it to complete after a short delay
                    delay(delayInterval) {
                        weakStatusables.forEach { (statusable) in
                            statusable.value?.handleEvent(status: .complete)
                        }

                        promise(.success(value))
                    }
                } else {
                    weakStatusables.forEach { (statusable) in
                        statusable.value?.handleEvent(status: .error("Request failed"))
                    }

                    promise(.failure(ClientError.apiError(detail: "Request failed")))
                }
            }
        }
    }

    func makeRequest(andUpdate statusables: [Statusable],
                     params: [String : Any],
                     callName: String,
                     delayInterval: TimeInterval = 2.0,
                     viewsToIgnore: [UIView]) async throws -> Any {

        // Trigger the loading event for all statusables
        for statusable in statusables {
            statusable.handleEvent(status: .loading)
        }

        // Reference the statusables weakly in case they are deallocated before the signal finishes.
        let weakStatusables: [WeakAnyStatusable] = statusables.map { (statusable)  in
            return WeakAnyStatusable(statusable)
        }

        do {
            let result = try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Any, Error>) in

                PFCloud.callFunction(inBackground: callName,
                                     withParameters: params) { (object, error) in

                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let value = object {
                        continuation.resume(returning: value)
                    } else {
                        continuation.resume(throwing: ClientError.apiError(detail: "Request failed"))
                    }
                }
            })

            try Task.checkCancellation()

            weakStatusables.forEach { (statusable) in
                statusable.value?.handleEvent(status: .saved)
            }

            // A saved status is temporary so we set it to complete after a short delay
            delay(delayInterval) {
                weakStatusables.forEach { (statusable) in
                    statusable.value?.handleEvent(status: .complete)
                }
            }

            return result
        } catch {
            SessionManager.shared.handleParse(error: error)
            weakStatusables.forEach { (statusable) in
                statusable.value?.handleEvent(status: .error(error.localizedDescription))
            }
            throw(error)
        }
    }
}
