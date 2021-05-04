//
//  RitualCoordinator.swift
//  Benji
//
//  Created by Benji Dodgson on 2/23/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class RitualCoordinator: PresentableCoordinator<Void> {

    lazy var ritualVC = RitualViewController(with: self)
    private var cancellables = Set<AnyCancellable>()

    override func toPresentable() -> DismissableVC {
        return self.ritualVC
    }
}

extension RitualCoordinator: RitualViewControllerDelegate {
    func ritualInputViewControllerDidAddRitual(_ controller: RitualViewController) {
        controller.dismiss(animated: true) {
            self.finishFlow(with: ())
        }
    }

    func ritualInputViewControllerNeedsAuthorization(_ controller: RitualViewController) {
        UserNotificationManager.shared.register(application: UIApplication.shared)
            .mainSink { (granted) in
                if granted {
                    controller.inputVC.state = .update
                } else if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl, completionHandler: { (success) in })
                }
            }.store(in: &self.cancellables)
    }
}
