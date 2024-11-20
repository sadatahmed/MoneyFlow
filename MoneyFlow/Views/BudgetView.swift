import SwiftUI
import CoreData

struct BudgetView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Budget.category, ascending: true)],
        animation: .default)
    private var budgets: FetchedResults<Budget>
    
    @State private var showingAddBudget = false
    @State private var selectedBudget: Budget?
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Total Budget Overview
                    BudgetOverviewCard(budgets: budgets)
                        .padding(.horizontal)
                    
                    // Budget List
                    LazyVStack(spacing: 12) {
                        ForEach(budgets) { budget in
                            BudgetRow(budget: budget)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3)) {
                                        if selectedBudget == budget {
                                            selectedBudget = nil
                                        } else {
                                            selectedBudget = budget
                                        }
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Budgets")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddBudget = true }) {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showingAddBudget) {
                AddBudgetView()
            }
        }
    }
}

struct BudgetOverviewCard: View {
    let budgets: FetchedResults<Budget>
    @Environment(\.colorScheme) private var colorScheme
    
    private var totalBudget: Double {
        budgets.reduce(0) { $0 + $1.limit }
    }
    
    private var totalSpent: Double {
        budgets.reduce(0) { $0 + $1.spent }
    }
    
    private var overallProgress: Double {
        guard totalBudget > 0 else { return 0 }
        return totalSpent / totalBudget
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Budget")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("$\(totalBudget, specifier: "%.2f")")
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                CircularProgressView(progress: overallProgress)
                    .frame(width: 50, height: 50)
            }
            
            Divider()
            
            HStack {
                Label {
                    Text("Spent")
                        .foregroundStyle(.secondary)
                } icon: {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundStyle(.red)
                }
                
                Spacer()
                
                Text("$\(totalSpent, specifier: "%.2f")")
                    .fontWeight(.medium)
            }
            .font(.subheadline)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemBackground))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color(.separator).opacity(0.1), lineWidth: 1)
        }
        .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.05), radius: 10)
    }
}

struct BudgetRow: View {
    @ObservedObject var budget: Budget
    @Environment(\.colorScheme) var colorScheme
    
    var progress: Double {
        guard budget.limit > 0 else { return 0 }
        return budget.spent / budget.limit
    }
    
    var progressColor: Color {
        if progress >= 1.0 {
            return .red
        } else if progress >= 0.8 {
            return .orange
        } else if progress >= 0.6 {
            return .yellow
        }
        return .blue
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack(spacing: 12) {
                // Category Icon
                ZStack {
                    Circle()
                        .fill(getCategoryColor())
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: getCategoryIcon())
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(budget.category ?? "Unknown")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(budget.period?.capitalized ?? "")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Progress Circle
                CircularProgressView(progress: progress, color: progressColor)
                    .frame(width: 40, height: 40)
            }
            
            // Progress Details
            VStack(spacing: 8) {
                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(height: 8)
                        
                        Rectangle()
                            .fill(progressColor)
                            .frame(width: geometry.size.width * progress, height: 8)
                    }
                    .clipShape(Capsule())
                }
                .frame(height: 8)
                
                // Amount Details
                HStack {
                    Text("$\(budget.spent, specifier: "%.2f") spent")
                    Spacer()
                    Text("of $\(budget.limit, specifier: "%.2f")")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            
            // Warning Label if needed
            if progress >= 0.8 {
                HStack {
                    Image(systemName: progress >= 1.0 ? "exclamationmark.circle.fill" : "exclamationmark.triangle.fill")
                    Text(progress >= 1.0 ? "Budget exceeded!" : "Approaching limit!")
                }
                .font(.caption)
                .foregroundStyle(progressColor)
                .padding(.top, 4)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemBackground))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color(.separator).opacity(0.1), lineWidth: 1)
        }
        .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.05), radius: 10)
    }
    
    private func getCategoryColor() -> Color {
        switch budget.category {
        case "Food": return .orange
        case "Transport": return .blue
        case "Entertainment": return .purple
        case "Shopping": return .green
        case "Bills": return .red
        default: return .gray
        }
    }
    
    private func getCategoryIcon() -> String {
        switch budget.category {
        case "Food": return "fork.knife"
        case "Transport": return "car.fill"
        case "Entertainment": return "tv.fill"
        case "Shopping": return "cart.fill"
        case "Bills": return "doc.text.fill"
        default: return "questionmark"
        }
    }
}

struct CircularProgressView: View {
    let progress: Double
    var color: Color = .blue
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    Color(.systemGray5),
                    lineWidth: 4
                )
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: 4,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut, value: progress)
            
            Text("\(Int(progress * 100))%")
                .font(.system(.caption2, design: .rounded))
                .fontWeight(.medium)
        }
    }
} 
