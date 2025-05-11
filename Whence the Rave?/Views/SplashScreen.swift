import SwiftUI

struct SplashScreen: View {
    @Binding var isFirstLaunch: Bool
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.8
    @State private var rotation: Double = -10
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            Image("SplashLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 250, height: 250)
                .opacity(opacity)
                .scaleEffect(scale)
                .rotationEffect(.degrees(rotation))
        }
        .onAppear {
            // Ensure animations complete in sequence
            withAnimation(.easeIn(duration: 0.8)) {
                opacity = 1
                scale = 1.1
                rotation = 0
            }
            
            // After fade in, hold for a moment
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                // Then fade out with a different animation
                withAnimation(.easeOut(duration: 1.2)) {
                    opacity = 0
                    scale = 1.2
                }
                
                // Only dismiss after all animations are complete
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                    isFirstLaunch = false
                }
            }
        }
        // Prevent any touch interaction during animation
        .allowsHitTesting(false)
    }
}

#Preview {
    SplashScreen(isFirstLaunch: .constant(true))
} 