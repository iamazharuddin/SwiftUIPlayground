//
//  ExpandableSearchBar.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 30/10/25.
//

import SwiftUI
private struct Home: View {
    @FocusState private var isSearching:Bool
    @State private var activeTab: Tab = .all
    @State private var searchText: String = ""
    @Environment(\.colorScheme) private var colorScheme
    @Namespace private var animation
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack {
                dummyMessageView()
            }
            .safeAreaPadding(15)
            .safeAreaInset(edge: .top) {
                ExpandableNavigationBar()
            }
            .animation(.snappy(duration: 0.25), value: isSearching)
        }.background(.gray.opacity(0.15))
        .contentMargins(.top, 190, for: .scrollIndicators)
        .scrollTargetBehavior(CustomScrollTargetBehaviour())
    }
    
    @ViewBuilder
    func ExpandableNavigationBar( _ title: String = "Message") -> some View {
        GeometryReader {
            let minY = $0.frame(in: .scrollView(axis: .vertical)).minY
            let progress = isSearching ? 1 : max(min(-minY / 70, 1), 0)
            
            let scrollViewHeight = $0.bounds(of: .scrollView(axis: .vertical))?.height ?? 0
            
            let scaleProgress  = minY > 0 ? 1 + max(min((minY/scrollViewHeight), 1), 0)*0.5 : 1
            VStack(spacing: 10) {
                Text(title)
                    .font(.largeTitle.bold())
                    .scaleEffect(scaleProgress, anchor: .topLeading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 10)
                
                
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                    TextField("Search Conversations", text: $searchText)
                        .focused($isSearching)
                    
                    if isSearching {
                        Button {
                            isSearching = false
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .transition(.asymmetric(insertion: .push(from: .bottom), removal: .push(from: .top)))
                    }
                }
                .foregroundStyle(Color.primary)
                .padding(.horizontal, 15 - (progress*15))
                .padding(.vertical, 10)
                .frame(height: 45)
                .clipShape(.capsule)
                .background {
                    RoundedRectangle(cornerRadius: 25 - (progress * 25))
                        .fill(.background)
                        .padding(.top, 190 * -progress)
                        .padding(.bottom, -progress*65)
                        .padding(.horizontal, -progress*15)
                }
                
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(Tab.allCases, id:\.rawValue) { tab in
                            Button(action: {
                                
                                withAnimation(.snappy){
                                    activeTab = tab
                                }
                                
                            }) {
                                Text(tab.rawValue)
                                    .font(.callout)
                                    .foregroundStyle(activeTab == tab ?  (colorScheme == .dark ? .black : .white) : Color.primary)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 15)
                                    .background {
                                        if activeTab == tab {
                                            Capsule().fill(Color.primary)
                                                .matchedGeometryEffect(id: "ActiveTab", in: animation)
                                        } else {
                                            Capsule()
                                                .fill(.background)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(height: 50)
            }
            .padding(.top, 25)
            .safeAreaPadding(.horizontal, 15)
            .offset(y: minY < 0 || isSearching ? -minY : 0)
            .offset(y: -progress*65)
        }
        .padding(.bottom, 10)
        .frame(height: 180)
        .padding(.bottom, isSearching ? -65 : 0)
    }
    
    @ViewBuilder
    func dummyMessageView() -> some View {
        ForEach(0..<20, id:\.self) { _ in
            HStack(spacing: 12) {
                Circle()
                    .frame(width: 44, height: 44)
                
                VStack(alignment: .leading, spacing: 6) {
                    Rectangle()
                        .frame(width: 140, height: 8)
                       
                    Rectangle()
                        .frame(height: 8)
                    
                    Rectangle()
                        .frame(width: 80, height: 8)
                }
            }
            .foregroundStyle(.gray.opacity(0.24))
            .padding(.horizontal, 15)
        }
    }
}

struct ExpandableSearchBar: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    Home()
}



private enum Tab: String, CaseIterable  {
    case all = "all"
    case personal = "Persoanl"
    case office = "Office"
    case community = "Community"
}


struct CustomScrollTargetBehaviour: ScrollTargetBehavior {
    func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
        if target.rect.minY < 70 {
            if target.rect.minY < 35 {
                target.rect.origin = .zero
            } else {
                target.rect.origin = .init(x: 0, y: 70)
            }
        }
    }
}
