//
//  ActivityViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/4/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

protocol ActivityViewControllerDelegate: AnyObject {
    func activityView(_ controller: ActivityViewController, didCompleteWith result: ActivityViewController.Result)
}

class ActivityViewController: UIActivityViewController {
    
    struct Result {
        var type: UIActivity.ActivityType?
        var didShare: Bool
        var items: [Any]
        var error: Error?
    }
    
    unowned let delegate: ActivityViewControllerDelegate
    
    init(with delegate: ActivityViewControllerDelegate, activityItems: [Any]) {
        self.delegate = delegate
        super.init(activityItems: activityItems, applicationActivities: nil)
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.excludedActivityTypes = [.postToFacebook, .postToVimeo, .postToWeibo, .assignToContact, .addToReadingList, .airDrop, .postToFlickr, .postToTencentWeibo, .assignToContact, .mail, .markupAsPDF, .saveToCameraRoll, .markupAsPDF]
        if #available(iOS 15.4, *) {
            self.allowsProminentActivity = true
        }
        
        self.completionWithItemsHandler = { type, completed, items, error in
            let result = Result(type: type,
                                didShare: completed,
                                items: items ?? [],
                                error: error)
            self.delegate.activityView(self, didCompleteWith: result)
        }
    }
}
