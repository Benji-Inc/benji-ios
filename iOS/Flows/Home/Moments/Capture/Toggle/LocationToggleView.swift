//
//  LocationToggleView.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/24/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class LocationToggleView: ToggleView {
    
    init() {
        super.init(type: .location)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        LocationManager.shared.$authorizationStatus.mainSink { [unowned self] status in
            self.button.isEnabled = LocationManager.shared.isAuthorized
            self.isON = LocationManager.shared.isAuthorized
            self.updateButtonState()
        }.store(in: &self.cancellables)
    }
    
    override func updateButtonState() {
        super.updateButtonState()
        
        if self.isON {
            if !LocationManager.shared.isAuthorized {
                LocationManager.shared.requestAuthorization()
            }
        }
    }
}
