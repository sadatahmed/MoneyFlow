import SwiftUI
import CoreData

// MARK: - Main Budget View
struct BudgetView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingAddBudget = false
    @State private var selectedBudget: Budget?
    @State private var isRefreshing = false
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Budget.category, ascending: true)],
        animation: .default
    ) private var budgets: FetchedResults<Budget>
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                // Adaptive background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        BudgetSummaryView(budgets: budgets)
                            .padding(.horizontal)
                            .padding(.top, 24)
                        
                        LazyVStack(spacing: 20) {
                            ForEach(budgets) { budget in
                                ModernBudgetCard(budget: budget)
                                    .padding(.horizontal)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.bottom, 80)
                    }
                }
                .overlay {
                    if budgets.isEmpty {
                        EmptyStateView(title: "", message: "", systemImage: "")
                    }
                }
                
                // Floating action button
                FloatingAddButton {
                    withAnimation(.spring()) {
                        showingAddBudget.toggle()
                    }
                }
                .padding()
            }
            .navigationTitle("Budget")
//            .overlay {
//                if budgets.isEmpty {
//                    ModernEmptyState()
//                }
//            }
            .sheet(isPresented: $showingAddBudget) {
                AddBudgetView()
                    .presentationDetents([.large, .medium])
                    .presentationCornerRadius(24)
                    .presentationBackground(.ultraThinMaterial)
            }
        }
    }
}

// MARK: - Modern Components
struct AnimatedRingChart: View {
    let progress: Double
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 12)
                .foregroundColor(Color.primary.opacity(0.1))
            
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        colors: [.blue, .purple, .pink],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: .blue.opacity(0.1), radius: 12)
            
            Text(animatedProgress.isFinite && !animatedProgress.isNaN ? "\(Int(animatedProgress * 100))%" : "0%")
                .font(.title3)
                .fontWeight(.bold)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { newValue in
            withAnimation(.easeInOut(duration: 1)) {
                animatedProgress = newValue
            }
        }
    }
}

struct FloatingAddButton: View {
    let action: () -> Void
    @State private var isPulsing = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .padding(20)
                .background(
                    Circle()
                        .fill(
                            AngularGradient(
                                colors: [.blue, .purple],
                                center: .center
                            )
                        )
                        .shadow(color: .blue.opacity(0.3), radius: 16)
                )
        }
        .scaleEffect(isPulsing ? 1.1 : 1)
        .animation(
            .easeInOut(duration: 1).repeatForever(autoreverses: true),
            value: isPulsing
        )
        .onAppear { isPulsing = true }
    }
}

// MARK: - Modern Budget Summary
struct BudgetSummaryView: View {
    @Environment(\.colorScheme) private var colorScheme
    let budgets: FetchedResults<Budget>
    
    private var totalBudget: Double { budgets.sum(of: \.limit) }
    private var totalSpent: Double { budgets.sum(of: \.spent) }
    private var remaining: Double { totalBudget - totalSpent }
    
    // Define background colors based on color scheme
    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color(.secondarySystemBackground)
            : Color(.systemBackground) // Or use Color(.tertiarySystemBackground) for more contrast
    }
    
    private var shadowColor: Color {
        colorScheme == .dark
            ? .clear
            : .black.opacity(0.05)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            HStack {
                AnimatedRingChart(progress: totalSpent / totalBudget)
                    .frame(width: 120, height: 120)
                
                VStack(alignment: .leading, spacing: 16) {
                    BudgetMetricView(
                        title: "Total Budget",
                        value: totalBudget.currencyFormat,
                        color: .blue
                    )
                    
                    BudgetMetricView(
                        title: "Spent",
                        value: totalSpent.currencyFormat,
                        color: .orange
                    )
                    
                    BudgetMetricView(
                        title: "Remaining",
                        value: remaining.currencyFormat,
                        color: .green
                    )
                }
                .padding(.leading, 8)
            }
            
            HStack {
                StatsPill(
                    icon: "chart.pie.fill",
                    value: budgets.count.formatted() + " Categories",
                    color: .purple
                )
                
                StatsPill(
                    icon: "clock.arrow.circlepath",
                    value: {
                        guard totalBudget > 0 else { return "0% Used" }
                        let percentage = (totalSpent / totalBudget) * 100
                        guard percentage.isFinite else { return "0% Used" }
                        return "\(Int(percentage))% Used"
                    }(),
                    color: .blue
                )
            }
        }
        .padding(.horizontal, 35)
        .padding(.vertical, 25)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(backgroundColor)
                .shadow(
                    color: shadowColor,
                    radius: 16,
                    x: 0,
                    y: 8
                )
        )
    }
}

// MARK: - Modern Budget Card (Fixed)
struct ModernBudgetCard: View {
    @ObservedObject var budget: Budget
    @Environment(\.colorScheme) private var colorScheme
    @State private var isExpanded = false
    @State private var showDeleteConfirmation = false
    
    private var progress: Double { budget.limit > 0 ? budget.spent / budget.limit : 0 }
    private var remaining: Double { budget.limit - budget.spent }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header Section
            HStack(spacing: 12) {
                GradientIconView(category: budget.category ?? "other")
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(budget.category ?? "Uncategorized")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Remaining: \(remaining.currencyFormat)")
                        .font(.caption)
                        .foregroundColor(progress >= 1 ? .red : .secondary)
                }
                
                Spacer()
                
                ExpandButton(isExpanded: $isExpanded)
            }
            
            // Progress Indicator
            DynamicProgressBar(value: progress)
                .frame(height: 8)
            
            // Quick Stats
            HStack {
                BudgetStatItem(title: "SPENT", value: budget.spent.currencyFormat)
                Spacer()
                BudgetStatItem(title: "LIMIT", value: budget.limit.currencyFormat)
                Spacer()
                BudgetStatItem(title: "DAYS LEFT", value: "22")
            }
            .padding(.bottom, 8)
            
            // Expanded Details
            if isExpanded {
                VStack(spacing: 16) {
                    Divider()
                        .background(Color.primary.opacity(0.1))
                    
                    HStack {
                        InfoPill(title: "Daily Average",
                               value: (budget.spent / 30).currencyFormat)
                        Spacer()
                        InfoPill(title: "Projected",
                               value: (budget.spent * 1.1).currencyFormat)
                    }
                    
                    // Delete Button
                    Button {
                        showDeleteConfirmation.toggle()
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                                .font(.system(size: 14, weight: .bold))
                            Text("Delete Budget")
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                colors: [Color.red, Color.orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.2 : 0.1),
                      radius: 12, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .confirmationDialog("Delete Budget", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) { deleteBudget() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this budget?")
        }
    }
    
    private func deleteBudget() {
        // Core Data deletion logic
        print("Deleting budget: \(budget.category ?? "Unknown")")
    }
}

// MARK: - Custom Components
struct GradientIconView: View {
    let category: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        let (icon, colors) = iconData(for: category)
        
        return Image(systemName: icon)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: 40, height: 40)
            .background(
                LinearGradient(
                    colors: colors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: colors[0].opacity(colorScheme == .dark ? 0.4 : 0.3),
                  radius: 8, x: 0, y: 4)
    }
    
    private func iconData(for category: String) -> (String, [Color]) {
        switch category.lowercased() {
        case "food": return ("fork.knife", [.orange, .yellow])
        case "transport": return ("car.fill", [.blue, .mint])
        case "entertainment": return ("film", [.indigo, .purple])
        case "shopping": return ("bag.fill", [.pink, .purple])
        case "bills": return ("doc.text.fill", [.green, .teal])
        default: return ("tag.fill", [.gray, .gray])
        }
    }
}

struct ExpandButton: View {
    @Binding var isExpanded: Bool
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                isExpanded.toggle()
            }
        } label: {
            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.secondary)
                .padding(8)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct DynamicProgressBar: View {
    let value: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .frame(width: geometry.size.width, height: 8)
                    .foregroundColor(Color.primary.opacity(0.1))
                
                Capsule()
                    .frame(width: min(CGFloat(value) * geometry.size.width, geometry.size.width), height: 8)
                    .foregroundStyle(progressGradient)
                    .shadow(color: progressColor.opacity(0.2), radius: 4, x: 0, y: 2)
            }
        }
    }
    
    private var progressColor: Color {
        switch value {
        case 1...: return .red
        case 0.8..<1: return .orange
        default: return .blue
        }
    }
    
    private var progressGradient: LinearGradient {
        LinearGradient(
            colors: [progressColor, progressColor.opacity(0.8)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

struct BudgetStatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
        }
    }
}

struct InfoPill: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 35)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemBackground))
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: 8,
                    x: 0,
                    y: 2
                )
        )
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct InfoBadge: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.footnote)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.tertiarySystemBackground))
        )
    }
}

// MARK: - Modern Empty State (Fixed)
struct ModernEmptyState: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack(alignment: .bottomTrailing, content: {
            // Background and main content
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .padding()
                    .background(
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                    )
                
                VStack(spacing: 12) {
                    Text("No Budgets Created")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Start by creating a new budget to manage your expenses effectively")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 40)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
        })
    }
}

// MARK: - Helper Views (Updated for Dark Mode)
struct BudgetMetricView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 4, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
        }
    }
}

struct StatsPill: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(color.opacity(0.1))
        )
    }
}

struct CategoryIconView: View {
    let category: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        let (icon, color) = iconData(for: category)
        
        return Image(systemName: icon)
            .font(.system(size: 18))
            .foregroundColor(.white)
            .padding(12)
            .background(
                Circle()
                    .fill(color)
                    .shadow(color: color.opacity(colorScheme == .dark ? 0.3 : 0.2), radius: 8)
            )
    }
    
    private func iconData(for category: String) -> (String, Color) {
        switch category.lowercased() {
        case "food": return ("fork.knife", .orange)
        case "transport": return ("car.fill", .blue)
        case "entertainment": return ("film", .purple)
        case "shopping": return ("bag.fill", .pink)
        case "bills": return ("doc.text.fill", .green)
        default: return ("tag.fill", .gray)
        }
    }
}

// MARK: - Extensions
extension FetchedResults where Result == Budget {
    func sum(of keyPath: KeyPath<Budget, Double>) -> Double {
        reduce(0) { $0 + $1[keyPath: keyPath] }
    }
}

extension Double {
    var currencyFormat: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: self)) ?? "$0.00"
    }
}

// MARK: - Preview
//struct BudgetView_Previews: PreviewProvider {
//    static var previews: some View {
//        BudgetView()
//    }
//}
