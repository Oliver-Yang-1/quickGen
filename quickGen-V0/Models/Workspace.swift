import Foundation

struct Workspace: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var creationDate: Date
    var lastModifiedDate: Date
    var isFavorite: Bool
    var generatedHTML: String?
    
    init(id: UUID = UUID(), name: String, creationDate: Date = Date(), lastModifiedDate: Date = Date(), isFavorite: Bool = false, generatedHTML: String? = nil) {
        self.id = id
        self.name = name
        self.creationDate = creationDate
        self.lastModifiedDate = lastModifiedDate
        self.isFavorite = isFavorite
        self.generatedHTML = generatedHTML
    }
    
    // 辅助方法，返回文件夹名（使用UUID作为文件夹名）
    func getFolderName() -> String {
        return id.uuidString
    }
    
    // 判断相等性
    static func == (lhs: Workspace, rhs: Workspace) -> Bool {
        return lhs.id == rhs.id
    }
} 