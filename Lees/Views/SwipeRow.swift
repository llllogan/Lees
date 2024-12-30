//
//  SwipeRow.swift
//  Lees
//
//  Created by Logan Janssen | Codify on 26/12/2024.
//

import SwiftUI

struct SwipeableRow<Content: View, LeadingActions: View, TrailingActions: View>: View {
    
    private let content: Content
    private let leadingActions: LeadingActions
    private let trailingActions: TrailingActions
    
    private let actionWidth: CGFloat = 100
    private let swipeThreshold: CGFloat = 50
    
    @State private var offsetX: CGFloat = 0
    @State private var direction: SwipeDirection = .none
    
    @Binding var resetOffset: Bool
    
    enum SwipeDirection {
        case none
        case leading
        case trailing
    }
    
    init(
        resetOffset: Binding<Bool>,
        @ViewBuilder content: () -> Content,
        @ViewBuilder leadingActions: () -> LeadingActions,
        @ViewBuilder trailingActions: () -> TrailingActions
    ) {
        self._resetOffset = resetOffset
        self.content = content()
        self.leadingActions = leadingActions()
        self.trailingActions = trailingActions()
    }
    
    var body: some View {
        ZStack {
            HStack {
                HStack {
                    leadingActions
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal)
                .background(Color.blue)
                
                HStack {
                    Spacer()
                    trailingActions
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal)
                .background(Color.red)
            }
            
            content
                .background(Color(.systemBackground))
                .offset(x: offsetX)
                .gesture(dragGesture)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: offsetX)
        }
        .clipped()
        .onChange(of: resetOffset) { oldValue, newValue in
            if newValue {
                withAnimation {
                    offsetX = 0
                    direction = .none
                }
                resetOffset = false
            }
        }
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let translation = value.translation.width
                
                if direction == .none {
                    if translation > 0 {
                        direction = .leading
                    } else if translation < 0 {
                        direction = .trailing
                    }
                }
                
                switch direction {
                case .leading:
                    offsetX = max(0, translation)
                    offsetX = min(actionWidth, offsetX)
                    
                case .trailing:
                    offsetX = min(0, translation)
                    offsetX = max(-actionWidth, offsetX)
                    
                case .none:
                    break
                }
            }
            .onEnded { value in
                let dragWidth = value.translation.width
                
                switch direction {
                case .leading:
                    if dragWidth > swipeThreshold {
                        offsetX = actionWidth
                    } else {
                        offsetX = 0
                        direction = .none
                    }
                    
                case .trailing:
                    if dragWidth < -swipeThreshold {
                        offsetX = -actionWidth
                    } else {
                        offsetX = 0
                        direction = .none
                    }
                    
                case .none:
                    offsetX = 0
                    direction = .none
                }
            }
    }
}
