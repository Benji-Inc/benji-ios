//
//  FavoriteExpressionView.swift
//  Jibber
//
//  Created by Benji Dodgson on 7/20/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class FavoriteExpressionView: BaseView {
    
    let favoriteType: FavoriteType
    let personView = PersonGradientView()
    private let label = ThemeLabel(font: .emoji)
    
    var didSelectEdit: ((FavoriteType) -> Void)? = nil
    
    private weak var firstResponderBeforeDisplay: UIResponder?
    private weak var inputHandlerBeforeDisplay: InputHandlerViewContoller?
    
    init(with expression: FavoriteType) {
        self.favoriteType = expression
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        let contextMenuInteraction = UIContextMenuInteraction(delegate: self)
        self.addInteraction(contextMenuInteraction)
        
        self.addSubview(self.personView)
        self.addSubview(self.label)
        self.label.textAlignment = .center
        self.label.setText(self.favoriteType.emoji)
        self.label.isVisible = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.personView.expandToSuperviewSize()
        
        self.label.sizeToFit()
        self.label.center = CGPoint(x: self.halfWidth + 1,
                                    y: self.halfHeight)
    }
    
    func loadExpression() async {
        if let expression = try? await self.favoriteType.getExpression() {
            self.personView.set(expression: expression, author: User.current())
            self.label.isVisible = false
        } else {
            self.label.isVisible = true
        }

        self.personView.set(emotionCounts: [self.favoriteType.emotion: 1])
    }
}

extension FavoriteExpressionView: UIContextMenuInteractionDelegate {
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {

        return UIContextMenuConfiguration(identifier: nil) { [unowned self] () -> UIViewController? in
            return FavoriteExpressionPreviewViewController(with: self.favoriteType)
        } actionProvider: { [unowned self] (suggestions) -> UIMenu? in
            return self.makeContextMenu()
        }
    }

    private func makeContextMenu() -> UIMenu {

        let edit = UIAction(title: "Edit",
                            image: ImageSymbol.faceSmiling.image) { [unowned self] _ in
            self.didSelectEdit?(self.favoriteType)
        }

        var menuElements: [UIMenuElement] = []
        
        menuElements.append(edit)

        return UIMenu.init(title: "",
                           image: nil,
                           identifier: nil,
                           options: [],
                           children: menuElements)
    }
    
    func loadMenu(completion: @escaping (([UIMenuElement]) -> Void)) {
            // load menu
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return nil
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                willDisplayMenuFor configuration: UIContextMenuConfiguration,
                                animator: UIContextMenuInteractionAnimating?) {

        self.firstResponderBeforeDisplay = UIResponder.firstResponder
        self.inputHandlerBeforeDisplay = self.firstResponderBeforeDisplay?.inputHandlerViewController
    }
        
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                willEndFor configuration: UIContextMenuConfiguration,
                                animator: UIContextMenuInteractionAnimating?) {

        // HACK: The input handler has problems becoming first responder again after the context menu
        // disappears. The text view also becomes unresponsive. To get around this, reset the responder
        // status on the input handler.
        self.inputHandlerBeforeDisplay?.resignFirstResponder()
        self.inputHandlerBeforeDisplay?.becomeFirstResponder()

        self.firstResponderBeforeDisplay?.becomeFirstResponder()
    }
}

fileprivate extension UIResponder {

    /// Returns the nearest input handler view controller in the responder chain that has an input accessory view or input accessory VC.
    var inputHandlerViewController: InputHandlerViewContoller? {
        if let vc = self as? InputHandlerViewContoller {
            return vc
        }

        return self.next?.inputHandlerViewController
    }
}
