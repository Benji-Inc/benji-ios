//
//  TimeAgo.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/14/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

enum TimeFromNow {
    
    case lessThanAMinute
    case lessThanAnHour(min: Int)
    case lessThanADay(hr: Int)
    case lessThanAWeek(days: Int)
    case lessThanAMonth(weeks: Int)
    case lessThanAYear(months: Int)
    case moreThanAYear
    
    var timeInterval: TimeInterval? {
        switch self {
        case .lessThanAMinute:
            return 5
        case .lessThanAnHour:
            return 60
        default:
            return nil
        }
    }
        
    static func getTime(from: Date) -> Self {
        
        let now = Date()
        let aMinuteAgo = now.subtract(component: .minute, amount: 1)
        
        if from.isBetween(now, and: aMinuteAgo!) {
            return .lessThanAMinute
        }
        
        let anHourAgo = now.subtract(component: .hour, amount: 1)
        if from.isBetween(now, and: anHourAgo!), let diff = from.minutes(from: now) {
            return .lessThanAnHour(min: abs(diff))
        }
        
        let aDayAgo = now.subtract(component: .day, amount: 1)
        if from.isBetween(anHourAgo!, and: aDayAgo!), let diff = from.hours(from: now)  {
            return .lessThanADay(hr: abs(diff))
        }
        
        let aWeekAgo = now.subtract(component: .weekday, amount: 1)
        if from.isBetween(now, and: aWeekAgo!), let diff = from.days(from: now) {
            return .lessThanAWeek(days: abs(diff))
        }
        
        let aMonthAgo = now.subtract(component: .month, amount: 1)
        if from.isBetween(now, and: aMonthAgo!), let diff = from.weeks(from: now) {
            return .lessThanAMonth(weeks: abs(diff))
        }
        
        let aYearAgo = now.subtract(component: .year, amount: 1)
        if from.isBetween(now, and: aYearAgo!), let diff = from.months(from: now) {
            return .lessThanAYear(months: abs(diff))
        } else {
            return .moreThanAYear
        }
    }
}

struct TimeAgo {
    var string: String
    var fromNow: TimeFromNow
}
