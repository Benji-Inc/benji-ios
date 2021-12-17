//
//  Shape+Extensions.swift
//  Jibber
//
//  Created by Benji Dodgson on 12/16/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import SwiftUI

extension Shape {
    
    func fill(_ color: ThemeColor, alpha: CGFloat = 1.0) -> some View {
        self.fill(Color(color.color.withAlphaComponent(alpha)))
    }
    
    func stroke(_ color: ThemeColor, alpha: CGFloat = 1.0, width: CGFloat = 1) -> some View {
        self.stroke(Color(color.color.withAlphaComponent(alpha)), lineWidth: width)
    }
}
