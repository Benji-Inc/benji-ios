//
//  EmotionsCoordinator.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/27/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class EmotionsCoordinator: PresentableCoordinator<[Emotion]> {
    
    lazy var emotionsVC = EmotionsViewController()

    override func toPresentable() -> DismissableVC {
        return self.emotionsVC
    }
    
    override func start() {
        super.start()
        
        //self.emotionsVC.button.didSelect { [unowned self] in
//            self.finishFlow(with: self.emotionsVC.selectedEmotions)
//        }
    }
}
