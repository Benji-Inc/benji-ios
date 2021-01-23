//
//  AttachmentView.swift
//  Ours
//
//  Created by Benji Dodgson on 1/22/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class AttachmentView: View {

    private let imageView = DisplayableImageView()
    private var cancellables = Set<AnyCancellable>()

    static let expandedHeight: CGFloat = 100

    @Published var attachement: Attachment?

    override func initializeSubviews() {
        super.initializeSubviews()

        self.translatesAutoresizingMaskIntoConstraints = false

        self.set(backgroundColor: .red)

        self.addSubview(self.imageView)
        self.imageView.imageView.contentMode = .center
        self.imageView.clipsToBounds = true
    }

    func configure(with item: Attachment?) {
        guard let attachement = item else { return }

        self.attachement = attachement

        AttachmentsManager.shared.getImage(for: attachement,
                                           contentMode: .aspectFit,
                                           size: CGSize(width: 300, height: 300))
            .mainSink { (image, _) in
                self.imageView.displayable = image
                self.layoutNow()
            }.store(in: &self.cancellables)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.imageView.expandToSuperviewSize()
    }
}
