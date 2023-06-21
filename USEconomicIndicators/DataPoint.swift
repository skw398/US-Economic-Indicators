import Foundation
    
struct DataPoint: Decodable {
    
    var date: Date
    var value: Double
    
    private enum CodingKeys: String, CodingKey {
        case date
        case value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let dateStr = try container.decode(String.self, forKey: .date)
        self.date = try DataPoint.decodeDate(from: dateStr)
        
        self.value = try container.decode(Double.self, forKey: .value)
    }
    
    private static func decodeDate(from dateString: String) throws -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = formatter.date(from: dateString) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: [], debugDescription: "Invalid date format"))
        }
        
        return date
    }
}
