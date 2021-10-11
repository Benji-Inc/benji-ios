//
//  ConversationHeaderAttributesConfigurer.swift
//  Benji
//
//  Created by Benji Dodgson on 11/26/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ConversationHeaderAttributesConfigurer {

    /// Used to configure the layout attributes for a given header.
    ///
    /// - Parameters:
    /// - attributes: The attributes of the header.
    /// The default does nothing
    func configure(attributes: ConversationCollectionViewLayoutAttributes,
                   for layout: ConversationThreadCollectionViewLayout) {}

    /// Used to size an item at a given `IndexPath`.
    ///
    /// - Parameters:
    /// - indexPath: The `IndexPath` of the item to be displayed.
    /// The default return .zero
    func sizeForHeader(at section: Int, for layout: ConversationThreadCollectionViewLayout) -> CGSize { return .zero }
}
