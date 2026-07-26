import PetHUDCore
import SwiftUI

struct DungeonNameplateView: View {
    let data: HUDPresentationData
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 5) {
            HStack {
                Text(data.petName)
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.4)
                    .lineLimit(1)
                Spacer()
                Text(data.statusLabel)
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(statusColor)
            }
            .padding(.horizontal, 13)

            meterRow(
                label: "HP",
                value: data.hpText
            ) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Color.black.opacity(0.72)
                        LinearGradient(
                            colors: [
                                hpColor.opacity(0.98),
                                hpColor.opacity(0.72),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(
                            width:
                                geometry.size.width *
                                data.hpFraction
                        )
                    }
                }
                .clipShape(
                    Rectangle()
                )
                .overlay(
                    Rectangle()
                        .stroke(
                            Color.white.opacity(0.16),
                            lineWidth: 1
                        )
                )
            }

            meterRow(
                label: "SP",
                value: data.resetText
            ) {
                HStack(spacing: 3) {
                    ForEach(0..<7, id: \.self) { index in
                        Rectangle()
                            .fill(
                                index < data.spCellsLit
                                ? Color(
                                    red: 0.22,
                                    green: 0.53,
                                    blue: 0.98
                                )
                                : Color.clear
                            )
                            .overlay(
                                Rectangle()
                                    .stroke(
                                        Color(
                                            red: 0.38,
                                            green: 0.65,
                                            blue: 0.98
                                        )
                                        .opacity(0.7),
                                        lineWidth: 1
                                    )
                            )
                            .frame(height: 11)
                            .skewed()
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(width: 280, height: 92)
        .background(
            DungeonPlateShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(
                                red: 0.19,
                                green: 0.22,
                                blue: 0.28
                            )
                            .opacity(0.98),
                            Color(
                                red: 0.03,
                                green: 0.05,
                                blue: 0.09
                            )
                            .opacity(0.98),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    DungeonPlateShape()
                        .stroke(
                            borderColor,
                            lineWidth: 2
                        )
                )
        )
        .foregroundStyle(Color(red: 1, green: 0.97, blue: 0.86))
        .shadow(
            color: borderColor.opacity(0.28),
            radius: data.band == .critical ? 14 : 5
        )
        .scaleEffect(
            data.band == .critical && pulse ? 1.015 : 1
        )
        .brightness(
            data.band == .critical && pulse ? 0.12 : 0
        )
        .onAppear {
            pulse = true
        }
        .animation(
            data.band == .critical
            ? .easeInOut(duration: 1.2).repeatForever(
                autoreverses: true
            )
            : .default,
            value: pulse
        )
    }

    private func meterRow<Content: View>(
        label: String,
        value: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 7) {
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.78))
                .frame(width: 20, alignment: .leading)
            content()
                .frame(height: 14)
            Text(value)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(
                    label == "HP" ? hpColor : Color.blue.opacity(0.9)
                )
                .frame(width: 32, alignment: .trailing)
        }
    }

    private var hpColor: Color {
        switch data.band {
        case .healthy:
            return Color(red: 0.20, green: 0.83, blue: 0.60)
        case .normal:
            return Color(red: 0.13, green: 0.77, blue: 0.37)
        case .warning:
            return Color(red: 0.96, green: 0.62, blue: 0.04)
        case .low:
            return Color(red: 0.94, green: 0.27, blue: 0.27)
        case .critical:
            return Color(red: 0.86, green: 0.15, blue: 0.15)
        case nil:
            return Color.gray
        }
    }

    private var borderColor: Color {
        switch data.band {
        case .low, .critical:
            return Color(red: 0.94, green: 0.27, blue: 0.27)
        case .warning:
            return Color(red: 0.98, green: 0.45, blue: 0.09)
        default:
            return Color(red: 0.73, green: 0.54, blue: 0.24)
        }
    }

    private var statusColor: Color {
        data.band == .critical
            ? Color.red.opacity(0.95)
            : Color.white.opacity(0.64)
    }
}

private struct DungeonPlateShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + 14, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - 14, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + 18))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 18))
        path.addLine(to: CGPoint(x: rect.maxX - 14, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + 14, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - 18))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + 18))
        path.closeSubpath()
        return path
    }
}

private extension View {
    func skewed() -> some View {
        projectionEffect(
            ProjectionTransform(
                CGAffineTransform(
                    a: 1,
                    b: 0,
                    c: -0.12,
                    d: 1,
                    tx: 0,
                    ty: 0
                )
            )
        )
    }
}

