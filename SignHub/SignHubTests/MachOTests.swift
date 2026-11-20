//
//  MachOTests.swift
//  SignHubTests
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import XCTest
@testable import SignHub

final class MachOTests: XCTestCase {
    
    func testDetect64BitArchitecture() {
        var header = Data()
        var magic: UInt32 = 0xfeedfacf // MH_MAGIC_64
        var cputype: Int32 = 0x0100000c // CPU_TYPE_ARM64
        header.append(Data(bytes: &magic, count: 4))
        header.append(Data(bytes: &cputype, count: 4))
        
        let arch = MachOHelper.detectArchitecture(binaryData: header)
        XCTAssertEqual(arch, "arm64")
    }
    
    func testDetectFairPlayDRM() {
        var data = Data()
        var magic: UInt32 = 0xfeedfacf
        var cputype: Int32 = 0x0100000c
        var cpusubtype: Int32 = 0
        var filetype: UInt32 = 2
        var ncmds: UInt32 = 1
        var sizeofcmds: UInt32 = 24
        var flags: UInt32 = 0
        var reserved: UInt32 = 0
        
        data.append(Data(bytes: &magic, count: 4))
        data.append(Data(bytes: &cputype, count: 4))
        data.append(Data(bytes: &cpusubtype, count: 4))
        data.append(Data(bytes: &filetype, count: 4))
        data.append(Data(bytes: &ncmds, count: 4))
        data.append(Data(bytes: &sizeofcmds, count: 4))
        data.append(Data(bytes: &flags, count: 4))
        data.append(Data(bytes: &reserved, count: 4))
        
        // LC_ENCRYPTION_INFO_64 command (cmd = 0x2c, cmdsize = 24, cryptoff = 4096, cryptsize = 8192, cryptid = 1)
        var cmd: UInt32 = 0x2c
        var cmdsize: UInt32 = 24
        var cryptoff: UInt32 = 4096
        var cryptsize: UInt32 = 8192
        var cryptid: UInt32 = 1 // 1 means encrypted
        var pad: UInt32 = 0
        
        data.append(Data(bytes: &cmd, count: 4))
        data.append(Data(bytes: &cmdsize, count: 4))
        data.append(Data(bytes: &cryptoff, count: 4))
        data.append(Data(bytes: &cryptsize, count: 4))
        data.append(Data(bytes: &cryptid, count: 4))
        data.append(Data(bytes: &pad, count: 4))
        
        let isEncrypted = MachOHelper.isFairPlayEncrypted(binaryData: data)
        XCTAssertTrue(isEncrypted)
    }
}
