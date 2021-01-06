//
//  RoutineCoordinator.swift
//  Benji
//
//  Created by Benji Dodgson on 2/23/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation

class RitualCoordinator: PresentableCoordinator<Void> {

    lazy var routineVC = RitualViewController(with: self)

    override func toPresentable() -> DismissableVC {
        return self.routineVC
    }
}

extension RitualCoordinator: RitualViewControllerDelegate {

    func ritualInputViewControllerNeedsAuthorization(_ controller: RitualViewController) {
        UserNotificationManager.shared.register(application: UIApplication.shared) { (success, error) in
            runMain {
                if success {
                    controller.routineInputVC.state = .update
                } else if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl, completionHandler: { (success) in })
                }
            }
        }
    }
}
