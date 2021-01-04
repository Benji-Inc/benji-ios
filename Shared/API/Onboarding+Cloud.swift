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

    func makeRequest(andUpdate statusables: [Statusable], viewsToIgnore: [UIView]) -> Future<Void> {
        let params = ["phoneNumber": PhoneKit.shared.format(self.phoneNumber, toType: .e164),
                      "installationId": self.installationId,
                      "region": self.region]
        
        return self.makeRequest(andUpdate: statusables,
                                params: params,
                                callName: "sendCode",
                                delayInterval: 0.0,
                                viewsToIgnore: viewsToIgnore).asVoid()
    }
}

enum VerifyCodeResult {
    case success(String)
    case error
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
                                    if let token = value as? String, !token.isEmpty {
                                        return .success(token)
                                    } else {
                                        return .error
                                    }
                                }
    }
}

struct ActivateUser: CloudFunction {
    typealias ReturnType = Void

    func makeRequest(andUpdate statusables: [Statusable], viewsToIgnore: [UIView]) -> Future<Void> {
        return self.makeRequest(andUpdate: statusables,
                                params: [:],
                                callName: "setActiveStatus",
                                delayInterval: 0.0,
                                viewsToIgnore: viewsToIgnore).asVoid()
    }
}
