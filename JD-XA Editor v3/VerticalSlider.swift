import SwiftUI

struct VerticalSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let height: CGFloat
    let defaultValue: Double
    var values: [Double]? = nil // For discrete values like gain settings
    
    @Environment(\.controlTint) private var tint
    @Environment(\.isCompactLayout) private var isCompact
    @State private var isDragging = false
    @State private var dragStart: CGFloat = 0
    @State private var startValue: Double = 0
    @State private var lastValue: Double = 0
    
    init(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double = 1,
        height: CGFloat = 110,
        defaultValue: Double? = nil,
        values: [Double]? = nil
    ) {
        self.title = title
        self._value = value
        self.range = range
        self.step = step
        self.height = height
        self.values = values
        self.defaultValue = defaultValue ?? (values?.first ?? (range.upperBound + range.lowerBound) / 2)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(formattedValue)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(ThemeColors.text)
                .opacity(isDragging ? 0.7 : 1.0)
                .scaleEffect(isDragging ? 1.2 : 1.0)
                .animation(.easeOut(duration: 0.2), value: isDragging)
                .frame(height: 20)
            
            // Slider track
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    let handleSize: CGFloat = 12
                    // Handle center travels between these, so it never leaves the track
                    let travel = max(geometry.size.height - handleSize, 0)
                    let handleY = handleSize / 2 + travel * normalizedValue
                    let originY = handleSize / 2 + travel * fillOrigin
                    let fillTint = isDragging ? tint.opacity(0.8) : tint

                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(ThemeColors.raised)
                        .frame(width: 8)

                    // Value track, from the bottom (or from zero for ± ranges)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(fillTint)
                        .frame(width: 8, height: abs(handleY - originY))
                        .offset(y: -min(handleY, originY))

                    // Zero mark for ± ranges
                    if isBipolar {
                        Rectangle()
                            .fill(ThemeColors.secondaryText.opacity(0.6))
                            .frame(width: 14, height: 1)
                            .offset(y: -originY)
                    }

                    // Handle
                    Circle()
                        .fill(fillTint)
                        .frame(width: handleSize, height: handleSize)
                        .overlay(
                            Circle()
                                .stroke(ThemeColors.secondaryBackground, lineWidth: 2)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                        .offset(y: -(handleY - handleSize / 2))

                    // Touch target (invisible wider area)
                    Color.clear
                        .frame(width: 30)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { gesture in
                                    if !isDragging {
                                        isDragging = true
                                        dragStart = gesture.location.y
                                        startValue = value
                                        lastValue = value
                                    }
                                    
                                    let isShiftPressed = NSEvent.modifierFlags.contains(.shift)
                                    let sensitivity: Double = isShiftPressed ? 0.25 : 1.0
                                    
                                    let delta = dragStart - gesture.location.y
                                    let valueRange = range.upperBound - range.lowerBound
                                    let newValue = startValue + Double(delta / geometry.size.height) * valueRange * sensitivity
                                    
                                    if let discreteValues = values {
                                        // Find closest discrete value
                                        value = discreteValues.min(by: { abs($0 - newValue) < abs($1 - newValue) }) ?? discreteValues[0]
                                    } else {
                                        // Snap to step
                                        let steppedValue = round(newValue / step) * step
                                        value = max(range.lowerBound, min(range.upperBound, steppedValue))
                                    }
                                    
                                    lastValue = value
                                }
                                .onEnded { _ in
                                    isDragging = false
                                }
                        )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            // Shorter in a compact column, to save vertical space
            .frame(height: isCompact ? (height * 0.7).rounded() : height)
            
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(ThemeColors.secondaryText)
                // Shrink rather than wrap or cut off in a compact column
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(width: isCompact ? 36 : 46)
        .gesture(
            TapGesture(count: 2)
                .onEnded {
                    value = defaultValue
                }
        )
        .help("Drag to adjust value. Shift+drag for fine control. Double-click to reset to \(Int(defaultValue)).")
    }
    
    /// Ranges like -63...63 fill from zero instead of from the bottom.
    private var isBipolar: Bool {
        values == nil && range.lowerBound < 0 && range.upperBound > 0
    }

    /// Where the fill starts, 0 (bottom) to 1 (top)
    private var fillOrigin: Double {
        isBipolar ? (0 - range.lowerBound) / (range.upperBound - range.lowerBound) : 0
    }

    private var normalizedValue: Double {
        (value - range.lowerBound) / (range.upperBound - range.lowerBound)
    }
    
    private var formattedValue: String {
        if values != nil {
            // For gain values, show + sign for positive values
            return value >= 0 ? "+\(Int(value))" : "\(Int(value))"
        }
        if isBipolar && value > 0 { return "+\(Int(value))" }
        return "\(Int(value))"
    }
}

#Preview {
    HStack(spacing: 20) {
        VerticalSlider(
            title: "PWM",
            value: .constant(64),
            range: 0...127,
            defaultValue: 0
        )
        
        VerticalSlider(
            title: "Gain",
            value: .constant(0),
            range: -6...12,
            defaultValue: 0,
            values: [-6, 0, 6, 12]
        )
    }
    .padding()
    .background(ThemeColors.background)
}
