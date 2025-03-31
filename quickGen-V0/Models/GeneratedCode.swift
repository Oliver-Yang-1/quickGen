import Foundation

struct GeneratedCode: Identifiable, Codable {
    var id: UUID
    var workspaceId: UUID
    var htmlContent: String
    var timestamp: Date
    
    init(id: UUID = UUID(), workspaceId: UUID, htmlContent: String, timestamp: Date = Date()) {
        self.id = id
        self.workspaceId = workspaceId
        self.htmlContent = htmlContent
        self.timestamp = timestamp
    }
} 