//
//  PresentableCoordinator.swift
//  Jibber
//
//  Created by Benji Dodgson on 5/26/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Coordinator

@MainActor
class PresentableCoordinator<Result>: BaseCoordinator<Result>, Presentable {

    open func toPresentable() -> DismissableVC {
        fatalError("toPresentable not implemented in \(self)")
    }
}
