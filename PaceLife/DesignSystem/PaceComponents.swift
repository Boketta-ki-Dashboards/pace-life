import SwiftUI

@MainActor
struct PaceCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(PaceSpacing.m)
            .background(PaceColor.surface, in: RoundedRectangle(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(PaceColor.border, lineWidth: 1)
                    .allowsHitTesting(false)
            }
            .shadow(color: .black.opacity(colorScheme == .light ? 0.04 : 0), radius: 10, y: 3)
    }
}

@MainActor
struct PaceTile<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, PaceSpacing.s)
            .padding(.vertical, PaceSpacing.xs)
            .background(PaceColor.surfaceSecondary, in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(PaceColor.border, lineWidth: 1)
                    .allowsHitTesting(false)
            }
    }
}

@MainActor
struct PaceButtonStyle: ButtonStyle {
    enum Kind { case primary, secondary, destructive }
    var kind: Kind = .primary
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 52)
            .padding(.horizontal, PaceSpacing.m)
            .foregroundStyle(foreground)
            .background(background, in: RoundedRectangle(cornerRadius: 14))
            .opacity(isEnabled ? (configuration.isPressed ? 0.78 : 1) : 0.45)
            .contentShape(RoundedRectangle(cornerRadius: 14))
    }

    private var foreground: Color {
        switch kind {
        case .primary: PaceColor.onAccent
        case .secondary: PaceColor.accentStrong
        case .destructive: PaceColor.danger
        }
    }

    private var background: Color {
        switch kind {
        case .primary: PaceColor.accentStrong
        case .secondary: PaceColor.accentSoft
        case .destructive: PaceColor.surfaceSecondary
        }
    }
}

/// Supply already localized value and label. Over-target progress remains a
/// complete ring; invalid input cannot produce a non-finite shape.
@MainActor
struct PaceProgressRing: View {
    let progress: Double
    let value: String
    let label: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var diameter: CGFloat = 144

    private var fraction: Double { progress.isFinite ? min(max(progress, 0), 1) : 0 }

    var body: some View {
        VStack(spacing: PaceSpacing.xs) {
            ZStack {
                Circle().stroke(PaceColor.track, lineWidth: 12)
                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(PaceColor.accent, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(value)
                    .font(.largeTitle.weight(.heavy))
                    .monospacedDigit()
                    .foregroundStyle(PaceColor.textPrimary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .padding(PaceSpacing.m)
            }
            .frame(width: min(diameter, 240), height: min(diameter, 240))
            .padding(6)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: fraction)
            Text(label)
                .font(.callout)
                .foregroundStyle(PaceColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(value)
    }
}

/// The wordmark asset has not been supplied. This explicitly labelled system
/// text is a temporary substitute, not a reconstruction of the Pace logo.
@MainActor
struct PaceRootHeader: View {
    let title: String
    var subtitle: String? = nil
    let placeholderLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: PaceSpacing.xs) {
            HStack(alignment: .firstTextBaseline, spacing: PaceSpacing.xs) {
                Text("Pace Life")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(PaceColor.brand)
                Spacer(minLength: 0)
            }
            .frame(minHeight: 44, alignment: .leading)
            Text(placeholderLabel)
                .font(.caption)
                .foregroundStyle(PaceColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Text(title)
                .font(.largeTitle.bold())
                .foregroundStyle(PaceColor.textPrimary)
                .frame(minHeight: 44, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
            if let subtitle {
                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(PaceColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, PaceSpacing.xs)
    }
}

@MainActor
struct PaceStatus: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: PaceSpacing.s) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(PaceColor.accent)
                .accessibilityHidden(true)
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(PaceColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text(message)
                .font(.body)
                .foregroundStyle(PaceColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
