import SwiftUI

struct PlayGround: View {
    @State private var offset:CGFloat = 0
    var body: some View {
        GeometryReader { proxy  in
            let safeAreaTop = proxy.safeAreaInsets.top
            ScrollView {
                VStack {
                    HeaderView(safeAreaTop)
                        .offset(y: -offset  - safeAreaTop)
                        .zIndex(1)
                    VStack {
                        ForEach(1...10, id:\.self) { _ in
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(.blue.gradient)
                                .frame(height: 220)
                        }
                    }
                    .padding(15)
                    .zIndex(0)
                }
                .offsetX(coordinateSpace: "SCROLL") { offset in
                    print(offset)
                    self.offset = offset
                }
            }
            .ignoresSafeArea(.container, edges: .top)
            .coordinateSpace(name: "SCROLL")
        }
    }
    
    @ViewBuilder
    func HeaderView(_ safeAreaTop: CGFloat) -> some View {
        VStack {
            HStack(spacing: 15) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.white)
                    TextField("Search", text: .constant("Search Here"))
                        .tint(.red)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 15)
                .background {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.black)
                        .opacity(0.15)
                }
            }
        }
        .padding(.top, safeAreaTop + 10)
        .background {
            Rectangle().fill(Color.red.gradient)
        }
    }
}

#Preview {
    PlayGround()
}



struct OffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}


private extension View {
    func offsetX(coordinateSpace: String, completion: @escaping (CGFloat) -> Void) -> some View {
        self
            .overlay {
                GeometryReader { proxy in
                    let minY = proxy.frame(in: .named("SCROLL")).minY
                    Color.clear
                        .preference(key: OffsetKey.self, value: minY)
                        .onPreferenceChange(OffsetKey.self) { value in
                            completion(value)
                        }
                }
            }
    }
}
