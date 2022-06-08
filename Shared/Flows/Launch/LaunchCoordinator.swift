//
//  LaunchCoordinator.swift
//  Jibber
//
//  Created by Martin Young on 1/12/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit
import Coordinator

enum LaunchResult {
    case success(DeepLinkable?)
    case failed
}

class LaunchCoordinator: PresentableCoordinator<LaunchResult> {

    lazy var splashVC = SplashViewController()

    override func toPresentable() -> DismissableVC {
        return self.splashVC
    }

    override func start() {
        super.start()

        self.startLaunchTask()
    }

    private var launchTask: Task<Void, Never>?
    private var retryCount: Int = 0

    private func startLaunchTask() {
        self.splashVC.startLoadAnimation()

        self.launchTask?.cancel()

        self.launchTask = Task { [weak self] in
            let launchStatus = await LaunchManager.shared.launchApp(with: self?.deepLink)

            guard !Task.isCancelled else { return }

            self?.handle(launchStatus: launchStatus)
        }
    }

    private func handle(launchStatus: LaunchStatus) {
        switch launchStatus {
        case .success(let deepLink):
            self.finishFlow(with: .success(deepLink))
        case .failed(let error):
            self.splashVC.stopLoadAnimation()
            if self.retryCount == 1 {
                self.finishFlow(with: .failed)
            } else {
                logDebug(error.debugDescription)
                logDebug(error?.code ?? "")
                // Show an error and let the user retry launching the app.
                self.presentErrorAlert(with: error)
            }
        }
    }

    private func presentErrorAlert(with error: ClientError?) {
        let alert = UIAlertController(title: "Unable to login",
                                      message: "Check your connection and please try again.",
                                      preferredStyle: .alert)
        let ok = UIAlertAction(title: "Retry", style: .default) { [unowned self] (_) in
            self.retryCount += 1
            self.startLaunchTask()
        }

        alert.addAction(ok)

        self.splashVC.present(alert, animated: true)
    }
}
