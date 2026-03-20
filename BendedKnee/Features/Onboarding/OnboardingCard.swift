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

            VStack(alignment: .leading, spacing: 14) {
                Text("FIRST RUN")
                    .font(AppType.label(13, weight: .bold))
                    .foregroundStyle(AppTheme.accent)
                    .tracking(1.5)

                Text("Set the phone once, calibrate upright, then let the app coach your bend while you skate.")
                    .font(AppType.title(30))
                    .foregroundStyle(AppTheme.ink)

                Text("This version works with one iPhone in one front pocket while the app stays open during your session.")
                    .font(AppType.label(15, weight: .semibold))
                    .foregroundStyle(AppTheme.inkMuted)

                Spacer(minLength: 0)

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
            title: "What The App Coaches",
            body: "Bended Knee watches how far your pocket and thigh tilt forward from your normal standing posture. It is a skating coach, not a medical knee-angle tool.",
            bullets: [
                "The live number is bend from standing.",
                "Quiet haptics start when you come up too tall.",
                "No session history is saved in this version."
            ],
            symbol: "figure.skating"
        ),
        OnboardingPage(
            eyebrow: "PHONE PLACEMENT",
            title: "Pick One Front Pocket",
            body: "Use the same front pocket you plan to skate with. Keep the phone top-up and the screen facing your thigh every time.",
            bullets: [
                "Left or right pocket both work.",
                "Do not rotate the phone sideways.",
                "If the phone shifts, recalibrate before skating again."
            ],
            symbol: "iphone.gen3"
        ),
        OnboardingPage(
            eyebrow: "CALIBRATE",
            title: "Stand Still For Three Seconds",
            body: "Tap calibrate while standing upright. The app waits three seconds, checks for a steady signal, and then locks your standing baseline.",
            bullets: [
                "Target = extra bend beyond standing.",
                "Start only after the baseline locks.",
                "If calibration is noisy, the app asks you to try again.",
                "Do not background the app while skating."
            ],
            symbol: "timer"
        ),
        OnboardingPage(
            eyebrow: "SESSION RULES",
            title: "What Happens While You Skate",
            body: "Keep the app open. If you rise too upright, haptics get more urgent. If the phone leaves your pocket, coaching pauses until it goes back in.",
            bullets: [
                "Below Target means bend more.",
                "On Target means hold that depth.",
                "Phone Removed means coaching is paused.",
                "Feel a sample pulse in Setup before you skate."
            ],
            symbol: "waveform.path.ecg"
        )
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("\(pageIndex + 1) / \(pages.count)")
                    .font(AppType.label(12, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Color.white.opacity(0.78)))

                Spacer()

                Text(pageIndex == pages.count - 1 ? "Next: setup" : "Swipe or tap next")
                    .font(AppType.label(13, weight: .bold))
                    .foregroundStyle(AppTheme.inkMuted)
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
                    .tag(index)
                    .padding(.top, 4)
                }
            }
            .frame(height: 312)
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .interactive))

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
