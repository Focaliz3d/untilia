import SwiftUI
import UIKit

/// Keep the two-column editor edge-attached at full safe-area width on compact
/// landscape phones as well as larger iPhones. SwiftUI's default floating sheet
/// can otherwise stay only 540 points wide despite page sizing.
struct SettingsSheetConfiguration: UIViewControllerRepresentable {
    var backgroundColor: Color

    func makeUIViewController(context: Context) -> Controller { Controller() }

    func updateUIViewController(_ controller: Controller, context: Context) {
        controller.backdrop.backgroundColor = UIColor(backgroundColor)
        controller.configureSheet()
    }

    final class Controller: UIViewController {
        let backdrop: UIView = {
            let view = UIView()
            view.isUserInteractionEnabled = false
            view.accessibilityElementsHidden = true
            return view
        }()

        override func loadView() {
            view = UIView()
            view.backgroundColor = .clear
            view.isUserInteractionEnabled = false
        }

        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)
            configureSheet()
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            configureSheet()
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            configureSheet()
        }

        override func viewDidDisappear(_ animated: Bool) {
            super.viewDidDisappear(animated)
            backdrop.removeFromSuperview()
        }

        func configureSheet() {
            var ancestor = parent
            while let controller = ancestor {
                if let sheet = controller.presentationController as? UISheetPresentationController {
                    if !sheet.prefersPageSizing { sheet.prefersPageSizing = true }
                    if !sheet.prefersEdgeAttachedInCompactHeight { sheet.prefersEdgeAttachedInCompactHeight = true }
                    if sheet.widthFollowsPreferredContentSizeWhenEdgeAttached { sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = false }
                    if let container = sheet.containerView, let presented = sheet.presentedView {
                        if container.bounds.width > container.bounds.height {
                            // Cover the dimmed margins without changing the sheet's frame.
                            var sheetRoot = presented
                            while let superview = sheetRoot.superview, superview !== container {
                                sheetRoot = superview
                            }
                            if sheetRoot.superview === container {
                                if backdrop.superview !== container {
                                    container.insertSubview(backdrop, belowSubview: sheetRoot)
                                }
                                backdrop.frame = container.bounds
                                backdrop.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                            }
                        } else {
                            backdrop.removeFromSuperview()
                        }
                    }
                    return
                }
                ancestor = controller.parent
            }
        }
    }
}
