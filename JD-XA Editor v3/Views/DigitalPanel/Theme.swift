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

// MARK: - Compact layout

private struct CompactLayoutKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// True when cards sit in a narrow column, as in the All Partials view.
    /// Cards then stack their control groups and wrap their chip rows.
    var isCompactLayout: Bool {
        get { self[CompactLayoutKey.self] }
        set { self[CompactLayoutKey.self] = newValue }
    }
}

/// The control groups of a card. Side by side normally; in a compact column
/// they flow left to right and wrap onto a new line when the column runs out
/// of width. Put a `ControlDivider` between groups; a divider where a line
/// wraps is hidden.
struct ControlGroupRow<Content: View>: View {
    var spacing: CGFloat = 16
    @ViewBuilder var content: () -> Content
    @Environment(\.isCompactLayout) private var isCompact

    var body: some View {
        let layout = isCompact
            ? AnyLayout(ControlFlowLayout(spacing: min(spacing, 8), lineSpacing: 10))
            : AnyLayout(HStackLayout(alignment: .top, spacing: spacing))
        layout { content() }
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Marks a `ControlDivider` for `ControlFlowLayout`.
private struct IsControlDivider: LayoutValueKey {
    static let defaultValue = false
}

/// Lays out control groups at their ideal size, left to right, wrapping when
/// the next group doesn't fit. Dividers stretch to the height of their line
/// and are dropped where a line wraps.
struct ControlFlowLayout: Layout {
    var spacing: CGFloat
    var lineSpacing: CGFloat

    private struct Line {
        var items: [Int] = []
        var height: CGFloat = 0
    }

    /// A group's ideal size, or its size squeezed to `width` when it's wider
    /// (a group can then rearrange itself, e.g. with `ViewThatFits`)
    private func size(of subview: LayoutSubview, width: CGFloat) -> CGSize {
        let ideal = subview.sizeThatFits(.unspecified)
        guard ideal.width > width else { return ideal }
        return subview.sizeThatFits(ProposedViewSize(width: width, height: nil))
    }

    private func lines(width: CGFloat, subviews: Subviews) -> [Line] {
        var lines = [Line()]
        var x: CGFloat = 0
        var pendingDivider: Int?

        for index in subviews.indices {
            if subviews[index][IsControlDivider.self] {
                pendingDivider = index
                continue
            }
            let size = size(of: subviews[index], width: width)
            let divider = pendingDivider
            pendingDivider = nil

            if lines[lines.count - 1].items.isEmpty {
                lines[lines.count - 1].items = [index]
                x = size.width
            } else {
                let dividerWidth = divider.map { subviews[$0].sizeThatFits(.unspecified).width + spacing } ?? 0
                if x + dividerWidth + spacing + size.width <= width {
                    if let divider { lines[lines.count - 1].items.append(divider) }
                    lines[lines.count - 1].items.append(index)
                    x += dividerWidth + spacing + size.width
                } else {
                    lines.append(Line(items: [index]))
                    x = size.width
                }
            }
            lines[lines.count - 1].height = max(lines[lines.count - 1].height, size.height)
        }
        return lines
    }

    private func idealWidth(_ subviews: Subviews) -> CGFloat {
        let widths = subviews.map { $0.sizeThatFits(.unspecified).width }
        return widths.reduce(0, +) + spacing * CGFloat(max(widths.count - 1, 0))
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width: CGFloat
        if let proposed = proposal.width, proposed.isFinite {
            width = proposed
        } else {
            width = idealWidth(subviews)
        }
        let lines = lines(width: width, subviews: subviews)
        let height = lines.reduce(0) { $0 + $1.height } + lineSpacing * CGFloat(max(lines.count - 1, 0))
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var placed = Set<Int>()
        var y = bounds.minY
        for line in lines(width: bounds.width, subviews: subviews) {
            var x = bounds.minX
            for index in line.items {
                let isDivider = subviews[index][IsControlDivider.self]
                let size = size(of: subviews[index], width: bounds.width)
                subviews[index].place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(width: size.width, height: isDivider ? line.height : size.height)
                )
                x += size.width + spacing
                placed.insert(index)
            }
            y += line.height + lineSpacing
        }
        // Dividers where a line wrapped: no room, so nothing shows
        for index in subviews.indices where !placed.contains(index) {
            subviews[index].place(at: bounds.origin, proposal: .zero)
        }
    }
}

/// A row of chips. In a compact column it becomes a grid with as many
/// columns as fit at `compactMinCellWidth`, balanced across rows.
struct ChipRow<Content: View>: View {
    var compactMinCellWidth: CGFloat
    @ViewBuilder var content: () -> Content
    @Environment(\.isCompactLayout) private var isCompact

    var body: some View {
        let layout = isCompact
            ? AnyLayout(ChipGridLayout(minCellWidth: compactMinCellWidth))
            : AnyLayout(HStackLayout(spacing: 4))
        layout { content() }
    }
}

/// Equal-width cells, as many to a row as fit at `minCellWidth`, with the
/// cells spread evenly over the rows. The cells of a shorter last row
/// stretch to fill it.
struct ChipGridLayout: Layout {
    var minCellWidth: CGFloat
    var spacing: CGFloat = 4

    private func columns(width: CGFloat, count: Int) -> Int {
        let fit = max(1, Int((width + spacing) / (minCellWidth + spacing)))
        let rowCount = (count + fit - 1) / fit
        return (count + rowCount - 1) / rowCount
    }

    private func rows(width: CGFloat, count: Int) -> [Range<Int>] {
        let columns = columns(width: width, count: count)
        return stride(from: 0, to: count, by: columns).map { $0..<min($0 + columns, count) }
    }

    private func cellWidth(_ width: CGFloat, cells: Int) -> CGFloat {
        (width - spacing * CGFloat(cells - 1)) / CGFloat(cells)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard !subviews.isEmpty else { return .zero }
        let width: CGFloat
        if let proposed = proposal.width, proposed.isFinite {
            width = proposed
        } else {
            // Ideal: one row
            let widest = subviews.map { $0.sizeThatFits(.unspecified).width }.max() ?? 0
            width = max(widest, minCellWidth) * CGFloat(subviews.count) + spacing * CGFloat(subviews.count - 1)
        }
        let rows = rows(width: width, count: subviews.count)
        let height = rows.reduce(CGFloat(0)) { total, row in
            let cell = cellWidth(width, cells: row.count)
            let rowHeight = row.map { subviews[$0].sizeThatFits(ProposedViewSize(width: cell, height: nil)).height }.max() ?? 0
            return total + rowHeight
        } + spacing * CGFloat(rows.count - 1)
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in rows(width: bounds.width, count: subviews.count) {
            let cell = cellWidth(bounds.width, cells: row.count)
            let cellProposal = ProposedViewSize(width: cell, height: nil)
            let rowHeight = row.map { subviews[$0].sizeThatFits(cellProposal).height }.max() ?? 0
            for (column, index) in row.enumerated() {
                subviews[index].place(
                    at: CGPoint(x: bounds.minX + CGFloat(column) * (cell + spacing), y: y),
                    proposal: ProposedViewSize(width: cell, height: rowHeight)
                )
            }
            y += rowHeight + spacing
        }
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
    @Environment(\.isCompactLayout) private var isCompact

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
        VStack(alignment: .leading, spacing: isCompact ? 10 : 14) {
            // The accessory goes under the title when they don't fit on one line
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    titleLabel
                    Spacer(minLength: 8)
                    accessory()
                }
                VStack(alignment: .leading, spacing: 10) {
                    titleLabel
                    accessory()
                }
            }

            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(isCompact ? 12 : ThemeMetrics.padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(ThemeColors.secondaryBackground, in: RoundedRectangle(cornerRadius: ThemeMetrics.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: ThemeMetrics.cornerRadius)
                .strokeBorder(ThemeColors.stroke)
        )
        .environment(\.controlTint, tint)
    }

    private var titleLabel: some View {
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
        }
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
            .layoutValue(key: IsControlDivider.self, value: true)
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
            .minimumScaleFactor(0.85)
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
    /// Narrowest chip in a compact column
    var compactMinCellWidth: CGFloat = 56

    var body: some View {
        ChipRow(compactMinCellWidth: compactMinCellWidth) {
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
