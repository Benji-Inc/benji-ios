//
//  HomeCoordinator.swift
//  Benji
//
//  Created by Benji Dodgson on 6/22/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import PhotosUI

class HomeCoordinator: PresentableCoordinator<Void> {

    private lazy var homeVC: HomeViewController = {
        let vc = HomeViewController()
        vc.delegate = self
        return vc
    }()

    override func toPresentable() -> DismissableVC {
        return self.homeVC
    }

    override func start() {
        super.start()

        ToastScheduler.shared.delegate = self

        self.checkForNotifications()

        if let deeplink = self.deepLink {
            self.handle(deeplink: deeplink)
        }

        self.homeVC.didTapAdd = { [unowned self] in
            Task.onMainActor {
                self.didTapAdd()
            }
        }

        self.homeVC.didTapCircles = { [unowned self] in
            self.startCirclesFlow()
        }

        self.homeVC.didTapArchive = { [unowned self] in
            self.startArchiveFlow()
        }
    }

    func handle(deeplink: DeepLinkable) {
        self.deepLink = deeplink

        guard let target = deeplink.deepLinkTarget else { return }

        switch target {
        case .conversation, .archive:
            self.startArchiveFlow()
        default:
            break
        }
    }

    func startCirclesFlow() {
        self.removeChild()
        let coordinator = CircleGroupCoordinator(router: self.router, deepLink: self.deepLink)
        self.addChildAndStart(coordinator) { result in
            coordinator.toPresentable().dismiss(animated: true) {

            }
        }
        self.router.present(coordinator, source: self.homeVC)
    }

    func didTapAdd() {
        self.removeChild()
        let coordinator = NewConversationCoordinator(router: self.router, deepLink: self.deepLink)
        self.addChildAndStart(coordinator) { result in
            coordinator.toPresentable().dismiss(animated: true) {
                if let controller = result {
                    self.startConversationFlow(for: controller.channel)
                }
            }
        }
        self.router.present(coordinator, source: self.homeVC)
    }

    func startArchiveFlow() {
        self.removeChild()

        let coordinator = ArchiveCoordinator(router: self.router,
                                                  deepLink: self.deepLink)
        self.addChildAndStart(coordinator, finishedHandler: { (_) in
            self.router.dismiss(source: coordinator.toPresentable(), animated: true) {
                self.finishFlow(with: ())
            }
        })
        self.router.present(coordinator, source: self.homeVC, animated: true)
    }

    func startConversationFlow(for conversation: Conversation?) {
        self.removeChild()

        let coordinator = ConversationCoordinator(router: self.router,
                                                  deepLink: self.deepLink,
                                                  conversation: conversation)
        self.addChildAndStart(coordinator, finishedHandler: { (_) in
            self.router.dismiss(source: coordinator.toPresentable(), animated: true) {
                self.finishFlow(with: ())
            }
        })
        self.router.present(coordinator, source: self.homeVC, animated: true)
    }
}
