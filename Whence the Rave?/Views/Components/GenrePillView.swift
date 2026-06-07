import SwiftUI

struct GenrePillView: View {
    let genre: RAGenre
    let isActive: Bool
    let beatPulse: Bool
    let showsRotationDimming: Bool

    private var scale: CGFloat {
        guard isActive else { return 1.0 }
        return beatPulse ? 1.08 : 1.0
    }

    private var opacity: Double {
        if !showsRotationDimming { return 1.0 }
        return isActive ? 1.0 : 0.5
    }

    var body: some View {
        Text(genre.name)
            .font(.system(.caption, design: .monospaced))
            .fontWeight(.bold)
            .foregroundColor(.black)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: isActive ? [.green, .cyan] : [.green.opacity(0.6), .cyan.opacity(0.6)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .scaleEffect(scale)
            .opacity(opacity)
            .animation(.easeOut(duration: 0.05), value: beatPulse)
    }
}
