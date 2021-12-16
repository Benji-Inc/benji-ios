//
//  Text+Extensions.swift
//  Jibber
//
//  Created by Benji Dodgson on 12/16/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import SwiftUI

extension Text {
    
    func fontType(_ type: FontType) -> some View {
        self.font(Font(type.font as CTFont))
    }
}
