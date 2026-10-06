//
//  AlphabetScroller.swift
//  Widgets
//
//  Created by Gangajaliya Sandeep on 5/12/2023.
//

import SwiftUI

@Observable
private class AlphabetScrollerViewState {
    init(selectedAlphabet: String) {
        self.selectedAlphabet = selectedAlphabet
    }

    static func empty() -> AlphabetScrollerViewState {
        .init(selectedAlphabet: "#")
    }

    var selectedAlphabet: String
}

struct AlphabetScroller: View {
    @Bindable private var viewState = AlphabetScrollerViewState.empty()
    let alphabets = Array("#ABCDEFGHIJKLMNOPQRSTUVWXYZ").map { String($0) }
    var didSelectAlphabet: ((String) -> Void)?

    var body: some View {
        VStack(spacing: .spacing0x) {
            ForEach(alphabets.indices, id: \.self) { index in
                BrightText(
                    alphabets[index],
                    size: .body3
                )
                .frame(
                    width: Constants.alphabetSize,
                    height: Constants.alphabetSize
                )
                .gesture(
                    TapGesture()
                        .onEnded {
                            viewState.selectedAlphabet = alphabets[index]
                            didSelectAlphabet?(viewState.selectedAlphabet)
                        }
                )
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let selectedIndex = Int(value.location.y / Constants.alphabetSize)
                            let clampedIndex = min(max(0, selectedIndex), alphabets.count - 1)
                            viewState.selectedAlphabet = alphabets[clampedIndex]
                            didSelectAlphabet?(viewState.selectedAlphabet)
                        }
                )
            }
        }
    }

    private class Constants {
        static let alphabetSize: CGFloat = 16
    }
}

#Preview {
    AlphabetScroller()
}
