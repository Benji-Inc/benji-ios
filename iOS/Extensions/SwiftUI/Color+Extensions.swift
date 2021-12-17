//
//  Color+Extensions.swift
//  Jibber
//
//  Created by Benji Dodgson on 12/16/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import SwiftUI

extension Color {
    static func color(_ color: ThemeColor, alpha: CGFloat = 1.0) -> some View {
        Color(color.color.withAlphaComponent(alpha))
    }
}
