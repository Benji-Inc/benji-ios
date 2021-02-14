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

    let textView = FeedTextView()
    let button = Button()
    var didGivePermission: CompletionOptional = nil

    override func initializeViews() {
        super.initializeViews()

        self.container.addSubview(self.textView)
        self.container.addSubview(self.button)
        self.textView.set(localizedText: "Notifications are only sent for important messages and daily ritual remiders. Nothing else.")
        self.button.set(style: .rounded(color: .purple, text: "OK"))
        self.button.didSelect { [unowned self] in
            self.handleNotificationPermissions()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.textView.setSize(withWidth: self.container.width)
        self.textView.bottom = self.container.centerY - 10
        self.textView.centerOnX()

        self.button.setSize(with: self.container.width)
        self.button.centerOnX()
        self.button.bottom = self.container.height - Theme.contentOffset
    }

    private func handleNotificationPermissions() {
        self.button.handleEvent(status: .loading)
        UserNotificationManager.shared.register(application: UIApplication.shared)
            .mainSink { (granted) in
                self.button.handleEvent(status: .complete)
                if granted {
                    self.didGivePermission?()
                } else if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                        print("Settings opened: \(success)") // Prints true
                    })
                }
            }.store(in: &self.cancellables)
    }
}

