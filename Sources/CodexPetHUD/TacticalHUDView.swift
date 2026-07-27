import PetHUDCore
import SwiftUI

struct TacticalHUDView: View {
    let data: HUDPresentationData
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    var body: some View {
        VStack(spacing: 6) {
            meterRow(
                label: "HP",
                trailing: data.hpText
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
                .frame(height: 9)
            }
            meterRow(
                label: "SP",
                trailing: data.resetText.uppercased()
            ) {
                HStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { index in
                        FlameCellView(
                            isLit: index < data.spCellsLit
                        )
                        .frame(width: 15, height: 19)
                    }
                }
            }
            if data.band == .critical {
                Text("EXHAUSTED · SIGNAL CRITICAL")
                    .font(
                        .system(
                            size: 8,
                            weight: .black,
                            design: .monospaced
                        )
                    )
                    .tracking(1.4)
                    .foregroundStyle(Color.red)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(tacticalBackground)
        .allowsHitTesting(false)
        .animation(
            reduceMotion ? nil : .easeInOut(duration: 0.8),
            value: data.spCellsLit
        )
    }

    private func meterRow<Content: View>(
        label: String,
        trailing: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 7) {
            Text(label)
                .frame(width: 26, alignment: .leading)
                .foregroundStyle(
                    data.band == .critical
                        ? Color.red
                        : Color.cyan
                )
            content()
                .frame(maxWidth: .infinity)
            Text(trailing)
                .frame(width: 42, alignment: .trailing)
                .foregroundStyle(Color.white)
        }
        .font(
            .system(
                size: 10,
                weight: .black,
                design: .monospaced
            )
        )
    }

    private var tacticalBackground: some View {
        TacticalPanelShape(cut: 8)
            .fill(
                Color.black.opacity(
                    data.band == .critical ? 0.88 : 0.78
                )
            )
            .overlay {
                TacticalPanelShape(cut: 8)
                    .stroke(
                        data.band == .critical
                            ? Color.red
                            : Color.cyan.opacity(0.78),
                        lineWidth: 1
                    )
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
