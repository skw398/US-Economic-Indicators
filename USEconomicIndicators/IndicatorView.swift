import SwiftUI
import Charts

struct IndicatorView: View {
    
    let indicator: Indicator
    
    @State private var items: [DataPoint] = []
    @State private var trackingItem: DataPoint? = nil
    
    @State private var selectedPeriod: Period = .all
    
    @State private var isLoading = false
    @State private var didError = false
    
    @State var trackingItemLabelSize: CGSize = .zero
    
    var body: some View {
        VStack {
            
            if isLoading {
                
                ProgressView()
                
            } else {
                
                if items.isEmpty {
                    
                    Text("No Data")
                    
                } else {
                    
                    Spacer().frame(height: trackingItemLabelSize.height)
                    
                    lineChart(
                        itemCountToDisplay: selectedPeriod.itemCountToDisplay(
                            updateCycle: indicator.updateCycle
                        )
                    )
                    
                }
            }
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                periodPicker
                    .onChange(of: selectedPeriod) { _ in
                        if let lastItem = items.last { trackingItem = lastItem }
                    }
            }
        }
        .task {
            isLoading = true
            do {
                items = try await getItems(for: indicator)
                if let lastItem = items.last { trackingItem = lastItem }
            } catch {
                didError = true
            }
            isLoading = false
        }
        .alert("Error", isPresented: $didError, actions: {})
        .navigationTitle(indicator.description)
    }
    
    private func lineChart(itemCountToDisplay: Int?) -> some View {
        let trackingItem = trackingItem ?? items.last!
        
        return Chart(
            items.suffix(itemCountToDisplay ?? items.count),
            id: \.date
        ) {
            LineMark(
                x: .value("date", $0.date),
                y: .value("value", $0.value)
            )
            .interpolationMethod(.catmullRom)
            
            if trackingItem.date ==  $0.date {
                RuleMark(x: .value("date", trackingItem.date))
                    .foregroundStyle(.gray)
            }
        }
        .chartOverlay { proxy in
            ZStack() {
                GeometryReader { geometry in
                    Rectangle().fill(.clear).contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    guard let date: Date = proxy.value(atX: value.location.x)
                                    else { return }
                                    
                                    if let item = items.min(
                                        by: { abs($0.date.distance(to: date)) < abs($1.date.distance(to: date)) }
                                    ) {
                                        self.trackingItem = item
                                    }
                                }
                        )
                    
                    if let position = proxy.position(forX: trackingItem.date) {
                        trackingItemLabel(trackingItem: trackingItem)
                            .offset(
                                x: position.normalize(
                                    from: 0...geometry.size.width,
                                    to: 0...geometry.size.width - trackingItemLabelSize.width
                                ),
                                y: -trackingItemLabelSize.height - 8
                            )
                            .background {
                                GeometryReader { geometry in
                                    Color.clear
                                        .preference(key: trackingItemLabelSizePreferenceKey.self, value: geometry.size)
                                }
                            }
                            .onPreferenceChange(trackingItemLabelSizePreferenceKey.self) { size in
                                trackingItemLabelSize = size
                            }
                    }
                }
            }
        }
        .chartYScale(domain: .automatic(includesZero: false))
    }
    
    private func trackingItemLabel(trackingItem: DataPoint) -> some View {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM"
        
        return HStack(alignment: .bottom) {
            Text(dateFormatter.string(from: trackingItem.date))
                .foregroundStyle(.secondary)
            Text(String(format: "%.2f", trackingItem.value))
                .font(.title2.bold())
        }
        .monospacedDigit()
        .padding(8)
        .background(Color.secondary.opacity(0.25))
        .cornerRadius(4)
    }
    
    private var periodPicker: some View {
        Picker("Period", selection: $selectedPeriod) {
            ForEach(Period.allCases, id: \.self) { period in
                Text(period.description)
                    .tag(period)
            }
        }
        .pickerStyle(.segmented)
    }
    
    private struct trackingItemLabelSizePreferenceKey: PreferenceKey {
        static var defaultValue: CGSize = .zero
        static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
            value = nextValue()
        }
    }
}

private extension IndicatorView {
    
    enum Period: CaseIterable, CustomStringConvertible {
        case _1Y, _5Y, _10Y, all
        
        func itemCountToDisplay(updateCycle: Indicator.Month) -> Int? {
            let _1Y = 12 / updateCycle
            switch self {
            case ._1Y: return _1Y
            case ._5Y: return _1Y * 5
            case ._10Y: return _1Y * 10
            case .all: return nil
            }
        }
        
        var description: String {
            switch self {
            case ._1Y: return "1年"
            case ._5Y: return "5年"
            case ._10Y: return "10年"
            case .all: return "全期間"
            }
        }
    }
}

private extension IndicatorView {
    
    func getItems(for indicator: Indicator) async throws -> [DataPoint] {
        let url: URL = .init(string: "https://financialmodelingprep.com/api/v4/economic?name=\(indicator.rawValue)&apikey=\(apiKey)")!
        
        let (data, response) = try await URLSession.shared.data(from: url)
        if let code = (response as? HTTPURLResponse)?.statusCode, code != 200 {
            throw ResponseError(code: code)
        }
        
        let items = try JSONDecoder().decode([DataPoint].self, from: data)
        return items.reversed()
    }
    
    struct ResponseError: Error {
        let code: Int
        
        init(code: Int) {
            print("RESPONSE ERROR:", code)
            self.code = code
        }
    }
}

private extension Comparable where Self == CGFloat {
    
    func clamp(to range: ClosedRange<Self>) -> Self {
        return max(range.lowerBound, min(range.upperBound, self))
    }
    
    func normalize(
        from originRange: ClosedRange<Self>,
        to newRange: ClosedRange<Self>
    ) -> Self {
        let normalized = (newRange.upperBound - newRange.lowerBound)
        * ((self - originRange.lowerBound) / (originRange.upperBound - originRange.lowerBound))
        + newRange.lowerBound
        
        return normalized.clamp(to: newRange)
    }
}

#if DEBUG
struct DetailView_Previews: PreviewProvider {
    
    static var previews: some View {
        NavigationView {
            IndicatorView(indicator: .industrialProductionTotalIndex)
        }
    }
}
#endif
