import SwiftUI

struct OnboardingView: View {
    let dismiss: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AppTheme.homeBackground.ignoresSafeArea()

                Circle()
                    .fill(AppTheme.accentSoft.opacity(0.16))
                    .frame(width: 260, height: 260)
                    .blur(radius: 20)
                    .offset(x: 120, y: -geometry.size.height * 0.28)

                VStack(alignment: .leading, spacing: 18) {
                    BendedKneeBrandMark(
                        iconSize: 86,
                        titleSize: 32,
                        subtitle: "Skate lower with a cleaner, calmer setup."
                    )

                    OnboardingCard(dismiss: dismiss)
                }
                .padding(.horizontal, 20)
                .padding(.top, max(geometry.safeAreaInsets.top, 20))
                .padding(.bottom, max(geometry.safeAreaInsets.bottom, 20))
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
            title: "Bended Knee coaches depth, not medical angle.",
            body: "The app uses your phone in one front pocket to estimate how much extra bend you have beyond upright standing.",
            bullets: [
                "The live number is bend from standing.",
                "Haptics warn you when you rise too tall.",
                "You keep the app open while skating."
            ],
            symbol: "figure.skating"
        ),
        OnboardingPage(
            eyebrow: "PLACEMENT",
            title: "Pick one front pocket and keep it consistent.",
            body: "Use the same front pocket every session. Keep the phone top-up and the screen facing your thigh.",
            bullets: [
                "Left or right pocket both work.",
                "If the phone shifts, recalibrate.",
                "Setup will ask for pocket side and target."
            ],
            symbol: "iphone.gen3"
        ),
        OnboardingPage(
            eyebrow: "WHEN YOU SKATE",
            title: "Calibrate upright, then let the haptics coach you.",
            body: "Stand still for a 3 second baseline capture. During your session, faster haptics mean you need more knee bend.",
            bullets: [
                "Target means extra bend beyond standing.",
                "If the phone leaves your pocket, coaching pauses.",
                "You can feel a sample pulse in setup first."
            ],
            symbol: "waveform.path.ecg"
        )
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("\(pageIndex + 1) / \(pages.count)")
                    .font(AppType.label(12, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Color.white.opacity(0.78)))

                Spacer()

                Text(pageIndex == pages.count - 1 ? "Ready for setup" : "Next")
                    .font(AppType.label(13, weight: .bold))
                    .foregroundStyle(AppTheme.inkMuted)
            }

            HStack(spacing: 8) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, _ in
                    Capsule()
                        .fill(index == pageIndex ? AppTheme.deepForest : Color.white.opacity(0.66))
                        .frame(width: index == pageIndex ? 26 : 10, height: 10)
                }
            }

            ScrollView(showsIndicators: false) {
                let page = pages[pageIndex]

                VStack(alignment: .leading, spacing: 18) {
                    Text(page.eyebrow)
                        .font(AppType.label(12, weight: .bold))
                        .foregroundStyle(AppTheme.accent)
                        .tracking(1.2)

                    HStack(alignment: .top, spacing: 16) {
                        Image(systemName: page.symbol)
                            .font(.system(size: 30, weight: .medium))
                            .frame(width: 58, height: 58)
                            .background(Circle().fill(AppTheme.accentSoft.opacity(0.45)))
                            .foregroundStyle(AppTheme.ink)

                        VStack(alignment: .leading, spacing: 10) {
                            Text(page.title)
                                .font(AppType.title(26))
                                .foregroundStyle(AppTheme.ink)

                            Text(page.body)
                                .font(AppType.label(16, weight: .medium))
                                .foregroundStyle(AppTheme.inkMuted)
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(page.bullets, id: \.self) { bullet in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(AppTheme.slate)
                                    .padding(.top, 2)

                                Text(bullet)
                                    .font(AppType.label(15, weight: .medium))
                                    .foregroundStyle(AppTheme.ink)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 6)
            }

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
                    Text(pageIndex == pages.count - 1 ? "Start Setup" : "Next")
                        .font(AppType.label(16, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(pageIndex == pages.count - 1 ? AppTheme.deepForest : AppTheme.accent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .accessibilityIdentifier(pageIndex == pages.count - 1 ? "continueButton" : "onboardingNextButton")
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppTheme.panelStrong)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(AppTheme.line, lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.08), radius: 24, x: 0, y: 10)
    }
}

private struct OnboardingPage {
    let eyebrow: String
    let title: String
    let body: String
    let bullets: [String]
    let symbol: String
}
