//
//  Config.swift
//  Benji
//
//  Created by Benji Dodgson on 12/29/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse

enum Environment: String {

    case staging = "staging"
    case production = "production"

    var url: String {
        switch self {
        //case .staging: return "https://parseapi.back4app.com"
        case .staging: return "https://jibber-development-backend.herokuapp.com/parse"
        case .production: return "https://jibber-backend.herokuapp.com/parse"
        }
    }
    
//    var clientKey: String {
//        switch self {
//        //case .staging: return "pDUO1RZrns7OQqUzz3VJhLTk3h2VhyinDQXvhAbp"
//        case .production: return ""
//        }
//    }

    var appId: String {
        switch self {
        //case .staging: return "zjvzFwmCPlSfCPKLd6C9cdm3HNxwMOA07iAoqffR"
        case .staging: return "jibber-development"
        case .production: return "bd263ac3-c8d9-4145-be8a-7d8eedbd5fcf"
        }
    }

    var bundleId: String {
        switch self {
        case .staging:
            return "com.Jibber-Inc.iOS-staging"
        case .production:
            return "com.Jibber-Inc.iOS"
        }
    }

    var displayName: String {
        switch self {
        case .staging: return "stag"
        case .production: return "prod"
        }
    }

    var groupId: String {
        switch self {
        case .staging:
            return "group.Jibber-staging"
        case .production:
            return "group.Jibber"
        }
    }

    var chatAPIKey: String {
        switch self {
        case .staging: return "hvmd2mhxcres"
        case .production: return "ybdsdqhd2nhg"
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

        if let bundledBuildTypeString = Bundle.main.infoDictionary!["RELEASE_TYPE"] as? String,
            let bundledBuildTypeEnum = BuildType(rawValue: bundledBuildTypeString.lowercased()) {
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
    
    func initializeParseIfNeeded() {
        if Parse.currentConfiguration.isNil  {
            Parse.initialize(with: ParseClientConfiguration(block: { (configuration: ParseMutableClientConfiguration) in
                configuration.applicationGroupIdentifier = self.environment.groupId
               // configuration.clientKey = self.environment.clientKey
                configuration.server = self.environment.url
                configuration.applicationId = self.environment.appId
                configuration.isLocalDatastoreEnabled = true
            }))
        }
    }
}
