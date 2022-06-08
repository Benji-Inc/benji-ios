//
//  SystemError.swift
//  Benji
//
//  Created by Benji Dodgson on 7/5/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

enum ClientError: Swift.Error {
    public static let genericErrorString = "We're having some difficulty, please try again later"

    case error(error: Error)
    case apiError(detail: String?)
    case message(detail: String)
    case generic
}

extension ClientError {
    
    var code: Int {
        switch self {
        case .error(let error):
            return error.code
        default:
            return 0 
        }
    }

    var localizedDescription: String {
        switch self {
        case .error(let error):
            return error.localizedDescription
        case .apiError(let detail):
            if let detail = detail {
                return detail
            } else {
                return ClientError.genericErrorString
            }
        case .message(let detail):
            return detail
        case .generic:
            return ClientError.genericErrorString
        }
    }
}
