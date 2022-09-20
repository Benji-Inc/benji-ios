//
//  LocationManager.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/17/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, CLLocationManagerDelegate {
    
    static let shared = LocationManager()
    private let manager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    
    var isAuthorized: Bool {
        return self.manager.authorizationStatus == .authorizedWhenInUse
    }
    
    @Published private(set) var currentLocation: CLLocation?
    @Published private(set) var currentPlaceMark: CLPlacemark?
    
    override init() {
        super.init()
        self.initialize()
    }
    
    private func initialize() {
        self.manager.delegate = self
        self.manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }
    
    func requestAuthorization() {
        self.manager.requestWhenInUseAuthorization()
    }
    
    func requestCurrentLocation() {
        self.manager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.currentLocation = locations.last
        
        Task {
            guard let location = self.currentLocation else {
                self.currentPlaceMark = nil
                return
            }
            
            let geoCoder = CLGeocoder()
            self.currentPlaceMark = try? await geoCoder.reverseGeocodeLocation(location).first
            
            // Location name
            if let locationName = self.currentPlaceMark?.location {
                logDebug(locationName)
            }
            // Street address
            if let street = self.currentPlaceMark?.thoroughfare {
                logDebug(street)
            }
            // City
            if let city = self.currentPlaceMark?.locality {
                logDebug(city)
            }
            // State
            if let state = self.currentPlaceMark?.administrativeArea {
                logDebug(state)
            }
            // Zip code
            if let zipCode = self.currentPlaceMark?.postalCode {
                logDebug(zipCode)
            }
            // Country
            if let country = self.currentPlaceMark?.country {
                logDebug(country)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        logDebug(error.localizedDescription)
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse:  // Location services are available.
            //enableLocationFeatures()
            break
            
        case .restricted, .denied:  // Location services currently unavailable.
           // disableLocationFeatures()
            break
            
        case .notDetermined:        // Authorization not determined yet.
            break
        default:
            break
        }
    }
}
