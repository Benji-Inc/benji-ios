//
//  Config.swift
//  Benji
//
//  Created by Benji Dodgson on 12/29/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation

enum Environment: String {

    case staging = "staging"
    case production = "production"

    var url: String {
        switch self {
        case .staging: return "https://ours-development-backend.herokuapp.com/parse"
        case .production: return "https://ours-backend.herokuapp.com/parse"
        }
    }

    var appID: String {
        switch self {
        case .staging: return "ours-development"
        case .production: return "bd263ac3-c8d9-4145-be8a-7d8eedbd5fcf"
        }
    }

    var displayName: String {
        switch self {
        case .staging: return "stag"
        case .production: return "prod"
        }
    }

    var groudID: String {
        return "group.com.Jibber"
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

    private(set) var appVersion: String = {
        var version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1"
        version = version.trimmingCharacters(in: CharacterSet(charactersIn: "0123456789.").inverted)
        return version
    }()
}
