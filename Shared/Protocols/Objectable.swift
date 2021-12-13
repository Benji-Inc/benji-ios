//
//  Objectable.swift
//  Benji
//
//  Created by Benji Dodgson on 11/3/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import ParseSwift
import Combine

enum ContainerName {
    case conversation(identifier: String)
    case favorites
    case users

    var name: String {
        switch self {
        case .conversation(let identifier):
            return "conversation\(identifier)"
        case .favorites:
            return "favorites"
        case .users:
            return "users"
        }
    }
}

extension ParseObject {

    @discardableResult
    func saveAsync() async throws -> Self {
        return try await self.save()
//        let object: Self = try await withCheckedThrowingContinuation { continuation in
//            self.save { [unowned self] result in
//                switch result {
//                case .success(_):
//                    continuation.resume(returning: self)
//                case .failure(let error):
//                    SessionManager.shared.handleParse(error: error)
//                    continuation.resume(throwing: error)
//                }
//            }
//        }
//
//        return object
    }

    static func getFirstObject(where key: String? = nil,
                               contains string: String? = nil) async throws -> Self {
        
        if let k = key, let s = string {
            return try await self.query(k == s).first()
        } else {
            return try await self.query().first()
        }
    }

    static func getObject(with objectId: String?) async throws -> Self {
        let object = try await self.getFirstObject(where: "objectId", contains: objectId)
        return object
    }

    static func fetchAll() async throws -> [Self] {
        return try await self.query().findAll()
    }

    func retrieveDataIfNeeded() async throws -> Self {
        return try await self.fetch()
    }
}
