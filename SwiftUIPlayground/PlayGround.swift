import SwiftUI
struct PracticeView: View {
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "person")
                Text("hellow world !")
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .padding(.top, safeAreaInset.top)
            .background {
                Rectangle()
                    .fill(.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
            }
            Spacer()
        }
        .ignoresSafeArea()
    }
    
    var safeAreaInset: UIEdgeInsets {
        return (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.keyWindow?.safeAreaInsets ?? .zero
    }
}

#Preview {
    PracticeView()
}
