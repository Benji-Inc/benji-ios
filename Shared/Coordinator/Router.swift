//
//  Router.swift
//  Benji
//
//  Created by Benji Dodgson on 8/3/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

class Router: NSObject, UINavigationControllerDelegate {

    var topmostViewController: UIViewController {
        return self.navController.topmostViewController()
    }

    private var completions: [UIViewController : () -> Void]
    unowned let navController: UINavigationController
    // True if the router is currently in the process of dismissing a module.
    private var isDismissing = false

    private let transitionRouter = ModalTransitionController()

    init(navController: UINavigationController) {
        self.navController = navController
        self.completions = [:]

        super.init()

        self.navController.delegate = self
    }

    /// The cancel handler is called when the presented module is dimissed
    /// by something other than this router.
    func present(_ module: Presentable,
                 source: UIViewController,
                 cancelHandler: (() -> Void)? = nil,
                 animated: Bool = true,
                 completion: (() -> Void)? = nil) {

        let viewController = module.toPresentable()

        // Don't override a view controller's default transitioning delegate if it has one.
        if viewController.transitioningDelegate.isNil {
            viewController.transitioningDelegate = self.transitionRouter
        }

        // IMPORTANT: The module will have a strong reference to its viewController. To avoid a retain
        // cycle, pass in a weak reference to the module in the capture list.
        let dismissHandler = DismissHandler()
        dismissHandler.handler
            = { [unowned self, unowned dismissHandler = dismissHandler, weak module = module] in
                module?.removeFromParent()

                // If this router didn't trigger the dismiss, then the module was cancelled.
                if !self.isDismissing {
                    cancelHandler?()
                }
                // Once the cancel handler is called, remove the dismissHandler from the array
                // so it's not called again.
                viewController.dismissHandlers.remove(object: dismissHandler)
        }
        viewController.dismissHandlers.append(dismissHandler)

        source.present(viewController,
                       animated: animated,
                       completion: completion)
    }

    func dismiss(source: UIViewController,
                 animated: Bool = true,
                 completion: (() -> Void)? = nil) {

        self.isDismissing = true
        source.dismiss(animated: animated) {
            self.isDismissing = false
            completion?()
        }
    }

    // The cancel handler is called when the presented module is popped off the nav stack
    // by something other than this router.
    func push(_ module: Presentable,
              cancelHandler: (() -> Void)? = nil,
              animated: Bool = true) {

        let viewController = module.toPresentable()

        // IMPORTANT: The module will have a strong reference to its viewController. To avoid a retain
        // cycle, pass in a weak reference to the module in the capture list.
        viewController.dismissHandlers.append { [unowned self, weak module = module] in
            module?.removeFromParent()

            if !self.isDismissing {
                cancelHandler?()
            }
        }

        self.navController.pushViewController(viewController, animated: animated)
    }

    /// Pops the top module, can pass in a module if the one you need to pop is not on the top of the stack, but you must ensure that the instance will be the same as the one in the navigation stack (aka to presentable does not create a new instance)
    func popModule(animated: Bool, module: Presentable? = nil) {
        self.isDismissing = true
        if let vc = module?.toPresentable(),
            self.navController.viewControllers.count > 1 {
            let array = self.navController.viewControllers
            let slice = array.split(separator: vc)[0]
            let stack = Array(slice)
            self.navController.setViewControllers(stack, animated: true)
        } else {
            self.navController.popViewController(animated: true)
        }
    }

    func setRootModule(_ module: Presentable, animated: Bool) {
        self.navController.setViewControllers([module.toPresentable()], animated: animated)
    }

    // MARK: UINavigationControllerDelegate

    func navigationController(_ navigationController: UINavigationController,
                              animationControllerFor operation: UINavigationController.Operation,
                              from fromVC: UIViewController,
                              to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {

        guard let from = fromVC as? TransitionableViewController, let to = toVC as? TransitionableViewController else { return nil }

        return TransitionRouter(fromVC: from, toVC: to, operation: operation)
    }

    func navigationController(_ navigationController: UINavigationController,
                              didShow viewController: UIViewController,
                              animated: Bool) {
        self.isDismissing = false
    }
}

