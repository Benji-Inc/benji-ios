//
//  AttachementCollectionView.swift
//  Benji
//
//  Created by Benji Dodgson on 8/29/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class EmptyAttachmentView: View {
    let button = Button()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.set(backgroundColor: .clear)
        self.addSubview(self.button)
        self.button.set(style: .normal(color: .purple, text: "Authorize"))
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.button.size = CGSize(width: 140, height: 40)
        self.button.centerOnXAndY()
    }
}

class AttachmentCollectionView: CollectionView {

    let emptyView = EmptyAttachmentView()
    var didTapAuthorize: CompletionOptional = nil
    private var cancellables = Set<AnyCancellable>()

    init() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 4
        layout.minimumLineSpacing = 4

        super.init(layout: layout)

        self.backgroundView = self.emptyView
        self.emptyView.alpha = 0

        self.emptyView.button.didSelect { [unowned self] in
            self.didTapAuthorize?()
        }

        self.publisher(for: \.contentSize).mainSink { (size) in
            self.emptyView.alpha = size.width > 0.0 ? 0.0 : 1.0
        }.store(in: &self.cancellables)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        self.bounces = false
        self.set(backgroundColor: .clear)
        self.showsHorizontalScrollIndicator = false

        self.register(AttachmentHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader)
    }
}
