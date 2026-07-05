//
//  DrawingCanvasView.swift
//  Couch Games
//

import SwiftUI

struct InteractiveDrawingCanvas: View {
    let strokes: [FakeArtistStroke]
    @Binding var activePoints: [CGPoint]
    let strokeColor: Color
    let inkLookup: (UUID) -> Color

    private let lineWidth: CGFloat = 5

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size

            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(red: 0.97, green: 0.96, blue: 0.93))

                Canvas { context, canvasSize in
                    for stroke in strokes {
                        drawStroke(stroke, in: &context, size: canvasSize, color: inkLookup(stroke.playerID))
                    }
                    if activePoints.count >= 2 {
                        var path = Path()
                        path.addNormalizedPoints(activePoints, in: canvasSize)
                        context.stroke(
                            path,
                            with: .color(strokeColor),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                        )
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 1, coordinateSpace: .local)
                        .onChanged { value in
                            let point = normalizedPoint(value.location, in: size)
                            activePoints.append(point)
                        }
                )

                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct ReadOnlyDrawingCanvas: View {
    let strokes: [FakeArtistStroke]
    let inkLookup: (UUID) -> Color

    var body: some View {
        GeometryReader { _ in
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(red: 0.97, green: 0.96, blue: 0.93))

                Canvas { context, canvasSize in
                    for stroke in strokes {
                        drawStroke(stroke, in: &context, size: canvasSize, color: inkLookup(stroke.playerID))
                    }
                }

                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

private func normalizedPoint(_ point: CGPoint, in size: CGSize) -> CGPoint {
    CGPoint(
        x: min(max(point.x / max(size.width, 1), 0), 1),
        y: min(max(point.y / max(size.height, 1), 0), 1)
    )
}

private func drawStroke(
    _ stroke: FakeArtistStroke,
    in context: inout GraphicsContext,
    size: CGSize,
    color: Color
) {
    guard stroke.points.count >= 2 else { return }
    var path = Path()
    path.addNormalizedPoints(stroke.points, in: size)
    context.stroke(
        path,
        with: .color(color),
        style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
    )
}

private extension Path {
    mutating func addNormalizedPoints(_ points: [CGPoint], in size: CGSize) {
        guard let first = points.first else { return }
        move(to: CGPoint(x: first.x * size.width, y: first.y * size.height))
        for point in points.dropFirst() {
            addLine(to: CGPoint(x: point.x * size.width, y: point.y * size.height))
        }
    }
}
