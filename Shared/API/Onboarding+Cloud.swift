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

struct SendCode: CloudFunction {
    
    typealias ReturnType = Any
    
    let phoneNumber: PhoneNumber
    let region: String
    let installationId: String
    
    func makeRequest(andUpdate statusables: [Statusable] = [],
                          viewsToIgnore: [UIView] = []) async throws -> Any {

        let phoneString = PhoneKit.shared.format(self.phoneNumber, toType: .e164)
        
        let params = ["phoneNumber": phoneString,
                      "installationId": self.installationId,
                      "region": self.region]
        
        let result = try await self.makeRequest(andUpdate: statusables,
                                                     params: params,
                                                     callName: "sendCode",
                                                     delayInterval: 0.0,
                                                     viewsToIgnore: viewsToIgnore)
        return result
    }
}

struct VerifyCode: CloudFunction {
    typealias ReturnType = [String: String]
    
    let code: String
    let phoneNumber: PhoneNumber
    let installationId: String
    let reservationId: String
    let passId: String

    func makeRequest(andUpdate statusables: [Statusable] = [],
                     viewsToIgnore: [UIView] = []) async throws -> [String: String] {
        
        let params: [String: Any] = ["authCode": self.code,
                                     "installationId": self.installationId,
                                     "passId": self.passId,
                                     "reservationId": self.reservationId,
                                     "phoneNumber": PhoneKit.shared.format(self.phoneNumber, toType: .e164)]
        
        let result = try await self.makeRequest(andUpdate: statusables,
                                                     params: params,
                                                     callName: "validateCode",
                                                     viewsToIgnore: viewsToIgnore)
        
        if let dict = result as? [String: String],
           let token = dict["sessionToken"],
            !token.isEmpty {
            return dict
        } else if let token = result as? String {
            var dict: [String: String] = [:]
            dict["sessionToken"] = token
            return dict 
        } else {
            throw(ClientError.apiError(detail: "Verify code error"))
        }
    }
}

struct ActivateUser: CloudFunction {

    typealias ReturnType = Any
    let fullName: String

    @discardableResult
    func makeRequest(andUpdate statusables: [Statusable], viewsToIgnore: [UIView]) async throws -> Any {

        let fullName = self.formatName(from: fullName)

        return try await self.makeRequest(andUpdate: statusables,
                                          params: ["givenName": fullName.givenName,
                                                   "familyName": fullName.familyName],
                                               callName: "setActiveStatus",
                                               delayInterval: 0.0,
                                               viewsToIgnore: viewsToIgnore)
    }

    private func formatName(from text: String) -> (givenName: String, familyName: String) {
        let components = text.components(separatedBy: " ").filter { (component) -> Bool in
            return !component.isEmpty
        }

        var givenName = ""
        var familyName = ""

        if let first = components.first {
            givenName = first
        }
        if let last = components.last {
            familyName = last
        }

        return (givenName, familyName)
    }
}
