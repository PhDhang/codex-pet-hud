import SwiftUI

struct FlameCellView: View {
    let isLit: Bool
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion
    @State private var flicker = false

    var body: some View {
        ZStack {
            FlameShape()
                .fill(isLit ? outerLit : outerUnlit)
            FlameShape()
                .fill(isLit ? middleLit : middleUnlit)
                .scaleEffect(0.68, anchor: .bottom)
            FlameShape()
                .fill(isLit ? innerLit : innerUnlit)
                .scaleEffect(0.40, anchor: .bottom)
        }
        .opacity(isLit ? 1 : 0.58)
        .shadow(
            color: isLit
                ? Color.red.opacity(0.72)
                : Color.blue.opacity(0.42),
            radius: isLit ? 6 : 3
        )
        .scaleEffect(
            x: 1,
            y:
                isLit && flicker && !reduceMotion
                ? 1.04
                : 0.96,
            anchor: .bottom
        )
        .onAppear {
            flicker = true
        }
        .animation(
            reduceMotion || !isLit
                ? nil
                : .easeInOut(duration: 0.8)
                    .repeatForever(autoreverses: true),
            value: flicker
        )
        .accessibilityLabel(
            isLit ? "SP elapsed" : "SP remaining"
        )
    }

    private let outerLit =
        Color(red: 1.00, green: 0.20, blue: 0.30)
    private let middleLit =
        Color(red: 1.00, green: 0.54, blue: 0.17)
    private let innerLit =
        Color(red: 1.00, green: 0.91, blue: 0.42)
    private let outerUnlit =
        Color(red: 0.18, green: 0.42, blue: 1.00)
    private let middleUnlit =
        Color(red: 0.16, green: 0.77, blue: 1.00)
    private let innerUnlit =
        Color(red: 0.79, green: 0.97, blue: 1.00)
}

private struct FlameShape: Shape {
    func path(in rect: CGRect) -> Path {
        let points = [
            CGPoint(x: 0.53, y: 0.02),
            CGPoint(x: 0.60, y: 0.20),
            CGPoint(x: 0.62, y: 0.40),
            CGPoint(x: 0.77, y: 0.28),
            CGPoint(x: 0.95, y: 0.58),
            CGPoint(x: 0.86, y: 0.86),
            CGPoint(x: 0.50, y: 0.99),
            CGPoint(x: 0.14, y: 0.86),
            CGPoint(x: 0.05, y: 0.58),
            CGPoint(x: 0.30, y: 0.20),
            CGPoint(x: 0.36, y: 0.47),
        ]
        var path = Path()
        path.move(
            to: CGPoint(
                x: rect.width * points[0].x,
                y: rect.height * points[0].y
            )
        )
        for point in points.dropFirst() {
            path.addCurve(
                to: CGPoint(
                    x: rect.width * point.x,
                    y: rect.height * point.y
                ),
                control1: CGPoint(
                    x: rect.midX,
                    y: rect.height * point.y
                ),
                control2: CGPoint(
                    x: rect.width * point.x,
                    y: rect.height * point.y
                )
            )
        }
        path.closeSubpath()
        return path
    }
}
