import SwiftUI

// Components follow docs/DESIGN_SYSTEM.md and the measured Pace Social reference
// (docs/DESIGN_REFERENCE_ANALYSIS.md). Views supply already localized strings.

@MainActor
struct PaceCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    private let padding: CGFloat
    private let content: Content

    init(padding: CGFloat = PaceSpacing.m, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(padding)
            .background(PaceColor.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(PaceColor.border, lineWidth: 1)
                    .allowsHitTesting(false)
            }
            .shadow(color: .black.opacity(colorScheme == .light ? 0.04 : 0), radius: 10, y: 3)
    }
}

/// Inner box of a card: own border, 14 pt radius, same surface family.
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
            .background(PaceColor.surfaceSecondary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
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
            .background(background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(isEnabled ? (configuration.isPressed ? 0.78 : 1) : 0.45)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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

/// Compact filled action of the header ("Anpassen"/"Fertig") and inline actions.
@MainActor
struct PaceCompactButtonStyle: ButtonStyle {
    var prominent = true
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .lineLimit(1)
            .padding(.horizontal, 14)
            .frame(minHeight: 40)
            .foregroundStyle(prominent ? PaceColor.onAccent : PaceColor.accentStrong)
            .background(prominent ? PaceColor.accentStrong : PaceColor.accentSoft,
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1) : 0.45)
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .frame(minHeight: 44)
    }
}

/// Text-only accent action ("Tagesziel ändern", "+ Gruppe erstellen").
@MainActor
struct PaceLinkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body)
            .foregroundStyle(PaceColor.accent)
            .opacity(configuration.isPressed ? 0.6 : 1)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
    }
}

/// Lowercase Pace wordmark. The original logo asset was not supplied; this is a
/// rounded system-font approximation, disclosed in Profile → About and VoiceOver.
@MainActor
struct PaceWordmark: View {
    var prominent = true
    @ScaledMetric(relativeTo: .largeTitle) private var size: CGFloat = 34

    var body: some View {
        let base = prominent ? size : size * 0.82
        HStack(alignment: .firstTextBaseline, spacing: base * 0.12) {
            Text(verbatim: "pace")
                .font(.system(size: min(base, 52), weight: .black, design: .rounded))
                .kerning(-0.6)
                .foregroundStyle(PaceColor.brand)
            Text(verbatim: "life")
                .font(.system(size: min(base * 0.5, 26), weight: .bold, design: .rounded))
                .foregroundStyle(PaceColor.accent)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "Pace Life"))
        .accessibilityAddTraits(.isHeader)
    }
}

/// Root page header: wordmark row with a primary action, then a large title row
/// with icon actions. Both rows keep a 44 pt minimum to avoid vertical jumps.
@MainActor
struct PaceRootHeader<Primary: View, Accessory: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder var primary: Primary
    @ViewBuilder var accessory: Accessory

    var body: some View {
        VStack(alignment: .leading, spacing: PaceSpacing.xxs) {
            HStack(alignment: .center, spacing: PaceSpacing.s) {
                PaceWordmark()
                Spacer(minLength: PaceSpacing.xs)
                primary
            }
            .frame(minHeight: 44)
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: PaceSpacing.xs) {
                    titleText
                    Spacer(minLength: PaceSpacing.xs)
                    accessory
                }
                VStack(alignment: .leading, spacing: PaceSpacing.xxs) {
                    titleText
                    HStack(spacing: PaceSpacing.xs) { accessory }
                }
            }
            .frame(minHeight: 44)
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

    private var titleText: some View {
        Text(title)
            .font(.title.bold())
            .foregroundStyle(PaceColor.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }
}

extension PaceRootHeader where Primary == EmptyView, Accessory == EmptyView {
    init(title: String, subtitle: String? = nil) {
        self.init(title: title, subtitle: subtitle, primary: { EmptyView() }, accessory: { EmptyView() })
    }
}

/// 44 pt icon target as used for calendar/bell in the Pace header.
@MainActor
struct PaceIconButton: View {
    let systemImage: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(PaceColor.textPrimary)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

/// Small mint square for page actions (add, edit, settings).
@MainActor
struct PaceSquareIcon: View {
    let systemImage: String
    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(PaceColor.accentStrong)
            .frame(width: 36, height: 36)
            .background(PaceColor.accentSoft, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
    }
}

/// Pushed subpage: native back button (keeps edge swipe), then wordmark,
/// large title and content in one vertical scroll. The fixed Pace dock stays visible.
@MainActor
struct PaceSubpage<Content: View, Actions: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder var actions: Actions
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PaceSpacing.m) {
                VStack(alignment: .leading, spacing: PaceSpacing.xxs) {
                    HStack(alignment: .center, spacing: PaceSpacing.xxs) {
                        PaceWordmark(prominent: false)
                        Spacer(minLength: PaceSpacing.xs)
                        actions
                    }
                    .frame(minHeight: 44)
                    Text(title)
                        .font(.title.bold())
                        .foregroundStyle(PaceColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    if let subtitle {
                        Text(subtitle)
                            .font(.callout)
                            .foregroundStyle(PaceColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                SaveErrorBanner()
                content
            }
            .padding(.horizontal, PaceSpacing.m)
            .padding(.bottom, PaceSpacing.l)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .background(PaceColor.background)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // The title is shown large in the content; the bar keeps only the back link.
            ToolbarItem(placement: .principal) { Text(verbatim: "").accessibilityHidden(true) }
        }
        .toolbar(.visible, for: .navigationBar)
    }
}

extension PaceSubpage where Actions == EmptyView {
    init(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.init(title: title, subtitle: subtitle, actions: { EmptyView() }, content: content)
    }
}

/// Card header: semibold title, optional trailing chevron or custom action.
@MainActor
struct PaceCardHeader<Trailing: View>: View {
    let title: String
    var systemImage: String? = nil
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(alignment: .center, spacing: PaceSpacing.xs) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(PaceColor.accent)
                    .accessibilityHidden(true)
            }
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(PaceColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: PaceSpacing.xs)
            trailing
        }
    }
}

extension PaceCardHeader where Trailing == PaceChevron {
    init(title: String, systemImage: String? = nil, chevron: Bool) {
        self.init(title: title, systemImage: systemImage, trailing: { PaceChevron(visible: chevron) })
    }
}

@MainActor
struct PaceChevron: View {
    var visible = true
    var body: some View {
        if visible {
            Image(systemName: "chevron.right")
                .font(.body.weight(.semibold))
                .foregroundStyle(PaceColor.textPrimary)
                .accessibilityHidden(true)
        }
    }
}

/// Equal-width segments (Tag · Woche · Monat, Automatisch · Hell · Dunkel).
@MainActor
struct PaceSegmentedControl<Value: Hashable>: View {
    @Binding var selection: Value
    let options: [(value: Value, title: String)]
    var identifierPrefix: String? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: PaceSpacing.xs) {
            ForEach(options.indices, id: \.self) { index in
                let option = options[index]
                let selected = option.value == selection
                Button {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.18)) { selection = option.value }
                } label: {
                    Text(option.title)
                        .font(.subheadline.weight(selected ? .semibold : .regular))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .padding(.horizontal, PaceSpacing.xxs)
                        .foregroundStyle(selected ? PaceColor.onAccent : PaceColor.textPrimary)
                        .background(selected ? PaceColor.accentStrong : PaceColor.fieldBackground,
                                    in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .contentShape(Rectangle())
                        .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
                .accessibilityIdentifier(identifierPrefix.map { $0 + "." + String(index) } ?? option.title)
            }
        }
    }
}

/// Capsule filter chip with icon (Schritte · Distanz · Kalorien pattern).
@MainActor
struct PaceChip: View {
    let title: String
    var systemImage: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: PaceSpacing.xxs) {
                if let systemImage { Image(systemName: systemImage).accessibilityHidden(true) }
                Text(title).lineLimit(1)
            }
            .font(.subheadline.weight(isSelected ? .semibold : .regular))
            .padding(.horizontal, PaceSpacing.s)
            .frame(minHeight: 34)
            .foregroundStyle(isSelected ? PaceColor.onSelection : PaceColor.textPrimary)
            .background(isSelected ? PaceColor.selectionFill : Color.clear, in: Capsule())
            .overlay { Capsule().strokeBorder(isSelected ? Color.clear : PaceColor.border, lineWidth: 1) }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Settings row card: mint icon square, title, secondary line, value and chevron.
@MainActor
struct PaceSettingsRowLabel: View {
    let systemImage: String
    let title: String
    var subtitle: String? = nil
    var value: String? = nil
    var showsChevron = true

    var body: some View {
        HStack(spacing: PaceSpacing.s) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(PaceColor.accentStrong)
                .frame(width: 32, height: 32)
                .background(PaceColor.accentSoft, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline).foregroundStyle(PaceColor.textPrimary)
                if let subtitle {
                    Text(subtitle).font(.footnote).foregroundStyle(PaceColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: PaceSpacing.xs)
            if let value {
                Text(value).font(.subheadline).foregroundStyle(PaceColor.textSecondary).lineLimit(1)
            }
            if showsChevron {
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold))
                    .foregroundStyle(PaceColor.textSecondary).accessibilityHidden(true)
            }
        }
        .padding(.horizontal, PaceSpacing.s)
        .padding(.vertical, PaceSpacing.s)
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        .background(PaceColor.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(PaceColor.border, lineWidth: 1)
                .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
    }
}

/// Section title outside of cards ("Einstellungen", "Top-Freunde").
@MainActor
struct PaceSectionTitle<Trailing: View>: View {
    let title: String
    @ViewBuilder var trailing: Trailing
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(.title3.weight(.semibold)).foregroundStyle(PaceColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: PaceSpacing.xs)
            trailing
        }
        .padding(.top, PaceSpacing.xs)
    }
}

extension PaceSectionTitle where Trailing == EmptyView {
    init(_ title: String) { self.init(title: title, trailing: { EmptyView() }) }
}

/// Linear goal bar with round caps.
@MainActor
struct PaceProgressBar: View {
    let progress: Double
    var height: CGFloat = 8
    var tint: Color? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var fraction: Double { progress.isFinite ? min(max(progress, 0), 1) : 0 }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(PaceColor.track)
                Capsule().fill(tint ?? PaceColor.accent)
                    .frame(width: fraction > 0 ? max(height, proxy.size.width * fraction) : 0)
            }
        }
        .frame(height: height)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: fraction)
        .accessibilityHidden(true)
    }
}

/// Ring with a centered value; 12 pt round line.
@MainActor
struct PaceRing: View {
    let progress: Double
    var diameter: CGFloat = 112
    var lineWidth: CGFloat = 12
    var centerText: String? = nil
    var tint: Color? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var fraction: Double { progress.isFinite ? min(max(progress, 0), 1) : 0 }

    var body: some View {
        ZStack {
            Circle().stroke(PaceColor.track, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(tint ?? PaceColor.accentStrong, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            if let centerText {
                Text(centerText)
                    .font(.system(size: diameter * 0.19, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(PaceColor.textPrimary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .padding(lineWidth + 4)
            }
        }
        .frame(width: diameter, height: diameter)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.35), value: fraction)
    }
}

/// Supply already localized value and label. Over-target progress remains a
/// complete ring; invalid input cannot produce a non-finite shape.
@MainActor
struct PaceProgressRing: View {
    let progress: Double
    let value: String
    let label: String
    @ScaledMetric(relativeTo: .largeTitle) private var diameter: CGFloat = 132

    var body: some View {
        VStack(spacing: PaceSpacing.xs) {
            PaceRing(progress: progress, diameter: min(diameter, 220), centerText: value)
            Text(label)
                .font(.callout)
                .foregroundStyle(PaceColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(value)
    }
}

/// Small stat box ("38.823 · Gesamt").
@MainActor
struct PaceStatTile: View {
    let value: String
    let label: String
    var systemImage: String? = nil

    var body: some View {
        PaceTile {
            HStack(spacing: PaceSpacing.xs) {
                if let systemImage {
                    Image(systemName: systemImage).foregroundStyle(PaceColor.accent).accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(value).font(.headline.weight(.bold)).monospacedDigit()
                        .foregroundStyle(PaceColor.textPrimary).lineLimit(1).minimumScaleFactor(0.7)
                    Text(label).font(.caption).foregroundStyle(PaceColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 2)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Empty state inside a card (icon circle, title, message, optional action).
@MainActor
struct PaceEmptyState<Action: View>: View {
    let systemImage: String
    let title: String
    let message: String
    @ViewBuilder var action: Action

    var body: some View {
        VStack(spacing: PaceSpacing.s) {
            Image(systemName: systemImage)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(PaceColor.accentStrong)
                .frame(width: 56, height: 56)
                .background(PaceColor.accentSoft, in: Circle())
                .accessibilityHidden(true)
            Text(title).font(.headline).foregroundStyle(PaceColor.textPrimary).multilineTextAlignment(.center)
            Text(message).font(.subheadline).foregroundStyle(PaceColor.textSecondary)
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            action
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, PaceSpacing.xs)
    }
}

extension PaceEmptyState where Action == EmptyView {
    init(systemImage: String, title: String, message: String) {
        self.init(systemImage: systemImage, title: title, message: message, action: { EmptyView() })
    }
}

/// Toggle in a softly tinted row ("In regionalen Rankings erscheinen").
@MainActor
struct PaceToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    var body: some View {
        Toggle(isOn: $isOn) { Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(PaceColor.textPrimary) }
            .tint(PaceColor.accentStrong)
            .padding(.horizontal, PaceSpacing.s)
            .frame(minHeight: 52)
            .background(PaceColor.accentSoft, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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

/// Small capsule label, e.g. "Demo" or "Lokal".
@MainActor
struct PaceBadge: View {
    let text: String
    var systemImage: String? = nil
    var body: some View {
        HStack(spacing: 4) {
            if let systemImage { Image(systemName: systemImage).accessibilityHidden(true) }
            Text(text)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 8).padding(.vertical, 3)
        .foregroundStyle(PaceColor.accentStrong)
        .background(PaceColor.accentSoft, in: Capsule())
    }
}

/// Grouped form styling for editors presented as sheets.
extension View {
    @MainActor func paceFormStyle() -> some View {
        self.scrollContentBackground(.hidden)
            .background(PaceColor.background)
            .tint(PaceColor.accentStrong)
    }
}
