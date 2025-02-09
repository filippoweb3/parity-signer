//
//  KeyDetails+ViewModel.swift
//  Polkadot Vault
//
//  Created by Krzysztof Rodak on 27/10/2022.
//

import Combine
import Foundation
import SwiftUI

extension KeyDetailsView {
    enum OnCompletionAction: Equatable {
        case keySetDeleted
    }

    enum ViewState {
        case emptyState
        case list
    }

    final class ViewModel: ObservableObject {
        let keyDetailsService: KeyDetailsService
        private let networksService: GetAllNetworksService
        private let warningStateMediator: WarningStateMediator
        private let cancelBag = CancelBag()

        private let exportPrivateKeyService: PrivateKeyQRCodeService
        private let keyDetailsActionsService: KeyDetailsActionService
        private let seedsMediator: SeedsMediating
        let keyName: String
        /// `MKwysNew` will currently be `nil` when navigating through given navigation path:
        /// `.newSeed` -> `.keys`, data will be filled on `onAppear`, so this can remain optional
        var keysData: MKeysNew?
        private var appState: AppState
        @Published var shouldPresentRemoveConfirmationModal = false
        @Published var shouldPresentBackupModal = false
        @Published var shouldPresentSelectionOverlay = false
        @Published var isShowingActionSheet = false
        @Published var isShowingRemoveConfirmation = false
        @Published var isShowingBackupModal = false
        @Published var isPresentingConnectivityAlert = false
        @Published var isPresentingSelectionOverlay = false
        @Published var isPresentingRootDetails = false
        @Published var isPresentingKeyDetails = false
        @Published var presentedKeyDetails: MKeyDetails!
        @Published var presentedPublicKeyDetails: String!

        @Published var isShowingKeysExportModal = false
        // Network selection
        @Published var isPresentingNetworkSelection = false

        @Published var keySummary: KeySummaryViewModel?
        @Published var derivedKeys: [DerivedKeyRowModel] = []
        @Published var selectedKeys: [DerivedKeyRowModel] = []
        @Published var isFilteringActive: Bool = false
        // Error handling
        @Published var isPresentingError: Bool = false
        @Published var presentableError: ErrorBottomModalViewModel = .noNetworksAvailable()
        @Published var viewState: ViewState = .list
        @Published var backupModal: BackupModalViewModel?
        var snackbarViewModel: SnackbarViewModel = .init(title: "")
        @Published var isSnackbarPresented: Bool = false

        // Derive New Key
        @Published var isPresentingDeriveNewKey: Bool = false

        // Back Navigation
        var dismissViewRequest: AnyPublisher<Void, Never> {
            dismissRequest.eraseToAnyPublisher()
        }

        private let dismissRequest = PassthroughSubject<Void, Never>()
        private let onCompletion: (OnCompletionAction) -> Void
        /// Name of seed to be removed with `Remove Seed` action
        private var removeSeed: String = ""

        init(
            keyName: String,
            keysData: MKeysNew?,
            exportPrivateKeyService: PrivateKeyQRCodeService = PrivateKeyQRCodeService(),
            keyDetailsService: KeyDetailsService = KeyDetailsService(),
            networksService: GetAllNetworksService = GetAllNetworksService(),
            keyDetailsActionsService: KeyDetailsActionService = KeyDetailsActionService(),
            warningStateMediator: WarningStateMediator = ServiceLocator.warningStateMediator,
            appState: AppState = ServiceLocator.appState,
            seedsMediator: SeedsMediating = ServiceLocator.seedsMediator,
            onCompletion: @escaping (OnCompletionAction) -> Void
        ) {
            self.keyName = keyName
            self.keysData = keysData
            self.exportPrivateKeyService = exportPrivateKeyService
            self.keyDetailsService = keyDetailsService
            self.networksService = networksService
            self.keyDetailsActionsService = keyDetailsActionsService
            self.warningStateMediator = warningStateMediator
            self.appState = appState
            self.seedsMediator = seedsMediator
            self.onCompletion = onCompletion
            use(appState: appState)
            updateRenderables()
            subscribeToNetworkChanges()
            refreshData()
        }

        func use(appState _: AppState) {
            $isPresentingNetworkSelection.sink { newValue in
                guard !newValue else { return }
                self.isFilteringActive = !self.appState.userData.selectedNetworks.isEmpty
            }
            .store(in: cancelBag)
        }

        func subscribeToNetworkChanges() {
            $isPresentingNetworkSelection.sink { newValue in
                guard !newValue else { return }
                self.refreshDerivedKeys()
            }
            .store(in: cancelBag)
        }

        func updateRenderables() {
            refreshDerivedKeys()
            refreshKeySummary()
            refreshNetworks()
        }

        func refreshData() {
            keyDetailsService.getKeys(for: keyName) { result in
                switch result {
                case let .success(keysData):
                    self.keysData = keysData
                    self.updateRenderables()
                case let .failure(error):
                    self.presentableError = .alertError(message: error.description)
                    self.isPresentingError = true
                }
            }
        }

        func refreshNetworks() {
            networksService.getNetworks { result in
                switch result {
                case let .success(networks):
                    self.appState.userData.allNetworks = networks
                case let .failure(error):
                    self.presentableError = .alertError(message: error.description)
                    self.isPresentingError = true
                }
            }
        }

        func onRemoveKeySetConfirmationTap() {
            let isRemoved = seedsMediator.removeSeed(seedName: removeSeed)
            guard isRemoved else { return }
            keyDetailsActionsService.forgetKeySetAction(keyName)
            dismissRequest.send()
            onCompletion(.keySetDeleted)
        }

        func onRemoveKeySetModalDismiss() {
            keyDetailsActionsService.resetNavigationStateToKeyDetails(keyName)
        }

        func onPublicKeyCompletion(_ completionAction: KeyDetailsPublicKeyView.OnCompletionAction) {
            switch completionAction {
            case .derivedKeyDeleted:
                refreshData()
                snackbarViewModel = .init(
                    title: Localizable.PublicKeyDetailsModal.Confirmation.snackbar.string,
                    style: .warning
                )
                isSnackbarPresented = true
            }
        }

        func onAddDerivedKeyCompletion(_ completionAction: CreateKeyNetworkSelectionView.OnCompletionAction) {
            switch completionAction {
            case .derivedKeyCreated:
                refreshData()
                snackbarViewModel = .init(
                    title: Localizable.CreateDerivedKey.Snackbar.created.string,
                    style: .info
                )
                isSnackbarPresented = true
            }
        }

        func createDerivedKeyViewModel() -> CreateKeyNetworkSelectionView.ViewModel {
            .init(
                seedName: keysData?.root?.address.seedName ?? "",
                keyName: keyName,
                // swiftlint: disable:next force_unwrapping
                keySet: keysData!,
                onCompletion: onAddDerivedKeyCompletion(_:)
            )
        }
    }
}

// MARK: - Tap Actions

extension KeyDetailsView.ViewModel {
    func onCreateDerivedKeyTap() {
        if appState.userData.allNetworks.isEmpty {
            presentableError = .noNetworksAvailable()
            isPresentingError = true
        } else {
            isPresentingDeriveNewKey = true
        }
    }

    func onRootKeyTap() {
        guard !isPresentingSelectionOverlay else { return }
        isPresentingRootDetails = true
    }

    func onNetworkSelectionTap() {
        networksService.getNetworks { result in
            if case let .success(networks) = result {
                self.appState.userData.allNetworks = networks
                self.isPresentingNetworkSelection = true
            }
        }
    }

    func onDerivedKeyTap(_ deriveKey: DerivedKeyRowModel) {
        if isPresentingSelectionOverlay {
            if selectedKeys.contains(deriveKey) {
                selectedKeys.removeAll { $0 == deriveKey }
            } else {
                selectedKeys.append(deriveKey)
            }
        } else {
            guard let keyDetails = keyDetailsActionsService.navigateToPublicKey(keyName, deriveKey.publicKeyDetails)
            else { return }
            presentedPublicKeyDetails = deriveKey.publicKeyDetails
            presentedKeyDetails = keyDetails
            isPresentingKeyDetails = true
        }
    }

    func onConnectivityAlertTap() {
        warningStateMediator.resetConnectivityWarnings()
        shouldPresentBackupModal.toggle()
    }
}

// MARK: - Modals

extension KeyDetailsView.ViewModel {
    func onActionSheetDismissal() {
        let isAlertVisible = warningStateMediator.alert
        if shouldPresentRemoveConfirmationModal {
            shouldPresentRemoveConfirmationModal.toggle()
            isShowingRemoveConfirmation.toggle()
        }
        if shouldPresentBackupModal {
            shouldPresentBackupModal.toggle()
            if isAlertVisible {
                isPresentingConnectivityAlert.toggle()
            } else {
                keyDetailsActionsService.performBackupSeed(keyName)
                updateBackupModel()
                isShowingBackupModal = true
            }
        }
        if shouldPresentSelectionOverlay {
            shouldPresentSelectionOverlay.toggle()
            isPresentingSelectionOverlay.toggle()
        }
    }

    func clearBackupModalState() {
        backupModal = nil
    }

    func keyExportModel() -> ExportMultipleKeysModalViewModel? {
        guard let keySummary = keySummary else { return nil }
        let derivedKeys = selectedKeys.map {
            DerivedKeyExportModel(viewModel: $0.viewModel, keyData: $0.keyData)
        }
        return ExportMultipleKeysModalViewModel(
            selectedItems: .keys(
                key: keySummary,
                derivedKeys: derivedKeys
            ),
            count: selectedKeys.count
        )
    }

    func rootKeyDetails() -> RootKeyDetailsModal.ViewModel {
        .init(name: keySummary?.keyName ?? "", publicKey: keySummary?.base58 ?? "")
    }
}

private extension KeyDetailsView.ViewModel {
    func updateBackupModel() {
        backupModal = exportPrivateKeyService.backupViewModel(keysData)
    }

    func keyData(for derivedKey: DerivedKeyRowModel) -> MKeyAndNetworkCard? {
        keysData?.set.first(where: { $0.key.address.path == derivedKey.viewModel.path })
    }

    func refreshDerivedKeys() {
        guard let keysData = keysData else { return }
        let sortedDerivedKeys = keysData.set
            .sorted(by: { $0.key.address.path < $1.key.address.path })
        let filteredKeys: [MKeyAndNetworkCard]
        if appState.userData.selectedNetworks.isEmpty {
            filteredKeys = sortedDerivedKeys
        } else {
            filteredKeys = sortedDerivedKeys.filter {
                appState.userData.selectedNetworks
                    .map(\.key)
                    .contains($0.network.networkSpecsKey)
            }
        }
        derivedKeys = filteredKeys
            .map {
                DerivedKeyRowModel(
                    keyData: $0,
                    viewModel: DerivedKeyRowViewModel($0),
                    publicKeyDetails: $0.publicKeyDetails
                )
            }
        viewState = derivedKeys.isEmpty ? .emptyState : .list
    }

    func refreshKeySummary() {
        guard let keysData = keysData else { return }
        keySummary = KeySummaryViewModel(
            keyName: keysData.root?.address.seedName ?? "",
            base58: keysData.root?.base58 ?? ""
        )
        removeSeed = keysData.root?.address.seedName ?? ""
    }
}
