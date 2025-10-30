import SwiftUI

struct SkeletonViewNew<S:Shape>: View {
    let shape: S
    @State var isAnimation: Bool = false
    var body: some View {
        shape
            .fill(Color.gray.opacity(0.5))
            .overlay {
                GeometryReader {
                    let size = $0.size
                    Rectangle()
                    
                        .frame(width: size.width / 2, height: size.height * 2)
                        .offset(y: -size.height / 2)
                        .offset(x: isAnimation ? size.width * 5 : -size.width * 1.1)
                        .blur(radius: size.width / 2)
                        .blendMode(.softLight)
                }
            }
            .mask(shape)
            .onAppear() {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false)) {
                    isAnimation = true
                }
            }
    }
}

#Preview {
    PlayGround()
}


struct PlayGround: View {
    var body: some View {
        VStack {
            shimmerView
            shimmerView
            shimmerView
            shimmerView
        }
    }
    
    var shimmerView: some View {
        HStack {
            SkeletonViewNew(
                shape: Circle()
            )
            .frame(
                width: 50,
                height: 50
            )
            VStack {
                SkeletonViewNew(
                    shape: RoundedRectangle(cornerRadius: 0)
                )
                .frame(
                    height: 40
                )
                .frame(maxWidth: .infinity)
                
                SkeletonViewNew(
                    shape: RoundedRectangle(cornerRadius: 0)
                )
                .frame(
                    height: 8
                )
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 24)
    }
}


