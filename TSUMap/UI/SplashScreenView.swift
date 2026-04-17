import SwiftUI

struct SplashScreenView: View {
    @Binding var isReady: Bool
    @ObservedObject var placeManager: PlaceManager
    @ObservedObject var locationManager: LocationManager
    var onReady: (() -> Void)?

    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                Text("TSUMap")
                    .font(.system(size: 36, weight: .medium, design: .rounded))
                    .foregroundColor(tsuBlue)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                Spacer()

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: tsuBlue))
            }
            .padding(.bottom, 80)
        }
        .onAppear {
            animateEntrance()
        }
    }

    private var tsuBlue: Color {
        Color(red: 0.156, green: 0.286, blue: 0.455)
    }

    private func animateEntrance() {
        withAnimation(.easeOut(duration: 0.8)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }

        Task {
            await locationManager.checkPermissions()
            while placeManager.isLoading {
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            try? await Task.sleep(nanoseconds: 500_000_000)
            onReady?()
            withAnimation { isReady = true }
        }
    }
}
