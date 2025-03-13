// Views/Components/ColorPicker.swift

import SwiftUI

struct ColorPickerView: View {
    @Binding var selectedColor: String
    // These properties might not always be needed
    @Binding var startMonth: Int
    @Binding var startYear: Int
    
    // Default colors palette
    let colors = [
        "FF5252", "FF4081", "E040FB", "7C4DFF",
        "536DFE", "448AFF", "40C4FF", "18FFFF",
        "64FFDA", "69F0AE", "B2FF59", "EEFF41",
        "FFFF00", "FFD740", "FFAB40", "FF6E40",
        "8D6E63", "BDBDBD", "78909C"
    ]
    
    // Simplified initializer for when only color is needed
    init(selectedColor: Binding<String>) {
        self._selectedColor = selectedColor
        // Use dummy bindings for month/year that aren't used
        self._startMonth = .constant(1)
        self._startYear = .constant(Calendar.current.component(.year, from: Date()))
    }
    
    // Full initializer when all properties are needed
    init(selectedColor: Binding<String>, startMonth: Binding<Int>, startYear: Binding<Int>) {
        self._selectedColor = selectedColor
        self._startMonth = startMonth
        self._startYear = startYear
    }
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 15) {
            ForEach(colors, id: \.self) { color in
                colorCircle(for: color)
            }
        }
        .padding(.vertical)
    }
    
    private func colorCircle(for color: String) -> some View {
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
