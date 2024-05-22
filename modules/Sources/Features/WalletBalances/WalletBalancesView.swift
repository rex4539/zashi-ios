//
//  WalletBalancesView.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 04-02-2024
//

import SwiftUI
import ComposableArchitecture
import Generated
import UIComponents

public struct WalletBalancesView: View {
    @Perception.Bindable var store: StoreOf<WalletBalances>
    let tokenName: String
    let underlinedAvailableBalance: Bool
    let couldBeHidden: Bool

    public init(
        store: StoreOf<WalletBalances>,
        tokenName: String,
        underlinedAvailableBalance: Bool = true,
        couldBeHidden: Bool = false
    ) {
        self.store = store
        self.tokenName = tokenName
        self.underlinedAvailableBalance = underlinedAvailableBalance
        self.couldBeHidden = couldBeHidden
    }

    public var body: some View {
        WithPerceptionTracking {
            VStack(spacing: 0) {
                BalanceWithIconView(balance: store.totalBalance, couldBeHidden: couldBeHidden)
                    .padding(.top, 40)

#if !SECANT_DISTRIB
                    .accessDebugMenuWithHiddenGesture {
                        store.send(.debugMenuStartup)
                    }
#endif

                if store.currencyConversion != nil || store.isExchangeRateStale {
                    Button {
                        store.send(.exchangeRateRefreshTapped)
                    } label: {
                        if store.isExchangeRateStale {
                            HStack {
                                Text(L10n.Tooltip.ExchangeRate.title)
                                    .font(.custom(FontFamily.Inter.semiBold.name, size: 14))
                                Asset.Assets.infoCircle.image
                                    .renderingMode(.template)
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(Asset.Colors.primary.color)
                            }
                            .frame(maxWidth: .infinity)
                            .anchorPreference(
                                key: BoundsPreferenceKey.self,
                                value: .bounds
                            ) { $0 }
                        } else if store.isExchangeRateRefreshEnabled {
                            HStack {
                                Text(store.currencyValue)
                                    .hiddenIfSet()
                                    .font(.custom(FontFamily.Inter.semiBold.name, size: 14))
                                if store.isExchangeRateUSDInFlight {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                        .frame(width: 20, height: 20)
                                } else {
                                    Asset.Assets.refreshCCW.image
                                        .renderingMode(.template)
                                        .resizable()
                                        .frame(width: 20, height: 20)
                                        .foregroundColor(Asset.Colors.primary.color)
                                }
                            }
                            .padding(8)
                            .padding(.horizontal, 6)
                            .background {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Asset.Colors.V2.exchangeRateBorder.color)
                                    .background {
                                        Asset.Colors.V2.exchangeRateBcg.color
                                            .cornerRadius(10)
                                    }
                            }
                        } else {
                            HStack {
                                Text(store.currencyValue)
                                    .hiddenIfSet()
                                    .font(.custom(FontFamily.Inter.semiBold.name, size: 14))
                                if store.isExchangeRateUSDInFlight {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                        .frame(width: 11, height: 14)
                                } else {
                                    Asset.Assets.refreshCCW.image
                                        .renderingMode(.template)
                                        .resizable()
                                        .frame(width: 20, height: 20)
                                        .foregroundColor(Asset.Colors.shade72.color)
                                }
                            }
                            .padding(8)
                            .padding(.horizontal, 6)
                        }
                    }
                    .frame(height: 36)
                    .padding(.top, 10)
                    .padding(.vertical, 5)
                }

                if store.migratingDatabase {
                    Text(L10n.Home.migratingDatabases)
                        .font(.custom(FontFamily.Inter.regular.name, size: 14))
                        .padding(.top, 10)
                        .padding(.bottom, 30)
                } else {
                    if underlinedAvailableBalance {
                        Button {
                            store.send(.availableBalanceTapped)
                        } label: {
                            AvailableBalanceView(
                                balance: store.shieldedBalance,
                                tokenName: tokenName,
                                showIndicator: store.isProcessingZeroAvailableBalance,
                                underlined: underlinedAvailableBalance,
                                couldBeHidden: couldBeHidden
                            )
                            .padding(.top, 10)
                            .padding(.bottom, 30)
                        }
                    } else {
                        AvailableBalanceView(
                            balance: store.shieldedBalance,
                            tokenName: tokenName,
                            showIndicator: store.isProcessingZeroAvailableBalance,
                            underlined: underlinedAvailableBalance,
                            couldBeHidden: couldBeHidden
                        )
                        .padding(.top, 10)
                        .padding(.bottom, 30)
                    }
                }
            }
            .foregroundColor(Asset.Colors.primary.color)
            .onAppear { store.send(.onAppear) }
            .onDisappear { store.send(.onDisappear) }
        }
    }
}

// MARK: - Previews

#Preview {
    WalletBalancesView(store: WalletBalances.initial, tokenName: "ZEC")
}

// MARK: - Store

extension WalletBalances {
    public static var initial = StoreOf<WalletBalances>(
        initialState: .initial
    ) {
        WalletBalances()
    }
}

// MARK: - Placeholders

extension WalletBalances.State {
    public static let initial = WalletBalances.State(
        shieldedBalance: .zero
    )
}
