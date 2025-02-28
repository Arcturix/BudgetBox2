import SwiftUI

struct TestPreviewView: View {
    var body: some View {
        ZStack {
            Color.blue.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Test Preview")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Button("Test Button") {
                    print("Button tapped")
                }
                .padding()
                .background(Color.white)
                .foregroundColor(.blue)
                .cornerRadius(10)
            }
        }
    }
}

struct TestPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        TestPreviewView()
    }
}
