// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import SwiftParser
import SwiftSyntaxBuilder
import SwiftSyntax

@main
struct DebugTestGroupBuildTool {
    static func main() {
        print("DebugTestGroup Build Script - Script started")
        
        do {
            try runScript()
            
            print("DebugTestGroup Build Script - Script succeeded!")
        }
        catch {
            print("DebugTestGroup Build Script - Script failed with error: \(error.errorDescription ?? "Unknown")")
        }
    }
    
    private static func runScript() throws(BuildError) {
        // Получаем переменные окружения
        let env = ProcessInfo.processInfo.environment
                
        // Проверяем, что не идет индексация
        guard env["ACTION"] != "indexbuild" else {
            throw .indexBuild
        }

        // Проверяем, что это не превью-сборка
        guard env["ENABLE_PREVIEWS"] != "YES" else {
            throw .previewBuild
        }
        
        // Получаем директорию с файлами
        guard let directoryPath = env["TEST_GROUPS_DIR"] else {
            throw .inputFolderNotFound
        }

        // Генерация кода
        let conformanceProtocolName = "DebuggableTestGroup"
        let typeName = "DebugTestGroup"
        
        let names = try makeTypeNames(
            in: URL(fileURLWithPath: directoryPath),
            conforming: conformanceProtocolName
        )
        
        let source = makeSourceFileSyntax(
            typeName: typeName,
            protocolName: conformanceProtocolName,
            debugTypeNames: names
        )
        
        // Записываем файл
        try write(
            source: source,
            to: typeName + ".swift"
        )
    }
    
    private static func write(
        source: SourceFileSyntax,
        to file: String
    ) throws(BuildError) {
        do {
            try source.formatted().description.write(
                toFile: file,
                atomically: true,
                encoding: .utf8
            )
        }
        catch {
            throw .failToWriteToFile(error: error)
        }

    }
    
    private static func allSwiftFiles(in directory: URL) -> [URL] {
        var result: [URL] = []
        
        guard let enumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: nil) else {
            return []
        }
        
        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension == "swift" {
                result.append(fileURL)
            }
        }
        
        return result
    }
    
    private static func makeTypeNames(
        in dirURL: URL,
        conforming protocolName: String
    ) throws(BuildError) -> [String] {
        let files = allSwiftFiles(in: dirURL)
        
        do {
            let sources = try files.map { try String(contentsOf: $0, encoding: .utf8) }
            
            let finder = ProtocolConformanceFinder(
                viewMode: .all,
                protocolName: protocolName
            )
            
            sources.forEach {
                let syntax = Parser.parse(source: $0)
                
                finder.walk(syntax)
            }
            
            return finder.names
        }
        catch {
            throw .fileDecodeError(error)
        }
    }
    
    private static func makeEnumSyntax(
        name: String,
        typeNames: [String]
    ) -> EnumDeclSyntax {
        EnumDeclSyntax(
            name: .identifier(name),
            inheritanceClause: InheritanceClauseSyntax {
                InheritedTypeSyntax(type: TypeSyntax(stringLiteral: "CaseIterable"))
            },
            memberBlockBuilder: {
                for name in typeNames {
                    EnumCaseDeclSyntax {
                        let caseName = name.prefix(1).lowercased() + name.dropFirst()
                        
                        EnumCaseElementSyntax(name: .identifier(caseName))
                    }
                }
            }
        )
    }
    
    private static func makeSourceFileSyntax(
        typeName: String,
        protocolName: String,
        debugTypeNames: [String]
    ) -> SourceFileSyntax {
        let enumDecl = makeEnumSyntax(
            name: typeName,
            typeNames: debugTypeNames
        )
        
        let extDecl = makeExtensionSyntax(
            name: typeName,
            protocolName: protocolName,
            debugTypeNames: debugTypeNames
        )
        
        return SourceFileSyntax(
            statementsBuilder: {
                enumDecl
                extDecl
            }
        )
    }
    
    private static func makeExtensionSyntax(
        name: String,
        protocolName: String,
        debugTypeNames: [String]
    ) -> ExtensionDeclSyntax {
        ExtensionDeclSyntax(
            extendedType: TypeSyntax(stringLiteral: name),
            memberBlockBuilder: {
                VariableDeclSyntax(
                    .var,
                    name: .init(stringLiteral: "debugType"),
                    type: TypeAnnotationSyntax(type: TypeSyntax(stringLiteral: "any \(protocolName).Type")),
                    accessorBlock: AccessorBlockSyntax(
                        accessors: .getter(
                            CodeBlockItemListSyntax(itemsBuilder: {
                                SwitchExprSyntax(
                                    switchKeyword: .keyword(.switch, trailingTrivia: .spaces(1)),
                                    subject: ExprSyntax(stringLiteral: "self"),
                                    casesBuilder: {
                                        for name in debugTypeNames { makeSwitchCase(for: name) }
                                    }
                                )
                            })
                        )
                    )
                )
            }
        )
    }
    
    private static func makeSwitchCase(for name: String) -> SwitchCaseSyntax {
        SwitchCaseSyntax(
            label: .case(
                SwitchCaseLabelSyntax(
                    caseKeyword: .keyword(.case),
                    caseItems: SwitchCaseItemListSyntax {
                        SwitchCaseItemSyntax(pattern: PatternSyntax(stringLiteral: ".\(name.lowercasedFirst)"))
                    },
                    colon: .colonToken()
                )
            ),
            statements: CodeBlockItemListSyntax {
                CodeBlockItemSyntax(
                    item: .expr(ExprSyntax(stringLiteral: "\(name).self"))
                )
            }
        )
    }

}

private extension String {
    var lowercasedFirst: String {
        prefix(1).lowercased() + dropFirst()
    }
}
