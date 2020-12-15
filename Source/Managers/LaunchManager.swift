//
//  LaunchManager.swift
//  Benji
//
//  Created by Benji Dodgson on 1/29/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import ReactiveSwift
import TMROFutures

enum LaunchStatus {
    case success(object: DeepLinkable?, token: String)
    case failed(error: ClientError?)
}

protocol LaunchManagerDelegate: class {
    func launchManager(_ manager: LaunchManager, didFinishWith status: LaunchStatus)
}

class LaunchManager {

    static let shared = LaunchManager()

    private(set) var finishedInitialFetch = false

    // Important - update this URL with your Twilio Function URL
    private let tokenURL = "https://topaz-booby-6355.twil.io/chat-token"

    // Important - this identity would be assigned by your app, for
    // instance after a user logs in
    private let url = "https://benji-backend.herokuapp.com/parse"
    private let appID = "BenjiApp"
    private let clientKey = "theStupidMasterKeyThatShouldBeSecret"

    weak var delegate: LaunchManagerDelegate?

    /// False if a branch session has already been started.
    private var shouldInitializeBranchSession = true

    func launchApp(with options: [UIApplication.LaunchOptionsKey: Any]?) {

        if !Parse.isLocalDatastoreEnabled {
            Parse.enableLocalDatastore()
        }

        if Parse.currentConfiguration == nil  {
            Parse.initialize(with: ParseClientConfiguration(block: { (configuration: ParseMutableClientConfiguration) -> Void in
                configuration.isLocalDatastoreEnabled = true
                configuration.server = self.url
                configuration.clientKey = self.clientKey
                configuration.applicationId = self.appID
            }))
        }

        if let user = User.current(), user.isAuthenticated {
            // Make sure we set this up each launch
            UserNotificationManager.shared.silentRegister(withApplication: UIApplication.shared)
        }

        self.initializeUserData(with: nil)
    }

    func updateUser(with deeplink: DeepLinkable) {
        guard let _ = User.current()?.objectId,
            let metaData = deeplink.customMetadata as? [String: Any],
            metaData.values.count > 0 else { return }

        _ = UpdateUser(attributes: metaData)
            .makeRequest(andUpdate: [], viewsToIgnore: [])
    }

    private func initializeUserData(with deeplink: DeepLinkable?) {
        if let _ = User.current()?.objectId {
            #if !APPCLIP
            self.getChatToken(with: deeplink)
            #endif
        } else {
            self.delegate?.launchManager(self, didFinishWith: .success(object: deeplink, token: String()))
        }
    }

    #if !APPCLIP
    // Code you don't want to use in your App Clip.
    func getChatToken(with deeplink: DeepLinkable?) {
        if ChannelManager.shared.isConnected {
            self.delegate?.launchManager(self, didFinishWith: .success(object: deeplink, token: String()))
        } else {
            GetChatToken()
                .makeRequest(andUpdate: [], viewsToIgnore: [])
                .observe { (result) in
                    switch result {
                    case .success(let token):
                        self.finishedInitialFetch = true
                        self.delegate?.launchManager(self, didFinishWith: .success(object: deeplink, token: token))
                    case .failure(_):
                        self.delegate?.launchManager(self, didFinishWith: .failed(error: ClientError.generic))
                    }
            }
        }
    }
    #endif

    func continueUser(activity: NSUserActivity) -> Bool {
        if activity.activityType == NSUserActivityTypeBrowsingWeb,
           let incomingURL = activity.webpageURL,
           let components = NSURLComponents(url: incomingURL, resolvingAgainstBaseURL: true) {
            // do something
            print(components)
        }
        return true
    }
}
