import SwiftUI

/// A small picture of an ADSR envelope. Times and level are 0...127.
struct EnvelopeGraph: View {
    let attack: Double
    let decay: Double
    let sustain: Double
    let release: Double

    @Environment(\.controlTint) private var tint

    var body: some View {
        let shape = EnvelopeShape(attack: attack, decay: decay, sustain: sustain, release: release)
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(ThemeColors.raised.opacity(0.5))
            shape
                .fill(LinearGradient(
                    colors: [tint.opacity(0.28), tint.opacity(0.04)],
                    startPoint: .top, endPoint: .bottom
                ))
                .padding(.horizontal, 4)
                .padding(.vertical, 3)
            shape
                .stroke(tint, style: StrokeStyle(lineWidth: 1.5, lineJoin: .round))
                .padding(.horizontal, 4)
                .padding(.vertical, 3)
        }
        .animation(.easeOut(duration: 0.08), value: [attack, decay, sustain, release])
        .accessibilityElement()
        .accessibilityLabel("Envelope: attack \(Int(attack)), decay \(Int(decay)), sustain \(Int(sustain)), release \(Int(release))")
    }
}

/// The envelope graph above Attack, Decay, Sustain and Release sliders.
/// Used by the Filter and Amp cards.
struct ADSRControls: View {
    @Binding var attack: Double
    @Binding var decay: Double
    @Binding var sustain: Double
    @Binding var release: Double
    /// Double-click reset values, in A, D, S, R order
    var defaults: (attack: Double, decay: Double, sustain: Double, release: Double) = (0, 64, 64, 0)

    private static let sliderWidth: CGFloat = 46
    private static let spacing: CGFloat = 4

    var body: some View {
        VStack(spacing: 6) {
            EnvelopeGraph(attack: attack, decay: decay, sustain: sustain, release: release)
                .frame(width: 4 * Self.sliderWidth + 3 * Self.spacing, height: 30)

            HStack(alignment: .top, spacing: Self.spacing) {
                VerticalSlider(title: "Attack", value: $attack, range: 0...127, height: 80, defaultValue: defaults.attack)
                VerticalSlider(title: "Decay", value: $decay, range: 0...127, height: 80, defaultValue: defaults.decay)
                VerticalSlider(title: "Sustain", value: $sustain, range: 0...127, height: 80, defaultValue: defaults.sustain)
                VerticalSlider(title: "Release", value: $release, range: 0...127, height: 80, defaultValue: defaults.release)
            }
        }
    }
}

/// Closed ADSR outline along the bottom edge, so it can be filled or stroked.
struct EnvelopeShape: Shape {
    var attack: Double
    var decay: Double
    var sustain: Double
    var release: Double

    var animatableData: AnimatablePair<AnimatablePair<Double, Double>, AnimatablePair<Double, Double>> {
        get { AnimatablePair(AnimatablePair(attack, decay), AnimatablePair(sustain, release)) }
        set {
            attack = newValue.first.first
            decay = newValue.first.second
            sustain = newValue.second.first
            release = newValue.second.second
        }
    }

    func path(in rect: CGRect) -> Path {
        // Each time segment gets up to 28% of the width; sustain holds for the rest
        let segment = rect.width * 0.28
        let a = segment * attack / 127
        let d = segment * decay / 127
        let r = segment * release / 127
        let hold = rect.width - a - d - r
        let sustainY = rect.maxY - rect.height * sustain / 127

        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + a, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + a + d, y: sustainY))
        path.addLine(to: CGPoint(x: rect.minX + a + d + hold, y: sustainY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        return path
    }
}

#Preview {
    EnvelopeGraph(attack: 20, decay: 64, sustain: 80, release: 50)
        .frame(width: 200, height: 40)
        .padding()
        .background(ThemeColors.secondaryBackground)
}
