//
//  CustomListVirw.swift
//  SwiftUIPlayground
//
//  Created by Azharuddin Salahuddin on 26/10/25.
//

import SwiftUI
struct CustomListView<NavBar: View, TopContent: View, Header: View, Content:View>: View {
    @ViewBuilder var navbar:( _ progress: CGFloat) -> NavBar
    @ViewBuilder var topContent:(_ progress: CGFloat, _ safeAreaTop: CGFloat) -> TopContent
    @ViewBuilder var header: ( _ progress: CGFloat) -> Header
    @ViewBuilder var content: Content
    
    // View Properties
    @State private var headerProgress:CGFloat = 0
    @State private var safeAreaTop:CGFloat = 0
    @State private var topContentHeight:CGFloat = 0
    
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        List {
            topContent(headerProgress, safeAreaTop)
                .onGeometryChange(for: CGFloat.self) {
                    $0.size.height
                } action: { newValue in
                    print("Top Content Height: \(newValue)")
                    topContentHeight = newValue
                }
                .customListRow()

            Section {
                content
            } header: {
                header(headerProgress)
                    .foregroundStyle(foregroundColor)
                    .onGeometryChange(for: CGFloat.self, of: { proxy in
                        let minY = topContentHeight == 0 ? 0 : proxy.frame(in: .named("LISTVIEW")).minY
                        print("minY = \(minY)")
                        return minY
                    }, action: { newValue in
                        guard topContentHeight != 0 else { return  }
                        let progress = (newValue - safeAreaTop) / (topContentHeight)
                        let clappedProgress = 1 - max(min(progress, 1), 0)
                        self.headerProgress = clappedProgress
                        print("clappedProgress => \(clappedProgress), topContentHeight = \(topContentHeight)")
                    })
                    .customListRow()
            }
        }
        .listStyle(.plain)
        .listRowSpacing(0)
        .listSectionSpacing(0)
        .coordinateSpace(.named("LISTVIEW"))
        .onGeometryChange(for: CGFloat.self) {
            $0.safeAreaInsets.top
        } action: { newValue in
            self.safeAreaTop = newValue
        }
    }
    
    var foregroundColor: Color {
        switch colorScheme {
        case .dark:
            return .white
        case .light:
            return .black
        @unknown default:
            fatalError()
        }
    }
}

#Preview {
    CustomListCallingView()
}

extension View {
    func customListRow() -> some View {
        self
            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}


struct CustomListCallingView: View  {
    var body: some View {
        CustomListView { progress in
            
        } topContent: { progress, safeAreaTop in
            HeroImage(progress, safeAreaTop)
        } header: { progress in
            HeaderView(progress)
        } content: {
            Rectangle()
                .fill(.clear)
                .frame(height: 800)
        }

    }
    
    @ViewBuilder
    func HeroImage( _ progress:CGFloat,  _ safeAreaTop:CGFloat) -> some View {
        GeometryReader { proxy in
            let minY = proxy.frame(in: .global).minY - safeAreaTop
            let size = proxy.size
            
            let height = size.height + (minY > 0 ? minY : 0)
            Image(.header)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size.width, height: height + safeAreaTop)
                .offset(y: minY > 0 ? -minY : 0)
                .offset(y: -safeAreaTop)
        }
        .frame(height: 250)
    }
    
    
    @ViewBuilder
    func HeaderView( _ progress:CGFloat) -> some View {
        VStack(alignment: .leading)  {
             Text("Apple Foods")
                .font(.title2.bold())
                .frame(height: 35)
            
            HStack {
                Image(systemName: "star.fill")
                    .font(.caption)
                
                Text("4.7")
                    .font(.callout)
                
                Image(systemName: "clock")
                    .font(.system(size: 15, weight: .semibold))
                    .padding(.leading, 10)
                Spacer()
                
                Text("30 - 40 minutes")
                    .font(.callout)
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            let backgroundProgress = max(progress - 0.8, 0) * 5
            Rectangle()
                .fill(.background)
                .padding(.top, backgroundProgress * -100)
                .shadow(color: .gray.opacity(backgroundProgress * 0.3), radius: 5, x: 0, y: 2)
        }
    }
}

