import SwiftUI

struct IndicatorView: View {
    
    let indicator: Indicator
    
    @State private var items: [DataPoint] = []
    
    @State private var selectedPeriod: Period = .all
    
    @State private var isLoading = false
    @State private var didError = false
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
            } else {
                LineChartView(
                    items: {
                        if let itemCountToDisplay = selectedPeriod.itemCountToDisplay(updateCycle: indicator.updateCycle) {
                            return items.suffix(itemCountToDisplay)
                        } else {
                            return items
                        }
                    }()
                )
            }
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .bottomBar) { periodPicker }
        }
        .task {
            isLoading = true
            do {
                items = try await getItems(for: indicator)
            } catch {
                didError = true
            }
            isLoading = false
        }
        .alert("Error", isPresented: $didError, actions: {})
        .navigationTitle(indicator.description)
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

#if DEBUG
struct IndicatorView_Previews: PreviewProvider {
    
    static var previews: some View {
        NavigationView {
            IndicatorView(indicator: .industrialProductionTotalIndex)
        }
    }
}
#endif
