import SwiftUI
import Charts

struct LineChartView: View {
    
    var items: [DataPoint]
    
    @State var trackingItem: DataPoint? = nil
    @State var trackingItemLabelSize: CGSize = .zero
    
    var body: some View {
        
        if items.isEmpty {
            Text("No Data")
        } else {
            let trackingItem = trackingItem ?? items.last!
            
            Spacer().frame(height: trackingItemLabelSize.height)
            
            Chart(items, id: \.date) {
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
                                        guard let date: Date = proxy.value(atX: value.location.x) else { return }
                                        
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
    
    private struct trackingItemLabelSizePreferenceKey: PreferenceKey {
        static var defaultValue: CGSize = .zero
        static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
            value = nextValue()
        }
    }
}

private extension Comparable where Self == CGFloat {
    
    func clamp(to range: ClosedRange<Self>) -> Self {
        return max(range.lowerBound, min(range.upperBound, self))
    }
    
    func normalize(from originRange: ClosedRange<Self>, to newRange: ClosedRange<Self>) -> Self {
        let normalized = (newRange.upperBound - newRange.lowerBound)
        * ((self - originRange.lowerBound) / (originRange.upperBound - originRange.lowerBound))
        + newRange.lowerBound
        
        return normalized.clamp(to: newRange)
    }
}
