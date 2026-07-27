import PetHUDCore
import SwiftUI

struct LifePodView: View {
    let data: HUDPresentationData
    @State private var pulse = false

    private var isPulsing: Bool {
        data.band == .critical && pulse
    }

    var body: some View {
        GeometryReader { geometry in
            let metrics = Metrics(size: geometry.size)
            ZStack {
                hpRing(metrics: metrics)
                spCells(metrics: metrics)
                topNode(metrics: metrics)
                hpNode(metrics: metrics)
                resetNode(metrics: metrics)
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
        }
        .allowsHitTesting(false)
        .scaleEffect(
            isPulsing ? 1.008 : 1
        )
        .brightness(
            isPulsing ? 0.1 : 0
        )
        .shadow(
            color: hpColor.opacity(
                data.band == .critical ? 0.7 : 0.35
            ),
            radius: data.band == .critical ? 14 : 7
        )
        .onAppear {
            pulse = true
        }
        .animation(
            isPulsing
            ? .easeInOut(duration: 1.1).repeatForever(
                autoreverses: true
            )
            : .default,
            value: isPulsing
        )
    }

    private func hpRing(
        metrics: Metrics
    ) -> some View {
        let start: CGFloat = 0.125
        let span: CGFloat = 0.75
        let fraction = CGFloat(
            min(1, max(0, data.hpFraction))
        )
        return ZStack {
            Ellipse()
                .inset(by: metrics.ringInset)
                .trim(from: start, to: start + span)
                .stroke(
                    Color.black.opacity(0.72),
                    style: StrokeStyle(
                        lineWidth: metrics.ringWidth + 5,
                        lineCap: .round
                    )
                )
            Ellipse()
                .inset(by: metrics.ringInset)
                .trim(from: start, to: start + span)
                .stroke(
                    hpColor.opacity(0.2),
                    style: StrokeStyle(
                        lineWidth: metrics.ringWidth,
                        lineCap: .round
                    )
                )
            Ellipse()
                .inset(by: metrics.ringInset)
                .trim(
                    from: start,
                    to: start + span * fraction
                )
                .stroke(
                    AngularGradient(
                        colors: [
                            hpColor.opacity(0.66),
                            hpColor,
                            Color.white.opacity(0.9),
                            hpColor,
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(
                        lineWidth: metrics.ringWidth,
                        lineCap: .round
                    )
                )
        }
        .rotationEffect(.degrees(90))
    }

    private func spCells(
        metrics: Metrics
    ) -> some View {
        ForEach(0..<7, id: \.self) { index in
            let degrees =
                24 + Double(index) * 22
            let radians = degrees * .pi / 180
            Capsule()
                .fill(
                    index < data.spCellsLit
                    ? spColor
                    : Color.black.opacity(0.42)
                )
                .overlay(
                    Capsule()
                        .stroke(
                            spColor.opacity(0.82),
                            lineWidth: 1
                        )
                )
                .frame(
                    width: metrics.cellWidth,
                    height: metrics.cellHeight
                )
                .shadow(
                    color:
                        index < data.spCellsLit
                        ? spColor.opacity(0.72)
                        : .clear,
                    radius: 4
                )
                .rotationEffect(.degrees(degrees + 90))
                .position(
                    x: metrics.size.width / 2 +
                        CGFloat(cos(radians)) *
                        metrics.cellRadiusX,
                    y: metrics.size.height / 2 +
                        CGFloat(sin(radians)) *
                        metrics.cellRadiusY
                )
        }
    }

    private func topNode(
        metrics: Metrics
    ) -> some View {
        VStack(spacing: 0) {
            Text(data.petName)
                .font(
                    .system(
                        size: metrics.labelSize,
                        weight: .bold
                    )
                )
                .tracking(metrics.labelSize * 0.08)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(data.statusLabel)
                .font(
                    .system(
                        size: metrics.captionSize,
                        weight: .semibold,
                        design: .monospaced
                    )
                )
                .foregroundStyle(statusColor)
                .lineLimit(1)
        }
        .foregroundStyle(Color(red: 1, green: 0.97, blue: 0.86))
        .frame(
            width: metrics.topNodeWidth,
            height: metrics.nodeHeight
        )
        .background(
            Capsule()
                .fill(Color.black.opacity(0.72))
                .overlay(
                    Capsule()
                        .stroke(
                            hpColor.opacity(0.72),
                            lineWidth: 1
                        )
                )
        )
        .position(
            x: metrics.size.width / 2,
            y: metrics.nodeHeight * 0.58
        )
    }

    private func hpNode(
        metrics: Metrics
    ) -> some View {
        meterNode(
            label: "HP",
            value: data.hpText,
            color: hpColor,
            metrics: metrics
        )
        .position(
            x: metrics.sideNodeWidth * 0.5,
            y: metrics.size.height * 0.5
        )
    }

    private func resetNode(
        metrics: Metrics
    ) -> some View {
        meterNode(
            label: "SP",
            value: data.resetText,
            color: spColor,
            metrics: metrics
        )
        .position(
            x: metrics.size.width * 0.5,
            y:
                metrics.size.height -
                metrics.nodeHeight * 1.55
        )
    }

    private func meterNode(
        label: String,
        value: String,
        color: Color,
        metrics: Metrics
    ) -> some View {
        VStack(spacing: 0) {
            Text(label)
                .font(
                    .system(
                        size: metrics.captionSize,
                        weight: .bold,
                        design: .monospaced
                    )
                )
                .foregroundStyle(Color.white.opacity(0.72))
            Text(value)
                .font(
                    .system(
                        size: metrics.labelSize,
                        weight: .bold,
                        design: .monospaced
                    )
                )
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(
            width: metrics.sideNodeWidth,
            height: metrics.nodeHeight
        )
        .background(
            RoundedRectangle(
                cornerRadius: metrics.nodeHeight * 0.28
            )
            .fill(Color.black.opacity(0.72))
            .overlay(
                RoundedRectangle(
                    cornerRadius: metrics.nodeHeight * 0.28
                )
                .stroke(
                    color.opacity(0.72),
                    lineWidth: 1
                )
            )
        )
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

    private var spColor: Color {
        Color(red: 0.22, green: 0.53, blue: 0.98)
    }

    private var statusColor: Color {
        data.band == .critical
            ? Color.red.opacity(0.95)
            : Color.white.opacity(0.64)
    }
}

private struct Metrics {
    let size: CGSize

    private var shortestSide: CGFloat {
        min(size.width, size.height)
    }

    var ringWidth: CGFloat {
        min(12, max(5, shortestSide * 0.035))
    }

    var ringInset: CGFloat {
        ringWidth / 2 + 3
    }

    var nodeHeight: CGFloat {
        min(28, max(18, shortestSide * 0.075))
    }

    var labelSize: CGFloat {
        min(12, max(8, shortestSide * 0.032))
    }

    var captionSize: CGFloat {
        max(7, labelSize * 0.68)
    }

    var topNodeWidth: CGFloat {
        min(
            size.width * 0.62,
            max(116, shortestSide * 0.55)
        )
    }

    var sideNodeWidth: CGFloat {
        min(76, max(52, shortestSide * 0.21))
    }

    var cellWidth: CGFloat {
        ringWidth * 1.65
    }

    var cellHeight: CGFloat {
        max(4, ringWidth * 0.72)
    }

    var cellRadiusX: CGFloat {
        max(
            0,
            size.width / 2 -
                ringInset -
                cellWidth / 2
        )
    }

    var cellRadiusY: CGFloat {
        max(
            0,
            size.height / 2 -
                ringInset -
                cellWidth / 2
        )
    }
}
