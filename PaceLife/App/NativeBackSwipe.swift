import SwiftUI
import UIKit

/// Keep the existing native interactive-pop recognizer scoped to the visible
/// detail. Never install a custom pan or affect the root pager.
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
    private var visible = false
    #if DEBUG
    private var originalIdentifier: String?
    #endif

    override func loadView() {
        view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        visible = true
        installIfAttached()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        installIfAttached()
    }
    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        if parent == nil { restore() } else { installIfAttached() }
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        installIfAttached()
    }
    private func installIfAttached() {
        guard visible, !installed, view.window != nil, let navigationController,
              navigationController.viewControllers.count > 1,
              let gesture = navigationController.interactivePopGestureRecognizer else { return }
        observedNavigation = navigationController
        originalDelegate = gesture.delegate
        originalEnabled = gesture.isEnabled
        installed = true
        gesture.delegate = self
        gesture.isEnabled = true
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--uitesting") {
            originalIdentifier = navigationController.view.accessibilityIdentifier
            navigationController.view.accessibilityIdentifier = "nativeBackNavigation"
        }
        #endif
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        visible = false
        restore()
    }
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard visible, let navigation = observedNavigation else { return false }
        return navigation.viewControllers.count > 1 && navigation.transitionCoordinator == nil
    }
    func restore() {
        guard installed else { return }
        if let gesture = observedNavigation?.interactivePopGestureRecognizer, gesture.delegate === self {
            gesture.delegate = originalDelegate
            gesture.isEnabled = originalEnabled
        }
        #if DEBUG
        if observedNavigation?.view.accessibilityIdentifier == "nativeBackNavigation" {
            observedNavigation?.view.accessibilityIdentifier = originalIdentifier
        }
        originalIdentifier = nil
        #endif
        installed = false
        observedNavigation = nil
        originalDelegate = nil
    }
}
