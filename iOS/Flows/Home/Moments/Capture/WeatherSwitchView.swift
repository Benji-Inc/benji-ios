//
//  WeatherSwitchView.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/20/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class WeatherSwitchView: PermissionSwitchView {
    
    init() {
        super.init(with: .weather)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        LocationManager.shared.$authorizationStatus.mainSink { [unowned self] status in
            if self.state != .hidden {
                self.state = LocationManager.shared.isAuthorized ? .enabled : .disabled
            }
        }.store(in: &self.cancellables)
        
        self.switchView.addAction(UIAction(handler: { [unowned self] action in
            // Ask or add weather
        }), for: .valueChanged)
        
        self.state = .hidden
        self.$state.mainSink { [unowned self] state in
            switch state {
            case .enabled:
                break
            default:
                break
            }
        }.store(in: &self.cancellables)
    }
}
