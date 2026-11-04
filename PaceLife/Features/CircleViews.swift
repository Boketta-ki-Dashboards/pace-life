import SwiftUI
import PaceLifeCore

struct CirclesView: View {
    @Environment(AppModel.self) private var model
    @State private var creating = false
    @State private var opening: LocalCircle?
    var body: some View {
        Page(title: model.text(.circles), subtitle: model.circleText(.localDemo)) {
            PaceCard { Text(model.circleText(.demoNote)).font(.callout) }
            Button(model.circleText(.newCircle)) { creating = true }.buttonStyle(PaceButtonStyle()).accessibilityIdentifier("addCircle")
            if model.state.circles.isEmpty { Text(model.circleText(.noCircles)) }
            ForEach(model.state.circles) { circle in
                Button { opening = circle } label: {
                    PaceCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(circle.title).font(.title3.bold())
                            Text(circle.notes).font(.callout)
                            Label(model.circleText(.localDemo), systemImage: "iphone").font(.caption)
                        }
                    }
                }.buttonStyle(.plain).accessibilityIdentifier("circle.open." + circle.title)
            }
        }
        .sheet(isPresented: $creating) { CircleEditor() }
        .sheet(item: $opening) { circle in NavigationStack { CircleDetail(circleID: circle.id) } }
    }
}
struct CircleDetail: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let circleID: UUID
    @State private var editing = false
    @State private var adding = false
    private var circle: LocalCircle? { model.state.circles.first { $0.id == circleID } }
    var body: some View {
        List {
            SaveErrorBanner()
            if let circle {
                Section {
                    Text(model.circleText(.demoNote))
                    Text(circle.notes)
                    Button(model.text(.edit)) { editing = true }
                }
                Section(model.circleText(.members)) {
                    ForEach(circle.members) { member in
                        LabeledContent(member.name + " · " + model.circleText(.demo), value: model.circleText(member.role == .member ? .member : .moderator))
                    }
                }
                Section(model.circleText(.challenge)) {
                    Button(model.circleText(.newChallenge)) { adding = true }.accessibilityIdentifier("addChallenge")
                    ForEach(model.state.circleChallenges.filter { $0.circleID == circleID }) { challenge in
                        NavigationLink { CircleChallengeDetail(challengeID: challenge.id) } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(challenge.title).font(.headline)
                                Text(model.pathStatusName(challenge.status == .active ? .active : challenge.status == .completed ? .completed : .archived)).font(.caption)
                                ProgressView(value: min(1, model.state.circleProgress(challenge).total / challenge.target)).tint(PaceColor.accent)
                            }
                        }.accessibilityIdentifier("challenge.open." + challenge.title)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden).background(PaceColor.background)
        .navigationTitle(circle?.title ?? "Pace Circles").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button(model.text(.done)) { dismiss() } } }
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
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SaveErrorBanner()
                if let challenge {
                    let progress = model.state.circleProgress(challenge)
                    Label(model.circleText(.localDemo), systemImage: "iphone").font(.footnote)
                    PaceProgressRing(progress: progress.total / challenge.target, value: model.number(progress.total) + " / " + model.number(challenge.target), label: challenge.kind == .duration ? model.text(.minutes) : challenge.unit)
                    HStack(alignment: .firstTextBaseline) {
                        Text(model.text(.progress))
                        Spacer()
                        Text(model.number(progress.total)).accessibilityIdentifier("circleTotal")
                    }
                    LabeledContent(model.circleText(.own), value: model.number(progress.own))
                    LabeledContent(model.circleText(.simulated), value: model.number(progress.demo))
                    Text(challenge.notes)
                    Text(model.dayLabel(challenge.startDay) + " – " + model.dayLabel(challenge.endDay))
                    if challenge.status == .active && challenge.startDay <= DayKey(date: model.today) {
                        Button(model.circleText(.contribution)) { recording = true }.buttonStyle(PaceButtonStyle()).accessibilityIdentifier("recordCircleContribution")
                    }
                    ForEach(model.state.circleContributions.filter { $0.challengeID == challengeID }.sorted { $0.day > $1.day }) { entry in contributionCard(entry, challenge: challenge) }
                    let days = Set(model.state.circleContributions.filter { $0.challengeID == challengeID }.map(\.day)).sorted()
                    ForEach(days, id: \.self) { day in
                        LabeledContent(model.dayLabel(day), value: model.number(model.state.circleProgress(challenge, through: day).total)).font(.footnote)
                    }
                    Text(model.circleText(.consent)).font(.footnote).foregroundStyle(PaceColor.textSecondary)
                    Button(model.text(.edit)) { editing = true }.buttonStyle(PaceButtonStyle(kind: .secondary))
                    if challenge.status == .active {
                        Button(model.circleText(.finish)) { model.perform { try $0.closeCircleChallenge(id: challengeID) } }
                            .disabled(challenge.startDay > DayKey(date: model.today))
                    }
                    if challenge.status != .archived { Button(model.text(.archive)) { model.perform { try $0.closeCircleChallenge(id: challengeID, archive: true) } } }
                    Button(model.circleText(.deleteChallenge), role: .destructive) { deleting = true }
                }
            }.padding(16)
        }.background(PaceColor.background).navigationTitle(challenge?.title ?? "Pace Circles").navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $editing) { if let challenge { ChallengeEditor(circleID: challenge.circleID, existing: challenge) } }
            .sheet(isPresented: $recording) { if let challenge { CircleContributionEditor(challenge: challenge) } }
            .confirmationDialog(model.circleText(.deleteChallenge), isPresented: $deleting) {
                Button(model.circleText(.deleteChallenge), role: .destructive) { if model.perform({ try $0.deleteCircleChallenge(id: challengeID) }) { dismiss() } }
            } message: { Text(model.circleText(.deleteWarning)) }
    }
    private func contributionCard(_ entry: CircleContribution, challenge: CircleChallenge) -> some View {
        let member = model.state.circles.first { $0.id == challenge.circleID }?.members.first { $0.id == entry.demoMemberID }
        return PaceCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(member.map { $0.name + " · " + model.circleText(.demo) } ?? model.circleText(.own)).font(.headline)
                Text(model.dayLabel(entry.day) + " · " + model.number(model.state.circleContributionValue(entry)))
                Text(model.circleText(entry.isShared ? .shared : .privateValue)).font(.footnote)
                if entry.isShared { Button(model.circleText(.revoke)) { model.perform { try $0.revokeCircleContribution(id: entry.id) } }.accessibilityIdentifier("revokeContribution") }
                Button(model.circleText(.remove), role: .destructive) { model.perform { try $0.deleteCircleContribution(id: entry.id) } }
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
