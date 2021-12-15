//
//  URL+Extensions.swift
//  Jibber
//
//  Created by Benji Dodgson on 5/21/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

extension URL: ImageDisplayable {
    
    var userObjectId: String? {
        nil
    }

    var image: UIImage? {
        nil
    }

    var url: URL? {
        return self
    }
}
