import SwiftUI

struct WelcomeBackView: View {
    let dismiss: () -> Void

    var body: some View {
        GeometryReader { geometry in
            let contentWidth = min(geometry.size.width - 24, 560)
            let titleSize = min(max(geometry.size.width * 0.12, 34), 52)

            ZStack {
                PosterBackdrop(style: .home)
                    .ignoresSafeArea()

                VStack(spacing: 18) {
                    HStack {
                        Spacer()
                        Button(action: dismiss) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundStyle(AppTheme.deepInk)
                        }
                        .accessibilityIdentifier("dismissWelcomeBackButton")
                    }

                    Spacer()

                    DropBrandMark(
                        iconSize: min(max(geometry.size.width * 0.24, 96), 132),
                        titleSize: titleSize,
                        subtitle: "Welcome back to the rink."
                    )

                    VStack(spacing: 12) {
                        Text("Welcome Back")
                            .font(AppType.posterTitle(min(max(geometry.size.width * 0.095, 30), 44)))
                            .foregroundStyle(AppTheme.deepInk)
                            .textCase(.uppercase)
                            .multilineTextAlignment(.center)

                        Text("You are one tap away from your setup, calibration, and live coaching.")
                            .font(AppType.label(16, weight: .bold))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(AppTheme.deepInk.opacity(0.84))
                    }

                    Button(action: dismiss) {
                        Text("Hit The Floor")
                            .font(AppType.label(18, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.deepInk)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }
                    .accessibilityIdentifier("welcomeBackContinueButton")

                    Spacer()
                }
                .frame(maxWidth: contentWidth)
                .padding(.horizontal, 12)
                .padding(.top, max(geometry.safeAreaInsets.top, 12) + 6)
                .padding(.bottom, max(geometry.safeAreaInsets.bottom, 16) + 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
