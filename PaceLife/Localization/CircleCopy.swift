import PaceLifeCore

enum CircleCopy {
    case total, target, value, localDemo, demoNote, newCircle, noCircles, members, addMember, demo, member, moderator, includeDemo, challenge, newChallenge, own, simulated, contribution, share, privateValue, shared, revoke, remove, source, manual, habit, consent, finish, deleteChallenge, deleteWarning, memberInUse
    func text(_ language: AppLanguage) -> String {
        let v: (String, String, String)
        switch self {
        case .total: v = ("Gemeinsamer Fortschritt", "Shared progress", "Общий прогресс")
        case .target: v = ("Gruppenziel", "Group target", "Общая цель")
        case .value: v = ("Beitrag", "Contribution", "Вклад")
        case .localDemo: v = ("Lokaler Testmodus", "Local test mode", "Локальный тестовый режим")
        case .demoNote: v = ("Keine Online-Gruppe. Demo-Mitglieder und ihre Beiträge werden nur von dir auf diesem Gerät angelegt. Es gibt keine Synchronisierung.", "No online group. You create demo members and their contributions on this device only. There is no synchronization.", "Это не онлайн-группа. Демо-участников и их вклад создаёшь ты на этом устройстве. Синхронизации нет.")
        case .newCircle: v = ("Neuer Circle", "New circle", "Новый круг")
        case .noCircles: v = ("Erstelle einen lokalen Circle und probiere gemeinsame Ziele aus.", "Create a local circle and try shared goals.", "Создай локальный круг и попробуй общие цели.")
        case .members: v = ("Demo-Mitglieder", "Demo members", "Демо-участники")
        case .addMember: v = ("Demo-Mitglied hinzufügen", "Add demo member", "Добавить демо-участника")
        case .demo: v = ("Demo", "Demo", "Демо")
        case .member: v = ("Mitglied", "Member", "Участник")
        case .moderator: v = ("Moderator", "Moderator", "Модератор")
        case .includeDemo: v = ("Simulierte Beiträge mitzählen", "Include simulated contributions", "Учитывать имитируемый вклад")
        case .challenge: v = ("Challenges", "Challenges", "Испытания")
        case .newChallenge: v = ("Neue Challenge", "New challenge", "Новое испытание")
        case .own: v = ("Mein Beitrag", "My contribution", "Мой вклад")
        case .simulated: v = ("Simulierter Beitrag", "Simulated contribution", "Имитируемый вклад")
        case .contribution: v = ("Beitrag erfassen", "Record contribution", "Записать вклад")
        case .share: v = ("Für dieses lokale Gruppenziel freigeben", "Share with this local group goal", "Разрешить для этой локальной цели")
        case .privateValue: v = ("Privat · nicht mitgezählt", "Private · not counted", "Личное · не учитывается")
        case .shared: v = ("Freigegeben", "Shared", "Разрешено")
        case .revoke: v = ("Freigabe widerrufen", "Revoke sharing", "Отозвать разрешение")
        case .remove: v = ("Entfernen", "Remove", "Удалить")
        case .source: v = ("Quelle", "Source", "Источник")
        case .manual: v = ("Zusätzlicher manueller Tageswert", "Additional manual daily value", "Дополнительное значение за день")
        case .habit: v = ("Ausgewählter Habit-Eintrag", "Selected habit entry", "Выбранная запись привычки")
        case .consent: v = ("Nur der ausgewählte Wert wird mitgezählt. Bei einem verknüpften Habit-Eintrag gilt die Freigabe auch für spätere Korrekturen dieses Eintrags. Widerruf bleibt jederzeit möglich. Dieselbe Arbeit nicht zusätzlich manuell erfassen. Keine Chapter-Texte, Fotos oder anderen privaten Daten werden geteilt.", "Only the selected value is counted. For a linked habit entry, sharing also covers later corrections of that entry. You can revoke at any time. Do not also record the same work manually. No chapter text, photos or other private data is shared.", "Учитывается только выбранное значение. Для связанной записи привычки разрешение также относится к её последующим исправлениям. Его можно отозвать в любой момент. Не записывай ту же работу вручную повторно. Тексты глав, фотографии и другие личные данные не передаются.")
        case .finish: v = ("Challenge abschließen", "Complete challenge", "Завершить испытание")
        case .deleteChallenge: v = ("Challenge löschen", "Delete challenge", "Удалить испытание")
        case .deleteWarning: v = ("Challenge und lokale Beiträge werden gelöscht. Private Habit-Einträge bleiben erhalten.", "The challenge and local contributions will be deleted. Private habit entries are preserved.", "Испытание и локальный вклад будут удалены. Личные записи привычек сохранятся.")
        case .memberInUse: v = ("Mitglieder mit Beiträgen bleiben im Verlauf erhalten.", "Members with contributions are kept in history.", "Участники с записями вклада сохраняются в истории.")
        }
        switch language { case .de: return v.0; case .en: return v.1; case .ru: return v.2 }
    }
}
extension AppModel {
    func circleText(_ key: CircleCopy) -> String { key.text(state.settings.language) }
    func saveCircle(_ circle: LocalCircle) -> Bool { perform { try $0.saveCircle(circle) } }
    func saveChallenge(_ challenge: CircleChallenge) -> Bool { perform { try $0.saveCircleChallenge(challenge) } }
}
