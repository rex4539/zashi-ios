//
//  AppInitializationTests.swift
//  secantTests
//
//  Created by Lukáš Korba on 31.05.2022.
//

import XCTest
import ComposableArchitecture
import MnemonicClient
import Models
import UIComponents
import Generated
import RecoveryPhraseDisplay
import Root
import ZcashLightClientKit
import Utils
@testable import secant_testnet

class AppInitializationTests: XCTestCase {
    /// This integration test starts with finishing the app launch and triggering bunch of initialization procedures.
    @MainActor func testDidFinishLaunching_to_InitializedWallet() async throws {
        var defaultRawFlags = WalletConfig.initial.flags
        defaultRawFlags[.testBackupPhraseFlow] = true
        let walletConfig = WalletConfig(flags: defaultRawFlags)

        var appState = RootReducer.State.initial
        appState.walletConfig = walletConfig

        let store = TestStore(
            initialState: appState
        ) {
            RootReducer()
        }
        
        let testQueue = DispatchQueue.test

        let storedWallet = StoredWallet(
            language: .english,
            seedPhrase: SeedPhrase(RecoveryPhrase.testPhrase.joined(separator: " ")),
            version: 0,
            birthday: Birthday(0),
            hasUserPassedPhraseBackupTest: true
        )
        
        store.dependencies.databaseFiles = .noOp
        store.dependencies.databaseFiles.areDbFilesPresentFor = { _ in true }
        store.dependencies.derivationTool = .liveValue
        store.dependencies.mainQueue = .immediate
        store.dependencies.mnemonic = .mock
        store.dependencies.walletStorage.exportWallet = { storedWallet }
        store.dependencies.walletStorage.areKeysPresent = { true }
        store.dependencies.walletConfigProvider = .noOp
        store.dependencies.sdkSynchronizer = .noOp
        store.dependencies.crashReporter = .noOp
        store.dependencies.numberFormatter = .noOp
        store.dependencies.restoreWalletStorage = .noOp

        // Root of the test, the app finished the launch process and triggers the checks and initializations.
        await store.send(.initialization(.appDelegate(.didFinishLaunching)))

        await testQueue.advance(by: 0.02)

        await store.receive(.initialization(.initialSetups))

        await testQueue.advance(by: 0.02)

        await store.receive(.initialization(.configureCrashReporter))

        await store.receive(.initialization(.checkWalletInitialization))

        await store.receive(.initialization(.respondToWalletInitializationState(.initialized)))

        await testQueue.advance(by: 3.00)

        await store.receive(.initialization(.initializeSDK(.existingWallet))) { state in
            state.storedWallet = storedWallet
        }

        await store.receive(.initialization(.checkBackupPhraseValidation)) { state in
            state.appInitializationState = .initialized
        }
        
        await store.receive(.initialization(.initializationSuccessfullyDone(nil)))

        await store.receive(.initialization(.registerForSynchronizersUpdate))

        await store.receive(.destination(.updateDestination(.tabs))) { state in
            state.destinationState.previousDestination = .welcome
            state.destinationState.internalDestination = .tabs
        }

        await store.finish()
    }
    
    @MainActor func testDidFinishLaunching_AwaitingPhraseConfirmation() async throws {
        var defaultRawFlags = WalletConfig.initial.flags
        defaultRawFlags[.testBackupPhraseFlow] = true
        let walletConfig = WalletConfig(flags: defaultRawFlags)

        var appState = RootReducer.State.initial
        appState.walletConfig = walletConfig

        let store = TestStore(
            initialState: appState
        ) {
            RootReducer()
        }
        
        let testQueue = DispatchQueue.test

        let storedWallet = StoredWallet(
            language: .english,
            seedPhrase: SeedPhrase(RecoveryPhrase.testPhrase.joined(separator: " ")),
            version: 0,
            birthday: Birthday(300_000),
            hasUserPassedPhraseBackupTest: false
        )
        
        store.dependencies.databaseFiles = .noOp
        store.dependencies.databaseFiles.areDbFilesPresentFor = { _ in true }
        store.dependencies.derivationTool = .liveValue
        store.dependencies.mainQueue = .immediate
        store.dependencies.mnemonic = .mock
        store.dependencies.walletStorage.exportWallet = { storedWallet }
        store.dependencies.walletStorage.areKeysPresent = { true }
        store.dependencies.walletConfigProvider = .noOp
        store.dependencies.sdkSynchronizer = .noOp
        store.dependencies.crashReporter = .noOp
        store.dependencies.numberFormatter = .noOp
        store.dependencies.restoreWalletStorage = .noOp

        // Root of the test, the app finished the launch process and triggers the checks and initializations.
        await store.send(.initialization(.appDelegate(.didFinishLaunching)))

        await testQueue.advance(by: 0.02)

        await store.receive(.initialization(.initialSetups))

        await testQueue.advance(by: 0.02)

        await store.receive(.initialization(.configureCrashReporter))

        await store.receive(.initialization(.checkWalletInitialization))

        await store.receive(.initialization(.respondToWalletInitializationState(.initialized)))

        await testQueue.advance(by: 3.00)

        await store.receive(.initialization(.initializeSDK(.existingWallet))) { state in
            state.storedWallet = storedWallet
        }

        let recoveryPhrase = RecoveryPhrase(words: try store.dependencies.mnemonic.randomMnemonicWords().map { $0.redacted })

        await store.receive(.initialization(.checkBackupPhraseValidation)) { state in
            state.appInitializationState = .initialized
            state.phraseDisplayState.phrase = recoveryPhrase
            state.phraseDisplayState.birthdayValue = ""
            state.phraseDisplayState.birthday = Birthday(300_000)
        }
        
        await store.receive(.initialization(.initializationSuccessfullyDone(nil)))

        await store.receive(.initialization(.registerForSynchronizersUpdate))

        await store.receive(.destination(.updateDestination(.phraseDisplay))) { state in
            state.destinationState.previousDestination = .welcome
            state.destinationState.internalDestination = .phraseDisplay
        }

        await store.finish()
    }
    
    /// Integration test validating the side effects work together properly when no wallet is stored but database files are present.
    @MainActor func testDidFinishLaunching_to_KeysMissing() async throws {
        var initialState = RootReducer.State.initial
        initialState.keychainReadRetries = 3
        
        let store = TestStore(
            initialState: initialState
        ) {
            RootReducer()
        }

        store.dependencies.databaseFiles = .noOp
        store.dependencies.databaseFiles.areDbFilesPresentFor = { _ in true }
        store.dependencies.walletStorage = .noOp
        store.dependencies.mainQueue = .immediate
        store.dependencies.walletConfigProvider = .noOp
        store.dependencies.crashReporter = .noOp
        store.dependencies.restoreWalletStorage = .noOp

        // Root of the test, the app finished the launch process and triggers the checks and initializations.
        await store.send(.initialization(.appDelegate(.didFinishLaunching)))

        await store.receive(.initialization(.initialSetups))

        await store.receive(.initialization(.configureCrashReporter))

        await store.receive(.initialization(.checkWalletInitialization))

        await store.receive(.initialization(.respondToWalletInitializationState(.keysMissing))) { state in
            state.appInitializationState = .keysMissing
        }
        
        await store.receive(.initialization(.retryKeychainRead(.keysMissing))) { state in
            state.alert = AlertState.walletStateFailed(.keysMissing)
        }
        
        await store.receive(.destination(.updateDestination(.tabs))) { state in
            state.destinationState.internalDestination = .tabs
            state.destinationState.previousDestination = .welcome
        }
        
        await store.finish()
    }
    
    @MainActor func testDidFinishLaunching_to_KeysMissing_3attempts() async throws {
        let store = TestStore(
            initialState: .initial
        ) {
            RootReducer()
        }

        store.dependencies.databaseFiles = .noOp
        store.dependencies.databaseFiles.areDbFilesPresentFor = { _ in true }
        store.dependencies.walletStorage = .noOp
        store.dependencies.mainQueue = .immediate
        store.dependencies.walletConfigProvider = .noOp
        store.dependencies.crashReporter = .noOp
        store.dependencies.restoreWalletStorage = .noOp

        // Root of the test, the app finished the launch process and triggers the checks and initializations.
        await store.send(.initialization(.appDelegate(.didFinishLaunching)))

        await store.receive(.initialization(.initialSetups))

        await store.receive(.initialization(.configureCrashReporter))

        // initial attempt
        await store.receive(.initialization(.checkWalletInitialization))

        await store.receive(.initialization(.respondToWalletInitializationState(.keysMissing))) { state in
            state.appInitializationState = .keysMissing
        }
        
        await store.receive(.initialization(.retryKeychainRead(.keysMissing))) { state in
            state.keychainReadRetries = 1
        }

        // 1st attempt
        await store.receive(.initialization(.checkWalletInitialization))
        await store.receive(.initialization(.respondToWalletInitializationState(.keysMissing)))
        await store.receive(.initialization(.retryKeychainRead(.keysMissing))) { state in
            state.keychainReadRetries = 2
        }

        // 2nd attempt
        await store.receive(.initialization(.checkWalletInitialization))
        await store.receive(.initialization(.respondToWalletInitializationState(.keysMissing)))
        await store.receive(.initialization(.retryKeychainRead(.keysMissing))) { state in
            state.keychainReadRetries = 3
        }

        // 3rd attempt
        await store.receive(.initialization(.checkWalletInitialization))
        await store.receive(.initialization(.respondToWalletInitializationState(.keysMissing)))
        await store.receive(.initialization(.retryKeychainRead(.keysMissing))) { state in
            state.alert = AlertState.walletStateFailed(.keysMissing)
        }
        
        await store.receive(.destination(.updateDestination(.tabs))) { state in
            state.destinationState.internalDestination = .tabs
            state.destinationState.previousDestination = .welcome
        }

        await store.finish()
    }
    
    /// Integration test validating the side effects work together properly when no wallet is stored and no database files are present.
    @MainActor func testDidFinishLaunching_to_Uninitialized() async throws {
        let store = TestStore(
            initialState: .initial
        ) {
            RootReducer()
        }
        
        store.dependencies.databaseFiles = .noOp
        store.dependencies.mainQueue = .immediate
        store.dependencies.walletStorage = .noOp
        store.dependencies.walletConfigProvider = .noOp
        store.dependencies.crashReporter = .noOp
        store.dependencies.restoreWalletStorage = .noOp

        // Root of the test, the app finished the launch process and triggers the checks and initializations.
        await store.send(.initialization(.appDelegate(.didFinishLaunching)))

        await store.receive(.initialization(.initialSetups))

        await store.receive(.initialization(.configureCrashReporter))

        await store.receive(.initialization(.checkWalletInitialization))

        await store.receive(.initialization(.respondToWalletInitializationState(.uninitialized)))
        
        await store.receive(.destination(.updateDestination(.onboarding))) { state in
            state.destinationState.previousDestination = .welcome
            state.destinationState.internalDestination = .onboarding
        }
        
        await store.finish()
    }
}
