import SwiftUI

struct LeaveReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    let providerId: String
    let bookingId: String
    let providerName: String

    @State private var rating: Int = 0
    @State private var reviewText = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var submitted = false

    var body: some View {
        VStack(spacing: 24) {
            // Header
            Text(appState.isSv ? "Lämna omdöme" : "Leave a review")
                .font(.title3.bold())
                .padding(.top, 8)

            Text(providerName)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Star rating
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .font(.title2)
                        .foregroundStyle(star <= rating ? .yellow : .secondary)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                rating = star
                            }
                            HapticManager.light()
                        }
                }
            }
            .padding(.vertical, 4)

            // Built by Christos Ferlachidis & Daniel Hedenberg

            // Review text
            TextEditor(text: $reviewText)
                .frame(minHeight: 120)
                .padding(8)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    Group {
                        if reviewText.isEmpty {
                            Text(appState.isSv ? "Beskriv din upplevelse..." : "Describe your experience...")
                                .foregroundStyle(.tertiary)
                                .padding(.leading, 12)
                                .padding(.top, 16)
                        }
                    },
                    alignment: .topLeading
                )
                .padding(.horizontal)

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Spacer()

            // Submit button
            Button {
                Task { await submitReview() }
            } label: {
                Group {
                    if isSubmitting {
                        ProgressView().tint(.white)
                    } else {
                        Text(appState.isSv ? "Skicka omdöme" : "Submit review")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(rating > 0 ? BokviaTheme.accent : BokviaTheme.accent.opacity(0.4))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(rating == 0 || isSubmitting)
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .padding(.horizontal)
        .navigationTitle(appState.isSv ? "Omdöme" : "Review")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(appState.isSv ? "Avbryt" : "Cancel") { dismiss() }
            }
        }
        .overlay {
            if submitted {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)
                    Text(appState.isSv ? "Tack for ditt omdöme!" : "Thank you for your review!")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ultraThinMaterial)
            }
        }
        .onChange(of: submitted) { _, done in
            if done {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }
        }
    }

    private func submitReview() async {
        isSubmitting = true
        errorMessage = nil

        struct ReviewRequest: Encodable {
            let providerId: String
            let rating: Int
            let text: String?
            let bookingId: String
        }

        let body = ReviewRequest(
            providerId: providerId,
            rating: rating,
            text: reviewText.isEmpty ? nil : reviewText,
            bookingId: bookingId
        )

        do {
            _ = try await APIClient.shared.post("/api/reviews", body: body, as: Review.self)
            HapticManager.success()
            submitted = true
        } catch {
            errorMessage = appState.isSv
                ? "Kunde inte skicka omdömet. Försök igen."
                : "Failed to submit review. Please try again."
            HapticManager.error()
        }
        isSubmitting = false
    }
}
