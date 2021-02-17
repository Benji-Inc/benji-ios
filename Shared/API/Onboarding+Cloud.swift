//
//  Onboarding+CloudCalls.swift
//  Benji
//
//  Created by Benji Dodgson on 2/11/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import PhoneNumberKit
import Combine

struct SendCode: CloudFunction {
    typealias ReturnType = Any
    
    let phoneNumber: PhoneNumber
    let region: String
    let installationId: String

    func makeRequest(andUpdate statusables: [Statusable], viewsToIgnore: [UIView]) -> AnyPublisher<Any, Error> {
        let params = ["phoneNumber": PhoneKit.shared.format(self.phoneNumber, toType: .e164),
                      "installationId": self.installationId,
                      "region": self.region]
        
        return self.makeRequest(andUpdate: statusables,
                                params: params,
                                callName: "sendCode",
                                delayInterval: 0.0,
                                viewsToIgnore: viewsToIgnore).eraseToAnyPublisher()
    }
}

enum VerifyCodeResult {
    case success(String)
    case error
}

struct VerifyCode: CloudFunction {
    typealias ReturnType = String

    let code: String
    let phoneNumber: PhoneNumber
    let installationId: String
    let reservationId: String

    func makeRequest(andUpdate statusables: [Statusable], viewsToIgnore: [UIView]) -> AnyPublisher<String, Error> {
        let params: [String: Any] = ["authCode": self.code,
                                     "installationId": self.installationId,
                                     "reservationId": self.reservationId,
                                     "phoneNumber": PhoneKit.shared.format(self.phoneNumber, toType: .e164)]

        return self.makeRequest(andUpdate: statusables,
                                params: params,
                                callName: "validateCode",
                                viewsToIgnore: viewsToIgnore).map({ (value) -> String in
                                    if let token = value as? String, !token.isEmpty {
                                        return token
                                    } else {
                                        return ""
                                    }
                                }).eraseToAnyPublisher()
    }
}

struct ActivateUser: CloudFunction {
    typealias ReturnType = Any

    func makeRequest(andUpdate statusables: [Statusable], viewsToIgnore: [UIView]) -> AnyPublisher<Any, Error> {
        return self.makeRequest(andUpdate: statusables,
                                params: [:],
                                callName: "setActiveStatus",
                                delayInterval: 0.0,
                                viewsToIgnore: viewsToIgnore).eraseToAnyPublisher()
    }
}
