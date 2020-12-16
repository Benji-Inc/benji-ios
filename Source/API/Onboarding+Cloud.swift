//
//  Onboarding+CloudCalls.swift
//  Benji
//
//  Created by Benji Dodgson on 2/11/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import TMROFutures
import PhoneNumberKit

struct SendCode: CloudFunction {
    typealias ReturnType = Void

    let phoneNumber: PhoneNumber
    let region: String
    let installationId: String
    let reservationId: String?

    func makeRequest(andUpdate statusables: [Statusable], viewsToIgnore: [UIView]) -> Future<Void> {
        let params = ["phoneNumber": PhoneKit.shared.format(self.phoneNumber, toType: .e164),
                      "installationId": self.installationId,
                      "reservationId": String(optional: self.reservationId),
                      "region": self.region]
        
        return self.makeRequest(andUpdate: statusables,
                                params: params,
                                callName: "sendCode",
                                viewsToIgnore: viewsToIgnore).asVoid()
    }
}

enum VerifyCodeResult {
    case success(String)
    case addedToWaitlist
}

struct VerifyCode: CloudFunction {
    typealias ReturnType = VerifyCodeResult

    let code: String
    let phoneNumber: PhoneNumber
    let installationId: String
    let reservationId: String

    func makeRequest(andUpdate statusables: [Statusable], viewsToIgnore: [UIView]) -> Future<VerifyCodeResult> {
        let params: [String: Any] = ["authCode": self.code,
                                     "installationId": self.installationId,
                                     "reservationId": self.reservationId,
                                     "phoneNumber": PhoneKit.shared.format(self.phoneNumber, toType: .e164)]

        return self.makeRequest(andUpdate: statusables,
                                params: params,
                                callName: "validateCode",
                                viewsToIgnore: viewsToIgnore).transform { (value) -> VerifyCodeResult in
                                    if let dict = value as? [String: String] {
                                        return .success("Foo")
                                    } else {
                                        return .addedToWaitlist
                                    }
                                }
    }
}
