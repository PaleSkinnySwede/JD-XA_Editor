import SwiftUI

// MARK: - Colors

struct ThemeColors {
    /// Window background, behind the section cards
    static let background = Color(red: 0.086, green: 0.090, blue: 0.102)
    /// Section cards
    static let secondaryBackground = Color(red: 0.122, green: 0.126, blue: 0.141)
    /// Controls that sit on a card (chip backgrounds, knob and slider tracks)
    static let raised = Color(red: 0.180, green: 0.184, blue: 0.204)
    /// Hairline borders around cards and chips
    static let stroke = Color.white.opacity(0.07)

    static let accent = Color(red: 0.36, green: 0.60, blue: 1.0)
    static let text = Color.white
    static let secondaryText = Color(white: 0.62)
    static let tertiaryText = Color(white: 0.42)

    static let connected = Color(red: 0.30, green: 0.82, blue: 0.46)
    static let disconnected = Color(red: 0.95, green: 0.62, blue: 0.22)

    // Kept for existing callers
    static let tabSelected = raised
    static let tabUnselected = secondaryBackground
}

/// One accent color per synth section, so you can tell OSC, FILTER, AMP and
/// the LFOs apart at a glance (like the color-coded panel on the hardware).
enum SectionTint {
    static let osc = Color(red: 1.00, green: 0.60, blue: 0.26)
    static let filter = Color(red: 0.27, green: 0.78, blue: 0.95)
    static let amp = Color(red: 0.42, green: 0.86, blue: 0.52)
    static let lfo = Color(red: 0.70, green: 0.55, blue: 1.00)
    static let modLFO = Color(red: 1.00, green: 0.46, blue: 0.70)
}

struct ThemeMetrics {
    static let cornerRadius: CGFloat = 12
    static let chipCornerRadius: CGFloat = 7
    static let padding: CGFloat = 16
    static let spacing: CGFloat = 8
}

// MARK: - Control tint

private struct ControlTintKey: EnvironmentKey {
    static let defaultValue: Color = ThemeColors.accent
}

extension EnvironmentValues {
    /// Accent color for knobs, sliders and chips. `SectionCard` sets it to
    /// the section's color.
    var controlTint: Color {
        get { self[ControlTintKey.self] }
        set { self[ControlTintKey.self] = newValue }
    }
}

// MARK: - Section card

/// A rounded panel with a colored title, one per synth section.
struct SectionCard<Content: View, Accessory: View>: View {
    let title: String
    let systemImage: String
    let tint: Color
    @ViewBuilder var accessory: () -> Accessory
    @ViewBuilder var content: () -> Content

    init(
        _ title: String,
        systemImage: String,
        tint: Color,
        @ViewBuilder accessory: @escaping () -> Accessory = { EmptyView() },
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.tint = tint
        self.accessory = accessory
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(tint)
                    .frame(width: 22, height: 22)
                    .background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 6))
                Text(title.uppercased())
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1.2)
                    .foregroundColor(ThemeColors.text)
                Spacer(minLength: 8)
                accessory()
            }

            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(ThemeMetrics.padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(ThemeColors.secondaryBackground, in: RoundedRectangle(cornerRadius: ThemeMetrics.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: ThemeMetrics.cornerRadius)
                .strokeBorder(ThemeColors.stroke)
        )
        .environment(\.controlTint, tint)
    }
}

/// A small caption above a group of controls inside a card.
struct ControlGroupBox<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    init(_ title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.8)
                .foregroundColor(ThemeColors.tertiaryText)
            content()
        }
    }
}

/// A thin vertical line between groups of controls.
struct ControlDivider: View {
    var body: some View {
        Rectangle()
            .fill(ThemeColors.stroke)
            .frame(width: 1)
            .padding(.vertical, 4)
    }
}

// MARK: - Chips

/// Compact rounded button that fills with the control tint when selected.
struct ChipButtonStyle: ButtonStyle {
    var isSelected: Bool
    var expands = true
    @Environment(\.controlTint) private var tint
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .semibold))
            .lineLimit(1)
            .padding(.horizontal, 8)
            .frame(maxWidth: expands ? .infinity : nil, minHeight: 26)
            .foregroundColor(isSelected ? .black.opacity(0.85) : ThemeColors.text.opacity(0.85))
            .background(
                RoundedRectangle(cornerRadius: ThemeMetrics.chipCornerRadius)
                    .fill(isSelected ? tint : ThemeColors.raised)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ThemeMetrics.chipCornerRadius)
                    .strokeBorder(isSelected ? Color.clear : ThemeColors.stroke)
            )
            .opacity(isEnabled ? (configuration.isPressed ? 0.75 : 1) : 0.35)
            .contentShape(RoundedRectangle(cornerRadius: ThemeMetrics.chipCornerRadius))
            .animation(.easeOut(duration: 0.12), value: isSelected)
    }
}

/// A row of chips where exactly one is selected.
struct ChipPicker<Item: Hashable>: View {
    let items: [Item]
    let selection: Item?
    let label: (Item) -> String
    let onSelect: (Item) -> Void

    var body: some View {
        HStack(spacing: 4) {
            ForEach(items, id: \.self) { item in
                Button(label(item)) { onSelect(item) }
                    .buttonStyle(ChipButtonStyle(isSelected: item == selection))
            }
        }
    }
}

extension ChipPicker {
    /// Chip picker bound directly to a value.
    init(_ items: [Item], selection: Binding<Item>, label: @escaping (Item) -> String) {
        self.items = items
        self.selection = selection.wrappedValue
        self.label = label
        self.onSelect = { selection.wrappedValue = $0 }
    }
}

/// An on/off chip.
struct ChipToggle: View {
    let title: String
    var systemImage: String?
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            if let systemImage {
                Label(title, systemImage: systemImage)
            } else {
                Text(title)
            }
        }
        .buttonStyle(ChipButtonStyle(isSelected: isOn, expands: false))
    }
}

// MARK: - Placeholder

/// Fills a card for a section that isn't built yet.
struct ComingSoonView: View {
    let message: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "hammer")
                .font(.system(size: 18))
                .foregroundColor(ThemeColors.tertiaryText)
            Text(message)
                .font(.callout)
                .foregroundColor(ThemeColors.secondaryText)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(ThemeColors.stroke, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
        )
    }
}

// MARK: - Layout

/// Two cards side by side with equal heights, stacked when there isn't room.
struct AdaptivePair<Leading: View, Trailing: View>: View {
    @ViewBuilder var leading: () -> Leading
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 12) {
                leading()
                trailing()
            }
            .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 12) {
                leading()
                trailing()
            }
        }
    }
}
