//
//  File.swift
//  
//
//  Created by Benji Dodgson on 5/26/22.
//

import Foundation

extension Optional {

    var isNil: Bool {
        return self == nil ? true : false
    }

    var exists: Bool {
        return self == nil ? false: true
    }
}
