import SwiftUI

@main
struct HatchwayTrailsApp: App {
    var body: some Scene { WindowGroup { FieldView() } }
}

enum TrailRegion: Int, CaseIterable {
    case downs, mill, orchard
    var name: String { tr(["Chalk Downs", "Willow Mill", "Lantern Orchard"][rawValue]) }
    var plate: String { ["Downs", "Mill", "Orchard"][rawValue] }
    var ink: Color { [woodland, Color(red:0.12, green:0.28, blue:0.32), Color(red:0.34, green:0.17, blue:0.20)][rawValue] }
    static func at(_ index: Int) -> Self { allCases[index / 8] }
}

private struct LandscapePlate: View {
    let region: TrailRegion
    let caption: String
    let title: String
    let height: CGFloat
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(caption.uppercased()).font(.system(.caption, design:.monospaced, weight:.bold)).tracking(interfaceLocale.language.languageCode?.identifier == "en" ? 1.5 : 0)
            Text(title).font(.system(.largeTitle, design:.serif, weight:.heavy)).fixedSize(horizontal:false,vertical:true)
        }
        .padding(18).frame(maxWidth:.infinity, minHeight:height, alignment:.bottomLeading)
        .foregroundStyle(Color.white)
        .background {
            GeometryReader { g in
                Image(region.plate).resizable().scaledToFill().frame(width:g.size.width,height:g.size.height,alignment:.trailing).clipped()
                LinearGradient(colors:[.black.opacity(0.76),.black.opacity(0.32),.clear],startPoint:.bottomLeading,endPoint:.topTrailing)
            }.allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius:12))
    }
}

private struct TrailAtlas: View {
    let book: YardBook
    let select: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var region: TrailRegion
    @Environment(\.dynamicTypeSize) private var type
    init(book: YardBook, select: @escaping (Int) -> Void) {
        self.book = book
        self.select = select
        _region = State(initialValue: .at(book.level))
    }
    var body: some View {
        ScrollView {
            VStack(alignment:.leading, spacing:16) {
                HStack {
                    Text("Trail atlas").font(.system(.largeTitle,design:.serif,weight:.bold))
                    Spacer()
                    Button { dismiss() } label: { Image(systemName:"xmark").frame(width:44,height:44) }.accessibilityLabel("Close atlas")
                }
                if type.isAccessibilitySize {
                    VStack(alignment:.leading,spacing:5) {
                        ForEach(TrailRegion.allCases,id:\.self) { placeButton($0,compact:false) }
                    }
                } else {
                    ViewThatFits(in:.horizontal) {
                        HStack { ForEach(TrailRegion.allCases,id:\.self) { placeButton($0,compact:false) } }
                        HStack { ForEach(TrailRegion.allCases,id:\.self) { placeButton($0,compact:true) } }
                    }
                }
                LandscapePlate(region:region,caption:tr("%@ of 8 trails home", numeral(book.finished.filter { TrailRegion.at($0) == region }.count)),title:region.name,height:126)
                LazyVGrid(columns:[GridItem(.adaptive(minimum:type.isAccessibilitySize ? 285 : 150),spacing:10)],spacing:10) {
                    ForEach(region.rawValue*8..<(region.rawValue+1)*8,id:\.self) { index in
                        let yard = Yard.levels[index]
                        Button { select(index); dismiss() } label: {
                            VStack(alignment:.leading,spacing:8) {
                                HStack {
                                    Text(numeral(index+1,padded:true)).font(.system(.subheadline,design:.monospaced,weight:.bold))
                                    Spacer()
                                    Image(systemName: book.finished.contains(index) ? "checkmark.seal.fill" : (index == book.level ? "location.fill" : "arrow.up.forward"))
                                }
                                RouteSketch(yard:yard,board:book.boards[index]).environment(\.layoutDirection,.leftToRight).frame(height:40).accessibilityHidden(true)
                                Text(tr(yard.title)).font(.system(.headline,design:.serif,weight:.bold)).fixedSize(horizontal:false,vertical:true)
                            }.padding(12).frame(maxWidth:.infinity,alignment:.leading)
                                .background(region.ink.opacity(index == book.level ? 0.13 : 0.055),in:RoundedRectangle(cornerRadius:9))
                                .overlay(RoundedRectangle(cornerRadius:9).strokeBorder(region.ink.opacity(index == book.level ? 0.8 : 0.17)))
                        }.buttonStyle(.plain).foregroundStyle(region.ink).accessibilityIdentifier("yard-\(index)")
                          .accessibilityLabel(tr("Trail %1$@, %2$@, %3$@", numeral(index+1), tr(yard.title), tr(book.finished.contains(index) ? "complete" : "open")))
                    }
                }
            }.padding(20).frame(maxWidth:880).frame(maxWidth:.infinity)
        }.background(parchment).foregroundStyle(woodland)
    }
    private func placeButton(_ place:TrailRegion,compact:Bool) -> some View {
        Button { region=place } label:{
            Text(compact ? tr(["Downs","Mill","Orchard"][place.rawValue]) : place.name)
                .font(.subheadline.bold()).fixedSize(horizontal:true,vertical:false).padding(.horizontal,10).frame(minHeight:44)
                .foregroundStyle(region == place ? parchment : place.ink)
                .background(region == place ? place.ink : place.ink.opacity(0.08),in:Capsule())
        }.accessibilityLabel(place.name).accessibilityIdentifier("region-\(place.rawValue)")
         .accessibilityAddTraits(region == place ? .isSelected : [])
    }

}

private struct RouteSketch: View {
    let yard: Yard
    let board: [Int]
    var body: some View {
        Canvas { ctx,size in
            let unit=min(size.width/CGFloat(yard.width),size.height/CGFloat(yard.height))
            for cell in yard.tiles.indices {
                let tile=yard.tiles[cell]
                let centre=CGPoint(x:(CGFloat(cell%yard.width)+0.5)*unit,y:(CGFloat(cell/yard.width)+0.5)*unit)
                for port in tile.ports(board[cell]) {
                    let dx:CGFloat = port == .east ? 1 : port == .west ? -1 : 0
                    let dy:CGFloat = port == .south ? 1 : port == .north ? -1 : 0
                    var stroke=Path()
                    stroke.move(to:centre)
                    stroke.addLine(to:CGPoint(x:centre.x+dx*unit*0.49,y:centre.y+dy*unit*0.49))
                    ctx.stroke(stroke,with:.color(woodland.opacity(0.73)),style:StrokeStyle(lineWidth:2,lineCap:.round))
                }
                if tile == .coop || tile == .start {
                    ctx.fill(Path(ellipseIn:CGRect(x:centre.x-2.3,y:centre.y-2.3,width:4.6,height:4.6)),with:.color(tile == .coop ? russet : woodland))
                }
            }
        }
    }
}

private var appDefaults: UserDefaults {
    #if DEBUG
    if StoreFrame.current != nil { return UserDefaults(suiteName:"preview.hatchway.store")! }
    if let suite = ProcessInfo.processInfo.environment["UI_TEST_SUITE"], suite.hasPrefix("test.") {
        return UserDefaults(suiteName:suite) ?? .standard
    }
    #endif
    return .standard
}

private struct FieldView: View {
    static let saveKey = "hatchway.yards.v1"
    @State private var book: YardBook
    @State private var visited = Set<Int>()
    @State private var position: Int?
    @State private var walkedPaths = [[Int]]()
    @State private var facingLeft = false
    @State private var atDoor = false
    @State private var arrivals = [Int:Int]()
    @State private var outcome: Bool?
    @State private var walking = false
    @State private var walkingTask: Task<Void,Never>?
    @State private var history = [(board:[Int],turns:Int)]()
    @State private var hinted: Int?
    @State private var showAtlas = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var type
    private var yard: Yard { Yard.levels[book.level] }
    private var board: [Int] { book.boards[book.level] }
    private var region: TrailRegion { .at(book.level) }
    private var turnCount: Int { book.turns?[book.level] ?? 0 }

    init() {
        #if DEBUG
        if let frame = StoreFrame.current {
            var book = YardBook()
            let level: Int
            switch frame {
            case .sunlitLane: level = 0
            case .trailAtlas: level = 10
            case .forkHint: level = 1
            case .millCrossing: level = 13
            case .orchardLanes: level = 19
            case .allTrailsHome: level = 23
            }
            func turnsToSolve(_ yard: Yard) -> Int {
                yard.tiles.indices.reduce(0) { sum, i in
                    let period = yard.tiles[i].turns
                    return sum + (yard.solution[i] - yard.initial[i] + period) % period
                }
            }
            for i in 0..<level {
                book.level = i
                book.boards[i] = Yard.levels[i].solution
                book.turns?[i] = turnsToSolve(Yard.levels[i])
                book.markHome()
            }
            book.level = level
            let yard = Yard.levels[level]
            if frame == .trailAtlas { _showAtlas = State(initialValue:true) }
            if frame == .forkHint { _hinted = State(initialValue:5) }
            if frame == .millCrossing || frame == .allTrailsHome {
                book.boards[level] = yard.solution
                book.turns?[level] = turnsToSolve(yard)
                let steps = yard.trace(yard.solution).steps
                let visible = frame == .allTrailsHome ? steps[...] : steps.dropLast(3)
                let paths = Dictionary(grouping:visible,by:\.chick).sorted { $0.key < $1.key }.map { $0.value.map(\.cell) }
                _visited = State(initialValue:Set(visible.map(\.cell)))
                _walkedPaths = State(initialValue:paths)
                _position = State(initialValue:visible.last?.cell)
                var counts = [Int:Int]()
                for path in paths {
                    if let last = path.last, yard.tiles[last] == .coop { counts[last,default:0] += 1 }
                }
                _arrivals = State(initialValue:counts)
                if frame == .allTrailsHome {
                    book.markHome()
                    _outcome = State(initialValue:true)
                    _atDoor = State(initialValue:true)
                } else {
                    _walking = State(initialValue:true)
                }
            }
            _book = State(initialValue:book)
            return
        }
        #endif
        _book = State(initialValue:YardBook.restore(appDefaults.data(forKey:Self.saveKey)))
    }

    var body: some View {
        GeometryReader { g in
            let landscape = g.size.width > 560 && g.size.width > g.size.height * 1.2 && !type.isAccessibilitySize
            ScrollView {
                VStack(alignment:.leading,spacing:14) {
                    ViewThatFits(in:.horizontal) {
                        HStack { masthead; Spacer(); atlasButton }
                        VStack(alignment:.leading) { masthead; atlasButton }
                    }
                    if landscape {
                        HStack(alignment:.top,spacing:18) {
                            field.frame(width:min(g.size.width*0.55,max(140,g.size.height-106)*CGFloat(yard.width)/CGFloat(yard.height)))
                            VStack(alignment:.leading,spacing:10) {
                                landscapeTitle(height:g.size.height < 480 ? 76 : 170)
                                status
                                controls
                            }.frame(maxWidth:.infinity)
                        }
                    } else {
                        landscapeTitle(height:min(252,max(136,g.size.height*0.19)))
                        field
                        status
                        controls
                    }
                }.padding(.horizontal,g.size.width > 700 ? 32 : 15).padding(.vertical,10)
                    .frame(maxWidth:1080).frame(maxWidth:.infinity)
            }
        }.background(parchment.ignoresSafeArea()).foregroundStyle(woodland).preferredColorScheme(.light)
        .onChange(of:book) { _, updated in
            if let data=try? JSONEncoder().encode(updated) { appDefaults.set(data,forKey:Self.saveKey) }
        }
        .onDisappear { clearWalk() }
        .sheet(isPresented:$showAtlas) {
            TrailAtlas(book:book,select:changeYard).presentationDetents([.large]).presentationDragIndicator(.visible)
        }
    }

    private func landscapeTitle(height:CGFloat) -> some View {
        LandscapePlate(region:region,caption:tr("%1$@ · Trail %2$@", region.name, numeral(book.level+1,padded:true)),title:tr(yard.title),height:height)
    }
    private var masthead: some View {
        HStack(spacing:8) {
            Image(systemName:"sun.horizon.fill").foregroundStyle(russet)
            Text("Chickososik").font(.system(.title3,design:.serif,weight:.black))
        }.fixedSize(horizontal:false,vertical:true)
    }
    private var atlasButton: some View {
        Button { showAtlas=true } label: {
            Label("Trail atlas",systemImage:"map").font(.subheadline.bold()).padding(.horizontal,13).frame(minHeight:44)
                .overlay(Capsule().strokeBorder(woodland.opacity(0.3)))
        }.buttonStyle(.plain).accessibilityIdentifier("yards")
    }

    private var field: some View {
        VStack(spacing:0) {
            Group {
                let chicks = tr(["1 chick", "2 chicks", "3 chicks"][yard.referenceRoutes.count-1])
                if type.isAccessibilitySize {
                    VStack(alignment:.leading,spacing:4) { Text(chicks); Text(tr("%@ turns", numeral(turnCount))) }
                        .frame(maxWidth:.infinity,alignment:.leading)
                } else {
                    HStack {
                        Label(chicks,systemImage:"bird.fill")
                        Spacer()
                        Text(tr("%@ turns", numeral(turnCount))).monospacedDigit()
                    }
                }
            }.font(.caption.bold()).foregroundStyle(parchment).padding(.horizontal,12).padding(.vertical,7)
            VStack(spacing:0) {
                ForEach(0..<yard.height,id:\.self) { row in
                    HStack(spacing:0) {
                        ForEach(0..<yard.width,id:\.self) { col in tileButton(row*yard.width+col) }
                    }
                }
            }.background { Image("Turf").resizable().allowsHitTesting(false) }
                .overlay { walkOverlay }
                .clipShape(RoundedRectangle(cornerRadius:6)).padding([.horizontal,.bottom],5)
                .environment(\.layoutDirection,.leftToRight)
        }.background(region.ink,in:RoundedRectangle(cornerRadius:11))
            .shadow(color:region.ink.opacity(0.24),radius:0,y:3)
    }

    private var walkOverlay: some View {
        GeometryReader { g in
            let w=g.size.width/CGFloat(yard.width), h=g.size.height/CGFloat(yard.height)
            let centre: (Int) -> CGPoint = { cell in
                CGPoint(x:(CGFloat(cell % yard.width)+0.5)*w,y:(CGFloat(cell / yard.width)+0.5)*h)
            }
            Canvas { context,_ in
                func half(_ a:CGPoint,_ b:CGPoint)->CGPoint { CGPoint(x:(a.x+b.x)/2,y:(a.y+b.y)/2) }
                for route in walkedPaths where route.count > 1 {
                    let points=route.map(centre)
                    var path=Path()
                    path.move(to:points[0])
                    path.addLine(to:half(points[0],points[1]))
                    for i in 1..<points.count-1 {
                        path.addQuadCurve(to:half(points[i],points[i+1]),control:points[i])
                    }
                    path.addLine(to:points.last!)
                    context.stroke(path,with:.color(woodland.opacity(0.76)),
                                   style:StrokeStyle(lineWidth:max(2,w*0.033),lineCap:.round,dash:[1,w*0.095]))
                }
            }
            if let position, !atDoor {
                Image("Chick").resizable().scaledToFit().frame(width:w*0.70,height:h*0.70)
                    .scaleEffect(x:facingLeft ? -1 : 1,y:1)
                    .position(centre(position))
            }
        }.accessibilityHidden(true).allowsHitTesting(false)
    }

    private var status: some View {
        let regionCount=book.finished.filter { TrailRegion.at($0) == region }.count
        let milestone=outcome == true && regionCount == 8
        return HStack(alignment:.top,spacing:10) {
            Image(systemName: milestone ? "rosette" : outcome == true ? "checkmark.seal.fill" : outcome == false ? "exclamationmark.circle.fill" : hinted != nil ? "lightbulb.fill" : "signpost.right.fill")
                .font(milestone ? .title : .body).foregroundStyle(outcome == false ? russet : region.ink)
            VStack(alignment:.leading,spacing:3) {
                if let outcome {
                    Text(outcome ? (book.finished.count == 24 ? tr("The atlas is complete!") : milestone ? tr("%@ complete", region.name) : tr("Everyone is home!")) : tr("The trail is blocked."))
                        .font(.system(milestone ? .title2 : .headline,design:.serif,weight:.bold)).accessibilityIdentifier(outcome ? "home" : "blocked")
                    if milestone { Text(tr(book.finished.count == 24 ? "All 24 trails are home." : "All eight trails are home.")).font(.callout.bold()) }
                    Text(outcome ? tr("Best on this trail: %@ turns.", numeral(book.best?[book.level] ?? turnCount)) : tr("Start at the marked tile and check the two neighbouring paths.")).font(.callout)
                } else if let hinted {
                    Text(tr("Try turning row %1$@, column %2$@.", numeral(hinted / yard.width + 1), numeral(hinted % yard.width + 1))).font(.callout.weight(.medium))
                } else { Text(tr(yard.hint)).font(.callout) }
            }
        }.fixedSize(horizontal:false,vertical:true)
            .padding(milestone ? 12 : 3).frame(maxWidth:.infinity,alignment:.leading)
            .background(milestone ? region.ink.opacity(0.09) : .clear,in:RoundedRectangle(cornerRadius:8))
    }

    private var controls: some View {
        VStack(spacing:7) {
            Button {
                if outcome == true {
                    if book.finished.count == Yard.levels.count { showAtlas=true }
                    else {
                        let next=(1...Yard.levels.count).map { (book.level+$0) % Yard.levels.count }.first { !book.finished.contains($0) }!
                        changeYard(next)
                    }
                } else { releaseChicks() }
            } label: {
                HStack { Text(tr(outcome == true ? (book.finished.count == 24 ? "Explore the atlas" : "Next trail") : walking ? "On the trail…" : "Release chicks")); Spacer(); Image(systemName:outcome == true ? "arrow.forward" : "play.fill") }
                    .font(.headline).padding(.horizontal,18).padding(.vertical,12).frame(maxWidth:.infinity,minHeight:48)
                    .background(region.ink,in:RoundedRectangle(cornerRadius:9)).foregroundStyle(parchment)
            }.buttonStyle(.plain).disabled(walking).accessibilityIdentifier("release")
            ViewThatFits(in:.horizontal) {
                HStack { undo; Spacer(); hint; Spacer(); reset }
                VStack(alignment:.leading) { undo; hint; reset }
            }.font(.subheadline.weight(.semibold)).buttonStyle(.plain)
        }
    }
    private var undo: some View {
        Button { if let previous=history.popLast() { clearWalk(); book.boards[book.level]=previous.board; book.turns?[book.level]=previous.turns } }
            label:{ Label("Undo",systemImage:"arrow.uturn.backward").frame(minHeight:44) }.disabled(history.isEmpty || walking)
    }
    private var hint: some View {
        Button {
            clearWalk()
            hinted=board.indices.first { board[$0] != yard.solution[$0] }
        } label:{ Label("Hint",systemImage:"lightbulb").frame(minHeight:44) }
            .disabled(walking || board == yard.solution)
    }
    private var reset: some View {
        Button { remember(); clearWalk(); book.resetAttempt() }
            label:{ Label("Reset",systemImage:"arrow.counterclockwise").frame(minHeight:44) }.disabled(walking || board == yard.initial && turnCount == 0)
    }
    private func remember() { history.append((board,turnCount)) }

    @ViewBuilder private func tileButton(_ index:Int) -> some View {
        let tile=yard.tiles[index]
        let face=FieldTile(tile:tile,cell:index,rotation:board[index],visited:visited.contains(index),
                           blocked:outcome == false && position == index,
                           homeChicks:arrivals[index,default:0],columns:yard.width,region:region.rawValue,hinted:hinted == index)
        let label = tr("Row %1$@, column %2$@, %3$@", numeral(index/yard.width+1), numeral(index%yard.width+1), tr(String(describing:tile)))
        if tile.turns > 1 {
            Button {
                remember(); clearWalk()
                book.boards[book.level][index]=(board[index]+1) % tile.turns
                book.turns?[book.level]=turnCount+1
            } label:{ face.contentShape(Rectangle()) }.buttonStyle(.plain).disabled(walking)
                .accessibilityLabel(label)
                .accessibilityValue(tile.ports(board[index]).map { tr(String(describing:$0)) }.formatted(.list(type:.and).locale(interfaceLocale)))
                .accessibilityIdentifier("track-\(index)")
        } else { face.accessibilityElement(children:.ignore).accessibilityLabel(label) }
    }

    private func changeYard(_ index:Int) {
        clearWalk(); history.removeAll(); book.level=index
    }
    private func clearWalk() {
        walkingTask?.cancel(); walkingTask=nil; walking=false; visited.removeAll(); arrivals.removeAll()
        outcome=nil; position=nil; hinted=nil; walkedPaths.removeAll(); atDoor=false; facingLeft=false
    }
    private func releaseChicks() {
        clearWalk(); walking=true
        let trail=yard.trace(board)
        walkingTask=Task { @MainActor in
            for step in trail.steps {
                guard !Task.isCancelled else { return }
                let firstStep = walkedPaths.count <= step.chick
                let previous = firstStep ? nil : position
                if firstStep { walkedPaths.append([]); facingLeft=false; atDoor=false }
                if let previous, previous / yard.width == step.cell / yard.width { facingLeft=step.cell < previous }
                walkedPaths[step.chick].append(step.cell)
                visited.insert(step.cell)
                withAnimation(firstStep || reduceMotion ? nil : .easeInOut(duration:0.17)) { position=step.cell }
                do { try await Task.sleep(for:.milliseconds(reduceMotion ? 50 : 200)) } catch { return }
                if yard.tiles[step.cell] == .coop, let previous,
                   Heading.east.neighbour(of:previous,width:yard.width,height:yard.height) == step.cell {
                    arrivals[step.cell,default:0]+=1
                    atDoor=true
                }
            }
            outcome=trail.success; walking=false
            if trail.success { book.markHome() }
        }
    }
}
