import SwiftUI

struct ProviderScheduleView: View {
    @Environment(AppState.self) private var appState
    @State private var schedules: [WorkModeSchedule] = []
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var providerId: String?
    @State private var overlapWarning: String?

    // Editable state per work mode
    @State private var editableSchedules: [String: [EditableDay]] = [:]

    private let workModeOrder = ["AT_SALON", "AT_PROVIDER", "HOME_VISIT"]
    private let svDays = ["", "Måndag", "Tisdag", "Onsdag", "Torsdag", "Fredag", "Lördag", "Söndag"]
    private let enDays = ["", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .padding(.horizontal)
                        }

                        if let success = successMessage {
                            Text(success)
                                .font(.caption)
                                .foregroundStyle(.green)
                                .padding(.horizontal)
                        }

                        if let warning = overlapWarning {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                Text(warning)
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .padding(.horizontal)
                        }

                        // Built by Christos Ferlachidis & Daniel Hedenberg

                        ForEach(workModeOrder, id: \.self) { mode in
                            if let days = editableSchedules[mode] {
                                scheduleSection(mode: mode, days: days)
                            }
                        }

                        saveButton
                    }
                    .padding(.vertical)
                }
            }
        }
        .navigationTitle(appState.isSv ? "Schema" : "Schedule")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadSchedule() }
    }

    // MARK: - Schedule Section

    private func scheduleSection(mode: String, days: [EditableDay]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(workModeLabel(mode))
                .font(.headline)
                .padding(.horizontal)

            ForEach(days.indices, id: \.self) { index in
                let day = days[index]
                VStack(spacing: 8) {
                    HStack {
                        Toggle(dayName(day.dayOfWeek), isOn: binding(for: mode, index: index, keyPath: \.isActive))
                            .font(.subheadline.weight(.medium))
                            .accessibilityLabel("\(dayName(day.dayOfWeek)): \(day.isActive ? (appState.isSv ? "aktiv" : "active") : (appState.isSv ? "inaktiv" : "inactive"))")
                    }

                    if day.isActive {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(appState.isSv ? "Start" : "Start")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                TextField("09:00", text: binding(for: mode, index: index, keyPath: \.startTime))
                                    .font(.subheadline)
                                    .padding(8)
                                    .background(Color(.secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .accessibilityLabel(appState.isSv ? "Starttid \(dayName(day.dayOfWeek))" : "Start time \(dayName(day.dayOfWeek))")
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(appState.isSv ? "Slut" : "End")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                TextField("17:00", text: binding(for: mode, index: index, keyPath: \.endTime))
                                    .font(.subheadline)
                                    .padding(8)
                                    .background(Color(.secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .accessibilityLabel(appState.isSv ? "Sluttid \(dayName(day.dayOfWeek))" : "End time \(dayName(day.dayOfWeek))")
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)
            }
        }
    }

    private func binding(for mode: String, index: Int, keyPath: WritableKeyPath<EditableDay, Bool>) -> Binding<Bool> {
        Binding(
            get: { editableSchedules[mode]?[index][keyPath: keyPath] ?? false },
            set: { newValue in
                editableSchedules[mode]?[index][keyPath: keyPath] = newValue
                checkOverlaps()
            }
        )
    }

    private func binding(for mode: String, index: Int, keyPath: WritableKeyPath<EditableDay, String>) -> Binding<String> {
        Binding(
            get: { editableSchedules[mode]?[index][keyPath: keyPath] ?? "" },
            set: { newValue in
                editableSchedules[mode]?[index][keyPath: keyPath] = newValue
                checkOverlaps()
            }
        )
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            Task { await saveAllSchedules() }
        } label: {
            HStack {
                if isSaving {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                }
                Text(appState.isSv ? "Spara schema" : "Save schedule")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(BokviaTheme.accent)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(isSaving)
        .padding(.horizontal)
        .accessibilityLabel(appState.isSv ? "Spara schema" : "Save schedule")
    }

    // MARK: - Overlap Detection

    private func checkOverlaps() {
        overlapWarning = nil
        for dayNum in 1...7 {
            var activeRanges: [(mode: String, start: String, end: String)] = []
            for mode in workModeOrder {
                if let days = editableSchedules[mode],
                   let day = days.first(where: { $0.dayOfWeek == dayNum }),
                   day.isActive {
                    activeRanges.append((mode, day.startTime, day.endTime))
                }
            }
            for i in 0..<activeRanges.count {
                for j in (i + 1)..<activeRanges.count {
                    let a = activeRanges[i]
                    let b = activeRanges[j]
                    if a.start < b.end && b.start < a.end {
                        let dayStr = dayName(dayNum)
                        overlapWarning = appState.isSv
                            ? "Överlappning på \(dayStr): \(workModeLabel(a.mode)) och \(workModeLabel(b.mode))"
                            : "Overlap on \(dayStr): \(workModeLabel(a.mode)) and \(workModeLabel(b.mode))"
                        return
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func workModeLabel(_ mode: String) -> String {
        switch mode {
        case "AT_SALON": return appState.isSv ? "På salong" : "At salon"
        case "AT_PROVIDER": return appState.isSv ? "Hemma / Egen lokal" : "Home / Own premises"
        case "HOME_VISIT": return appState.isSv ? "Hembesök" : "Home visit"
        default: return mode
        }
    }

    private func dayName(_ day: Int) -> String {
        guard day >= 1 && day <= 7 else { return "" }
        return appState.isSv ? svDays[day] : enDays[day]
    }

    // MARK: - Data Loading

    private func loadSchedule() async {
        isLoading = true
        errorMessage = nil
        do {
            let me = try await APIClient.shared.get("/api/providers/me", as: ProviderMeResponse.self)
            providerId = me.id
            let result = try await APIClient.shared.get("/api/slots/schedule/\(me.id)", as: ScheduleResponse.self)
            schedules = result.schedules

            // Initialize editable state
            for mode in workModeOrder {
                let existing = schedules.first(where: { $0.workMode == mode })
                var days: [EditableDay] = []
                for dayNum in 1...7 {
                    if let day = existing?.days.first(where: { $0.dayOfWeek == dayNum }) {
                        days.append(EditableDay(dayOfWeek: dayNum, isActive: day.isActive, startTime: day.startTime ?? "09:00", endTime: day.endTime ?? "17:00"))
                    } else {
                        days.append(EditableDay(dayOfWeek: dayNum, isActive: false, startTime: "09:00", endTime: "17:00"))
                    }
                }
                editableSchedules[mode] = days
            }
        } catch {
            errorMessage = appState.isSv ? "Kunde inte ladda schemat." : "Failed to load schedule."
        }
        isLoading = false
    }

    private func saveAllSchedules() async {
        guard let pid = providerId else { return }
        isSaving = true
        errorMessage = nil
        successMessage = nil

        do {
            for mode in workModeOrder {
                guard let days = editableSchedules[mode] else { continue }
                let body = SaveScheduleBody(
                    workMode: mode,
                    days: days.map { day in
                        SaveScheduleDayBody(
                            dayOfWeek: day.dayOfWeek,
                            isActive: day.isActive,
                            startTime: day.isActive ? day.startTime : nil,
                            endTime: day.isActive ? day.endTime : nil
                        )
                    }
                )
                _ = try await APIClient.shared.post("/api/slots/schedule/\(pid)", body: body, as: ScheduleResponse.self)
            }
            HapticManager.success()
            successMessage = appState.isSv ? "Schemat har sparats!" : "Schedule saved!"
        } catch {
            errorMessage = appState.isSv ? "Kunde inte spara schemat." : "Failed to save schedule."
            HapticManager.error()
        }
        isSaving = false
    }
}

struct EditableDay {
    let dayOfWeek: Int
    var isActive: Bool
    var startTime: String
    var endTime: String
}
