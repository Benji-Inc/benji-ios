//
//  Reservation+CloudCalls.swift
//  Benji
//
//  Created by Benji Dodgson on 2/11/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROFutures
import Parse

enum ReservationResponse {
    case found(Reservation)
    case notFound
}

struct VerifyReservation: CloudFunction {

    let code: String

    func makeRequest() -> Future<ReservationResponse> {
        let promise = Promise<ReservationResponse>()

        let params: [String: Any] = ["code": self.code]

        PFCloud.callFunction(inBackground: "verifyReservation",
                             withParameters: params) { (object, error) in
                                if let strongError = error {
                                    if (strongError as NSError).code == 141 {
                                        promise.resolve(with: .notFound)
                                    } else {
                                        promise.reject(with: strongError)
                                    }
                                } else if let reservation = object as? Reservation {
                                    promise.resolve(with: .found(reservation))
                                } else {
                                    promise.reject(with: ClientError.message(detail: "There was a problem verifying the code you entered."))
                                }
        }

        return promise.withResultToast()
    }
}
