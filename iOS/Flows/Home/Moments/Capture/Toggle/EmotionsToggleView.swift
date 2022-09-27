//
//  EmotionsToggleView.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/24/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class EmotionsToggleView: ToggleView {
    
    init() {
        super.init(type: .emotions)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
    }
    
    override func update(isON: Bool) {
        guard self.alpha != 0 else { return }
        self.button.alpha = 0.25
        Task {
            await ToastScheduler.shared.schedule(toastType: .success(.heart, "Emotions COMING SOON"), duration: 3)
        }
    }
}
