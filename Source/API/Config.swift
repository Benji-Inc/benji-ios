//
//  Config.swift
//  Benji
//
//  Created by Benji Dodgson on 12/29/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation

enum Environment: String {

    case development = "development"
    case production = "production"

    var url: String {
        switch self {
        case .development: return "https://benji-backend.herokuapp.com/parse"
        case .production: return "http://ours-backend.herokuapp.com/parse"
        }
    }

    var appID: String {
        switch self {
        case .development: return "ours-development"
        case .production: return "ours-production"
        }
    }

    var clientKey: String {
        switch self {
        case .development: return "R7-6qsaqe9xK"
        case .production: return "96744143-bd04-4343-b637-4688ff44ba44"
        }
    }

    var displayName: String {
        switch self {
        case .development: return "dev"
        case .production: return "prod"
        }
    }
}

enum BuildType: String, CaseIterable {
    case release = "release"
    case debug = "debug"
}

var isRelease: Bool {
    return Config.shared.buildType == .release
}

class Config: NSObject {

    static let shared = Config.init()

    let environment: Environment = {
        var environmentToReturn = Environment.production

        if let bundledApiTargetString = Bundle.main.infoDictionary!["API_TARGET"] as? String,
            let bundledApiTargetEnum = Environment(rawValue: bundledApiTargetString.lowercased()) {
            environmentToReturn = bundledApiTargetEnum
        } else {
            fatalError("Info.plist (Or Info-dev.plist) not properly configured to have "
                + "API_TARGET set, crashing because you screwed something up.")
        }

        return environmentToReturn
    }()

    let buildType: BuildType = {
        var buildTypeToReturn = BuildType.release

        if Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt" {
            return .debug
        }

        if let bundledBuildTypeString = Bundle.main.infoDictionary!["RELEASE_TYPE"] as? String,
            let bundledBuildTypeEnum = BuildType.init(rawValue: bundledBuildTypeString.lowercased()) {
            buildTypeToReturn = bundledBuildTypeEnum
        } else {
            fatalError("Info.plist (Or Info-dev.plist) not properly configured to have "
                + "RELEASE_TYPE set, crashing because you screwed something up.")
        }

        return buildTypeToReturn
    }()
}
