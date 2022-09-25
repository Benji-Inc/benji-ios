//
//  CLLocation+Extensions.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/25/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import CoreLocation

extension CLLocation {
    
    func getPlaceMark() async -> CLPlacemark? {
        let geoCoder = CLGeocoder()
        return try? await geoCoder.reverseGeocodeLocation(self).first
    }
    
    func getLocationString() async -> String {
        guard let placemark = await self.getPlaceMark() else { return "" }
        
        var locationString = ""
        // Street address
        if let street = placemark.thoroughfare {
            locationString.append(contentsOf: "\(street)\n")
        }
        // City
        if let city = placemark.locality {
            locationString.append(contentsOf: "\(city)")
        }
        // State
        if let state = placemark.administrativeArea {
            locationString.append(contentsOf: ", \(state)")
        }
        
        return locationString
    }
    
    func getStreetString() async -> String {
        guard let placemark = await self.getPlaceMark() else { return "" }
        
        var locationString = ""
        // Street address
        if let street = placemark.thoroughfare {
            locationString.append(contentsOf: "\(street)")
        }
        
        return locationString
    }
}
