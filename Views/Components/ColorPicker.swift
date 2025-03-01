import SwiftUI

struct ColorPickerView: View {
    @Binding var selectedColor: String
    @Binding var startMonth: Int
    @Binding var startYear: Int
    
    let colors = [
        "FF5252", "FF4081", "E040FB", "7C4DFF",
        "536DFE", "448AFF", "40C4FF", "18FFFF",
        "64FFDA", "69F0AE", "B2FF59", "EEFF41",
        "FFFF00", "FFD740", "FFAB40", "FF6E40",
        "8D6E63", "BDBDBD", "78909C"
    ]
    
    let columns = [
        GridItem(.adaptive(minimum: 60))
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 15) {
            ForEach(colors, id: \.self) { color in
                ZStack {
                    Circle()
                        .foregroundColor(Color(hex: color))
                        .frame(width: 40, height: 40)
                    
                    if color == selectedColor {
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 40, height: 40)
                    }
                }
                .onTapGesture {
                    selectedColor = color
                }
            }
        }
        .padding(.vertical)
    }
}
