//
//  MachOHelper.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import Foundation

/// High-performance native Swift parser and modifier for Mach-O binaries and Fat / Universal Mach-O files
public final class MachOHelper {
    
    // Mach-O Magic Numbers
    public static let MH_MAGIC_64: UInt32 = 0xfeedfacf
    public static let MH_CIGAM_64: UInt32 = 0xcffaedfe
    public static let MH_MAGIC: UInt32 = 0xfeedface
    public static let MH_CIGAM: UInt32 = 0xcefaedfe
    public static let FAT_MAGIC: UInt32 = 0xcafebabe
    public static let FAT_CIGAM: UInt32 = 0xbebafeca
    
    // Load Command Constants
    public static let LC_LOAD_DYLIB: UInt32 = 0x0c
    public static let LC_LOAD_WEAK_DYLIB: UInt32 = 0x80000018
    public static let LC_RPATH: UInt32 = 0x8000001c
    public static let LC_CODE_SIGNATURE: UInt32 = 0x1d
    public static let LC_ENCRYPTION_INFO: UInt32 = 0x21
    public static let LC_ENCRYPTION_INFO_64: UInt32 = 0x2c
    public static let LC_SEGMENT_64: UInt32 = 0x19
    
    public enum MachOError: LocalizedError {
        case notMachO
        case unsupportedArchitecture
        case insufficientHeaderPadding
        case dylibAlreadyInjected
        case writeFailed(String)
        
        public var errorDescription: String? {
            switch self {
            case .notMachO: return "File is not a valid Mach-O binary."
            case .unsupportedArchitecture: return "Unsupported binary architecture (only 64-bit arm64 supported)."
            case .insufficientHeaderPadding: return "Not enough header space between load commands and first segment."
            case .dylibAlreadyInjected: return "The specified dylib is already linked in this binary."
            case .writeFailed(let reason): return "Failed to modify Mach-O binary: \(reason)"
            }
        }
    }
    
    // MARK: - Inspection
    
    /// Checks whether the Mach-O has FairPlay DRM enabled (cryptid != 0)
    public static func isFairPlayEncrypted(binaryData: Data) -> Bool {
        guard binaryData.count >= 32 else { return false }
        let magic = binaryData.withUnsafeBytes { $0.load(as: UInt32.self) }
        
        if magic == FAT_MAGIC || magic == FAT_CIGAM {
            // Check slices inside Fat binary
            guard let slices = getFatSlices(from: binaryData) else { return false }
            for slice in slices {
                let sliceData = binaryData.subdata(in: slice.offset..<(slice.offset + slice.size))
                if isSingleSliceEncrypted(sliceData: sliceData) { return true }
            }
            return false
        } else {
            return isSingleSliceEncrypted(sliceData: binaryData)
        }
    }
    
    private static func isSingleSliceEncrypted(sliceData: Data) -> Bool {
        guard sliceData.count >= 32 else { return false }
        let magic = sliceData.withUnsafeBytes { $0.load(as: UInt32.self) }
        let is64 = (magic == MH_MAGIC_64 || magic == MH_CIGAM_64)
        let headerSize = is64 ? 32 : 28
        
        guard sliceData.count >= headerSize else { return false }
        let ncmds = Int(sliceData.withUnsafeBytes { $0.load(fromByteOffset: 16, as: UInt32.self) })
        
        var offset = headerSize
        for _ in 0..<ncmds {
            guard offset + 8 <= sliceData.count else { break }
            let cmd = sliceData.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) }
            let cmdsize = Int(sliceData.withUnsafeBytes { $0.load(fromByteOffset: offset + 4, as: UInt32.self) })
            guard cmdsize > 0 && offset + cmdsize <= sliceData.count else { break }
            
            if cmd == LC_ENCRYPTION_INFO || cmd == LC_ENCRYPTION_INFO_64 {
                // cryptid is at offset + 16
                if offset + 20 <= sliceData.count {
                    let cryptid = sliceData.withUnsafeBytes { $0.load(fromByteOffset: offset + 16, as: UInt32.self) }
                    if cryptid != 0 { return true }
                }
            }
            offset += cmdsize
        }
        return false
    }
    
    /// Detects binary architecture (e.g. arm64, Universal)
    public static func detectArchitecture(binaryData: Data) -> String {
        guard binaryData.count >= 8 else { return "Unknown" }
        let magic = binaryData.withUnsafeBytes { $0.load(as: UInt32.self) }
        
        if magic == FAT_MAGIC || magic == FAT_CIGAM {
            return "Universal (Fat Binary)"
        } else if magic == MH_MAGIC_64 {
            let cputype = binaryData.withUnsafeBytes { $0.load(fromByteOffset: 4, as: Int32.self) }
            if cputype == 0x0100000c { // CPU_TYPE_ARM64
                return "arm64"
            }
            return "64-bit"
        } else if magic == MH_MAGIC {
            return "32-bit (armv7)"
        }
        return "Unknown"
    }
    
    // MARK: - Dylib Injection
    
    /// Injects an `LC_LOAD_DYLIB` load command into a Mach-O binary
    /// - Parameters:
    ///   - binaryURL: File URL of the executable
    ///   - dylibInstallPath: e.g. "@executable_path/Frameworks/MyTweak.dylib" or "@rpath/MyTweak.dylib"
    public static func injectDylib(at binaryURL: URL, dylibInstallPath: String) throws {
        var data = try Data(contentsOf: binaryURL)
        let magic = data.withUnsafeBytes { $0.load(as: UInt32.self) }
        
        if magic == FAT_MAGIC || magic == FAT_CIGAM {
            guard let slices = getFatSlices(from: data) else {
                throw MachOError.notMachO
            }
            for slice in slices {
                var sliceData = data.subdata(in: slice.offset..<(slice.offset + slice.size))
                try injectSingleSlice(data: &sliceData, dylibInstallPath: dylibInstallPath)
                data.replaceSubrange(slice.offset..<(slice.offset + sliceData.count), with: sliceData)
            }
        } else if magic == MH_MAGIC_64 {
            try injectSingleSlice(data: &data, dylibInstallPath: dylibInstallPath)
        } else {
            throw MachOError.unsupportedArchitecture
        }
        
        try data.write(to: binaryURL)
    }
    
    private static func injectSingleSlice(data: inout Data, dylibInstallPath: String) throws {
        guard data.count >= 32 else { throw MachOError.notMachO }
        let magic = data.withUnsafeBytes { $0.load(as: UInt32.self) }
        guard magic == MH_MAGIC_64 else { throw MachOError.unsupportedArchitecture }
        
        let headerSize = 32
        var ncmds = data.withUnsafeBytes { $0.load(fromByteOffset: 16, as: UInt32.self) }
        var sizeofcmds = data.withUnsafeBytes { $0.load(fromByteOffset: 20, as: UInt32.self) }
        
        // Scan existing commands to prevent duplicates and find end of commands
        var offset = headerSize
        var firstSectionOffset: Int = Int.max
        
        for _ in 0..<ncmds {
            guard offset + 8 <= data.count else { break }
            let cmd = data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) }
            let cmdsize = Int(data.withUnsafeBytes { $0.load(fromByteOffset: offset + 4, as: UInt32.self) })
            guard cmdsize > 0 else { break }
            
            if cmd == LC_LOAD_DYLIB || cmd == LC_LOAD_WEAK_DYLIB {
                let nameOffset = Int(data.withUnsafeBytes { $0.load(fromByteOffset: offset + 8, as: UInt32.self) })
                if offset + nameOffset < offset + cmdsize {
                    let pathData = data.subdata(in: (offset + nameOffset)..<(offset + cmdsize))
                    if let pathStr = String(data: pathData, encoding: .utf8)?.trimmingCharacters(in: CharacterSet(["\0"])),
                       pathStr == dylibInstallPath {
                        // Already injected
                        return
                    }
                }
            }
            
            if cmd == LC_SEGMENT_64 && offset + 72 <= data.count {
                let fileoff = Int(data.withUnsafeBytes { $0.load(fromByteOffset: offset + 40, as: UInt64.self) })
                if fileoff > 0 && fileoff < firstSectionOffset {
                    firstSectionOffset = fileoff
                }
            }
            
            offset += cmdsize
        }
        
        // Calculate new LC_LOAD_DYLIB command size
        guard let pathData = dylibInstallPath.data(using: .utf8) else {
            throw MachOError.writeFailed("Invalid dylib path")
        }
        
        let baseCmdSize = 24 // sizeof(struct dylib_command)
        let unalignedSize = baseCmdSize + pathData.count + 1
        let alignedCmdSize = (unalignedSize + 7) & ~7 // Align to 8 bytes
        
        let endOfCommands = headerSize + Int(sizeofcmds)
        
        // Verify available padding space before first segment data
        if firstSectionOffset < Int.max && (endOfCommands + alignedCmdSize > firstSectionOffset) {
            throw MachOError.insufficientHeaderPadding
        }
        
        // Construct dylib_command structure
        var newCmdData = Data(capacity: alignedCmdSize)
        var cmd = LC_LOAD_DYLIB
        var cmdsize = UInt32(alignedCmdSize)
        var nameOffset: UInt32 = 24
        var timestamp: UInt32 = 2
        var currentVersion: UInt32 = 0x010000
        var compatibilityVersion: UInt32 = 0x010000
        
        newCmdData.append(Data(bytes: &cmd, count: 4))
        newCmdData.append(Data(bytes: &cmdsize, count: 4))
        newCmdData.append(Data(bytes: &nameOffset, count: 4))
        newCmdData.append(Data(bytes: &timestamp, count: 4))
        newCmdData.append(Data(bytes: &currentVersion, count: 4))
        newCmdData.append(Data(bytes: &compatibilityVersion, count: 4))
        newCmdData.append(pathData)
        newCmdData.append(0) // Null terminator
        
        // Pad to aligned size
        let paddingCount = alignedCmdSize - (baseCmdSize + pathData.count + 1)
        if paddingCount > 0 {
            newCmdData.append(Data(repeating: 0, count: paddingCount))
        }
        
        // Overwrite zeroed header padding with the new load command
        if endOfCommands + alignedCmdSize <= data.count {
            data.replaceSubrange(endOfCommands..<(endOfCommands + alignedCmdSize), with: newCmdData)
        } else {
            throw MachOError.insufficientHeaderPadding
        }
        
        // Increment ncmds and sizeofcmds in mach_header_64
        ncmds += 1
        sizeofcmds += UInt32(alignedCmdSize)
        
        var newNcmds = ncmds
        var newSizeofcmds = sizeofcmds
        data.replaceSubrange(16..<20, with: Data(bytes: &newNcmds, count: 4))
        data.replaceSubrange(20..<24, with: Data(bytes: &newSizeofcmds, count: 4))
    }
    
    // MARK: - Fat Binary Slice Inspection
    
    struct FatSlice {
        let offset: Int
        let size: Int
        let cputype: Int32
    }
    
    private static func getFatSlices(from data: Data) -> [FatSlice]? {
        guard data.count >= 8 else { return nil }
        let magic = data.withUnsafeBytes { $0.load(as: UInt32.self) }
        guard magic == FAT_MAGIC || magic == FAT_CIGAM else { return nil }
        
        let nfat_arch = Int(data.withUnsafeBytes { $0.load(fromByteOffset: 4, as: UInt32.self).bigEndian })
        var slices: [FatSlice] = []
        var offset = 8
        
        for _ in 0..<nfat_arch {
            guard offset + 20 <= data.count else { break }
            let cputype = Int32(data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self).bigEndian })
            let fileOffset = Int(data.withUnsafeBytes { $0.load(fromByteOffset: offset + 8, as: UInt32.self).bigEndian })
            let size = Int(data.withUnsafeBytes { $0.load(fromByteOffset: offset + 12, as: UInt32.self).bigEndian })
            
            slices.append(FatSlice(offset: fileOffset, size: size, cputype: cputype))
            offset += 20
        }
        return slices
    }
}
