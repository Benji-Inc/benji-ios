//
//  WeatherToggleView.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/24/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class WeatherToggleView: ToggleView {
    
    init() {
        super.init(type: .weather)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        
    }
    
    override func update(isON: Bool) {
        super.update(isON: isON)
        guard self.alpha != 0 else { return }

        Task {
            let text = isON ? "Weather added" : "Weather removed"
            await ToastScheduler.shared.schedule(toastType: .success(.cloudRain, text), duration: 3)
        }
    }
}
