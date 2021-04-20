//
//  ArchiveCell.swift
//  Ours
//
//  Created by Benji Dodgson on 4/20/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ArchiveCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = Post

    private let gradientView = ArchiveGradientView()
    private let imageView = UIImageView()
    private let label = Label(font: .small)

    var currentItem: Post?

    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.addSubview(self.imageView)
        self.imageView.contentMode = .scaleAspectFill
        self.imageView.clipsToBounds = true 

        self.contentView.addSubview(self.gradientView)

        self.contentView.addSubview(self.label)
        self.label.setTextColor(.background4)
    }

    func configure(with item: Post) {
        guard let file = item.file else { return }

        file.getDataInBackground { data, error in
            if let data = data, let image = UIImage(data: data) {
                self.imageView.image = image
            }
        } progressBlock: { progress in
            print(progress)
        }

        self.label.setText(item.createdAt?.getDistanceAgoString() ?? String())
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.imageView.expandToSuperviewSize()

        self.gradientView.expandToSuperviewWidth()
        self.gradientView.height = self.contentView.halfHeight
        self.gradientView.pin(.bottom)

        self.label.setSize(withWidth: self.width)
        self.label.pin(.left, padding: 6)
        self.label.pin(.bottom, padding: 6)
    }
}

class ArchiveGradientView: GradientView {

    init() {
        let colors: [CGColor] = [Color.background1.color.withAlphaComponent(0.6).cgColor,
                                 Color.background1.color.withAlphaComponent(0).cgColor].reversed()

        super.init(with: colors, startPoint: .topCenter, endPoint: .bottomCenter)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
