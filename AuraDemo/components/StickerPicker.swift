//
//  StickerPicker.swift
//  AuraDemo
//
//  Created by nick on 11/5/25.
//

import Foundation
import SwiftUI

struct StickerPickerView: View {
    let availableStickers: [StickerContent]
    let onSelect: (StickerContent) -> Void
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(availableStickers.indices, id: \.self) { i in
                    Button {
                        onSelect(availableStickers[i])
                    } label: {
                        GeometryReader { geo in
                            stickerView(for: availableStickers[i], containerSize: geo.size)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .foregroundColor(.white)
                        } .frame(height: 100)
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .cornerRadius(8)
                        
                    }
                }
            }
            .padding()
        }
    }
}
