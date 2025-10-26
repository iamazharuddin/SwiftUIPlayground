import SwiftUI

struct PlayGround: View {
    var body: some View {
        VStack {
            Spacer()
            SLideView()
        }
    }
}

#Preview {
    PlayGround()
}



struct SLideView: View {
    
    @State private var offsetX : CGFloat = 0
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            ZStack(alignment: .leading) {
                UnevenRoundedRectangle(topLeadingRadius: 25, bottomLeadingRadius: 25, bottomTrailingRadius: 25, topTrailingRadius: 25, style: .continuous)
                    .fill(Color.gray)
                
                let knobSize : CGFloat = size.height
                let extraWidth  =  size.width - knobSize
                let progress = offsetX / extraWidth
                confirmationView()
                    .frame(width: knobSize + extraWidth * progress, height: knobSize)
                knowView(size, progress)
            }
        }
        .frame(width: 300)
        .frame(height: 50)
    }
    
    func knowView(  _ size: CGSize,  _ progress: CGFloat) -> some View {
         Circle()
            .fill(Color.green.opacity(0.5))
            .frame(width: size.height, height: size.height)
            .overlay {
                ZStack  {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 20))
                        .fontWeight(.bold)
                        .foregroundStyle(Color.white)
                        .opacity(1 - progress)
                        .blur(radius: 5 * progress)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 20))
                        .fontWeight(.bold)
                        .foregroundStyle(Color.white)
                        .opacity(progress)
                        .blur(radius: 5 * (1-progress))
                    
                }
            }
            .offset(x: offsetX)
            .gesture(
                DragGesture()
                    .onChanged({ value in
                        let maxWidth = size.width - size.height
                        offsetX =  max(min(value.translation.width, maxWidth), 0)
                    })
                    .onEnded({ value in
                        let maxWidth = size.width - size.height
                        if offsetX == maxWidth  {
                            print("Slide completed")
                        } else {
                            offsetX = 0
                        }
                    })
            )
    }
    
    func confirmationView() -> some View {
         RoundedRectangle(cornerRadius: 25)
            .fill(Color.green)
    }
}
