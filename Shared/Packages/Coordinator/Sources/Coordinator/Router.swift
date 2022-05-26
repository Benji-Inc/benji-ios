//
//  File.swift
//  
//
//  Created by Benji Dodgson on 5/26/22.
//

import Foundation
import UIKit

public typealias ModalTransitionRouter = NSObject & UIViewControllerTransitioningDelegate

/// An object that can present Presentable objects via a navigation controller push, or modally.
/// Optionally, a cancel handler can be provided to execute code when the Presentable is dismissed
/// prematurely by something other than the router.
public class Router: NSObject, UINavigationControllerDelegate {

    unowned let navController: UINavigationController

    public var topmostViewController: UIViewController {
        return self.navController.topmostViewController()
    }

    // True if the router is currently in the process of dismissing a module.
    var isDismissing = false

    let modalTransitionRouter: ModalTransitionRouter?

    public init(navController: UINavigationController, modalTransitionRouter: ModalTransitionRouter?) {
        
        self.navController = navController
        self.modalTransitionRouter = modalTransitionRouter
        
        super.init()

        self.navController.delegate = self
    }

    // MARK: Modal Presentation

    /// The cancel handler is called when the presented module is dimissed
    /// by something other than this router.
    public func present(_ module: Presentable,
                 source: UIViewController,
                 cancelHandler: (() -> Void)? = nil,
                 animated: Bool = true,
                 completion: (() -> Void)? = nil) {

        let viewController = module.toPresentable()

        // Don't override a view controller's default transitioning delegate if it has one.
        if viewController.transitioningDelegate == nil {
            viewController.transitioningDelegate = self.modalTransitionRouter
        }

        // IMPORTANT: The module may have a strong reference to its viewController. To avoid a retain
        // cycle, pass in a weak reference to the module in the capture list.
        let dismissHandler = DismissHandler()
        dismissHandler.handler = { [unowned self,
                                    unowned dismissHandler = dismissHandler,
                                    weak module = module,
                                    weak viewController = viewController] in

            let currentPresentable = module?.toPresentable()

            // Only remove the module if its current VC is the one being dismissed.
            guard currentPresentable === viewController else { return }
            module?.removeFromParent()

            // If this router didn't trigger the dismiss, then the module was cancelled.
            if !self.isDismissing {
                cancelHandler?()
            }
            // Once the cancel handler is called, remove the dismissHandler from the array
            // so it's not called again.
            viewController?.dismissHandlers.remove(object: dismissHandler)
        }
        viewController.dismissHandlers.append(dismissHandler)

        source.present(viewController,
                       animated: animated,
                       completion: completion)
    }

    public func dismiss(source: UIViewController,
                 animated: Bool = true,
                 completion: (() -> Void)? = nil) {

        self.isDismissing = true
        source.dismiss(animated: animated) {
            self.isDismissing = false
            completion?()
        }
    }

    // MARK: Navigation Controller Presentation

    // The cancel handler is called when the presented module is popped off the nav stack
    // by something other than this router.
    public func push(_ module: Presentable,
              cancelHandler: (() -> Void)? = nil,
              animated: Bool = true) {

        let viewController = module.toPresentable()

        // IMPORTANT: The module will have a strong reference to its viewController. To avoid a retain
        // cycle, pass in a weak reference to the module in the capture list.
        viewController.dismissHandlers.append { [unowned self,
                                                 weak module = module,
                                                 weak viewController = viewController] in

            let currentPresentable = module?.toPresentable()

            // Only remove the module if its current VC is the one being dismissed.
            guard currentPresentable === viewController else { return }
            module?.removeFromParent()

            // If this router didn't trigger the dismiss, then the module was cancelled.
            if !self.isDismissing {
                cancelHandler?()
            }
        }

        self.navController.pushViewController(viewController, animated: animated)
    }

    /// Similar to a push, however the current view controller will be removed from the stack once the new one is pushed, effectively making it a swap.
    /// From the user's point of view, this just means that if they tap the back button, they'll go back to the screen before last.
    public func swapPush(_ module: Presentable,
                  cancelHandler: (() -> Void)? = nil,
                  animated: Bool = true) {

        let oldVC = self.navController.viewControllers.last
        self.push(module, cancelHandler: cancelHandler, animated: animated)
        if let oldVC = oldVC {
            self.navController.viewControllers.remove(object: oldVC)
        }
    }

    /// Removes the passed in module off the nav stack and any modules above it. The passed in module's view controller
    /// must exist in the nav stack or this function will have no effect. (Ensure that toPresentable does not create a new instance)
    /// If no module is passed in, the top view controller is popped off the navigation stack.
    public func popModule(module: Presentable? = nil, animated: Bool = true) {
        self.isDismissing = true
        if let vc = module?.toPresentable(),
           self.navController.viewControllers.count > 1 {

            let array = self.navController.viewControllers
            let element = array.enumerated().first { (sequence) -> Bool in
                return sequence.element == vc
            }

            // Check if VC is the rootVC if so just pop
            guard let index = element?.offset,
                  index > 0 else {
                      self.navController.popViewController(animated: animated)
                      return
                  }

            // Otherwise get the vc behind our module
            let popToVC = array[index - 1]
            self.navController.popToViewController(popToVC, animated: animated)
        } else {
            self.navController.popViewController(animated: animated)
        }
    }

    /// Pops to the passed in module by removing any modules above it on the navigation stack.
    public func popToModule(module: Presentable, animated: Bool = true) {
        self.popToViewController(module.toPresentable(), animated: animated)
    }

    func popToViewController(_ viewController: UIViewController, animated: Bool = true) {
        self.isDismissing = true
        if self.navController.viewControllers.count > 1 {
            self.navController.popToViewController(viewController, animated: animated)
        }
    }

    func setRootModule(_ module: Presentable, animated: Bool = true) {
        self.isDismissing = true
        self.navController.setViewControllers([module.toPresentable()], animated: animated)
    }

    // MARK: UINavigationControllerDelegate

    public func navigationController(_ navigationController: UINavigationController,
                              didShow viewController: UIViewController,
                              animated: Bool) {
        self.isDismissing = false
    }

    public func navigationController(_ navigationController: UINavigationController,
                              animationControllerFor operation: UINavigationController.Operation,
                              from fromVC: UIViewController,
                              to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return nil 
    }
}
