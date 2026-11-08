import SwiftUI
import PaceLifeCore

struct CirclesView: View {
    @Environment(AppModel.self) private var model
    @State private var creating = false
    var body: some View {
        Page(title: model.text(.circles), subtitle: nil) {
            EmptyView()
        } accessory: {
            PaceBadge(text: model.circleText(.localDemo), systemImage: "iphone")
        } content: {
            Button { creating = true } label: { Label(model.circleText(.newCircle), systemImage: "person.2.badge.plus") }
                .buttonStyle(PaceButtonStyle(kind: .secondary)).accessibilityIdentifier("addCircle")
            PaceCard {
                Label(model.circleText(.demoNote), systemImage: "info.circle").font(.footnote).foregroundStyle(PaceColor.textSecondary)
            }
            PaceSectionTitle(model.circleText(.yourCircles))
            if model.state.circles.isEmpty {
                PaceCard { PaceEmptyState(systemImage: "person.2", title: model.text(.circles), message: model.circleText(.noCircles)) }
            }
            ForEach(model.state.circles) { circle in
                NavigationLink(value: AppRoute.circle(circle.id)) { CircleRowCard(circle: circle) }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("circle.open." + circle.title)
            }
            let active = model.state.circleChallenges.filter { $0.status == .active }
            if !active.isEmpty {
                PaceSectionTitle(model.circleText(.challenge))
                ForEach(active) { challenge in
                    NavigationLink(value: AppRoute.challenge(challenge.id)) { ChallengeRowCard(challenge: challenge) }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("circles.challenge." + challenge.title)
                }
            }
        }
        .sheet(isPresented: $creating) { CircleEditor() }
    }
}

/// Group row like the Pace Social group list: avatar, name, status line, counter.
struct CircleRowCard: View {
    @Environment(AppModel.self) private var model
    let circle: LocalCircle
    var body: some View {
        let challenges = model.state.circleChallenges.filter { $0.circleID == circle.id && $0.status == .active }
        PaceCard(padding: PaceSpacing.s) {
            HStack(spacing: PaceSpacing.s) {
                PaceAvatar(name: circle.title, seed: circle.id)
                VStack(alignment: .leading, spacing: 2) {
                    Text(circle.title).font(.headline).foregroundStyle(PaceColor.textPrimary)
                    Text(model.circleMembersLine(circle) + " · " + model.number(Double(challenges.count)) + " " + model.circleText(.challenge))
                        .font(.footnote).foregroundStyle(PaceColor.textSecondary)
                }
                Spacer(minLength: PaceSpacing.xs)
                PaceChevron()
            }
        }
    }
}

struct ChallengeRowCard: View {
    @Environment(AppModel.self) private var model
    let challenge: CircleChallenge
    var body: some View {
        let progress = model.state.circleProgress(challenge)
        PaceCard {
            VStack(alignment: .leading, spacing: PaceSpacing.xs) {
                HStack(alignment: .firstTextBaseline) {
                    Text(challenge.title).font(.headline).foregroundStyle(PaceColor.textPrimary)
                    Spacer()
                    Text(model.number(progress.total) + " / " + model.number(challenge.target)).font(.subheadline.weight(.semibold)).monospacedDigit()
                }
                PaceProgressBar(progress: progress.total / challenge.target)
                Text(model.dayLabel(challenge.startDay) + " – " + model.dayLabel(challenge.endDay)).font(.footnote).foregroundStyle(PaceColor.textSecondary)
            }
        }
    }
}

/// Initial avatar with a stable pastel derived from the ID.
struct PaceAvatar: View {
    let name: String
    let seed: UUID
    var size: CGFloat = 44
    var body: some View {
        let hues: [Double] = [0.38, 0.45, 0.52, 0.58, 0.12, 0.08, 0.72, 0.9]
        let index = Int(seed.uuid.0) % hues.count
        Text(String(name.trimmingCharacters(in: .whitespaces).prefix(1)).uppercased())
            .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
            .foregroundStyle(Color(hue: hues[index], saturation: 0.55, brightness: 0.35))
            .frame(width: size, height: size)
            .background(Color(hue: hues[index], saturation: 0.25, brightness: 0.95), in: Circle())
            .overlay { Circle().strokeBorder(PaceColor.border, lineWidth: 1) }
            .accessibilityHidden(true)
    }
}

struct CircleDetail: View {
    @Environment(AppModel.self) private var model
    let circleID: UUID
    @State private var editing = false
    @State private var adding = false
    private var circle: LocalCircle? { model.state.circles.first { $0.id == circleID } }
    var body: some View {
        PaceSubpage(title: circle?.title ?? "Pace Circles", subtitle: circle.map { model.circleMembersLine($0) }) {
            if circle != nil {
                Button { editing = true } label: { PaceSquareIcon(systemImage: "gearshape") }
                    .buttonStyle(.plain).accessibilityLabel(model.text(.edit)).accessibilityIdentifier("editCircle")
            }
        } content: {
            if let circle {
                PaceBadge(text: model.circleText(.localDemo), systemImage: "iphone")
                if !circle.notes.isEmpty { PaceCard { Text(circle.notes) } }
                PaceSectionTitle(title: model.circleText(.challenge)) {
                    Button { adding = true } label: { Label(model.circleText(.newChallenge), systemImage: "plus") }
                        .buttonStyle(PaceLinkButtonStyle()).accessibilityIdentifier("addChallenge")
                }
                let challenges = model.state.circleChallenges.filter { $0.circleID == circleID }
                if challenges.isEmpty { PaceCard { Text(model.circleText(.noChallenges)).foregroundStyle(PaceColor.textSecondary) } }
                ForEach(challenges) { challenge in
                    NavigationLink(value: AppRoute.challenge(challenge.id)) { ChallengeRowCard(challenge: challenge) }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("challenge.open." + challenge.title)
                }
                PaceSectionTitle(model.circleText(.members))
                PaceCard {
                    VStack(alignment: .leading, spacing: PaceSpacing.s) {
                        HStack(spacing: PaceSpacing.s) {
                            PaceAvatar(name: model.circleText(.own), seed: circleID, size: 36)
                            Text(model.circleText(.own)).font(.subheadline.weight(.semibold))
                            Spacer()
                        }
                        ForEach(circle.members) { member in
                            HStack(spacing: PaceSpacing.s) {
                                PaceAvatar(name: member.name, seed: member.id, size: 36)
                                Text(member.name).font(.subheadline)
                                PaceBadge(text: model.circleText(.demo))
                                Spacer()
                                Text(model.circleText(member.role == .member ? .member : .moderator)).font(.footnote).foregroundStyle(PaceColor.textSecondary)
                            }
                        }
                        Text(model.circleText(.demoNote)).font(.footnote).foregroundStyle(PaceColor.textSecondary)
                    }
                }
            }
        }
        .sheet(isPresented: $editing) { if let circle { CircleEditor(existing: circle) } }
        .sheet(isPresented: $adding) { ChallengeEditor(circleID: circleID) }
    }
}

struct CircleEditor: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var circle: LocalCircle
    init(existing: LocalCircle? = nil) { _circle = State(initialValue: existing ?? LocalCircle(title: "")) }
    var body: some View {
        NavigationStack {
            Form {
                SaveErrorBanner()
                Text(model.circleText(.demoNote)).font(.footnote)
                TextField(model.text(.name), text: $circle.title).accessibilityIdentifier("circleTitle")
                TextField(model.routineText(.notes), text: $circle.notes, axis: .vertical)
                Toggle(model.circleText(.includeDemo), isOn: $circle.includeDemoContributions)
                Section(model.circleText(.members)) {
                    ForEach($circle.members) { $member in
                        VStack(alignment: .leading, spacing: 8) {
                            TextField(model.circleText(.demo), text: $member.name).accessibilityIdentifier("demoMemberName")
                            Picker(model.circleText(.member), selection: $member.role) {
                                Text(model.circleText(.member)).tag(DemoMemberRole.member)
                                Text(model.circleText(.moderator)).tag(DemoMemberRole.moderator)
                            }
                            Button(model.circleText(.remove), role: .destructive) { circle.members.removeAll { $0.id == member.id } }
                                .disabled(model.state.circleContributions.contains { $0.demoMemberID == member.id })
                        }
                    }
                    Button(model.circleText(.addMember)) { circle.members.append(CircleDemoMember(name: "")) }.accessibilityIdentifier("addDemoMember")
                    Text(model.circleText(.memberInUse)).font(.footnote)
                }
            }
            .navigationTitle(model.circleText(.localDemo)).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(model.text(.cancel)) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(model.text(.save)) { if model.saveCircle(circle) { dismiss() } }
                        .disabled(circle.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || circle.members.contains { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
                        .accessibilityIdentifier("saveCircle")
                }
            }
        }
    }
}
struct CircleChallengeDetail: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let challengeID: UUID
    @State private var editing = false
    @State private var recording = false
    @State private var deleting = false
    private var challenge: CircleChallenge? { model.state.circleChallenges.first { $0.id == challengeID } }
    var body: some View {
        PaceSubpage(title: challenge?.title ?? "Pace Circles", subtitle: challenge.map { model.dayLabel($0.startDay) + " – " + model.dayLabel($0.endDay) }) {
            if challenge != nil {
                Button { editing = true } label: { PaceSquareIcon(systemImage: "pencil") }
                    .buttonStyle(.plain).accessibilityLabel(model.text(.edit)).accessibilityIdentifier("editChallenge")
            }
        } content: {
            if let challenge {
                let progress = model.state.circleProgress(challenge)
                PaceBadge(text: model.circleText(.localDemo), systemImage: "iphone")
                PaceCard {
                    VStack(alignment: .leading, spacing: PaceSpacing.s) {
                        HStack(alignment: .center, spacing: PaceSpacing.m) {
                            VStack(alignment: .leading, spacing: PaceSpacing.xxs) {
                                Text(model.circleText(.total)).font(.headline)
                                Text(model.number(progress.total)).font(.system(size: 48, weight: .bold)).monospacedDigit()
                                    .accessibilityIdentifier("circleTotal")
                                Text(model.circleText(.target) + ": " + model.number(challenge.target) + " " + (challenge.kind == .duration ? model.text(.minutes) : challenge.unit))
                                    .font(.subheadline).foregroundStyle(PaceColor.textSecondary)
                            }
                            Spacer(minLength: PaceSpacing.xs)
                            PaceRing(progress: progress.total / challenge.target, diameter: 92, lineWidth: 11, centerText: model.percent(progress.total / challenge.target))
                        }
                        PaceProgressBar(progress: progress.total / challenge.target)
                        HStack(spacing: PaceSpacing.xs) {
                            PaceStatTile(value: model.number(progress.own), label: model.circleText(.own), systemImage: "person")
                            PaceStatTile(value: model.number(progress.demo), label: model.circleText(.simulated), systemImage: "person.2")
                        }
                        if challenge.status == .active && challenge.startDay <= DayKey(date: model.today) {
                            Button(model.circleText(.contribution)) { recording = true }
                                .buttonStyle(PaceButtonStyle()).accessibilityIdentifier("recordCircleContribution")
                        }
                    }
                }
                if !challenge.notes.isEmpty { PaceCard { Text(challenge.notes) } }
                let entries = model.state.circleContributions.filter { $0.challengeID == challengeID }.sorted { $0.day > $1.day }
                if !entries.isEmpty { PaceSectionTitle(model.circleText(.value)) }
                ForEach(entries) { entry in contributionCard(entry, challenge: challenge) }
                let days = Set(entries.map(\.day)).sorted()
                if !days.isEmpty {
                    PaceCard {
                        VStack(alignment: .leading, spacing: PaceSpacing.xs) {
                            Text(model.text(.history)).font(.headline)
                            ForEach(days, id: \.self) { day in
                                HStack {
                                    Text(model.dayLabel(day))
                                    Spacer()
                                    Text(model.number(model.state.circleProgress(challenge, through: day).total)).monospacedDigit()
                                }.font(.footnote).foregroundStyle(PaceColor.textSecondary)
                            }
                        }
                    }
                }
                Text(model.circleText(.consent)).font(.footnote).foregroundStyle(PaceColor.textSecondary)
                VStack(spacing: PaceSpacing.xs) {
                    if challenge.status == .active {
                        Button(model.circleText(.finish)) { model.perform { try $0.closeCircleChallenge(id: challengeID) } }
                            .buttonStyle(PaceButtonStyle(kind: .secondary))
                            .disabled(challenge.startDay > DayKey(date: model.today))
                    }
                    if challenge.status != .archived {
                        Button(model.text(.archive)) { model.perform { try $0.closeCircleChallenge(id: challengeID, archive: true) } }
                            .buttonStyle(PaceButtonStyle(kind: .secondary))
                    }
                    Button(model.circleText(.deleteChallenge), role: .destructive) { deleting = true }
                        .buttonStyle(PaceButtonStyle(kind: .destructive))
                }
            }
        }
        .sheet(isPresented: $editing) { if let challenge { ChallengeEditor(circleID: challenge.circleID, existing: challenge) } }
        .sheet(isPresented: $recording) { if let challenge { CircleContributionEditor(challenge: challenge) } }
        .confirmationDialog(model.circleText(.deleteChallenge), isPresented: $deleting) {
            Button(model.circleText(.deleteChallenge), role: .destructive) { if model.perform({ try $0.deleteCircleChallenge(id: challengeID) }) { dismiss() } }
        } message: { Text(model.circleText(.deleteWarning)) }
    }
    private func contributionCard(_ entry: CircleContribution, challenge: CircleChallenge) -> some View {
        let member = model.state.circles.first { $0.id == challenge.circleID }?.members.first { $0.id == entry.demoMemberID }
        return PaceCard {
            VStack(alignment: .leading, spacing: PaceSpacing.xs) {
                HStack(spacing: PaceSpacing.s) {
                    PaceAvatar(name: member?.name ?? model.circleText(.own), seed: member?.id ?? challenge.circleID, size: 36)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: PaceSpacing.xs) {
                            Text(member?.name ?? model.circleText(.own)).font(.headline)
                            if member != nil { PaceBadge(text: model.circleText(.demo)) }
                        }
                        Text(model.dayLabel(entry.day) + " · " + model.number(model.state.circleContributionValue(entry)))
                            .font(.footnote).foregroundStyle(PaceColor.textSecondary)
                    }
                    Spacer()
                    Label(model.circleText(entry.isShared ? .shared : .privateValue), systemImage: entry.isShared ? "person.2.fill" : "lock")
                        .font(.caption.weight(.semibold)).foregroundStyle(entry.isShared ? PaceColor.accent : PaceColor.textSecondary)
                }
                HStack(spacing: PaceSpacing.xs) {
                    if entry.isShared {
                        Button(model.circleText(.revoke)) { model.perform { try $0.revokeCircleContribution(id: entry.id) } }
                            .buttonStyle(PaceCompactButtonStyle(prominent: false)).accessibilityIdentifier("revokeContribution")
                    }
                    Spacer()
                    Button(model.circleText(.remove), role: .destructive) { model.perform { try $0.deleteCircleContribution(id: entry.id) } }
                        .font(.subheadline).foregroundStyle(PaceColor.danger).frame(minHeight: 44)
                }
            }
        }
    }
}

struct ChallengeEditor: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let circleID: UUID
    let existing: CircleChallenge?
    @State private var title = ""
    @State private var notes = ""
    @State private var start = Date()
    @State private var end = Date()
    @State private var kind = GoalType.duration
    @State private var unit = ""
    @State private var target = "60"
    @State private var initialized = false
    init(circleID: UUID, existing: CircleChallenge? = nil) { self.circleID = circleID; self.existing = existing }
    private var valid: Bool {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, let value = model.parseNumber(target), value > 0,
              value <= 1_000_000_000, DayKey(date: end) >= DayKey(date: start) else { return false }
        return kind == .duration || (kind == .binary ? value == 1 : value.rounded() == value)
    }
    var body: some View {
        NavigationStack {
            Form {
                SaveErrorBanner()
                TextField(model.text(.name), text: $title).accessibilityIdentifier("challengeTitle")
                TextField(model.routineText(.notes), text: $notes, axis: .vertical)
                DatePicker(model.chapterText(.start), selection: $start, displayedComponents: .date).disabled(existing != nil)
                DatePicker(model.chapterText(.end), selection: $end, in: start..., displayedComponents: .date)
                Picker(model.experimentText(.unit), selection: $kind) {
                    ForEach(GoalType.allCases, id: \.self) { Text(model.goalName($0)).tag($0) }
                }.disabled(existing != nil).onChange(of: kind) { _, kind in if kind == .binary { target = "1" } }
                if kind == .count { TextField(model.experimentText(.unit), text: $unit).disabled(existing != nil) }
                TextField(model.circleText(.target), text: $target).keyboardType(.decimalPad).accessibilityIdentifier("challengeTarget")
                Text(model.circleText(.localDemo)).font(.footnote)
            }
            .navigationTitle(model.circleText(.newChallenge)).navigationBarTitleDisplayMode(.inline)
            .onAppear {
                guard !initialized else { return }; initialized = true
                if let existing {
                    title = existing.title; notes = existing.notes; start = model.date(for: existing.startDay); end = model.date(for: existing.endDay)
                    kind = existing.kind; unit = existing.unit; target = model.inputNumber(existing.target)
                } else { end = Calendar.current.date(byAdding: .day, value: 29, to: start) ?? start }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(model.text(.cancel)) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(model.text(.save)) {
                        guard let target = model.parseNumber(target) else { return }
                        var challenge = existing ?? CircleChallenge(circleID: circleID, title: title, startDay: DayKey(date: start), endDay: DayKey(date: end), kind: kind, unit: unit, target: target)
                        challenge.title = title; challenge.notes = notes; challenge.endDay = DayKey(date: end); challenge.target = target
                        if model.saveChallenge(challenge) { dismiss() }
                    }.disabled(!valid).accessibilityIdentifier("saveChallenge")
                }
            }
        }
    }
}

struct CircleContributionEditor: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let challenge: CircleChallenge
    @State private var date = Date()
    @State private var memberID: UUID?
    @State private var completionID: UUID?
    @State private var value = ""
    @State private var shared = false
    @State private var initialized = false
    private var latest: Date { model.date(for: min(DayKey(date: model.today), challenge.endDay)) }
    private var candidates: [HabitCompletion] {
        model.state.completions.filter { $0.goalTypeSnapshot == challenge.kind && $0.day >= challenge.startDay && $0.day <= challenge.endDay && $0.day <= DayKey(date: model.today) }.sorted { $0.day > $1.day }
    }
    private var valid: Bool {
        if completionID != nil { return true }
        guard let number = model.parseNumber(value), number <= 1_000_000_000 else { return false }
        return challenge.kind == .duration || (challenge.kind == .binary ? [0, 1].contains(number) : number.rounded() == number)
    }
    var body: some View {
        NavigationStack {
            Form {
                SaveErrorBanner()
                Picker(model.circleText(.members), selection: $memberID) {
                    Text(model.circleText(.own)).tag(UUID?.none)
                    ForEach(model.state.circles.first(where: { $0.id == challenge.circleID })?.members ?? []) { member in
                        Text(member.name + " · " + model.circleText(.demo)).tag(Optional(member.id))
                    }
                }.onChange(of: memberID) { _, _ in completionID = nil; loadValue() }
                if memberID == nil {
                    Picker(model.circleText(.source), selection: $completionID) {
                        Text(model.circleText(.manual)).tag(UUID?.none)
                        ForEach(candidates) { completion in
                            let title = model.state.habits.first { $0.id == completion.habitID }?.title ?? model.circleText(.habit)
                            Text(title + " · " + model.dayLabel(completion.day) + " · " + model.number(completion.actualValue)).tag(Optional(completion.id))
                        }
                    }.onChange(of: completionID) { _, _ in
                        if let completion = candidates.first(where: { $0.id == completionID }) { date = model.date(for: completion.day) }
                        loadValue()
                    }
                }
                DatePicker(model.experimentText(.days), selection: $date, in: model.date(for: challenge.startDay)...latest, displayedComponents: .date)
                    .disabled(completionID != nil).onChange(of: date) { _, _ in loadValue() }
                if completionID == nil {
                    TextField(challenge.kind == .duration ? model.text(.minutes) : model.circleText(.value), text: $value)
                        .keyboardType(.decimalPad).accessibilityIdentifier("circleContributionValue")
                }
                Toggle(model.circleText(.share), isOn: $shared).accessibilityIdentifier("shareContribution")
                Text(model.circleText(.consent)).font(.footnote)
            }
            .navigationTitle(model.circleText(.contribution)).navigationBarTitleDisplayMode(.inline)
            .onAppear { if !initialized { initialized = true; date = latest; loadValue() } }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(model.text(.cancel)) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(model.text(.save)) {
                        let source: CircleContributionSource
                        if let completionID { source = .habitCompletion(completionID) }
                        else if let number = model.parseNumber(value) { source = .manual(number) }
                        else { return }
                        if model.perform({ try $0.recordCircleContribution(challengeID: challenge.id, day: DayKey(date: date), demoMemberID: memberID, source: source, shared: shared) }) { dismiss() }
                    }.disabled(!valid).accessibilityIdentifier("saveCircleContribution")
                }
            }
        }
    }
    private func loadValue() {
        let entry = model.state.circleContributions.first { entry in
            guard entry.challengeID == challenge.id else { return false }
            switch entry.source {
            case .manual: return completionID == nil && entry.demoMemberID == memberID && entry.day == DayKey(date: date)
            case .habitCompletion(let id): return id == completionID
            }
        }
        value = entry.map { model.inputNumber(model.state.circleContributionValue($0)) } ?? ""
        shared = entry?.isShared ?? false
    }
}
