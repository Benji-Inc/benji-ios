//
//  CircleCoordinator.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/26/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class CircleCoordinator: PresentableCoordinator<Void> {
    
    lazy var circleVC = CircleViewController()
    
    override func toPresentable() -> PresentableCoordinator<Void>.DismissableVC {
        return self.circleVC
    }
    
    override func start() {
        super.start()
        
        self.circleVC.button.didSelect { [unowned self] in
            self.presentCircleTitleAlert()
        }
        
        self.circleVC.$selectedItems.mainSink { [unowned self] items in
            guard !items.isEmpty else { return }
            self.presentPeoplePicker()
        }.store(in: &self.cancellables)
    }
    
    func presentPeoplePicker() {
        
        self.removeChild()
        let coordinator = PeopleCoordinator(conversationID: nil,
                                            router: self.router,
                                            deepLink: self.deepLink)
        
        self.addChildAndStart(coordinator) { [unowned self] connections in
            self.router.dismiss(source: coordinator.toPresentable(), animated: true) { [unowned self] in
                self.updateCircle(with: connections)
            }
        }
        
        self.router.present(coordinator, source: self.circleVC)
    }
    
    func updateCircle(with connections: [Connection]) {
        
    }
    
    func presentCircleTitleAlert() {
        
        let alertController = UIAlertController(title: "Update Circle Name", message: "", preferredStyle: .alert)
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Name"
        }
        let saveAction = UIAlertAction(title: "Confirm", style: .default, handler: { [unowned self] alert -> Void in
            if let textField = alertController.textFields?.first,
               let text = textField.text,
               !text.isEmpty {
                
                self.circleVC.circleNameLabel.setText(text)
                self.circleVC.view.layoutNow()
                
                alertController.dismiss(animated: true, completion: {
                })
            }
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (action : UIAlertAction!) -> Void in
        })
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        self.circleVC.present(alertController, animated: true, completion: nil)
    }
}
