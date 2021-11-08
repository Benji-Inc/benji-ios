//
//  File.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/6/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ToastErrorView: ToastView {

    private let label = Label(font: .smallBold, textColor: .red)

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.label)
        self.set(backgroundColor: .red)
    }

    override func reveal() {

    }

    override func dismiss() {

    }

    

    override func layoutSubviews() {
        super.layoutSubviews()



        
    }
}
