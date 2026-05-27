import SwiftUI

/// Submit + Edit action pair at the bottom of `JournalReviewView`.
/// The submit button toggles a `ProgressView` while `isSubmitting`,
/// and both buttons disable while submission is in flight.
///
/// Extracted from `JournalReviewView` so the review body stays
/// composition-focused and the action affordances live behind a
/// single named entry point.
struct JournalReviewActions: View {
  let isSubmitting: Bool
  let onSubmit: () -> Void
  let onEdit: () -> Void

  var body: some View {
    VStack(spacing: 12) {
      Button(action: onSubmit) {
        if isSubmitting {
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle())
        } else {
          Text("Submit Entry")
            .fontWeight(.semibold)
        }
      }
      .disabled(isSubmitting)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 12)
      .background(isSubmitting ? Color.gray : Color.blue)
      .foregroundStyle(.white)
      .cornerRadius(10)

      Button(action: onEdit) {
        Text("Edit")
          .foregroundStyle(.blue)
      }
      .disabled(isSubmitting)
    }
  }
}

#if DEBUG
#Preview("Idle") {
  JournalReviewActions(isSubmitting: false, onSubmit: {}, onEdit: {})
    .padding()
    .background(Color.black)
}

#Preview("Submitting") {
  JournalReviewActions(isSubmitting: true, onSubmit: {}, onEdit: {})
    .padding()
    .background(Color.black)
}
#endif
