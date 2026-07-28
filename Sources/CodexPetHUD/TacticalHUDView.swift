import PetHUDCore
import SwiftUI

struct TacticalHUDView: View {
    let data: HUDPresentationData
    let frameSize: CGSize
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    var body: some View {
        let metrics = TacticalHUDLayoutMetrics(
            frameSize: frameSize
        )
        ZStack {
            tacticalBackground
            VStack(spacing: metrics.rowSpacing) {
                meterRow(
                    label: "HP",
                    trailing: data.hpText,
                    rowHeight: metrics.hpRowHeight
                ) {
                    GeometryReader { geometry in
                        Capsule()
                            .fill(Color.black.opacity(0.72))
                            .overlay(alignment: .leading) {
                                Capsule()
                                    .fill(hpColor)
                                    .frame(
                                        width:
                                            geometry.size.width *
                                            data.hpFraction
                                    )
                            }
                    }
                    .frame(height: metrics.hpBarHeight)
                }
                meterRow(
                    label: "SP",
                    trailing: data.resetText.uppercased(),
                    rowHeight: metrics.flameHeight,
                    accessibilityValue: spAccessibilityValue
                ) {
                    HStack(spacing: metrics.flameSpacing) {
                        ForEach(0..<7, id: \.self) { index in
                            FlameCellView(
                                isLit: index < data.spCellsLit
                            )
                            .frame(
                                width: metrics.flameWidth,
                                height: metrics.flameHeight
                            )
                            .accessibilityHidden(true)
                        }
                    }
                    .frame(height: metrics.flameHeight)
                }
                Text(data.statusLabel)
                    .font(
                        .system(
                            size: metrics.statusFontSize,
                            weight: .black,
                            design: .monospaced
                        )
                    )
                    .tracking(metrics.statusTracking)
                    .foregroundStyle(tacticalAccentColor)
                    .frame(height: metrics.statusRowHeight)
            }
            .padding(.horizontal, metrics.horizontalPadding)
            .padding(.vertical, metrics.verticalPadding)
            .frame(
                width: frameSize.width,
                height: frameSize.height
            )
        }
        .frame(width: frameSize.width, height: frameSize.height)
        .allowsHitTesting(false)
        .animation(
            reduceMotion ? nil : .easeInOut(duration: 0.8),
            value: data.spCellsLit
        )
    }

    private var spAccessibilityValue: String {
        "\(data.spCellsLit) of 7 elapsed; reset in " +
            data.resetText
    }

    private var tacticalAccentColor: Color {
        switch data.band {
        case .low, .critical:
            Color.red
        default:
            Color.cyan
        }
    }

    private func meterRow<Content: View>(
        label: String,
        trailing: String,
        rowHeight: CGFloat,
        accessibilityValue: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        let metrics = TacticalHUDLayoutMetrics(
            frameSize: frameSize
        )
        return HStack(spacing: metrics.columnSpacing) {
            Text(label)
                .frame(width: metrics.labelWidth, alignment: .leading)
                .foregroundStyle(tacticalAccentColor)
            content()
                .frame(maxWidth: .infinity)
            Text(trailing)
                .frame(width: metrics.trailingWidth, alignment: .trailing)
                .foregroundStyle(Color.white)
        }
        .font(
            .system(
                size: metrics.meterFontSize,
                weight: .black,
                design: .monospaced
            )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue(accessibilityValue ?? trailing)
        .frame(height: rowHeight)
    }

    private var tacticalBackground: some View {
        TacticalPanelShape(
            cut: TacticalHUDLayoutMetrics(
                frameSize: frameSize
            ).cornerCut
        )
            .fill(
                Color.black.opacity(
                    data.band == .critical ? 0.88 : 0.78
                )
            )
            .overlay {
                TacticalPanelShape(
                    cut: TacticalHUDLayoutMetrics(
                        frameSize: frameSize
                    ).cornerCut
                )
                    .stroke(tacticalAccentColor, lineWidth: 1)
            }
    }

    private var hpColor: Color {
        switch data.band {
        case .healthy:
            Color(red: 0.26, green: 0.93, blue: 0.60)
        case .normal:
            Color(red: 0.45, green: 0.85, blue: 0.36)
        case .warning:
            Color(red: 1.00, green: 0.71, blue: 0.23)
        case .low:
            Color(red: 1.00, green: 0.24, blue: 0.31)
        case .critical:
            Color(red: 1.00, green: 0.12, blue: 0.22)
        case nil:
            Color.gray
        }
    }
}

private struct TacticalPanelShape: Shape {
    let cut: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: cut, y: 0))
        path.addLine(
            to: CGPoint(x: rect.maxX - cut, y: 0)
        )
        path.addLine(
            to: CGPoint(x: rect.maxX, y: cut)
        )
        path.addLine(
            to: CGPoint(
                x: rect.maxX,
                y: rect.maxY - cut
            )
        )
        path.addLine(
            to: CGPoint(
                x: rect.maxX - cut,
                y: rect.maxY
            )
        )
        path.addLine(
            to: CGPoint(x: cut, y: rect.maxY)
        )
        path.addLine(
            to: CGPoint(x: 0, y: rect.maxY - cut)
        )
        path.addLine(to: CGPoint(x: 0, y: cut))
        path.closeSubpath()
        return path
    }
}
