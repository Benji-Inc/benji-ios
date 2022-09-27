//
//  WeatherManager.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/26/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import WeatherKit
import CoreLocation

@available(iOS 16.0, *)
class WeatherManager {
        
    private let service = WeatherService()
    
    func getWeather(for location: CLLocation) async -> CurrentWeather? {
        guard let weather = try? await self.service.weather(for: location) else { return nil }
        return weather.currentWeather
    }
}
