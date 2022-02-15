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
    
    override func start() {
        super.start()
        
        self.walletVC.dataSource.didTapDetail = {
            self.presentAlert()
        }
    }
    
    private func presentAlert() {
                
        let alertController = UIAlertController(title: "Jibs",
                                                message: "Earn Jibs now and soon you can use them to upgrade, vote on features, or invest in Jibber.",
                                                preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: "Got it", style: .cancel, handler: {
            (action : UIAlertAction!) -> Void in
        })

        alertController.addAction(cancelAction)
        self.walletVC.present(alertController, animated: true, completion: nil)
    }
}
