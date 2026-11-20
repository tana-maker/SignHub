//
//  LocalizedStrings.swift
//  SignHub
//
//  Created for SignHub - iOS IPA Library, Signer & Installer.
//

import Foundation

/// Type-safe localization helper providing fallback strings for English and Arabic
public enum LocalizedStrings {
    // Navigation / Tabs
    public static var tabApps: String { localized("tab.apps", default: "Apps") }
    public static var tabSources: String { localized("tab.sources", default: "Sources") }
    public static var tabFiles: String { localized("tab.files", default: "Files") }
    public static var tabDownloads: String { localized("tab.downloads", default: "Downloads") }
    public static var tabSettings: String { localized("tab.settings", default: "Settings") }
    public static var tabSigned: String { localized("tab.signed", default: "Signed Apps") }
    
    // Actions
    public static var actionGet: String { localized("action.get", default: "GET") }
    public static var actionSign: String { localized("action.sign", default: "Sign") }
    public static var actionInstall: String { localized("action.install", default: "Install") }
    public static var actionOpen: String { localized("action.open", default: "Open") }
    public static var actionCancel: String { localized("action.cancel", default: "Cancel") }
    public static var actionDone: String { localized("action.done", default: "Done") }
    public static var actionDelete: String { localized("action.delete", default: "Delete") }
    public static var actionShare: String { localized("action.share", default: "Share") }
    public static var actionRename: String { localized("action.rename", default: "Rename") }
    public static var actionImport: String { localized("action.import", default: "Import") }
    public static var actionRetry: String { localized("action.retry", default: "Retry") }
    public static var actionPause: String { localized("action.pause", default: "Pause") }
    public static var actionResume: String { localized("action.resume", default: "Resume") }
    public static var actionClear: String { localized("action.clear", default: "Clear") }
    
    // Certificate Manager
    public static var certManagerTitle: String { localized("cert.title", default: "Certificates") }
    public static var certImportPrompt: String { localized("cert.import_prompt", default: "Import .p12 and .mobileprovision") }
    public static var certDefaultBadge: String { localized("cert.default", default: "Default") }
    public static var certStatusValid: String { localized("cert.status.valid", default: "Valid") }
    public static var certStatusExpiring: String { localized("cert.status.expiring", default: "Expiring Soon") }
    public static var certStatusExpired: String { localized("cert.status.expired", default: "Expired") }
    
    // Signing Flow
    public static var signingTitle: String { localized("signing.title", default: "Sign Application") }
    public static var signingOptions: String { localized("signing.options", default: "Signing Options") }
    public static var signingAppName: String { localized("signing.app_name", default: "App Display Name") }
    public static var signingBundleID: String { localized("signing.bundle_id", default: "Bundle Identifier") }
    public static var signingVersion: String { localized("signing.version", default: "App Version") }
    public static var signingDylibInject: String { localized("signing.inject_dylib", default: "Inject Dylibs / Frameworks") }
    public static var signingRemoveExtensions: String { localized("signing.remove_extensions", default: "Remove App Extensions") }
    public static var signingRemoveSupportedDevices: String { localized("signing.remove_supported_devices", default: "Remove Device Limits (UISupportedDevices)") }
    public static var signingFileSharing: String { localized("signing.file_sharing", default: "Enable File Sharing") }
    public static var signingiPadFullscreen: String { localized("signing.ipad_fullscreen", default: "Enable iPad Fullscreen") }
    public static var signingStartButton: String { localized("signing.start", default: "Sign Now") }
    
    // Installation
    public static var installLocalHTTPS: String { localized("install.starting_server", default: "Starting secure local server...") }
    public static var installGeneratingManifest: String { localized("install.generating_manifest", default: "Generating wireless manifest...") }
    public static var installTriggeringOTA: String { localized("install.triggering_ota", default: "Triggering iOS installation prompt...") }
    public static var installSuccessPrompt: String { localized("install.success", default: "Follow prompt on your Home Screen to finish install.") }
    
    private static func localized(_ key: String, default defaultValue: String) -> String {
        let val = NSLocalizedString(key, comment: "")
        return val == key ? defaultValue : val
    }
}
