//
//  BuildError.swift
//  DebugModePackage
//
//  Created by Aleksandr Velikanov on 24.10.2025.
//

import Foundation

enum BuildError: Error {
    case indexBuild
    case previewBuild
    case inputFolderNotFound //
    case fileDecodeError(Error)
    case outputFileNotFound
    case failToWriteToFile(error: Error)
}

extension BuildError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .indexBuild: "Not running during indexing"
        case .previewBuild: "Not running during preview builds"
        case .inputFolderNotFound: "TestGroups folder path does not found"
        case .fileDecodeError(let error): "Can't decode file: \(error.localizedDescription)"
        case .outputFileNotFound: "DebugTestGroup output file does not exist"
        case .failToWriteToFile(let error): "Failed to write file: \(error.localizedDescription)"
        }
    }
}
