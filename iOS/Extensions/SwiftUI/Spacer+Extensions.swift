//
//  Spacer+Extensions.swift
//  Jibber
//
//  Created by Benji Dodgson on 12/16/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import SwiftUI

extension Spacer {
    
    static func length(_ value: Theme.ContentOffset) -> some View {
        Spacer().frame(minWidth: value.value,
                       idealWidth: value.value,
                       maxWidth: value.value,
                       minHeight: value.value,
                       idealHeight: value.value,
                       maxHeight: value.value)
    }
}
