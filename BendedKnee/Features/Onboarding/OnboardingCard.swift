import SwiftUI

struct OnboardingView: View {
    let dismiss: () -> Void

    var body: some View {
        ZStack {
            AppTheme.homeBackground.ignoresSafeArea()

            Circle()
                .fill(AppTheme.accentSoft.opacity(0.30))
                .frame(width: 320, height: 320)
                .blur(radius: 16)
                .offset(x: 150, y: -280)

            Circle()
                .fill(AppTheme.mist.opacity(0.42))
                .frame(width: 260, height: 260)
                .blur(radius: 16)
                .offset(x: -140, y: 320)

            VStack(alignment: .leading, spacing: 18) {
                Text("Get Ready To Skate")
                    .font(AppType.label(13, weight: .bold))
                    .foregroundStyle(AppTheme.accent)
                    .tracking(1.5)

                Text("Learn the setup once, then calibrate and skate.")
                    .font(AppType.title(34))
                    .foregroundStyle(AppTheme.ink)

                OnboardingCard(dismiss: dismiss)
            }
            .padding(20)
        }
    }
}

struct OnboardingCard: View {
    let dismiss: () -> Void
    @State private var pageIndex = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            eyebrow: "FIRST SESSION",
            title: "What Bended Knee Measures",
            body: "This app coaches how much extra bend you get from your standing posture. It is a skating posture coach, not a medical knee-angle tool.",
            bullets: [
                "The phone sits in either front pocket.",
                "The number means extra bend beyond upright standing.",
                "Quiet haptics start only when you are too upright."
            ],
            symbol: "figure.skating"
        ),
        OnboardingPage(
            eyebrow: "PHONE PLACEMENT",
            title: "Set The Phone Once",
            body: "Use the same front pocket you plan to skate with. Keep the phone top-up and the screen facing your thigh.",
            bullets: [
                "Either front pocket works.",
                "Do not rotate the phone sideways.",
                "If the phone shifts, recalibrate before skating again."
            ],
            symbol: "iphone.gen3"
        ),
        OnboardingPage(
            eyebrow: "CALIBRATE",
            title: "Stand Still For Three Seconds",
            body: "Tap calibrate while standing upright. The app waits three seconds and locks your standing baseline only if the pocket signal is steady enough.",
            bullets: [
                "Target = extra bend beyond standing.",
                "Start the session only after calibration locks.",
                "Keep the app open during skating so tracking stays active."
            ],
            symbol: "timer"
        ),
        OnboardingPage(
            eyebrow: "SESSION RULES",
            title: "What Happens While You Skate",
            body: "If you rise too upright, the haptics get more urgent. If the phone leaves your pocket, haptics pause and resume when the phone returns.",
            bullets: [
                "Large live number = bend from standing.",
                "No history is stored in this version.",
                "Use setup review anytime before a session."
            ],
            symbol: "waveform.path.ecg"
        )
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("\(pageIndex + 1) / \(pages.count)")
                    .font(AppType.label(12, weight: .bold))
                    .foregroundStyle(AppTheme.mutedInk)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Color.white.opacity(0.65)))
            }

            TabView(selection: $pageIndex) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    VStack(alignment: .leading, spacing: 18) {
                        Text(page.eyebrow)
                            .font(AppType.label(12, weight: .bold))
                            .foregroundStyle(AppTheme.accent)
                            .tracking(1.2)

                        HStack(alignment: .top, spacing: 18) {
                            Image(systemName: page.symbol)
                                .font(.system(size: 34, weight: .medium))
                                .frame(width: 62, height: 62)
                                .background(Circle().fill(AppTheme.accentSoft.opacity(0.55)))
                                .foregroundStyle(AppTheme.ink)

                            VStack(alignment: .leading, spacing: 10) {
                                Text(page.title)
                                    .font(AppType.title(28))
                                    .foregroundStyle(AppTheme.ink)

                                Text(page.body)
                                    .font(AppType.label(16, weight: .medium))
                                    .foregroundStyle(AppTheme.mutedInk)
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
                    .tag(index)
                    .padding(.top, 4)
                }
            }
            .frame(height: 330)
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .interactive))

            HStack(spacing: 12) {
                if pageIndex > 0 {
                    Button(action: { pageIndex -= 1 }) {
                        Text("Back")
                            .font(AppType.label(16, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.58))
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
                        .background(pageIndex == pages.count - 1 ? AppTheme.slate : AppTheme.accent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .accessibilityIdentifier(pageIndex == pages.count - 1 ? "continueButton" : "onboardingNextButton")
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppTheme.panelStrong)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(AppTheme.line.opacity(0.8), lineWidth: 1)
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
