//
//  Logger.swift
//  Logger
//
//  Created by Martin Young on 8/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import os
import Sentry

func logDebug(_ message: CustomStringConvertible) {
    Logger().log(level: .debug, "🟡 === \(message.description)")
}

func logError(_ error: Error) {
    SentrySDK.capture(error: error)
    Logger().log(level: .debug, "🔴 === \(error.localizedDescription)")
}
