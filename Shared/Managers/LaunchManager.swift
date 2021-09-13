//
//  LaunchManager.swift
//  Benji
//
//  Created by Benji Dodgson on 1/29/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import SDWebImageLinkPlugin
import StreamChat

enum LaunchActivity {
    case onboarding(phoneNumber: String)
    case reservation(reservationId: String)
}

protocol LaunchActivityHandler {
    func handle(launchActivity: LaunchActivity)
}

enum LaunchStatus {
    case success(object: DeepLinkable?, token: String)
    case failed(error: ClientError?)
}

protocol LaunchManagerDelegate: AnyObject {
    func launchManager(_ manager: LaunchManager, didReceive activity: LaunchActivity)
}

class LaunchManager {
    
    static let shared = LaunchManager()
    
    private(set) var finishedInitialFetch = false
    
    weak var delegate: LaunchManagerDelegate?

    func launchApp(with options: [UIApplication.LaunchOptionsKey: Any]?) async -> LaunchStatus {
        if Parse.currentConfiguration == nil  {
            Parse.initialize(with: ParseClientConfiguration(block: { (configuration: ParseMutableClientConfiguration) -> Void in
                configuration.applicationGroupIdentifier = "group.com.BENJI"
                configuration.server = Config.shared.environment.url
                configuration.applicationId = Config.shared.environment.appID
                configuration.isLocalDatastoreEnabled = true
            }))
        }

#if !NOTIFICATION
        // Silently register for notifications every launch.
        if let user = User.current(), user.isAuthenticated {
            Task {
                await UserNotificationManager.shared.silentRegister(withApplication: UIApplication.shared)
            }
        }
#endif

        SDImageLoadersManager.shared.addLoader(SDImageLinkLoader.shared)
        SDWebImageManager.defaultImageLoader = SDImageLoadersManager.shared

        let launchStatus = await self.initializeUserData(with: nil)
        return launchStatus
    }

    private func initializeUserData(with deeplink: DeepLinkable?) async -> LaunchStatus {
        guard let _ = User.current()?.objectId else {
            return .success(object: deeplink, token: String())
        }

#if !APPCLIP && !NOTIFICATION
        return await self.getChatToken(with: deeplink)
#else
        return .success(object: deeplink, token: String())
#endif
    }
    
#if !APPCLIP && !NOTIFICATION

    func getChatToken(with deeplink: DeepLinkable?) async -> LaunchStatus {
        // No need to get a new chat token if we're already connected.
        guard !ChatClient.isConnected else {
            return .success(object: deeplink, token: String())
        }

        do {
            let token = try await GetChatToken().makeRequest()
            self.finishedInitialFetch = true
            return .success(object: deeplink, token: token)
        } catch {
            return .failed(error: ClientError.apiError(detail: error.localizedDescription))
        }
    }
#endif
    
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
            default:
                break
            }
        }
        return true
    }
}
