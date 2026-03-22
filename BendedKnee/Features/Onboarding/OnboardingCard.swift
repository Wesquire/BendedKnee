import SwiftUI

struct OnboardingView: View {
    let dismiss: () -> Void

    var body: some View {
        GeometryReader { geometry in
            let horizontalPadding = min(max(geometry.size.width * 0.05, 14), 24)
            let verticalSpacing = min(max(geometry.size.height * 0.016, 8), 16)

            ZStack {
                PosterBackdrop(style: .home).ignoresSafeArea()

                VStack(spacing: verticalSpacing) {
                    DropBrandMark(
                        iconSize: min(max(geometry.size.width * 0.18, 72), 94),
                        titleSize: min(max(geometry.size.width * 0.08, 26), 32),
                        subtitle: "Left pocket coaching with poster-grade attitude."
                    )
                    .padding(.top, geometry.safeAreaInsets.top + 4)

                    OnboardingCard(dismiss: dismiss)
                        .frame(maxHeight: .infinity)
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, max(geometry.safeAreaInsets.bottom, 14))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
    }
}

struct OnboardingCard: View {
    let dismiss: () -> Void
    @State private var pageIndex = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            eyebrow: "WHAT IT DOES",
            title: "Drop coaches depth, not medical angle.",
            body: "Drop uses your phone in your left front pocket to estimate how much extra bend you have beyond upright standing.",
            bullets: [
                "The live number is bend from standing.",
                "Haptics and pulse audio warn you when you rise too tall.",
                "The app must stay open while you skate."
            ],
            symbol: "figure.skating"
        ),
        OnboardingPage(
            eyebrow: "PLACEMENT",
            title: "Drop is built for the left front pocket.",
            body: "Use your left front pocket every session. Keep the phone top-up and the screen facing your thigh.",
            bullets: [
                "Left pocket is the supported position.",
                "If the phone shifts, recalibrate.",
                "Choose your target bend on the next screen."
            ],
            symbol: "iphone.gen3"
        ),
        OnboardingPage(
            eyebrow: "WHEN YOU SKATE",
            title: "Calibrate upright, then let the audio and haptics coach you.",
            body: "Stand still for a 7-second calibration. During your session, faster pulse patterns mean you need more knee bend.",
            bullets: [
                "Target means extra bend beyond standing.",
                "If the phone leaves your pocket, coaching pauses.",
                "Locking or leaving the app pauses coaching."
            ],
            symbol: "waveform.path.ecg"
        )
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Page indicator
            HStack {
                Text("\(pageIndex + 1) / \(pages.count)")
                    .font(AppType.label(12, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Color.white.opacity(0.78)))

                Spacer()
            }
            .padding(.bottom, 10)

            // Progress dots
            HStack(spacing: 8) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, _ in
                    Capsule()
                        .fill(index == pageIndex ? AppTheme.deepForest : Color.white.opacity(0.66))
                        .frame(width: index == pageIndex ? 26 : 10, height: 10)
                }
            }
            .padding(.bottom, 16)

            // Scrollable content area — takes all remaining space
            ScrollView(showsIndicators: false) {
                let page = pages[pageIndex]

                VStack(alignment: .leading, spacing: 16) {
                    Text(page.eyebrow)
                        .font(AppType.label(12, weight: .bold))
                        .foregroundStyle(AppTheme.accent)
                        .tracking(1.2)

                    VStack(alignment: .leading, spacing: 10) {
                        Image(systemName: page.symbol)
                            .font(.system(size: 28, weight: .medium))
                            .frame(width: 52, height: 52)
                            .background(Circle().fill(AppTheme.accentSoft.opacity(0.45)))
                            .foregroundStyle(AppTheme.ink)

                        Text(page.title)
                            .font(AppType.title(24))
                            .foregroundStyle(AppTheme.ink)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(page.body)
                            .font(AppType.label(15, weight: .medium))
                            .foregroundStyle(AppTheme.inkMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(page.bullets, id: \.self) { bullet in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(AppTheme.slate)
                                    .padding(.top, 2)

                                Text(bullet)
                                    .font(AppType.label(14, weight: .medium))
                                    .foregroundStyle(AppTheme.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }

                    if pageIndex == pages.count - 1 {
                        Label("Important: keep the app open and in the foreground while skating.", systemImage: "hand.raised.fill")
                            .font(AppType.label(13, weight: .bold))
                            .foregroundStyle(AppTheme.danger)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(AppTheme.danger.opacity(0.10))
                            )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 8)
            }
            .frame(maxHeight: .infinity, alignment: .top)

            // Navigation buttons — always pinned at bottom
            HStack(spacing: 12) {
                if pageIndex > 0 {
                    Button(action: { pageIndex -= 1 }) {
                        Text("Back")
                            .font(AppType.label(16, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.82))
                            .foregroundStyle(AppTheme.ink)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .accessibilityIdentifier("onboardingBackButton")
                }

                Button(action: {
                    if pageIndex == pages.count - 1 {
                        dismiss()
                    } else {
                        pageIndex += 1
                    }
                }) {
                    Text(pageIndex == pages.count - 1 ? "Get Started" : "Next")
                        .font(AppType.label(16, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(pageIndex == pages.count - 1 ? AppTheme.deepForest : AppTheme.accent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .accessibilityIdentifier(pageIndex == pages.count - 1 ? "continueButton" : "onboardingNextButton")
            }
            .padding(.top, 14)
        }
        .padding(22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppTheme.panelStrong)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.76), lineWidth: 2)
                )
        )
        .shadow(color: AppTheme.deepInk.opacity(0.18), radius: 24, x: 0, y: 12)
    }
}

private struct OnboardingPage {
    let eyebrow: String
    let title: String
    let body: String
    let bullets: [String]
    let symbol: String
}
