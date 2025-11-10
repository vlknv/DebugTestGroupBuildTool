//
//  ProtocolConformanceFinder.swift
//  DebugTestGroupBuildTool
//
//  Created by Aleksandr Velikanov on 09.11.2025.
//

import SwiftSyntax
//import SwiftParser

/// Посетитель для поиска реализаций протокола
final class ProtocolConformanceFinder: SyntaxVisitor {
    let protocolName: String
    var names: [String] = []

    init(
        viewMode: SyntaxTreeViewMode,
        protocolName: String
    ) {
        self.protocolName = protocolName
        
        super.init(viewMode: viewMode)
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        checkConformance(node)
        
        return .skipChildren
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        checkConformance(node)

        return .skipChildren
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        checkConformance(node)

        return .skipChildren
    }

    private func checkConformance<T: DeclSyntaxProtocol>(_ node: T) {
        let inheritanceClause = node.as(StructDeclSyntax.self)?.inheritanceClause
            ?? node.as(ClassDeclSyntax.self)?.inheritanceClause
            ?? node.as(EnumDeclSyntax.self)?.inheritanceClause
        
        inheritanceClause?.inheritedTypes.forEach { inheritedType in
            let name = inheritedType.type.trimmedDescription
            
            if
                name == protocolName,
                let nameText = node.asProtocol(NamedDeclSyntax.self)?.name.text
            {
                names.append(nameText)
            }
        }
    }
}
