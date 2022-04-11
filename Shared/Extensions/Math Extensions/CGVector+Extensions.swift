//
//  CGVector+Extensions.swift
//  Jibber
//
//  Created by Martin Young on 1/25/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

extension CGVector {

    var magnitude: CGFloat {
        return sqrt(self.dx * self.dx + self.dy * self.dy)
    }

    init(startPoint: CGPoint, endPoint: CGPoint) {
        self.init(dx: endPoint.x - startPoint.x,
                  dy: endPoint.y - startPoint.y)
    }
}
