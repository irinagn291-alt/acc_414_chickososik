import SwiftUI

let woodland = Color(red: 0.11, green: 0.23, blue: 0.16)
let russet = Color(red: 0.54, green: 0.20, blue: 0.10)
let parchment = Color(red: 0.98, green: 0.95, blue: 0.85)

struct FieldTile: View {
    let tile: Tile
    let cell: Int
    let rotation: Int
    let visited: Bool
    let blocked: Bool
    var homeChicks = 0
    var columns = 4
    var region = 0
    var hinted = false

    var body: some View {
        Canvas { context, size in
            let w = size.width, h = size.height
            let mid = CGPoint(x: w / 2, y: h / 2)
            func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x*w, y: y*h) }
            func line(_ points: [CGPoint], _ color: Color, _ width: CGFloat) {
                var p = Path()
                p.addLines(points)
                context.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
            }
            func disc(_ x: CGFloat, _ y: CGFloat, _ radius: CGFloat, _ color: Color) {
                let r = radius*w
                context.fill(Path(ellipseIn: CGRect(x: x*w-r, y: y*h-r, width: 2*r, height: 2*r)), with: .color(color))
            }
            func piece(_ name: String, scale: CGFloat, x: CGFloat = 0.5, y: CGFloat = 0.5) {
                let side = min(w, h) * scale
                context.draw(context.resolve(Image(name)), in: CGRect(x: x*w-side/2, y: y*h-side/2, width: side, height: side))
            }
            let tint = [Color.green, Color.teal, Color.orange][region]
            let light = (cell / columns + cell % columns).isMultiple(of: 2)
            let bounds = Path(CGRect(origin:.zero,size:size))
            context.fill(bounds,with:.color(tint.opacity(light ? 0.06 : 0.13)))
            context.stroke(bounds,with:.color(woodland.opacity(0.23)),style:StrokeStyle(lineWidth:1,dash:[2,3]))
            for seed in 0..<6 {
                let x = CGFloat((cell*19 + seed*31) % 87 + 5)/100
                let y = CGFloat((cell*17 + seed*39) % 79 + 12)/100
                line([point(x-0.025,y-0.05), point(x,y), point(x+0.02,y-0.035)], woodland.opacity(0.26), max(1,w*0.014))
            }
            if tile == .grass {
                let motifs = [["Daisies","Pines","Mushrooms"],
                              ["Reeds","Willow","Stones"],
                              ["AppleBasket","AppleTree","Lantern"]][region]
                switch (cell + cell / columns * 2 + region) % 7 {
                case 0, 4: piece(motifs[0], scale:0.56, x:0.46, y:0.54)
                case 1: piece(motifs[1], scale:0.85)
                case 3, 6: piece(motifs[2], scale:0.64, x:0.53, y:0.54)
                default: break
                }
            }
            let ends = [point(0.5,0), point(1,0.5), point(0.5,1), point(0,0.5)]
            let ports = tile.ports(rotation)
            if let first = ports.first {
                var lane = Path()
                lane.move(to: ends[first.rawValue])
                if ports.count == 2 {
                    lane.addQuadCurve(to: ends[ports[1].rawValue], control: mid)
                } else {
                    lane.addLine(to: mid)
                    for port in ports.dropFirst() { lane.move(to: mid); lane.addLine(to: ends[port.rawValue]) }
                }
                for (colour, width) in [(Color(red: 0.53, green: 0.43, blue: 0.26), 0.26),
                                         (Color(red: 0.96, green: 0.82, blue: 0.55), 0.215)] {
                    context.stroke(lane, with: .color(colour), style: StrokeStyle(lineWidth: w * width, lineCap: .round, lineJoin: .round))
                }
                context.stroke(lane, with: .color(russet.opacity(0.54)), style: StrokeStyle(lineWidth: w * 0.014, lineCap: .round, dash: [w * 0.065, w * 0.065]))
            }
            if tile == .bridge {
                for x in [0.32,0.44,0.56,0.68] {
                    line([point(x,0.37),point(x,0.63)],russet,w*0.09)
                    line([point(x,0.39),point(x,0.60)],parchment.opacity(0.60),w*0.025)
                }
            }
            if tile.turns > 1 {
                disc(0.5,0.5,0.098,woodland)
                disc(0.5,0.5,0.071,Color(red:0.97,green:0.72,blue:0.24))
                line([point(0.477,0.53),point(0.523,0.47)],russet,w*0.019)
            }
            if tile == .coop {
                piece("Henhouse", scale: 0.75, x: 0.56, y: 0.46)
                for number in 0..<homeChicks {
                    piece("Chick", scale: 0.33, x: 0.25 + CGFloat(number) * 0.3, y: 0.77)
                }
            }
            if tile == .stump { piece("Stump", scale: 0.62) }
            if tile == .start && !visited { piece("Chick", scale: 0.75) }
            if blocked || hinted {
                let rect = CGRect(origin: .zero, size: size).insetBy(dx: 2.5, dy: 2.5)
                context.stroke(Path(roundedRect: rect, cornerRadius: 6), with: .color(blocked ? russet : .yellow), lineWidth: 4)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
