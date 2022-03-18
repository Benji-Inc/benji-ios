//
//  AttachmentsCoordinator.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/18/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class AttachmentsCoordinator: PresentableCoordinator<[Attachment]> {
    
    lazy var attachementsVC = AttachmentsViewController()
    
    override init(router: Router, deepLink: DeepLinkable?) {
        super.init(router: router, deepLink: deepLink)
        
//        self.creatorVC.didCreateContextCue = { [unowned self] in
//            self.finishFlow(with: ())
//        }
    }

    override func toPresentable() -> DismissableVC {
        return self.attachementsVC
    }
}
