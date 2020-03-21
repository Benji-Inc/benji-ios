//
//  Connection+CloudCalls.swift
//  Benji
//
//  Created by Benji Dodgson on 2/11/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import TMROFutures
import PhoneNumberKit

struct CreateConnection: CloudFunction {

    var phoneNumber: PhoneNumber

    func makeRequest() -> Future<Connection> {
        let promise = Promise<Connection>()

        var params: [String: Any] = [:]
        params["phoneNumber"] = PhoneKit.shared.format(self.phoneNumber, toType: .e164)

        PFCloud.callFunction(inBackground: "createConnection",
                             withParameters: params) { (object, error) in
                                if let error = error {
                                    promise.reject(with: error)
                                } else if let connection = object as? Connection {
                                    promise.resolve(with: connection)
                                } else {
                                    promise.reject(with: ClientError.message(detail: "There was a problem connecting with that phone number."))
                                }
        }

        return promise.withResultToast()
    }
}

struct UpdateConnection: CloudFunction {

    var connection: Connection

    func makeRequest() -> Future<Void> {
        let promise = Promise<Void>()

        PFCloud.callFunction(inBackground: "updateConnection",
                             withParameters: ["connectionID": self.connection.objectId!,
                                              "status": self.connection.status!.rawValue]) { (object, error) in
                                if let error = error {
                                    promise.reject(with: error)
                                } else {
                                    promise.resolve(with: ())
                                }
        }

        return promise.withResultToast()
    }
}


