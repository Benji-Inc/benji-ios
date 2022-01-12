//
//  LaunchManager.swift
//  Benji
//
//  Created by Benji Dodgson on 1/29/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
#if !APPCLIP && !NOTIFICATION
import StreamChat
#endif

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

    func launchApp() async -> LaunchStatus {
        // Initialize Parse if necessary
        if Parse.currentConfiguration.isNil  {
            Parse.initialize(with: ParseClientConfiguration(block: { (configuration: ParseMutableClientConfiguration) in
                configuration.applicationGroupIdentifier = Config.shared.environment.groupId
                configuration.server = Config.shared.environment.url
                configuration.applicationId = Config.shared.environment.appId
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

        let launchStatus = await self.initializeUserData(with: nil)
        return launchStatus
    }

    private func initializeUserData(with deeplink: DeepLinkable?) async -> LaunchStatus {
        guard let user = User.current() else {
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
                   let passId = item.value {
                    self.delegate?.launchManager(self, didReceive: .pass(passId: passId))
                }
            default:
                break
            }
        }
        return true
    }
}

extension LaunchManager {

#if !APPCLIP && !NOTIFICATION
    func getChatToken(for user: User, deepLink: DeepLinkable?) async -> LaunchStatus {
        // No need to get a new chat token if we're already connected.
        guard !ChatClient.isConnected else {
            return .success(object: deepLink)
        }

        do {
            try await ChatClient.initialize(for: user)
            if let user = User.current(), user.isAuthenticated {
                await UserNotificationManager.shared.silentRegister(withApplication: UIApplication.shared)
            }

            var link = deepLink
            /// Used to load the initial conversation when a user has downloaded the full app from an app clip
            if let initial = try? await InitialConveration.retrieve() {
                if let cidString = initial.conversationIdString {
                    link?.conversationId = try? ConversationId(cid: cidString)
                }

                link?.deepLinkTarget = .conversation
            }

            self.finishedInitialFetch = true
            return .success(object: link)
        } catch {
            return .failed(error: ClientError.apiError(detail: error.localizedDescription))
        }
    }
#endif
}
