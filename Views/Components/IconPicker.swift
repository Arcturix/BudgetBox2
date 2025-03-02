import SwiftUI

struct IconPicker: View {
    @Binding var selectedIcon: String
    @Binding var startMonth: Int
    @Binding var startYear: Int
    
    let icons = [
        "house.fill", "car.fill", "airplane", "cart.fill",
        "creditcard.fill", "gift.fill", "bag.fill",
        "fork.knife", "wineglass.fill", "cup.and.saucer.fill",
        "film.fill", "gamecontroller.fill", "graduationcap.fill",
        "heart.fill", "cross.fill", "pills.fill",
        "dollarsign.circle.fill", "eurosign.circle.fill",
        "sterlingsign.circle.fill", "yensign.circle.fill", "tv.fill",
        
        // BABY/CHILDREN RELATED ICONS
        // iOS 15+
        "figure.2.and.child.holdinghands",
        "figure.wave.circle",
        "figure.wave.circle.fill",
        "figure.child.circle",
        "figure.child.circle.fill",
        "figure.child",

        // iOS 16+
        "birthday.cake",
        "birthday.cake.fill",
        "bubbles.and.sparkles",
        "bubbles.and.sparkles.fill",
        "party.popper",
        "party.popper.fill",
     
        // SAVINGS/MONEY/FINANCE RELATED ICONS
        // iOS 13+
        "banknote",
        "banknote.fill",
        "wallet.pass",
        "wallet.pass.fill",
        "giftcard",
        "giftcard.fill",
        "chart.bar",
        "chart.bar.fill",
        "chart.pie",
        "chart.pie.fill",
        "arrow.up.right",
        "arrow.up.right.circle",
        "arrow.up.right.circle.fill",
        "lock",
        "lock.fill",
        "lock.circle",
        "lock.circle.fill",
        "building.columns",
        "building.columns.fill",
    ]
    
    let columns = [
        GridItem(.adaptive(minimum: 60))
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 15) {
            ForEach(icons, id: \.self) { icon in
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
        .padding(.vertical)
    }
}
