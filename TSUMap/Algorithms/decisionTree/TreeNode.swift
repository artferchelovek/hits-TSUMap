///
///  TreeNode.swift
///  TSUMap
///
///  Created by Екатерина Кондрашова on 17.04.2026.
///
class TreeNode {
    var attributeName: String?
    var children: [String: TreeNode] = [:]
    var result: String?
    var defaultResult: String?

    init(attributeName: String, defaultResult: String? = nil) {
        self.attributeName = attributeName
        self.defaultResult = defaultResult
    }

    init(result: String) {
        self.result = result
    }
}
