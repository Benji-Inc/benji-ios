//
//  NSTextCheckingResult+Extension.swift
//  Ours
//
//  Created by Benji Dodgson on 6/4/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

extension NSTextCheckingResult: ImageDisplayable {
    
    var userObjectID: String? {
        return nil
    }

    var image: UIImage? {
        return nil
    }

    var textResult: NSTextCheckingResult? {
        return self
    }
}
