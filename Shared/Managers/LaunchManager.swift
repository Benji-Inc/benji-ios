//
//  LaunchManager.swift
//  Benji
//
//  Created by Benji Dodgson on 1/29/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import ParseSwift

enum LaunchActivity {
    case onboarding(phoneNumber: String)
    case reservation(reservationId: String)
    case pass(passId: String)
}

protocol LaunchActivityHandler {
    func handle(launchActivity: LaunchActivity)
}

enum LaunchStatus {
    case success(object: DeepLinkable?)
    case failed(error: ClientError?)
}

protocol LaunchManagerDelegate: AnyObject {
    func launchManager(_ manager: LaunchManager, didReceive activity: LaunchActivity)
}

class LaunchManager {
    
    static let shared = LaunchManager()
    
    var finishedInitialFetch = false
    
    weak var delegate: LaunchManagerDelegate?

    func launchApp(with options: [UIApplication.LaunchOptionsKey: Any]?) async -> LaunchStatus {
        // Initialize Parse if necessary
        Config.shared.initializeParse()

#if !NOTIFICATION
        // Silently register for notifications every launch.
        if let user = User.current, user.isOnboarded {
            Task {
                await UserNotificationManager.shared.silentRegister(withApplication: UIApplication.shared)
            }
        }
#endif

        let launchStatus = await self.initializeUserData(with: nil)
        return launchStatus
    }

    private func initializeUserData(with deeplink: DeepLinkable?) async -> LaunchStatus {
        guard let user = User.current else {
            return .success(object: deeplink)
        }

#if !APPCLIP && !NOTIFICATION
        return await self.getChatToken(for: user, deepLink: deeplink)
#else
        return .success(object: deeplink)
#endif
    }
    
    func continueUser(activity: NSUserActivity) -> Bool {
        if activity.activityType == NSUserActivityTypeBrowsingWeb,
           let incomingURL = activity.webpageURL,
           let components = NSURLComponents(url: incomingURL, resolvingAgainstBaseURL: true) {
            guard let path = components.path else { return true }
            switch path {
            case "/onboarding":
                if let item = components.queryItems?.first,
                   let phoneNumber = item.value {
                    self.delegate?.launchManager(self, didReceive: .onboarding(phoneNumber: phoneNumber))
                }
            case "/reservation":
                if let item = components.queryItems?.first,
                   let reservationId = item.value {
                    self.delegate?.launchManager(self, didReceive: .reservation(reservationId: reservationId))
                }
            case "/pass":
                if let item = components.queryItems?.first,
                   let passID = item.value {
                    self.delegate?.launchManager(self, didReceive: .pass(passId: passID))
                }
            default:
                break
            }
        }
        return true
    }
}
