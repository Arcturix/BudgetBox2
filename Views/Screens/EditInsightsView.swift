// Views/Screens/EditInsightsView.swift

import SwiftUI

struct EditInsightsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: BudgetViewModel
    
    // MARK: - UI Constants
    private let backgroundColor = Color(hex: "383C51")
    private let cardBackground = Color(hex: "282C3E")
    private let accentColor = Color(hex: "A169F7")
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Choose up to \(viewModel.maxInsights) insights to display on your home screen.")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                            .padding(.horizontal)
                        
                        Text("Selected: \(viewModel.selectedInsights.count)/\(viewModel.maxInsights)")
                            .foregroundColor(viewModel.selectedInsights.count == viewModel.maxInsights ? .orange : .gray)
                            .font(.caption)
                            .padding(.horizontal)
                    }
                    .padding(.top)
                    
                    // Available insights
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(InsightType.allCases) { insight in
                                insightSelectionRow(insight: insight)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Edit Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        viewModel.saveSelectedInsights()
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    private func insightSelectionRow(insight: InsightType) -> some View {
        let isSelected = viewModel.isInsightSelected(insight)
        let isSelectable = isSelected || viewModel.selectedInsights.count < viewModel.maxInsights
        
        return Button(action: {
            if isSelectable || isSelected {
                viewModel.toggleInsight(insight)
            }
        }) {
            HStack {
                // Icon with color background
                ZStack {
                    Circle()
                        .fill(Color(hex: insight.defaultColor).opacity(0.3))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: insight.icon)
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                }
                
                // Title
                Text(insight.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? accentColor : (isSelectable ? Color.gray.opacity(0.6) : Color.gray.opacity(0.3)))
                    .font(.title3)
            }
            .padding()
            .background(cardBackground)
            .cornerRadius(12)
            .opacity(isSelectable ? 1.0 : 0.5)
        }
        .disabled(!isSelectable && !isSelected)
    }
}

#Preview {
    let viewModel = BudgetViewModel()
    viewModel.selectedInsights = [.savingsRate, .essentialExpenses]
    
    return EditInsightsView()
        .environmentObject(viewModel)
        .preferredColorScheme(.dark)
}
