//
//  LaunchManager.swift
//  Benji
//
//  Created by Benji Dodgson on 1/29/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import PostHog
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
    case success(deepLink: DeepLinkable?)
    case failed(error: ClientError?)
}

protocol LaunchManagerDelegate: AnyObject {
    func launchManager(_ manager: LaunchManager, didReceive activity: LaunchActivity)
}

class LaunchManager {
    
    static let shared = LaunchManager()
    
    weak var delegate: LaunchManagerDelegate?

    func launchApp(with deepLink: DeepLinkable?) async -> LaunchStatus {
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
            // Ensure that the user object is up to date.
            _ = try? await user.fetchInBackground()
            
            async let first: Void
            = UserNotificationManager.shared.silentRegister(withApplication: UIApplication.shared)
            // Initialize the stores.
            async let second: Void = PersonStore.shared.initializeIfNeeded()
            let _: [Void] = await [first, second]

            // Pre-load contacts
            _ = ContactsManger.shared
            
            // Update the timeZone
            user.timeZone = TimeZone.current.identifier
            user.saveEventually()
        }
#endif
        let configuration = PHGPostHogConfiguration(apiKey: "phc_nTIZgY0M0QgX0QB14Ux428lvGVnUeddJCqEFEo4vt9n",
                                                    host: "https://app.posthog.com")

        configuration.captureApplicationLifecycleEvents = true; // Record certain application events automatically!
        configuration.recordScreenViews = true; // Record screen views automatically!

        PHGPostHog.setup(with: configuration)
        
        let launchStatus = await self.initializeUserData(with: deepLink)
        try? await PFConfig.awaitConfig()
        return launchStatus
    }

    private func initializeUserData(with deeplink: DeepLinkable?) async -> LaunchStatus {
        guard let user = User.current() else {
            // There is no user object yet, there's nothing to initialize.
            return .success(deepLink: deeplink)
        }

#if !APPCLIP && !NOTIFICATION
        do {
            try await ChatClient.initialize(for: user)
        } catch {
            return .failed(error: ClientError.apiError(detail: error.localizedDescription))
        }

        return await self.getChatToken(for: user, deepLink: deeplink)
#else
        return .success(deepLink: deeplink)
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
        if let user = User.current(), user.isAuthenticated {
            await UserNotificationManager.shared.silentRegister(withApplication: UIApplication.shared)
        }

        var link = deepLink

        // Used to load the initial conversation when a user has downloaded the full app from an app clip.
        if let initial = try? await InitialConveration.retrieve() {
            if let cidString = initial.conversationIdString {
                link?.conversationId = try? ConversationId(cid: cidString)
            }

            link?.deepLinkTarget = .conversation
        }

        return .success(deepLink: link)
    }
#endif
}
