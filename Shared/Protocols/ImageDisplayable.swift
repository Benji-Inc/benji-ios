//
//  ImageDisplayable.swift
//  Benji
//
//  Created by Benji Dodgson on 12/27/18.
//  Copyright © 2018 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

protocol ImageDisplayable {
    var userObjectID: String? { get }
    var image: UIImage? { get }
    var textResult: NSTextCheckingResult? { get }
}

extension ImageDisplayable {
    var url: URL? {
        return nil 
    }

    var textResult: NSTextCheckingResult? {
        return nil
    }
}
