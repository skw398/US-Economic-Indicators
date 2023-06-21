import Foundation

enum Indicator: String, CustomStringConvertible {
    
    case GDP
    case realGDP
    case realGDPPerCapita
    case federalFunds
    case CPI
    case retailSales
    case consumerSentiment
    case durableGoods
    case unemploymentRate
    case totalNonfarmPayroll
    case industrialProductionTotalIndex
    case newPrivatelyOwnedHousingUnitsStartedTotalUnits
    case totalVehicleSales
    
    typealias Month = Int
    
    var updateCycle: Month {
        switch self {
        case .GDP, .realGDP, .realGDPPerCapita: return 3
        default: return 1
        }
    }
    
    var description: String {
        switch self {
        case .GDP: return "国内総生産(GDP)"
        case .realGDP: return "実質GDP"
        case .realGDPPerCapita: return "一人当たり実質GDP"
        case .federalFunds: return "フェデラルファンズレート"
        case .CPI: return "消費者物価指数(CPI)"
        case .retailSales: return "小売売上高"
        case .consumerSentiment: return "消費者信頼感指数"
        case .durableGoods: return "耐久財受注"
        case .unemploymentRate: return "失業率"
        case .totalNonfarmPayroll: return "非農業部門雇用者数"
        case .industrialProductionTotalIndex: return "鉱工業生産指数"
        case .newPrivatelyOwnedHousingUnitsStartedTotalUnits: return "住宅着工件数"
        case .totalVehicleSales: return "自動車販売台数"
        }
    }
}
