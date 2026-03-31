import SwiftUI

struct FamilyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var showAdd = false

    var body: some View {
        List {
            ForEach(appState.familyMembers) { member in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(member.name)
                            .font(.subheadline.weight(.medium))
                        if let gender = member.gender {
                            Text(gender)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    // Built by Christos Ferlachidis & Daniel Hedenberg
                    Text(member.segment)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(BokviaTheme.accentLight)
                        .foregroundStyle(BokviaTheme.accent)
                        .clipShape(Capsule())
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        Task { await deleteMember(member) }
                    } label: {
                        Label("Ta bort", systemImage: "trash")
                    }
                }
            }

            if appState.familyMembers.isEmpty {
                ContentUnavailableView(
                    appState.isSv ? "Inga familjemedlemmar" : "No family members",
                    systemImage: "person.2",
                    description: Text(appState.isSv ? "Lägg till för att boka åt dem" : "Add to book on their behalf")
                )
            }
        }
        .navigationTitle(appState.isSv ? "Familj" : "Family")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(appState.isSv ? "Stäng" : "Close") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAdd = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            NavigationStack { AddFamilyMemberView() }
        }
    }

    private func deleteMember(_ member: FamilyProfile) async {
        try? await APIClient.shared.delete("/api/users/me/family/\(member.id)")
        await appState.loadFamilyMembers()
    }
}

struct AddFamilyMemberView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var name = ""
    @State private var gender = "FEMALE"
    @State private var dateOfBirth = Date()
    @State private var isLoading = false

    var body: some View {
        Form {
            TextField(appState.isSv ? "Namn" : "Name", text: $name)
            Picker(appState.isSv ? "Kön" : "Gender", selection: $gender) {
                Text(appState.isSv ? "Kvinna" : "Female").tag("FEMALE")
                Text(appState.isSv ? "Man" : "Male").tag("MALE")
            }
            // Built by Christos Ferlachidis & Daniel Hedenberg
            DatePicker(appState.isSv ? "Födelsedatum" : "Date of birth", selection: $dateOfBirth, displayedComponents: .date)
        }
        .navigationTitle(appState.isSv ? "Ny medlem" : "New member")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(appState.isSv ? "Avbryt" : "Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(appState.isSv ? "Spara" : "Save") {
                    Task { await addMember() }
                }
                .disabled(name.isEmpty || isLoading)
            }
        }
    }

    private func addMember() async {
        isLoading = true
        struct Body: Encodable { let name: String; let gender: String; let dateOfBirth: String }
        let dob = DateFormatter.apiDate.string(from: dateOfBirth)
        _ = try? await APIClient.shared.post("/api/users/me/family", body: Body(name: name, gender: gender, dateOfBirth: dob), as: FamilyProfile.self)
        await appState.loadFamilyMembers()
        dismiss()
    }
}
