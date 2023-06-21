import SwiftUI

struct IndicatorListView: View {
    
    var body: some View {
        
        NavigationStack {
            List {
                ForEach(Category.allCases, id: \.self) { category in
                    Section(category.rawValue) {
                        ForEach(category.indicators, id: \.self) { indicator in
                            NavigationLink(indicator.description, value: indicator)
                        }
                    }
                }
            }
            .navigationTitle("米国経済統計")
            .navigationDestination(for: Indicator.self) { indicator in
                IndicatorView(indicator: indicator)
            }
        }
    }
    
    enum Category: String, CaseIterable {
        case 景気・金融, 消費, 雇用, 産業
        
        var indicators: [Indicator] {
            switch self {
            case .景気・金融: return [.GDP, .realGDP, .realGDPPerCapita, .federalFunds]
            case .消費: return [.CPI, .retailSales, .consumerSentiment]
            case .雇用: return [.unemploymentRate, .totalNonfarmPayroll]
            case .産業: return [.durableGoods, .industrialProductionTotalIndex, .newPrivatelyOwnedHousingUnitsStartedTotalUnits, .totalVehicleSales]
            }
        }
    }
}

#if DEBUG
struct IndicatorListView_Previews: PreviewProvider {
    
    static var previews: some View {
        IndicatorListView()
    }
}
#endif
