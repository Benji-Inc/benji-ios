//
//  HomeCoordinator.swift
//  Benji
//
//  Created by Benji Dodgson on 6/22/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import Combine

class HomeCoordinator: PresentableCoordinator<Void> {

    private lazy var homeVC = HomeViewController()
    private var cancellable: AnyCancellable?

    var cancellables = Set<AnyCancellable>()


    override func toPresentable() -> DismissableVC {
        return self.homeVC
    }

    override func start() {
        super.start()

        let future1 = Future<Int, Never> { promise in
            promise(.success(1))
        }

        let future2 = Future<Int, Never> { promise in
            promise(.success(2))
        }

        let future3 = Future<Int, Never> { promise in
            delay(2.0) { [unowned self] in
                promise(.success(3))
            }
        }

        let combine = Publishers.Zip3 (
            future1, future2, future3
        )

        waitForAll([future1, future2, future3]).mainSink { (values) in
            values.forEach { (value) in
                print(value)
            }
        }.store(in: &self.cancellables)

        self.cancellable = self.homeVC.$current
            .removeDuplicates()
            .mainSink { [weak self] (current) in
            guard let `self` = self, let content = current else { return }

            self.removeChild()

            // Only use the deeplink once so that we don't repeatedly try
            // to deeplink whenever content changes.
            defer {
                self.deepLink = nil
            }

            switch content {
            case .feed(let vc):
                let coordinator = FeedCoordinator(router: self.router,
                                                  deepLink: self.deepLink,
                                                  feedVC: vc)
                self.addChildAndStart(coordinator) { (_) in }
            case .channels(let vc):
                let coordinator = ChannelsCoordinator(router: self.router,
                                                      deepLink: self.deepLink,
                                                      channelsVC: vc)
                self.addChildAndStart(coordinator) { (_) in }
            case .profile(let vc):
                let coordinator = ProfileCoordinator(router: self.router,
                                                     deepLink: self.deepLink,
                                                     profileVC: vc)
                self.addChildAndStart(coordinator) { (_) in }
            }
        }

        if let deeplink = self.deepLink {
            self.handle(deeplink: deeplink)
        }
    }

//    let masterPromise = Promise<[Value]>()

//    let waitQueue = queue ?? waitSyncQueue
//
//    let totalFutures = futures.count
//    var resolvedFutures = 0
//    var values: [Value] = []
//
//    if futures.isEmpty {
//        masterPromise.resolve(with: values)
//    } else {
//        futures.forEach { promise in
//            promise.observe(with: { (result) in
//                waitQueue.mainSyncSafe {
//                    switch result {
//                    case .success(let value):
//                        resolvedFutures += 1
//                        values.append(value)
//                        if resolvedFutures == totalFutures {
//                            masterPromise.resolve(with: values)
//                        }
//                    case .failure(let error):
//                        masterPromise.reject(with: error)
//                    }
//                }
//            })
//        }
//    }
//
//    return masterPromise

    func handle(deeplink: DeepLinkable) {
        self.deepLink = deeplink

        guard let target = deeplink.deepLinkTarget else { return }

        switch target {
        case .reservation:
            break // show a reservation alert. 
        case .home:
            break
        case .login:
            break
        case .channel:
            if let channelId = deeplink.customMetadata["channelId"] as? String,
               let channel = ChannelSupplier.shared.getChannel(withSID: channelId) {
                self.startChannelFlow(for: channel.channelType)
            }
        case .routine:
            self.startRoutineFlow()
        case .profile:
            self.homeVC.current = .profile(self.homeVC.profileVC)
        case .feed:
            self.homeVC.current = .feed(self.homeVC.feedVC)
        case .channels:
            self.homeVC.current = .channels(self.homeVC.channelsVC)
        }
    }

    private func startRoutineFlow() {
        let coordinator = RitualCoordinator(router: self.router, deepLink: self.deepLink)
        self.addChildAndStart(coordinator) { (result) in }
        let source = self.homeVC.currentCenterVC ?? self.homeVC
        self.router.present(coordinator, source: source)
    }

    func startChannelFlow(for type: ChannelType?) {
        self.removeChild()
        var channel: DisplayableChannel?
        if let t = type {
            channel = DisplayableChannel(channelType: t)
        }
        let coordinator = ChannelCoordinator(router: self.router, deepLink: self.deepLink, channel: channel)
        self.addChildAndStart(coordinator, finishedHandler: { (_) in
            self.router.dismiss(source: coordinator.toPresentable(), animated: true) {
                self.finishFlow(with: ())
            }
        })
        self.router.present(coordinator, source: self.homeVC, animated: true)
    }
}
