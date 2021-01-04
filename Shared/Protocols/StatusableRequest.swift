//
//  StatusableRequest.swift
//  Benji
//
//  Created by Benji Dodgson on 12/8/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROFutures

protocol StatusableRequest {
    associatedtype ReturnType
}

extension StatusableRequest {
    
    func handleValue(statusables: [Statusable],
                     value: ReturnType,
                     promise: Promise<ReturnType>) {
        
        var futures: [Future<Void>] = []
        for statusable in statusables {
            let future = statusable.handleEvent(status: .saved)
            futures.append(future)
        }
        
        // Wait for all statusables to finish handling saved
        waitForAll(futures: futures)
            .observeValue { (_) in
                // A saved status is temporary so we set it to complete right after
                statusables.forEach { (statusable) in
                    statusable.handleEvent(status: .complete)
                }
                promise.resolve(with: value)
            }
    }
    
    func handleFailed(statusables: [Statusable],
                      error: Error,
                      promise: Promise<ReturnType>) {
        
        var futures: [Future<Void>] = []
        for statusable in statusables {
            let future = statusable.handleEvent(status: .error(error.localizedDescription))
            futures.append(future)
        }
        waitForAll(futures: futures)
            .observeValue { (_) in
                promise.reject(with: error)
            }
    }
}
