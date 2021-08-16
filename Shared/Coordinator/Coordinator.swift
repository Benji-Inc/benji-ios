//
//  Coordinator.swift
//  Benji
//
//  Created by Benji Dodgson on 6/22/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

@MainActor
protocol CoordinatorType: AnyObject {
    var parentCoordinator: CoordinatorType? { set get }
    var furthestChild: CoordinatorType { get }

    func start()
    func removeChild()
    func handle(launchActivity: LaunchActivity)
}

@MainActor
class Coordinator<Result>: NSObject, CoordinatorType {

    let router: Router
    var deepLink: DeepLinkable?

    private var onFinishedFlow: ((Result) -> Void)?

    weak var parentCoordinator: CoordinatorType?
    private(set) var childCoordinator: CoordinatorType?
    var furthestChild: CoordinatorType {
        if let child = self.childCoordinator {
            return child.furthestChild
        }
        return self
    }

    init(router: Router, deepLink: DeepLinkable?) {
        self.router = router
        self.deepLink = deepLink
    }

    func start() { }

    final func start(with deepLink: DeepLinkable?) {
        self.deepLink = deepLink
        self.start()
    }

    func addChildAndStart<ChildResult>(_ coordinator: Coordinator<ChildResult>,
                                       finishedHandler: @escaping (ChildResult) -> Void) {
        guard self.childCoordinator == nil else {
            print("WARNING!!!!! ATTEMPTING TO ADD CHILD COORDINATOR \(coordinator)"
                + " TO COORDINATOR \(self) THAT ALREADY HAS ONE \(self.childCoordinator!)")
            return
        }

        coordinator.parentCoordinator = self
        self.childCoordinator = coordinator

        // Assign the finish handler before calling start in case the coordinator finishes immediately
        coordinator.onFinishedFlow = finishedHandler
        coordinator.start()
    }

    func removeChild() {
        self.childCoordinator = nil
    }

    func removeFromParent() {
        self.parentCoordinator?.removeChild()
    }

    func finishFlow(with result: Result) {
        self.removeFromParent()
        self.onFinishedFlow?(result)
    }

    func handle(launchActivity: LaunchActivity) {}
}

class PresentableCoordinator<Result>: Coordinator<Result>, Presentable {

    var isFinished: Bool = false

    func toPresentable() -> DismissableVC {
        fatalError("toPresentable not implemented in \(self)")
    }

    override func finishFlow(with result: Result) {
        // IMPORTANT: Set isFinished true before calling super in case a VC dismissal happens in the
        // finished handler
        self.isFinished = true

        super.finishFlow(with: result)
    }
}
