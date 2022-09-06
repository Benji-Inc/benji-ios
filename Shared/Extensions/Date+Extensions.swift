//
//  Date+Extensions.swift
//  Benji
//
//  Created by Benji Dodgson on 12/25/18.
//  Copyright © 2018 Benjamin Dodgson. All rights reserved.
//

import Foundation

extension Date {

    static var currentTimeZoneCalendar: Calendar = {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        return calendar
    }()

    static let today = Date().beginningOfDay

    static var nowInLocalFormat: String {
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "EE, h:mm a"
        return formatter.string(from: now)
    }

    static var standard: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter
    }
    
    static var monthYear: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter
    }

    static var monthAndDay: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }

    static var monthDayYear: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter
    }

    static var weekdayMonthDayYear: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, yyyy"
        return formatter
    }

    static func add(component: Calendar.Component,
                    amount: Int,
                    toDate: Date) -> Date? {

        let newDate = Calendar.current.date(byAdding: component,
                                            value: amount,
                                            to: toDate)
        return newDate
    }

    static func subtract(component: Calendar.Component,
                         amount: Int,
                         toDate: Date) -> Date? {
        let newDate = Calendar.current.date(byAdding: component,
                                            value: amount * -1,
                                            to: toDate)
        return newDate
    }

    func add(component: Calendar.Component, amount: Int) -> Date? {
        return Date.add(component: component, amount: amount, toDate: self)
    }

    func subtract(component: Calendar.Component, amount: Int) -> Date? {
        return Date.subtract(component: component, amount: amount, toDate: self)
    }

    static var jsonFriendly: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZ"
        return formatter
    }

    static var dayHourMinuteTimeOfDay: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, h:mm a"
        return formatter
    }
    
    static var hourMinuteTimeOfDayWithWeekday: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a, E"
        return formatter
    }
    
    static var hourMinuteTimeOfDayWithDate: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a, MMM d"
        return formatter
    }
    
    static var monthWithDate: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter
    }
    
    static var yearWithDate: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY"
        return formatter
    }

    static var hourMinuteTimeOfDay: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }

    static var countDown: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH : mm : ss"
        return formatter
    }

    func isBetween(_ date1: Date, and date2: Date) -> Bool {
        return (min(date1, date2) ... max(date1, date2)).contains(self)
    }

    static func easy(_ mmddyyyy: String) -> Date {
        return Date.standard.date(from: mmddyyyy) ?? Date()
    }

    var year: Int {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: self)
        return year
    }

    var month: Int {
        let calendar = Calendar.current
        let day = calendar.component(.month, from: self)
        return day
    }

    var week: Int {
        let calendar = Calendar.current
        let day = calendar.component(.weekOfYear, from: self)
        return day
    }
    
    var weekday: Int {
        let calendar = Calendar.current
        let day = calendar.component(.weekday, from: self)
        return day
    }

    var day: Int {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: self)
        return day
    }

    var hour: Int {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: self)
        return hour
    }

    var minute: Int {
        let calendar = Calendar.current
        let minute = calendar.component(.minute, from: self)
        return minute
    }

    var second: Int {
        let calendar = Calendar.current
        let second = calendar.component(.second, from: self)
        return second
    }

    var beginningOfDay: Date {
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: self)
        return Date.currentTimeZoneCalendar.date(from: dateComponents)!
    }

    var endOfDay: Date {
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day,
                                                              .hour, .minute, .second],
                                                             from: self)
        dateComponents.hour = 23
        dateComponents.minute = 59
        dateComponents.second = 59
        return Date.currentTimeZoneCalendar.date(from: dateComponents)!
    }

    func isSameDay(as date: Date) -> Bool {
        return self.year == date.year
        && self.month == date.month
        && self.day == date.day
    }

    func isSameDateOrInFuture(for date: Date) -> Bool {
        if self.isSameDay(as: date) {
            return true
        } else if self > date {
            return true
        } else {
            return false
        }
    }

    var ageInYears: Int {
        return Date().year - self.year
    }

    static func date(from components: DateComponents) -> Date? {
        let calendar = Calendar.current
        return calendar.date(from: components)
    }

    /// Returns the amount of years from another date
    func years(from date: Date) -> Int? {
        return Calendar.current.dateComponents([.year], from: date, to: self).year ?? 0
    }
    /// Returns the amount of months from another date
    func months(from date: Date) -> Int? {
        return Calendar.current.dateComponents([.month], from: date, to: self).month
    }
    /// Returns the amount of weeks from another date
    func weeks(from date: Date) -> Int? {
        return Calendar.current.dateComponents([.weekOfMonth], from: date, to: self).weekOfMonth
    }
    /// Returns the amount of days from another date
    func days(from date: Date) -> Int? {
        return Calendar.current.dateComponents([.day], from: date, to: self).day
    }
    /// Returns the amount of hours from another date
    func hours(from date: Date) -> Int? {
        return Calendar.current.dateComponents([.hour], from: date, to: self).hour
    }
    /// Returns the amount of minutes from another date
    func minutes(from date: Date) -> Int? {
        return Calendar.current.dateComponents([.minute], from: date, to: self).minute
    }
    /// Returns the amount of seconds from another date
    func seconds(from date: Date) -> Int? {
        return Calendar.current.dateComponents([.second], from: date, to: self).second
    }
    
    func getTimeAgoString() -> String {
        
        let now = Date()
        let aMinuteAgo = now.subtract(component: .minute, amount: 1)
        let anHourAgo = now.subtract(component: .hour, amount: 1)
        let aDayAgo = now.subtract(component: .day, amount: 1)
        let twoDaysAgo = now.subtract(component: .day, amount: 2)
        let aWeekAgo = now.subtract(component: .weekday, amount: 1)

        if self.isBetween(now, and: aMinuteAgo!) {
            return "Just now"

        // If less than hour - show # minutes
        } else if self.isBetween(now, and: anHourAgo!), let diff = self.minutes(from: now) {
            if abs(diff) == 1 {
                return "\(abs(diff)) min ago"
            } else {
                return "\(abs(diff)) mins ago"
            }
        // If greater than an hour AND less than a day - show # hours
        } else if self.isBetween(anHourAgo!, and: aDayAgo!), let diff = self.hours(from: now) {
            if abs(diff) == 1 {
                return "\(abs(diff)) hour ago"
            } else {
                return "\(abs(diff)) hours ago"
            }
        } else if self.isBetween(now, and: twoDaysAgo!) {
            return "\(Date.hourMinuteTimeOfDay.string(from: self)), Yesterday"
        } else if self.isBetween(now, and: aWeekAgo!) {
            return Date.hourMinuteTimeOfDayWithWeekday.string(from: self)
        } else {
            return Date.hourMinuteTimeOfDayWithDate.string(from: self)
        }
    }
    
    func getDaysAgoString() -> String {
        
        let now = Date()
        let aDayAgo = now.subtract(component: .day, amount: 1)
        let aWeekAgo = now.subtract(component: .weekOfYear, amount: 1)
        let aMonthAgo = now.subtract(component: .month, amount: 1)
        let aYearAgo = now.subtract(component: .year, amount: 1)

        if self.isBetween(now, and: aDayAgo!) {
            return "Today"
        // If greater than a day AND less than a week - show # of days
        } else if self.isBetween(aDayAgo!, and: aWeekAgo!), let diff = self.days(from: now) {
            if abs(diff) == 1 {
                return "\(abs(diff)) day ago"
            } else {
                return "\(abs(diff)) days ago"
            }
        // If greater than a week AND less than a month - show # of weeks
        } else if self.isBetween(aWeekAgo!, and: aMonthAgo!), let diff = self.weeks(from: now) {
            if abs(diff) == 1 {
                return "\(abs(diff)) week ago"
            } else {
                return "\(abs(diff)) weeks ago"
            }
        // If greater than a month AND less than a year - show # of months
        } else if self.isBetween(aMonthAgo!, and: aYearAgo!), let diff = self.months(from: now) {
            if abs(diff) == 1 {
                return "\(abs(diff)) month ago"
            } else {
                return "\(abs(diff)) months ago"
            }
        // Else show year and month
        } else {
            return Date.standard.string(from: self)
        }
    }
}

extension Calendar {
    func numberOfDaysBetween(_ from: Date, and to: Date) -> Int {
        let fromDate = startOfDay(for: from) // <1>
        let toDate = startOfDay(for: to) // <2>
        let numberOfDays = dateComponents([.day], from: fromDate, to: toDate) // <3>
        
        return numberOfDays.day!
    }
}

