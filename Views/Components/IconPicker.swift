// Views/Components/IconPicker.swift

import SwiftUI

struct IconPicker: View {
    @Binding var selectedIcon: String
    // These properties might not always be needed
    @Binding var startMonth: Int
    @Binding var startYear: Int
    
    // Organize icons by category for better maintainability
    private struct IconCategory {
        let name: String
        let icons: [String]
    }
    
    // Categorized icons
    private let categories: [IconCategory] = [
        IconCategory(name: "Finance", icons: [
            "dollarsign.circle.fill", "eurosign.circle.fill",
            "sterlingsign.circle.fill", "yensign.circle.fill",
            "banknote", "banknote.fill", "creditcard.fill",
            "chart.bar", "chart.bar.fill", "chart.pie", "chart.pie.fill"
        ]),
        IconCategory(name: "Home", icons: [
            "house.fill", "bed.double.fill", "tv.fill", "sofa.fill"
        ]),
        IconCategory(name: "Food", icons: [
            "fork.knife", "cup.and.saucer.fill", "wineglass.fill"
        ]),
        IconCategory(name: "Travel", icons: [
            "car.fill", "airplane", "bus.fill", "tram.fill"
        ]),
        IconCategory(name: "Shopping", icons: [
            "cart.fill", "bag.fill", "gift.fill", "tag.fill"
        ]),
        IconCategory(name: "Health", icons: [
            "heart.fill", "cross.fill", "pills.fill", "stethoscope"
        ]),
        IconCategory(name: "Education", icons: [
            "graduationcap.fill", "book.fill", "pencil"
        ]),
        IconCategory(name: "Entertainment", icons: [
            "gamecontroller.fill", "film.fill", "music.note"
        ])
    ]
    
    // Flattened list of all icons for backward compatibility
    private var allIcons: [String] {
        categories.flatMap { $0.icons }
    }
    
    // Simplified initializer for when only icon is needed
    init(selectedIcon: Binding<String>) {
        self._selectedIcon = selectedIcon
        // Use dummy bindings for month/year that aren't used
        self._startMonth = .constant(1)
        self._startYear = .constant(Calendar.current.component(.year, from: Date()))
    }
    
    // Full initializer when all properties are needed
    init(selectedIcon: Binding<String>, startMonth: Binding<Int>, startYear: Binding<Int>) {
        self._selectedIcon = selectedIcon
        self._startMonth = startMonth
        self._startYear = startYear
    }
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 15) {
            ForEach(allIcons, id: \.self) { icon in
                iconCircle(for: icon)
            }
        }
        .padding(.vertical)
    }
    
    private func iconCircle(for icon: String) -> some View {
        ZStack {
            Circle()
                .foregroundColor(icon == selectedIcon ? .blue.opacity(0.2) : .gray.opacity(0.1))
                .frame(width: 50, height: 50)
            
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(icon == selectedIcon ? .blue : .gray)
        }
        .onTapGesture {
            selectedIcon = icon
        }
    }
}
