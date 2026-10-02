//
//  AddressesView.swift
//  Widgets
//

import SwiftUI

struct AddressesView: View {
    @State private var addressBook = BrightAddressBook()
    @State private var isLoading = true
    @State private var isAddingAddress = false
    @State private var editingAddress: BrightShippingAddress?

    var body: some View {
        BrightPageViewV5(title: Constants.title, scrollableTitle: false, horizontalPadding: .spacing0x) {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isAddingAddress = true
                } label: {
                    Label(Constants.addTitle, systemImage: "plus")
                        .labelStyle(.iconOnly)
                }
            }
        } content: {
            content
        }
        .brightBottomButtonV5 {
            if !isLoading && addressBook.addresses.isEmpty {
                BrightPillButton(Constants.addTitle, buttonSize: .large) {
                    isAddingAddress = true
                }
            }
        }
        .sheet(isPresented: $isAddingAddress) {
            BrightAddAddressSheetV5 { address in
                Task { _ = await addressBook.add(address) }
            }
        }
        .sheet(item: $editingAddress) { address in
            BrightAddAddressSheetV5(editing: address) { updated in
                Task { await addressBook.update(updated) }
            }
        }
        .task {
            await addressBook.loadIfNeeded()
            isLoading = false
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            ProgressView()
                .controlSize(.large)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if addressBook.addresses.isEmpty {
            BrightPlaceholderViewV5(
                systemImage: "house",
                title: Constants.emptyTitle,
                subtitle: Constants.emptySubtitle
            )
        } else {
            List {
                ForEach(addressBook.addresses) { address in
                    row(address)
                        .listRowBackground(Color.defaultCards)
                        .contextMenu {
                            Button {
                                editingAddress = address
                            } label: {
                                Label(Constants.editTitle, systemImage: "pencil")
                            }

                            if !address.isDefault {
                                Button {
                                    Task { await addressBook.makeDefault(address) }
                                } label: {
                                    Label(Constants.makeDefaultTitle, systemImage: "checkmark.circle")
                                }
                            }

                            Button(role: .destructive) {
                                Task { await addressBook.remove(address) }
                            } label: {
                                Label(Constants.deleteTitle, systemImage: "trash")
                            }
                            .tint(.defaultRed)
                        }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .animation(.brightSnappy, value: addressBook.addresses.map(\.id))
        }
    }

    private func row(_ address: BrightShippingAddress) -> some View {
        HStack(alignment: .top, spacing: .spacing2x) {
            VStack(alignment: .leading, spacing: .spacing05x) {
                BrightText(address.name, size: .body1, weight: .regular)

                BrightText(address.street, size: .body1, color: .lightTextColor)
                    .fixedSize(horizontal: false, vertical: true)

                if let phone = address.phone {
                    BrightText(phone, size: .body1, color: .lightTextColor)
                }
            }

            Spacer(minLength: .spacing2x)

            if address.isDefault {
                BrightChipV5(title: Constants.defaultTitle, tint: .defaultBlue, fill: .defaultBlue.opacity(.veryMinimalOpacity))
            }
        }
        .padding(.vertical, .spacing1x)
    }

    private enum Constants {
        static let title = "Addresses"
        static let addTitle = "Add address"
        static let editTitle = "Edit"
        static let deleteTitle = "Delete"
        static let makeDefaultTitle = "Make Default"
        static let defaultTitle = "Default"
        static let emptyTitle = "No saved addresses"
        static let emptySubtitle = "Addresses you add here or at checkout are saved for your next order."
    }
}

#Preview {
    NavigationStack {
        AddressesView()
    }
}
