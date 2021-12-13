//
//  File.swift
//  
//
//  Created by Benji Dodgson on 12/11/21.
//

import Foundation

public extension String {
    
    init(optional value: String?) {
        if let strongValue = value {
            self.init(stringLiteral: strongValue)
        } else {
            self.init()
        }
    }
}

extension String: Localized {

    public var identifier: String {
        return String()
    }

    public var arguments: [Localized] {
        return []
    }

    public var defaultString: String? {
        return self
    }
}
