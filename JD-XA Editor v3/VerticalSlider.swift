import SwiftUI

struct VerticalSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let height: CGFloat
    let defaultValue: Double
    var values: [Double]? = nil // For discrete values like gain settings
    
    @State private var isDragging = false
    @State private var dragStart: CGFloat = 0
    @State private var startValue: Double = 0
    @State private var lastValue: Double = 0
    
    init(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double = 1,
        height: CGFloat = 150,
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
                .font(.system(.body, design: .monospaced))
                .foregroundColor(ThemeColors.text)
                .opacity(isDragging ? 0.7 : 1.0)
                .scaleEffect(isDragging ? 1.2 : 1.0)
                .animation(.easeOut(duration: 0.2), value: isDragging)
                .frame(height: 20)
            
            // Slider track
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(ThemeColors.secondaryBackground)
                        .frame(width: 8)
                    
                    // Value track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isDragging ? ThemeColors.accent.opacity(0.8) : ThemeColors.accent)
                        .frame(width: 8, height: max(geometry.size.height * normalizedValue, 0))
                    
                    // Handle
                    Group {
                        Circle()
                            .fill(isDragging ? ThemeColors.accent.opacity(0.8) : ThemeColors.accent)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(ThemeColors.background, lineWidth: 2)
                            )
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .offset(y: -geometry.size.height * normalizedValue)
                    
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
            .frame(height: height)
            
            Text(title)
                .font(.caption)
                .foregroundColor(ThemeColors.secondaryText)
        }
        .frame(width: 50)
        .gesture(
            TapGesture(count: 2)
                .onEnded {
                    value = defaultValue
                }
        )
        .help("Drag to adjust value. Shift+drag for fine control. Double-click to reset to \(Int(defaultValue)).")
    }
    
    private var normalizedValue: Double {
        (value - range.lowerBound) / (range.upperBound - range.lowerBound)
    }
    
    private var formattedValue: String {
        if values != nil {
            // For gain values, show + sign for positive values
            return value >= 0 ? "+\(Int(value))" : "\(Int(value))"
        }
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
