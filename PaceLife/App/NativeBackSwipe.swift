import SwiftUI
import UIKit

/// SwiftUI's modal NavigationStack can expose a native back button while its
/// interactive-pop recognizer refuses an edge swipe. Scope the native recognizer
/// to this detail's lifetime; never install a custom pan or affect the root pager.
struct NativeBackSwipe: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> NativeBackSwipeController { NativeBackSwipeController() }
    func updateUIViewController(_ controller: NativeBackSwipeController, context: Context) {}
    static func dismantleUIViewController(_ controller: NativeBackSwipeController, coordinator: ()) { controller.restore() }
}

@MainActor
final class NativeBackSwipeController: UIViewController, UIGestureRecognizerDelegate {
    private weak var observedNavigation: UINavigationController?
    private weak var originalDelegate: (any UIGestureRecognizerDelegate)?
    private var originalEnabled = false
    private var installed = false

    override func loadView() {
        view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !installed, let navigationController,
              navigationController.viewControllers.count > 1,
              let gesture = navigationController.interactivePopGestureRecognizer else { return }
        observedNavigation = navigationController
        originalDelegate = gesture.delegate
        originalEnabled = gesture.isEnabled
        installed = true
        gesture.delegate = self
        gesture.isEnabled = true
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        restore()
    }
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let navigation = observedNavigation else { return false }
        return navigation.viewControllers.count > 1 && navigation.transitionCoordinator == nil
    }
    func restore() {
        guard installed else { return }
        if let gesture = observedNavigation?.interactivePopGestureRecognizer, gesture.delegate === self {
            gesture.delegate = originalDelegate
            gesture.isEnabled = originalEnabled
        }
        installed = false
        observedNavigation = nil
        originalDelegate = nil
    }
}
