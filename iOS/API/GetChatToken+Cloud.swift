//
//  ChatToken+Cloud.swift
//  Benji
//
//  Created by Benji Dodgson on 5/14/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import Combine

struct GetChatToken: CloudFunction {
    
    typealias ReturnType = String
    
    func makeRequest(andUpdate statusables: [Statusable] = [],
                     viewsToIgnore: [UIView] = []) async throws -> String {
        
        let result = try await self.makeRequest(andUpdate: [],
                                                params: [:],
                                                callName: "getChatToken",
                                                viewsToIgnore: [])
        
        guard let token = result as? String else {
            throw(ClientError.apiError(detail: "Chat token error"))
        }
        
        return token
    }
}
