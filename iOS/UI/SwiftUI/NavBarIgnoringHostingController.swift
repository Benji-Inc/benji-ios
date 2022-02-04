//
//  NavBarIgnoringHostingController.swift
//  Jibber
//
//  Created by Martin Young on 2/3/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import SwiftUI

/// A subclass of UIHostingController  that doesn't allow its embedded SwiftUI views to affect the UINavigationControllers nav bar visibility.
/// NOTE: This class is a HACK that  exists to work around undesirable interactions between UINavigationControllers and embedded SwiftUI views.
/// For some reason, embedded SwiftUI Views set the their containing NavController's nav bar to visible regardless of the navigationBarHidden state.
class NavBarIgnoringHostingController<Content>: UIHostingController<Content> where Content: View {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.set(backgroundColor: .clear)
    }

    override func viewWillAppear(_ animated: Bool) {
        let wasNavigationBarHidden = self.navigationController?.isNavigationBarHidden

        super.viewWillAppear(animated)

        // If the SwiftUI view changed the NavBar's visibility, reset it back to what it was.
        if let wasNavigationBarHidden = wasNavigationBarHidden,
            self.navigationController?.isNavigationBarHidden != wasNavigationBarHidden {

            self.navigationController?.isNavigationBarHidden = wasNavigationBarHidden
        }
    }
}
