//
//  WalletCoordinator.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/4/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class WalletCoordinator: PresentableCoordinator<Void> {
    
    lazy var walletVC = WalletViewController()

    override func toPresentable() -> DismissableVC {
        return self.walletVC
    }
}
