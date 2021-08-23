//
//  Logger.swift
//  Logger
//
//  Created by Martin Young on 8/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import os

func logDebug(_ message: String) {
    Logger().log(level: .debug, "🟡 === \(message)")
}

func logDebug(_ error: Error) {
    Logger().log(level: .debug, "🔴 === \(error.localizedDescription)")
}
