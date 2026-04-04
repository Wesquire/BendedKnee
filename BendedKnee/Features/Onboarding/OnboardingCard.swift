import SwiftUI

struct OnboardingView: View {
    let dismiss: () -> Void
    @State private var pageIndex = 0
    @GestureState private var dragOffset: CGFloat = 0

    private let pageCount = 3

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                PosterBackdrop(style: .home).ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    // Illustration
                    Group {
                        switch pageIndex {
                        case 0: pocketIllustration(size: geometry.size)
                        case 1: placementIllustration(size: geometry.size)
                        default: pulseIllustration(size: geometry.size)
                        }
                    }
                    .frame(height: geometry.size.height * 0.38)
                    .offset(x: dragOffset)

                    Spacer().frame(height: geometry.size.height * 0.04)

                    // Single sentence
                    Text(pageSentence)
                        .font(.system(size: min(26, geometry.size.width * 0.065), weight: .black, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(AppTheme.deepInk)
                        .padding(.horizontal, 32)
                        .offset(x: dragOffset * 0.6)
                        .accessibilityIdentifier("onboardingSentence")

                    Spacer()

                    // Page dots
                    HStack(spacing: 8) {
                        ForEach(0..<pageCount, id: \.self) { i in
                            Capsule()
                                .fill(i == pageIndex ? AppTheme.deepInk : AppTheme.deepInk.opacity(0.25))
                                .frame(width: i == pageIndex ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: pageIndex)
                        }
                    }

                    Spacer().frame(height: 20)

                    // Navigation
                    if pageIndex == pageCount - 1 {
                        Button(action: dismiss) {
                            Text("Get Started")
                                .font(.system(size: 20, weight: .black, design: .rounded))
                                .tracking(0.5)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .fill(AppTheme.posterGold)
                                        .shadow(color: AppTheme.posterGold.opacity(0.40), radius: 12, x: 0, y: 6)
                                )
                                .foregroundStyle(AppTheme.deepInk)
                        }
                        .padding(.horizontal, 40)
                        .accessibilityIdentifier("continueButton")
                    } else {
                        Button(action: { withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { pageIndex += 1 } }) {
                            Text("Next")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .fill(AppTheme.posterCoral)
                                )
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 40)
                        .accessibilityIdentifier("onboardingNextButton")
                    }

                    if pageIndex > 0 {
                        Button(action: { withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { pageIndex -= 1 } }) {
                            Text("Back")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.deepInk.opacity(0.55))
                        }
                        .padding(.top, 10)
                        .accessibilityIdentifier("onboardingBackButton")
                    }

                    Spacer()
                        .frame(height: max(geometry.safeAreaInsets.bottom, 16) + 8)
                }
            }
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation.width
                    }
                    .onEnded { value in
                        let threshold: CGFloat = 50
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            if value.translation.width < -threshold && pageIndex < pageCount - 1 {
                                pageIndex += 1
                            } else if value.translation.width > threshold && pageIndex > 0 {
                                pageIndex -= 1
                            }
                        }
                    }
            )
        }
    }

    private var pageSentence: String {
        switch pageIndex {
        case 0: return "Pick your pocket.\nDrop does the rest."
        case 1: return "Drop measures how deep you bend."
        default: return "Faster pulses mean:\nbend more."
        }
    }

    // MARK: - Illustrations

    private func pocketIllustration(size: CGSize) -> some View {
        let s = min(size.width * 0.5, 200.0)
        return ZStack {
            // Pants pocket shape
            RoundedRectangle(cornerRadius: s * 0.12, style: .continuous)
                .fill(AppTheme.deepInk.opacity(0.08))
                .frame(width: s * 1.1, height: s * 1.4)

            // Pocket opening
            UnevenRoundedRectangle(
                topLeadingRadius: s * 0.08,
                bottomLeadingRadius: s * 0.15,
                bottomTrailingRadius: s * 0.15,
                topTrailingRadius: s * 0.08
            )
            .stroke(AppTheme.deepInk.opacity(0.20), lineWidth: 2)
            .frame(width: s * 0.7, height: s * 0.9)
            .offset(y: s * 0.08)

            // Phone sliding into pocket
            RoundedRectangle(cornerRadius: s * 0.06, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.posterCoral, AppTheme.posterGold],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: s * 0.35, height: s * 0.65)
                .overlay(
                    RoundedRectangle(cornerRadius: s * 0.06, style: .continuous)
                        .stroke(Color.white.opacity(0.40), lineWidth: 1.5)
                )
                .shadow(color: AppTheme.posterCoral.opacity(0.30), radius: 12, x: 0, y: 6)
                .offset(y: -s * 0.15)

            // Arrow pointing down
            Image(systemName: "arrow.down")
                .font(.system(size: s * 0.15, weight: .bold))
                .foregroundStyle(AppTheme.deepInk.opacity(0.35))
                .offset(y: s * 0.55)
        }
    }

    private func placementIllustration(size: CGSize) -> some View {
        let s = min(size.width * 0.5, 200.0)
        return ZStack {
            // Leg silhouette (simplified bent shape)
            LegShape()
                .fill(AppTheme.deepInk.opacity(0.10))
                .frame(width: s * 1.2, height: s * 1.4)

            // Angle arc
            ArcShape(progress: 0.65)
                .stroke(AppTheme.neonGold, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: s * 0.6, height: s * 0.6)
                .shadow(color: AppTheme.neonGold.opacity(0.40), radius: 6)
                .offset(x: -s * 0.05, y: -s * 0.08)

            // Angle number
            Text("18°")
                .font(.system(size: s * 0.22, weight: .black, design: .rounded))
                .foregroundStyle(AppTheme.posterCoral)
                .offset(x: s * 0.25, y: -s * 0.20)
        }
    }

    private func pulseIllustration(size: CGSize) -> some View {
        let s = min(size.width * 0.5, 200.0)
        return ZStack {
            // Phone in pocket (small)
            RoundedRectangle(cornerRadius: s * 0.05, style: .continuous)
                .fill(AppTheme.deepInk.opacity(0.12))
                .frame(width: s * 0.3, height: s * 0.55)

            // Pulse rings emanating
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(AppTheme.posterCoral.opacity(0.30 - Double(i) * 0.08), lineWidth: 2.5)
                    .frame(width: s * (0.5 + CGFloat(i) * 0.35), height: s * (0.5 + CGFloat(i) * 0.35))
            }

            // Vibration lines
            ForEach(0..<3, id: \.self) { i in
                Capsule()
                    .fill(AppTheme.posterGold.opacity(0.50 - Double(i) * 0.12))
                    .frame(width: 3, height: s * (0.12 + CGFloat(i) * 0.05))
                    .offset(x: s * (-0.18 + CGFloat(i) * 0.18), y: -s * 0.40)
                    .rotationEffect(.degrees(-15 + Double(i) * 15))
            }
        }
    }
}

// MARK: - Leg Shape

private struct LegShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        // Simplified thigh-to-calf silhouette
        path.move(to: CGPoint(x: w * 0.30, y: h * 0.05))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.45, y: h * 0.45),
            control: CGPoint(x: w * 0.50, y: h * 0.20)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.65, y: h * 0.90),
            control: CGPoint(x: w * 0.35, y: h * 0.65)
        )
        path.addLine(to: CGPoint(x: w * 0.75, y: h * 0.90))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.55, y: h * 0.45),
            control: CGPoint(x: w * 0.55, y: h * 0.65)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.40, y: h * 0.05),
            control: CGPoint(x: w * 0.60, y: h * 0.20)
        )
        path.closeSubpath()
        return path
    }
}
