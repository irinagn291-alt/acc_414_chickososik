import Foundation

enum Heading: Int, CaseIterable {
    case north, east, south, west

    func turned(_ turns: Int) -> Heading { Self.allCases[(rawValue + turns) % 4] }
    var opposite: Heading { turned(2) }

    func neighbour(of cell: Int, width: Int, height: Int) -> Int? {
        let row = cell / width, col = cell % width
        switch self {
        case .north: return row > 0 ? cell - width : nil
        case .east: return col + 1 < width ? cell + 1 : nil
        case .south: return row + 1 < height ? cell + width : nil
        case .west: return col > 0 ? cell - 1 : nil
        }
    }
}

enum Tile {
    case grass, start, coop, straight, bend, fork, merge, stump, bridge

    var turns: Int {
        switch self {
        case .straight, .fork: return 2
        case .bend: return 4
        default: return 1
        }
    }

    func ports(_ rotation: Int) -> [Heading] {
        switch self {
        case .bridge: return Heading.allCases
        case .grass: return []
        case .start: return [.east]
        case .stump: return [.west]
        case .straight: return [Heading.west.turned(rotation), Heading.east.turned(rotation)]
        case .bend: return [Heading.north.turned(rotation), Heading.east.turned(rotation)]
        case .fork: return [.west, rotation == 0 ? .east : .north]
        case .merge: return [.west, .south, .east]
        case .coop: return [.west]
        }
    }

    func exit(entering from: Heading, rotation: Int) -> Heading? {
        let open = ports(rotation)
        guard open.contains(from) else { return nil }
        if self == .bridge { return from.opposite }
        if self == .merge { return from == .east ? nil : .east }
        return open.first { $0 != from }
    }
}

struct Yard {
    var width = 4
    var height = 3
    let solution: [Int]
    let referenceRoutes: [[Int]]
    let title: String
    let hint: String
    let tiles: [Tile]
    let initial: [Int]

    init(_ title: String, _ hint: String, _ placed: [Int: Tile], _ rotations: [Int: Int], solution solved: [Int: Int], routes: [[Int]]) {
        solution = (0..<12).map { solved[$0] ?? 0 }
        referenceRoutes = routes
        self.title = title
        self.hint = hint
        tiles = (0..<12).map { placed[$0] ?? .grass }
        initial = (0..<12).map { rotations[$0] ?? 0 }
    }

    init(_ title: String, width: Int, height: Int, routes: [[Int]], displaced: [Int]) {
        self.title = title
        self.width = width
        self.height = height
        referenceRoutes = routes
        var links = [Int: Set<Heading>]()
        for route in routes {
            for (a, b) in zip(route, route.dropFirst()) {
                let direction = Heading.allCases.first { $0.neighbour(of: a, width: width, height: height) == b }!
                links[a, default: []].insert(direction)
                links[b, default: []].insert(direction.opposite)
            }
        }
        var terrain = Array(repeating: Tile.grass, count: width * height)
        var solved = Array(repeating: 0, count: terrain.count)
        for (cell, ports) in links {
            if routes.contains(where: { $0.first == cell }) { terrain[cell] = .start }
            else if routes.contains(where: { $0.last == cell }) { terrain[cell] = .coop }
            else if ports.count == 4 { terrain[cell] = .bridge }
            else if ports.count == 3 { terrain[cell] = .merge }
            else {
                let piece: Tile = ports.contains(ports.first!.opposite) ? .straight : .bend
                terrain[cell] = piece
                solved[cell] = (0..<piece.turns).first { Set(piece.ports($0)) == ports }!
            }
        }
        tiles = terrain
        solution = solved
        var start = solved
        for (offset, cell) in displaced.enumerated() {
            let turns = terrain[cell].turns
            start[cell] = (solved[cell] + 1 + offset % (turns - 1)) % turns
        }
        initial = start
        if terrain.contains(.bridge) {
            hint = "At a timber bridge each chick carries straight on. Connect both sides of each crossing."
        } else if terrain.contains(.merge) {
            hint = "Bring both lanes together at the junction, then follow their shared path home."
        } else if routes.count > 1 {
            hint = "Trace each chick’s lane to a coop. Every chick needs an unbroken path."
        } else {
            hint = "Turn the brass pivots to build a continuous path from the chick to the coop."
        }
    }

    static let levels = [
        Yard("Sunlit Lane", "Tap a gold pivot to turn it. Join the chick to the red coop.",
             [4: .start, 5: .straight, 6: .straight, 7: .coop], [5: 1], solution: [:], routes: [[4,5,6,7]]),
        Yard("Willow Fork", "Turn the fork to send the flock up the hill and around the stump.",
             [4: .start, 5: .fork, 6: .stump, 1: .bend, 2: .straight, 3: .coop], [1: 1], solution: [5: 1, 1: 1], routes: [[4,5,1,2,3]]),
        Yard("Orchard Bend", "Two chicks share one way home. Connect the lower lane to the upper one.",
             [4: .start, 5: .merge, 6: .straight, 7: .coop, 8: .start, 9: .bend], [6: 1, 9: 2], solution: [9: 3], routes: [[4,5,6,7],[8,9,5,6,7]]),
        Yard("Daisy Steps", width: 4, height: 4, routes: [[8, 9, 5, 1, 2, 3]], displaced: [2, 5]),
        Yard("The Low Wall", width: 4, height: 4, routes: [[0, 1, 2, 6, 10, 11]], displaced: [1, 2, 6]),
        Yard("Clover Rise", width: 5, height: 4, routes: [[10, 11, 6, 7, 2, 3, 4]], displaced: [11, 6, 2]),
        Yard("The Long Way", width: 5, height: 4, routes: [[0, 1, 2, 7, 6, 11, 12, 13, 14]], displaced: [13, 1, 7, 11]),
        Yard("Gatehouse Run", width: 5, height: 4, routes: [[15, 16, 17, 12, 11, 6, 7, 8, 9]], displaced: [16, 17, 11, 7]),
        Yard("Under the Willow", width: 5, height: 4, routes: [[10, 11, 12, 7, 2, 3, 4]], displaced: [2, 3, 12]),
        Yard("Reed Bed", width: 5, height: 4, routes: [[0, 1, 2, 3, 8, 13, 12, 17, 18]], displaced: [3, 8, 12, 1]),
        Yard("Sedge Corner", width: 5, height: 4, routes: [[5, 6, 11, 16, 17, 18, 13, 8, 9]], displaced: [17, 18, 8, 11]),
        Yard("The Mill Race", width: 5, height: 5, routes: [[15, 16, 11, 6, 7, 8, 13, 18, 19]], displaced: [8, 13, 18, 11, 6]),
        Yard("Two Banks", width: 5, height: 5, routes: [[0, 1, 6, 7, 8], [15, 16, 21, 22, 23, 24]], displaced: [22, 23, 1, 7, 16]),
        Yard("Kingfisher Ford", width: 5, height: 5, routes: [[10, 11, 12, 13, 14], [0, 1, 2, 7, 12, 17, 22, 23, 24]], displaced: [17, 22, 11, 13, 2]),
        Yard("Waterwheel", width: 6, height: 5, routes: [[0, 1, 2, 3, 4, 10, 16, 22, 21, 20, 19, 25, 26, 27, 28, 29]], displaced: [1, 3, 10, 21, 19, 26]),
        Yard("Mill Bridge", width: 6, height: 5, routes: [[12, 13, 14, 15, 16, 17], [0, 1, 2, 3, 9, 15, 21, 20, 26, 27, 28]], displaced: [2, 3, 21, 26, 13, 16]),
        Yard("Apple Terrace", width: 5, height: 5, routes: [[15, 16, 17, 12, 11, 6, 1, 2, 3, 4]], displaced: [16, 17, 11, 6, 2]),
        Yard("Windfall", width: 6, height: 4, routes: [[0, 1, 2, 3, 4, 5, 11, 17, 23, 22, 21, 20, 19, 13, 14, 15]], displaced: [4, 11, 23, 20, 13, 1]),
        Yard("The Picking Lane", width: 6, height: 5, routes: [[18, 19, 20, 21, 15, 9, 8, 7, 1, 2, 3, 4, 5]], displaced: [1, 2, 4, 20, 15, 8]),
        Yard("Bough to Bough", width: 6, height: 5, routes: [[6, 7, 8, 9, 10, 11], [24, 25, 26, 20, 14, 8, 2, 3, 4, 5]], displaced: [4, 7, 10, 26, 20, 2]),
        Yard("Lantern Row", width: 6, height: 5, routes: [[0, 1, 7, 13, 19, 25, 26, 27], [2, 3, 4, 10, 16, 22, 23]], displaced: [16, 22, 7, 19, 26, 4]),
        Yard("Press House", width: 6, height: 5, routes: [[12, 13, 14, 15, 16, 17], [0, 1, 7, 13, 19, 25, 26, 27, 28, 22, 16, 17]], displaced: [15, 1, 7, 25, 26, 28, 22]),
        Yard("At Dusk", width: 6, height: 5, routes: [[6, 7, 8, 9, 15, 16, 17], [24, 25, 26, 20, 14, 8, 9, 15, 16, 17]], displaced: [20, 14, 7, 9, 15, 16, 25]),
        Yard("Home Before Dark", width: 6, height: 5, routes: [[6, 7, 8, 9, 10, 11], [24, 25, 26, 20, 14, 8, 9, 10, 11], [0, 1, 2, 3, 4, 10, 16, 22, 28, 27, 21, 22, 23]], displaced: [4, 16, 27, 21, 9, 25, 20, 14, 2]),
    ]

    struct Step {
        let cell: Int
        let chick: Int
    }

    func trace(_ rotations: [Int]) -> (steps: [Step], success: Bool) {
        var steps = [Step]()
        for (chick, start) in tiles.indices.filter({ tiles[$0] == .start }).enumerated() {
            var cell = start, direction = Heading.east
            var seen = Set<Int>()
            steps.append(Step(cell: cell, chick: chick))
            while true {
                guard seen.insert(cell * 4 + direction.rawValue).inserted,
                      let next = direction.neighbour(of: cell, width: width, height: height) else { return (steps, false) }
                cell = next
                steps.append(Step(cell: cell, chick: chick))
                if tiles[cell] == .coop, tiles[cell].ports(0).contains(direction.opposite) { break }
                guard let exit = tiles[cell].exit(entering: direction.opposite, rotation: rotations[cell])
                else { return (steps, false) }
                direction = exit
            }
        }
        return (steps, true)
    }
}

struct YardBook: Codable, Equatable {
    var level = 0
    var boards = Yard.levels.map(\.initial)
    var finished = Set<Int>()

    var turns: [Int: Int]? = [:]
    var best: [Int: Int]? = [:]

    mutating func resetAttempt() {
        boards[level] = Yard.levels[level].initial
        turns?[level] = 0
    }

    mutating func markHome() {
        finished.insert(level)
        let count = turns?[level] ?? 0
        let prior = best?[level] ?? count
        best?[level] = min(prior, count)
    }

    static func restore(_ data: Data?) -> Self {
        guard let data, let saved = try? JSONDecoder().decode(Self.self, from: data) else { return Self() }
        var book = Self()
        for (i, board) in saved.boards.prefix(Yard.levels.count).enumerated() {
            let yard = Yard.levels[i]
            guard board.count == yard.tiles.count,
                  zip(board, yard.tiles).allSatisfy({ (0..<$1.turns).contains($0) }) else { continue }
            book.boards[i] = board
            // Old saves have orientations but no move counter. Recover the shortest equivalent turns.
            let minimum = zip(board.indices, board).reduce(0) { total, entry in
                let cell = entry.0, modulus = yard.tiles[cell].turns
                return total + (entry.1 - yard.initial[cell] + modulus) % modulus
            }
            book.turns?[i] = max(minimum, saved.turns?[i] ?? 0)
        }
        book.level = Yard.levels.indices.contains(saved.level) ? saved.level : 0
        book.finished = saved.finished.filter { Yard.levels.indices.contains($0) }
        book.best = (saved.best ?? [:]).filter { book.finished.contains($0.key) && $0.value >= 0 }
        return book
    }
}
