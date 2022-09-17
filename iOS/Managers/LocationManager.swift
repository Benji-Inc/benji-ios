//
//  LocationManager.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/17/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    
    static let shared = LocationManager()
    private let manager = CLLocationManager()
    
    @Published private(set) var currentLocation: CLLocation? 

    override init() {
        super.init()
        self.initialize()
    }
    
    private func initialize() {
        self.manager.delegate = self
    }
    
    func requestCurrentLocation() {
        self.manager.requestWhenInUseAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.currentLocation = locations.first
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        logError(error)
    }
}
