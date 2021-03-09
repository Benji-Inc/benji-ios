//
//  FeedNotificationPermissionsView.swift
//  Benji
//
//  Created by Benji Dodgson on 12/24/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class PostNotificationPermissionsViewController: PostViewController {

    override func initializeViews() {
        super.initializeViews()

        self.textView.set(localizedText: String(optional: self.post.body))
        self.button.set(style: .rounded(color: .purple, text: "OK"))
    }

    override func didTapButton() {
        super.didTapButton()

        self.handleNotificationPermissions()
    }

    private func handleNotificationPermissions() {
        self.button.handleEvent(status: .loading)
        UserNotificationManager.shared.register(application: UIApplication.shared)
            .mainSink { (granted) in
                self.button.handleEvent(status: .complete)
                if granted {
                    self.didFinish?()
                } else if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                        print("Settings opened: \(success)") // Prints true
                    })
                }
            }.store(in: &self.cancellables)
    }
}

