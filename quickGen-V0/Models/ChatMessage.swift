import Foundation

struct ChatMessage: Identifiable, Codable {
    var id: UUID
    var workspaceId: UUID
    var sender: MessageSender
    var content: String
    var timestamp: Date
    var isError: Bool
    
    init(id: UUID = UUID(), workspaceId: UUID, sender: MessageSender, content: String, timestamp: Date = Date(), isError: Bool = false) {
        self.id = id
        self.workspaceId = workspaceId
        self.sender = sender
        self.content = content
        self.timestamp = timestamp
        self.isError = isError
    }
}

enum MessageSender: String, Codable {
    case user
    case ai
} 