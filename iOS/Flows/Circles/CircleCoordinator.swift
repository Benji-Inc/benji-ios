//
//  CircleCoordinator.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/26/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class CircleCoordinator: PresentableCoordinator<Void> {
    
    let circleVC: CircleViewController
    
    init(with cirlce: Circle,
         router: Router,
         deepLink: DeepLinkable?) {
        
        self.circleVC = CircleViewController(with: cirlce)
        super.init(router: router, deepLink: deepLink)
    }
    
    override func toPresentable() -> PresentableCoordinator<Void>.DismissableVC {
        return self.circleVC
    }
    
    override func start() {
        super.start()
        
        self.circleVC.button.didSelect { [unowned self] in
            self.presentCircleTitleAlert()
        }
        
        self.circleVC.$selectedItems.mainSink { [unowned self] items in
            guard let itemType = items.first else { return }
            switch itemType {
            case .item(let circleItem):
                if circleItem.canAdd {
                    self.presentPeoplePicker()
                }
            }
        }.store(in: &self.cancellables)
    }
    
    func presentPeoplePicker() {
        
        self.removeChild()
        let coordinator = PeopleCoordinator(router: self.router, deepLink: self.deepLink)
        
        self.addChildAndStart(coordinator) { [unowned self] people in
            self.router.dismiss(source: coordinator.toPresentable(), animated: true) { [unowned self] in
                self.updateCircle(with: people)
            }
        }
        
        self.router.present(coordinator, source: self.circleVC)
    }
    
    func updateCircle(with people: [Person]) {
        Task {
           let updated = try await self.circleVC.circle.add(people: people)
            self.circleVC.update(with: updated)
        }
    }
    
    func presentCircleTitleAlert() {
        
        let alertController = UIAlertController(title: "Update Name", message: "", preferredStyle: .alert)
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Name"
        }
        let saveAction = UIAlertAction(title: "Confirm", style: .default, handler: { [unowned self] alert -> Void in
            if let textField = alertController.textFields?.first,
               let text = textField.text,
               !text.isEmpty {
                
                alertController.dismiss(animated: true, completion: {
                    Task {
                        self.circleVC.circle.name = text
                        try await self.circleVC.circle.saveToServer()
                        self.circleVC.circleNameLabel.setText(text)
                        self.circleVC.view.layoutNow()
                    }
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
