//
//  LaunchManager.swift
//  Benji
//
//  Created by Benji Dodgson on 1/29/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import Combine

enum LaunchActivity {
    case onboarding(phoneNumber: String)
    case reservation(reservationId: String)
}

enum LaunchStatus {
    case success(object: DeepLinkable?, token: String)
    case failed(error: ClientError?)
}

protocol LaunchManagerDelegate: AnyObject {
    func launchManager(_ manager: LaunchManager, didFinishWith status: LaunchStatus)
    func launchManager(_ manager: LaunchManager, didReceive activity: LaunchActivity)
}

class LaunchManager {
    
    static let shared = LaunchManager()
    
    private(set) var finishedInitialFetch = false
    
    weak var delegate: LaunchManagerDelegate?

    private var cancellables = Set<AnyCancellable>()
    
    func launchApp(with options: [UIApplication.LaunchOptionsKey: Any]?) {
        
        if !Parse.isLocalDatastoreEnabled {
            Parse.enableLocalDatastore()
        }
        
        if Parse.currentConfiguration == nil  {
            Parse.initialize(with: ParseClientConfiguration(block: { (configuration: ParseMutableClientConfiguration) -> Void in
                configuration.isLocalDatastoreEnabled = true
                configuration.server = Config.shared.environment.url
                configuration.applicationId = Config.shared.environment.appID
            }))
        }
        
        if let user = User.current(), user.isAuthenticated {
            // Make sure we set this up each launch
            UserNotificationManager.shared.silentRegister(withApplication: UIApplication.shared)
        }
        
        self.initializeUserData(with: nil)
    }
    
    private func initializeUserData(with deeplink: DeepLinkable?) {
        if let _ = User.current()?.objectId {
            #if !APPCLIP
            self.getChatToken(with: deeplink)
            #else
            self.delegate?.launchManager(self, didFinishWith: .success(object: deeplink, token: String()))
            #endif
        } else {
            self.delegate?.launchManager(self, didFinishWith: .success(object: deeplink, token: String()))
        }
    }
    
    #if !APPCLIP
    // Code you don't want to use in your App Clip.
    func getChatToken(with deeplink: DeepLinkable?) {
        if ChatClientManager.shared.isConnected {
            self.delegate?.launchManager(self, didFinishWith: .success(object: deeplink, token: String()))
        } else {
            GetChatToken()
                .makeRequest(andUpdate: [], viewsToIgnore: [])
                .mainSink(receiveValue: { (token) in
                    self.delegate?.launchManager(self, didFinishWith: .success(object: deeplink, token: token))
                }, receiveCompletion: { (result) in
                    self.finishedInitialFetch = true
                    switch result {
                    case .finished:
                        break 
                    case .failure(_):
                        self.delegate?.launchManager(self, didFinishWith: .failed(error: ClientError.generic))
                    }
                }).store(in: &self.cancellables)
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
