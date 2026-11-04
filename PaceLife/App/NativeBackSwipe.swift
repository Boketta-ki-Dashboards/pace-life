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
    private var originalValue: String?
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
            originalValue = navigationController.view.accessibilityValue
            navigationController.view.accessibilityIdentifier = "nativeBackNavigation"
            navigationController.view.accessibilityValue = "Ready; depth=\(navigationController.viewControllers.count)"
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
        var horizontalBack = true
        if let pan = gestureRecognizer as? UIPanGestureRecognizer {
            let movement = pan.velocity(in: navigation.view)
            let direction: CGFloat = navigation.view.effectiveUserInterfaceLayoutDirection == .rightToLeft ? -1 : 1
            horizontalBack = movement.x * direction > abs(movement.y)
        }
        let allowed = navigation.viewControllers.count > 1 && navigation.transitionCoordinator == nil && horizontalBack
        #if DEBUG
        if navigation.view.accessibilityIdentifier == "nativeBackNavigation" {
            navigation.view.accessibilityValue = "Begin=\(allowed); depth=\(navigation.viewControllers.count); transition=\(navigation.transitionCoordinator != nil); horizontal=\(horizontalBack)"
        }
        #endif
        return allowed
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // The native edge gesture takes precedence over a descendant scroll pan.
        // A vertical edge drag still fails shouldBegin and remains a scroll.
        if gestureRecognizer === observedNavigation?.interactivePopGestureRecognizer,
           otherGestureRecognizer is UIPanGestureRecognizer { return true }
        return originalDelegate?.gestureRecognizer?(gestureRecognizer, shouldBeRequiredToFailBy: otherGestureRecognizer) ?? false
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
            observedNavigation?.view.accessibilityValue = originalValue
        }
        originalIdentifier = nil
        originalValue = nil
        #endif
        installed = false
        observedNavigation = nil
        originalDelegate = nil
    }
}
