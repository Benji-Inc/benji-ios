//
//  PFGeopoint+Extensions.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/20/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse

extension PFGeoPoint {
    
    var clLocation: CLLocation? {
        return CLLocation(latitude: self.latitude, longitude: self.longitude)
    }
    
    func getPlaceMark() async -> CLPlacemark? {
        guard let clLocation = self.clLocation else { return nil }
        let geoCoder = CLGeocoder()
        return try? await geoCoder.reverseGeocodeLocation(clLocation).first
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
}
