// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

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
        
        // Получаем список файлов
        guard let directoryPath = env["TEST_GROUPS_DIR"] else {
            throw .inputFolderNotFound
        }
        
        let fileManager = FileManager.default
        let files = try? fileManager.contentsOfDirectory(atPath: directoryPath).filter { $0.hasSuffix(".swift") }
        
        guard let files else {
            throw .filesNotFound(directory: directoryPath)
        }
        
        // Генерация кода
        var output = """
        // The file is generated automatically. Do not modify.

        enum DebugTestGroup: CaseIterable {
        """

        var cases: [String] = []
        var switchCases: [String] = []

        files.forEach { file in
            let fileName = (file as NSString).lastPathComponent
            let className = (fileName as NSString).deletingPathExtension

            let firstLowerClassName = className.prefix(1).lowercased() + className.dropFirst()

            cases.append("    case \(firstLowerClassName)")
            switchCases.append("        case .\(firstLowerClassName): \(className).self")
        }

        output += "\n" + cases.joined(separator: "\n") + "\n"
        output += """

            var rawValue: any DebuggableTestGroup.Type {
                switch self {
        \(switchCases.joined(separator: "\n"))
                }
            }
        }
        
        """
        
        // Записываем файл
        let args = CommandLine.arguments
        
        guard
            let index = args.firstIndex(of: "--output-url"),
            index + 1 < args.count,
            let outputURL = URL(string: args[index + 1])
        else {
            throw .outputFileNotFound
        }
        
        do {
            try output.write(to: outputURL, atomically: true, encoding: .utf8)
        }
        catch {
            throw .failToWriteToFile(error: error)
        }
    }
}
