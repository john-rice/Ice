//
//  AppState.swift
//  Ice
//

import Combine
import OSLog
import SwiftUI

/// The model for app-wide state.
final class AppState: ObservableObject {
    /// The shared app state singleton.
    static let shared = AppState()

    /// Manager for the state of the menu bar.
    private(set) lazy var menuBarManager = MenuBarManager(appState: self)

    /// Manager for app permissions.
    private(set) lazy var permissionsManager = PermissionsManager(appState: self)

    /// Manager for app updates.
    let updatesManager = UpdatesManager()

    /// The application's delegate.
    private(set) weak var appDelegate: AppDelegate?

    /// The window that contains the settings interface.
    private(set) weak var settingsWindow: NSWindow?

    private var cancellables = Set<AnyCancellable>()

    /// A Boolean value that indicates whether the app is running
    /// as a SwiftUI preview.
    let isPreview: Bool = {
        #if DEBUG
        let environment = ProcessInfo.processInfo.environment
        let key = "XCODE_RUNNING_FOR_PREVIEWS"
        return environment[key] != nil
        #else
        return false
        #endif
    }()

    private init() {
        configureCancellables()
    }

    private func configureCancellables() {
        var c = Set<AnyCancellable>()

        menuBarManager.objectWillChange
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &c)
        permissionsManager.objectWillChange
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &c)
        updatesManager.objectWillChange
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &c)

        cancellables = c
    }

    func assignAppDelegate(_ appDelegate: AppDelegate) {
        guard self.appDelegate == nil else {
            Logger.appState.warning("Multiple attempts made to assign app delegate")
            return
        }
        self.appDelegate = appDelegate
    }

    func assignSettingsWindow(_ settingsWindow: NSWindow) {
        guard self.settingsWindow == nil else {
            Logger.appState.warning("Multiple attempts made to assign settings window")
            return
        }
        self.settingsWindow = settingsWindow
    }

    func performSetup() {
        permissionsManager.stopAllChecks()
        menuBarManager.performSetup()
    }
}

// MARK: AppState: BindingExposable
extension AppState: BindingExposable { }

// MARK: - Logger
private extension Logger {
    static let appState = Logger(category: "AppState")
}