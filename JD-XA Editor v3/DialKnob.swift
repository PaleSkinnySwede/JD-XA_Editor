import SwiftUI

struct DialKnob: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let size: CGFloat
    let defaultValue: Double
    let isBidirectional: Bool
    let displayValues: [String]?
    
    @Environment(\.controlTint) private var tint
    @State private var isDragging = false
    @State private var dragStart: Double = 0
    @State private var lastValue: Double = 0
    @GestureState private var isDetectingLongPress = false
    
    init(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double = 1,
        size: CGFloat = 52,
        defaultValue: Double? = nil,
        isBidirectional: Bool = true,
        displayValues: [String]? = nil
    ) {
        self.title = title
        self._value = value
        self.range = range
        self.step = step
        self.size = size
        self.defaultValue = defaultValue ?? (range.upperBound + range.lowerBound) / 2
        self.isBidirectional = isBidirectional
        self.displayValues = displayValues
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(ThemeColors.secondaryText)
            
            ZStack {
                // Background circle
                Circle()
                    .stroke(ThemeColors.raised, lineWidth: 4)
                    .frame(width: size, height: size)

                // Knob face
                Circle()
                    .fill(ThemeColors.raised.opacity(0.55))
                    .frame(width: size - 12, height: size - 12)
                
                // Value arc
                if isBidirectional {
                    // Bidirectional arc (existing logic)
                    if abs(value - defaultValue) > 0.01 {
                        if value > defaultValue {
                            Circle()
                                .trim(from: 0.5, to: 0.5 + (normalizedValue * 0.416))
                                .stroke(isDragging ? tint.opacity(0.8) : tint,
                                       style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .frame(width: size, height: size)
                                .rotationEffect(.degrees(90))
                        } else {
                            Circle()
                                .trim(from: 0.5 - (normalizedValue * 0.416), to: 0.5)
                                .stroke(isDragging ? tint.opacity(0.8) : tint,
                                       style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .frame(width: size, height: size)
                                .rotationEffect(.degrees(90))
                        }
                    }
                } else {
                    // Unidirectional arc (new logic)
                    Circle()
                        .trim(from: 0, to: normalizedValue * 250 / 360)
                        .stroke(isDragging ? tint.opacity(0.8) : tint,
                               style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: size, height: size)
                        .rotationEffect(.degrees(145)) // Start at the handle's minimum (-125° from 12 o'clock)
                }
                
                // Handle
                Circle()
                    .fill(isDragging ? tint.opacity(0.8) : tint)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(ThemeColors.secondaryBackground, lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    .offset(y: -size/2)
                    .rotationEffect(.degrees(getHandleRotation()))
                
                // Value label
                Text(formattedValue)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(ThemeColors.text)
                    .opacity(isDragging ? 0.7 : 1.0)
                    .scaleEffect(isDragging ? 1.2 : 1.0)
                    .animation(.easeOut(duration: 0.2), value: isDragging)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let isShiftPressed = NSEvent.modifierFlags.contains(.shift)
                        if !isDragging {
                            isDragging = true
                            dragStart = Double(gesture.location.y)
                            lastValue = value
                        }
                        
                        let sensitivity: Double = isShiftPressed ? 0.25 : 1.0
                        let delta = Double(dragStart - gesture.location.y) * sensitivity
                        let valueRange = range.upperBound - range.lowerBound
                        let newValue = lastValue + (delta / 100.0) * valueRange
                        
                        // Snap to step
                        let steppedValue = round(newValue / step) * step
                        value = max(range.lowerBound, min(range.upperBound, steppedValue))
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
            .gesture(
                TapGesture(count: 2)
                    .onEnded {
                        value = defaultValue
                    }
            )
            .help("Drag to adjust value. Shift+drag for fine control. Double-click to reset to \(Int(defaultValue)).")
        }
        .frame(width: max(size, 60), height: size + 22)
    }
    
    private func getHandleRotation() -> Double {
        if isBidirectional {
            return value > defaultValue ? (150 * normalizedValue) : -(150 * normalizedValue)
        } else {
            // Map 0-127 to -125 to +125 degrees (7 o'clock to 5 o'clock)
            return -125 + (250 * normalizedValue)
        }
    }
    
    private var normalizedValue: Double {
        if isBidirectional {
            // Existing bidirectional logic
            let maxRange = value >= defaultValue ? range.upperBound : abs(range.lowerBound)
            return abs(value - defaultValue) / abs(maxRange - defaultValue)
        } else {
            // Simple 0-1 normalization for unidirectional
            return (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        }
    }
    
    private var formattedValue: String {
        if let displayValues = displayValues {
            let index = Int(value - range.lowerBound)
            return index >= 0 && index < displayValues.count ? displayValues[index] : "\(Int(value))"
        } else if isBidirectional {
            return value >= 0 ? "+\(Int(value))" : "\(Int(value))"
        } else {
            return "\(Int(value))"
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        // Bidirectional knob (default)
        DialKnob(
            title: "Pitch",
            value: .constant(0),
            range: -24...24,
            defaultValue: 0
        )
        
        // Unidirectional knob
        DialKnob(
            title: "Level",
            value: .constant(64),
            range: 0...127,
            defaultValue: 0,
            isBidirectional: false
        )
    }
    .padding()
    .background(ThemeColors.background)
}
