//
//  ScrollableTabbar.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 11/01/26.
//

// https://www.youtube.com/watch?v=UQ8ZQIhi8ow
import SwiftUI
enum ScrollableTab: Identifiable, CaseIterable, Hashable {
     var id: Self { self }
     case home
     case profile
     case chat
    
    var icon: String {
        switch self {
        case .home:
            return "house"
        case .profile:
            return "person.circle"
        case .chat:
            return "bubble.left.and.bubble.right"
        }
    }
    
    var title: String {
        switch self {
        case .home:
            return "Home"
        case .profile:
            return "Profile"
        case .chat:
            return "Chat"
        }
    }
    
    var color: Color {
        switch self {
        case .home:
            return .blue
        case .profile:
            return .yellow
        case .chat:
            return .green
        }
    }
}


struct OffsetXPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}



extension View {
    func offsetX(completion: @escaping (CGFloat) -> Void) -> some View {
        self.overlay {
            GeometryReader {
                let minX = $0.frame(in: .scrollView(axis: .horizontal)).minX
                Color.clear
                    .preference(key: OffsetXPreferenceKey.self, value: minX)
                    .onPreferenceChange(OffsetXPreferenceKey.self, perform: completion)
            }
        }
    }
    
    func applyMask(_ progress:CGFloat) -> some View {
        ZStack {
            self
                .foregroundStyle(.gray)
            
            self
                .symbolVariant(.fill)
                .mask {
                    GeometryReader {
                        let size = $0.size
                        let tabWidth = size.width / CGFloat(ScrollableTab.allCases.count)
                        
                        let xOffset = (size.width - tabWidth) * progress
                        Capsule()
                            .fill(Color.white)
                            .frame(width: tabWidth )
                            .offset(x: xOffset)
                    }
                }
        }
    }
}

struct ScrollableTabbar: View {
    @State private var progress: CGFloat = 0
    @State private var selectedTab: ScrollableTab? = .home
    var body: some View {
        VStack {
            customTabbar
            ScrollView(.horizontal) {
                LazyHStack(spacing:0) {
                    ForEach(ScrollableTab.allCases) { tabItem in
                        pageView(tabItem)
                            .containerRelativeFrame(.horizontal)
                    }
                }
                .scrollTargetLayout()
                .offsetX { value in
//                    print(value)
                   let width =  (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.keyWindow?.screen.bounds.width ?? 0
                    let calculatedProgress:CGFloat  = -(value) / (CGFloat(ScrollableTab.allCases.count - 1) * width)
                    
                    let clampedProgress:CGFloat = min(max(0, calculatedProgress), 1)
                    
//                    progress = clampedProgress
//                    print(calculatedProgress)
                }
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $selectedTab)
            .scrollClipDisabled()
            .onScrollGeometryChange(for: CGFloat.self) {
                 $0.contentOffset.x
            } action: { oldValue, newValue in
                print(newValue)
                let width =  (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.keyWindow?.screen.bounds.width ?? 0
                 let calculatedProgress:CGFloat  = (newValue) / (CGFloat(ScrollableTab.allCases.count - 1) * width)
                 
                 let clampedProgress:CGFloat = min(max(0, calculatedProgress), 1)
                self.progress = clampedProgress
            }

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    private func pageView( _ tabItem: ScrollableTab) -> some View  {
        ScrollView {
            LazyVGrid(columns: .init(repeating: GridItem(), count: 2)) {
                ForEach(0..<10) { _ in
                    RoundedRectangle(cornerRadius: 12.0)
                        .fill(tabItem.color)
                        .frame(height: 150)
                    
                }
            }
            .padding(10)
        }
        .scrollIndicators(ScrollIndicatorVisibility.hidden)
    }
    
    private var customTabbar: some View {
        HStack(spacing:0) {
            ForEach(ScrollableTab.allCases) { tabItem in
                HStack {
                    Image(systemName: tabItem.icon)
                    Text(tabItem.title)
                }
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
                .id(tabItem)
                .onTapGesture {
                    selectedTab = tabItem
                }
            }
        }
        .padding()
        .background(content: {
            GeometryReader {
                let size = $0.size
                let tabWidth = size.width / CGFloat(ScrollableTab.allCases.count)
                
                let xOffset = (size.width - tabWidth) * progress
                Capsule()
                    .fill(Color.white)
                    .frame(width: tabWidth )
                    .offset(x: xOffset)
            }
        })
        .background(Color.gray.opacity(0.2), in:.capsule)
        .padding(10)
        .applyMask(progress)
    }
}

#Preview {
    ScrollableTabbar()
}
