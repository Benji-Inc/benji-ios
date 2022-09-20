//
//  LocationSwitchView.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/20/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class LocationSwitchView: PermissionSwitchView {
    
    init() {
        super.init(with: .location)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.state = .hidden
        
        self.switchView.addAction(UIAction(handler: { [unowned self] action in
            if self.isON {
                if !LocationManager.shared.isAuthorized {
                    LocationManager.shared.requestAuthorization()
                }
            }
        }), for: .valueChanged)
        
        LocationManager.shared.$authorizationStatus.mainSink { [unowned self] status in
            self.switchView.isOn = LocationManager.shared.isAuthorized
        }.store(in: &self.cancellables)
    }
}
