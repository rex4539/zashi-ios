//
//  Tabs.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 09.10.2023.
//

import Foundation
import ComposableArchitecture
import SwiftUI

import Generated
import AddressDetails
import BalanceBreakdown
import Home
import SendFlow
import Settings
import ZcashLightClientKit
import SendConfirmation
import Utils
import ExchangeRate

public typealias TabsStore = Store<TabsReducer.State, TabsReducer.Action>
public typealias TabsViewStore = ViewStore<TabsReducer.State, TabsReducer.Action>

public struct TabsReducer: Reducer {
    public struct State: Equatable {
        public enum Destination: Equatable {
            case sendConfirmation
            case settings
        }

        public enum Tab: Int, CaseIterable {
            case account = 0
            case send
            case receive
            case balances
            
            public var title: String {
                switch self {
                case .account:
                    return L10n.Tabs.account
                case .send:
                    return L10n.Tabs.send
                case .receive:
                    return L10n.Tabs.receive
                case .balances:
                    return L10n.Tabs.balances
                }
            }
        }
        
        public var addressDetailsState: AddressDetails.State
        public var balanceBreakdownState: BalanceBreakdownReducer.State
        public var destination: Destination?
        public var isRateTooltipEnabled = false
        public var homeState: Home.State
        public var selectedTab: Tab = .account
        public var sendConfirmationState: SendConfirmation.State
        public var sendState: SendFlowReducer.State
        public var settingsState: SettingsReducer.State
        
        public init(
            addressDetailsState: AddressDetails.State,
            balanceBreakdownState: BalanceBreakdownReducer.State,
            destination: Destination? = nil,
            isRateTooltipEnabled: Bool = false,
            homeState: Home.State,
            selectedTab: Tab = .account,
            sendConfirmationState: SendConfirmation.State,
            sendState: SendFlowReducer.State,
            settingsState: SettingsReducer.State
        ) {
            self.addressDetailsState = addressDetailsState
            self.balanceBreakdownState = balanceBreakdownState
            self.destination = destination
            self.isRateTooltipEnabled = isRateTooltipEnabled
            self.homeState = homeState
            self.selectedTab = selectedTab
            self.sendConfirmationState = sendConfirmationState
            self.sendState = sendState
            self.settingsState = settingsState
        }
    }
    
    public enum Action: Equatable {
        case addressDetails(AddressDetails.Action)
        case balanceBreakdown(BalanceBreakdownReducer.Action)
        case home(Home.Action)
        case rateTooltipTapped
        case selectedTabChanged(State.Tab)
        case send(SendFlowReducer.Action)
        case sendConfirmation(SendConfirmation.Action)
        case settings(SettingsReducer.Action)
        case updateDestination(TabsReducer.State.Destination?)
    }

    @Dependency(\.exchangeRate) var exchangeRate
    @Dependency(\.mainQueue) var mainQueue

    public init() { }

    public var body: some Reducer<State, Action> {
        Scope(state: \.sendState, action: /Action.send) {
            SendFlowReducer()
        }

        Scope(state: \.sendConfirmationState, action: /Action.sendConfirmation) {
            SendConfirmation()
        }

        Scope(state: \.addressDetailsState, action: /Action.addressDetails) {
            AddressDetails()
        }
        
        Scope(state: \.balanceBreakdownState, action: /Action.balanceBreakdown) {
            BalanceBreakdownReducer()
        }

        Scope(state: \.homeState, action: /Action.home) {
            Home()
        }

        Scope(state: \.settingsState, action: /Action.settings) {
            SettingsReducer()
        }

        Reduce { state, action in
            switch action {
            case .addressDetails:
                return .none
            
            case .balanceBreakdown(.shieldFundsSuccess):
                return .none
            
            case .balanceBreakdown:
                return .none
                
            case .home(.walletBalances(.availableBalanceTapped)),
                .send(.walletBalances(.availableBalanceTapped)):
                state.selectedTab = .balances
                return .none
                
            case .home(.walletBalances(.exchangeRateRefreshTapped)):
                if state.isRateTooltipEnabled {
                    state.isRateTooltipEnabled = false
                    return .none
                }
                state.isRateTooltipEnabled = state.homeState.walletBalancesState.isExchangeRateStale
                return .none
                
            case .home:
                return .none
                
            case .send(.sendConfirmationRequired):
                state.sendConfirmationState.amount = state.sendState.amount
                state.sendConfirmationState.address = state.sendState.address.data
                state.sendConfirmationState.proposal = state.sendState.proposal
                state.sendConfirmationState.feeRequired = state.sendState.feeRequired
                state.sendConfirmationState.message = state.sendState.message
                state.sendConfirmationState.currencyAmount = state.sendState.currencyConversion?.convert(state.sendState.amount).redacted ?? .empty
                return .send(.updateDestination(.sendConfirmation))
                                
            case .send:
                return .none

            case .sendConfirmation(.sendPartial):
                state.selectedTab = .send
                return .none

            case .sendConfirmation(.sendDone):
                state.selectedTab = .account
                return .merge(
                    .send(.updateDestination(nil)),
                    .send(.send(.resetForm))
                    )
                
            case .sendConfirmation(.partialProposalError(.dismiss)):
                return .run { send in
                    await send(.updateDestination(nil))
                    try? await mainQueue.sleep(for: .seconds(0.5))
                    await send(.sendConfirmation(.partialProposalErrorDismiss))
                }

            case .sendConfirmation(.goBackPressed):
                return .send(.updateDestination(nil))

            case .sendConfirmation:
                return .none

            case .settings:
                return .none

            case .selectedTabChanged(let tab):
                state.selectedTab = tab
                if tab == .send {
                    exchangeRate.refreshExchangeRateUSD()
                }
                return .none
                
            case .updateDestination(let destination):
                state.destination = destination
                return .none
                
            case .rateTooltipTapped:
                state.isRateTooltipEnabled = false
                return .none
            }
        }
    }
}

// MARK: - Store

extension TabsStore {
    public static var demo = TabsStore(
        initialState: .initial
    ) {
        TabsReducer()
    }
}

extension TabsStore {
    func settingsStore() -> SettingsStore {
        self.scope(
            state: \.settingsState,
            action: TabsReducer.Action.settings
        )
    }
    
    func sendConfirmationStore() -> StoreOf<SendConfirmation> {
        self.scope(
            state: \.sendConfirmationState,
            action: TabsReducer.Action.sendConfirmation
        )
    }
}

// MARK: - ViewStore

extension TabsViewStore {
    func bindingForDestination(_ destination: TabsReducer.State.Destination) -> Binding<Bool> {
        self.binding(
            get: { $0.destination == destination },
            send: { isActive in .updateDestination(isActive ? destination : nil) }
        )
    }
}

// MARK: - Placeholders

extension TabsReducer.State {
    public static let initial = TabsReducer.State(
        addressDetailsState: .initial,
        balanceBreakdownState: .initial,
        destination: nil,
        homeState: .initial,
        selectedTab: .account,
        sendConfirmationState: .initial,
        sendState: .initial,
        settingsState: .initial
    )
}
