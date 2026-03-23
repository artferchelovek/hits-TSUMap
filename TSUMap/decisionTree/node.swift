class Node {
    var attributeName: String?
    var children: [String: Node] = [:]
    var result: String?
    var defaultResult: String?
    
    init(attributeName: String, defaultResult: String? = nil) {
        self.attributeName = attributeName
        self.defaultResult = defaultResult
    }
    init (result: String) {
        self.result = result
    }
}
