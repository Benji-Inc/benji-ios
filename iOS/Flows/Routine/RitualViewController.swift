//
//  RoutineViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 10/17/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization

protocol RitualViewControllerDelegate: class {
    func ritualInputViewControllerNeedsAuthorization(_ controller: RitualViewController)
}

class RitualViewController: NavigationBarViewController {

    let routineInputVC = RitualInputViewController()

    unowned let delegate: RitualViewControllerDelegate

    init(with delegate: RitualViewControllerDelegate) {
        self.delegate = delegate
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        self.addChild(viewController: self.routineInputVC)
        self.backButton.isHidden = true

        self.routineInputVC.didTapNeedsAthorization = {
            self.delegate.ritualInputViewControllerNeedsAuthorization(self)
        }

        self.routineInputVC.$state
            .removeDuplicates()
            .mainSink { (state) in
                self.updateNavigationBar()
            }.store(in: &self.cancellables)
    }

    override func getTitle() -> Localized {
        switch self.routineInputVC.state {
        case .needsAuthorization:
            return "Need Permission"
        default:
            return "DAILY ROUTINE"
        }
    }

    override func getDescription() -> Localized {
        switch self.routineInputVC.state {
        case .needsAuthorization:
            return "You will need to add notification permission to use this feature."
        default:
            return "Get a daily reminder to follow up and connect with others."
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.routineInputVC.view.size = CGSize(width: self.view.width, height: RitualInputViewController.height)
        self.routineInputVC.view.centerOnX()
        self.routineInputVC.view.bottom = self.view.height - self.view.safeAreaInsets.bottom

        self.scrollView.contentSize = CGSize(width: self.view.width, height: self.routineInputVC.view.bottom + 20)
    }
}
