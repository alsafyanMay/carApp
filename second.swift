import SwiftUI

// Compatibility for existing references; both pages now share one component.
struct coontentView: View {
    @AppStorage("hasCompletedOnboarding.v1") private var completed = false
    var body: some View {
        Group {
            if completed { ContentView() }
            else { AcademyOnboarding(initialPage: 1) { completed = true } }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .background(CarVisualStyle.background.ignoresSafeArea())
    }
}

#Preview("Second onboarding — Arabic") { coontentView() }
