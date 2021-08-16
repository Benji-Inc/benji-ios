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
        let phoneString = PhoneKit.shared.format(self.phoneNumber, toType: .e164)
        
        let params = ["phoneNumber": phoneString,
                      "installationId": self.installationId,
                      "region": self.region]
        
        return self.makeRequest(andUpdate: statusables,
                                params: params,
                                callName: "sendCode",
                                delayInterval: 0.0,
                                viewsToIgnore: viewsToIgnore).eraseToAnyPublisher()
    }
    
    func makeAsyncRequest(andUpdate statusables: [Statusable] = [],
                          viewsToIgnore: [UIView] = []) async throws -> Any {

        let phoneString = PhoneKit.shared.format(self.phoneNumber, toType: .e164)
        
        let params = ["phoneNumber": phoneString,
                      "installationId": self.installationId,
                      "region": self.region]
        
        let result = try await self.makeAsyncRequest(andUpdate: statusables,
                                                     params: params,
                                                     callName: "sendCode",
                                                     delayInterval: 0.0,
                                                     viewsToIgnore: viewsToIgnore)
        return result
    }
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
    
    func makeAsyncRequest(andUpdate statusables: [Statusable],
                          viewsToIgnore: [UIView]) async throws -> String {
        
        let params: [String: Any] = ["authCode": self.code,
                                     "installationId": self.installationId,
                                     "reservationId": self.reservationId,
                                     "phoneNumber": PhoneKit.shared.format(self.phoneNumber, toType: .e164)]
        
        let result = try await self.makeAsyncRequest(andUpdate: statusables,
                                                     params: params,
                                                     callName: "validateCode",
                                                     viewsToIgnore: viewsToIgnore)
        
        if let token = result as? String, !token.isEmpty {
            return token
        } else {
            throw(ClientError.apiError(detail: "Verify code error"))
        }
    }
}

struct ActivateUser: CloudFunction {
    
    typealias ReturnType = Any
    
    func makeRequest(andUpdate statusables: [Statusable],
                     viewsToIgnore: [UIView]) -> AnyPublisher<Any, Error> {
        
        return self.makeRequest(andUpdate: statusables,
                                params: [:],
                                callName: "setActiveStatus",
                                delayInterval: 0.0,
                                viewsToIgnore: viewsToIgnore).eraseToAnyPublisher()
    }
    
    func makeAsyncRequest(andUpdate statusables: [Statusable], viewsToIgnore: [UIView]) async throws -> Any {
        return try await self.makeAsyncRequest(andUpdate: statusables,
                                               params: [:],
                                               callName: "setActiveStatus",
                                               delayInterval: 0.0,
                                               viewsToIgnore: viewsToIgnore)
    }
}
