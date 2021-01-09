//
//  HealthKitManager.swift
//  Benji
//
//  Created by Benji Dodgson on 4/11/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import HealthKit
import Combine

class HealthKitManager: NSObject, StatusableRequest {
    typealias ReturnType = Bool

    static let shared = HealthKitManager()
    private let store = HKHealthStore()

    private let allReadTypes = Set([HKObjectType.categoryType(forIdentifier: .mindfulSession)!, HKObjectType.quantityType(forIdentifier: .heartRate)!])
    private let allSetTypes = Set([HKObjectType.categoryType(forIdentifier: .mindfulSession)!])

    func requestAuthorization(andUpdate statusables: [Statusable]) -> Future<Void, Error> {
        return Future { promise in
            // Trigger the loading event for all statusables
            for statusable in statusables {
                statusable.handleEvent(status: .loading)
            }

            self.store.requestAuthorization(toShare: self.allSetTypes, read: self.allReadTypes) { (success, error) in
                if let e = error {
                    promise(.failure(e))
                    //self.handleFailed(statusables: statusables, error: e, promise: promise)
                } else {
                    promise(.success(()))
                    //self.handleValue(statusables: statusables, value: success, promise: promise)
                }
            }
        }
    }

    func saveMindfullAnalysis(startTime: Date, endTime: Date, completion: @escaping CompletionHandler) {
        if let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession) {

            // Create a mindful session with the given start and end time
            let mindfullSample = HKCategorySample(type: mindfulType,
                                                  value: 0,
                                                  start: startTime,
                                                  end: endTime)

            // Save it to the health store
            self.store.save(mindfullSample, withCompletion: { (success, error) -> Void in
                completion(success, error)
            })
        } else {
            completion(false, ClientError.generic)
        }
    }
}

