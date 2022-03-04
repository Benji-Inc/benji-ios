//
//  ImageDisplayable.swift
//  Benji
//
//  Created by Benji Dodgson on 12/27/18.
//  Copyright © 2018 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse

protocol ImageDisplayable {
    var image: UIImage? { get }
    var url: URL? { get }
    var fileObject: PFFileObject? { get }
}

extension ImageDisplayable {

    var url: URL? {
        return nil 
    }

    var fileObject: PFFileObject? {
        return nil
    }
}
