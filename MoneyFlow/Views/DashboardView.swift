import SwiftUI
import CoreData
import Charts

// MARK: - Main Dashboard View
struct DashboardView: View {
    // MARK: - Core Data Properties
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.date, ascending: false)],
        animation: .default
    ) private var transactions: FetchedResults<Transaction>
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Account.name, ascending: true)],
        animation: .default
    ) private var accounts: FetchedResults<Account>
    
    // MARK: - View States
    @State private var selectedChartPeriod: ChartPeriod = .week
    @State private var showingTransactionSheet = false
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Main Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    TotalBalanceCard(totalBalance: calculateTotalBalance())
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        IncomeCard(amount: calculateMonthlyIncome())
                        ExpenseCard(amount: calculateMonthlyExpenses())
                    }
                    
                    BalanceTrendChart(
                        selectedPeriod: $selectedChartPeriod,
                        chartData: getChartData(),
                        colorScheme: colorScheme
                    )
                    
                    RecentTransactionsSection(transactions: transactions)
                    
                    SpendingAnalyticsSection(
                        categoryData: getCategoryData(),
                        averageSpending: getAverageDailySpending(),
                        topCategory: getTopCategory()
                    )
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .background(Color.systemGroupedBackground.ignoresSafeArea())
        }
    }
    
    // MARK: - Data Calculations
    private func calculateTotalBalance() -> Double {
        accounts.reduce(0) { $0 + $1.balance }
    }
    
    private func calculateMonthlyIncome() -> Double {
        transactions.filter { $0.isIncome && $0.isThisMonth }.reduce(0) { $0 + $1.amount }
    }
    
    private func calculateMonthlyExpenses() -> Double {
        abs(transactions.filter { $0.isExpense && $0.isThisMonth }.reduce(0) { $0 + $1.amount })
    }
    
    private func getChartData() -> [ChartData] {
        let calendar = Calendar.current
        let now = Date()
        var data: [ChartData] = []
        var runningBalance = calculateTotalBalance()
        let sortedTransactions = transactions.sorted { $0.wrappedDate > $1.wrappedDate }
        
        switch selectedChartPeriod {
        case .week:
            for dayOffset in 0..<7 {
                let date = calendar.date(byAdding: .day, value: -dayOffset, to: now)!
                let transactions = sortedTransactions.filter { calendar.isDate($0.wrappedDate, inSameDayAs: date) }
                runningBalance -= transactions.reduce(0) { $0 + $1.amount }
                data.append(ChartData(date: date, balance: runningBalance))
            }
        case .month:
            for dayOffset in 0..<30 {
                let date = calendar.date(byAdding: .day, value: -dayOffset, to: now)!
                let transactions = sortedTransactions.filter { calendar.isDate($0.wrappedDate, inSameDayAs: date) }
                runningBalance -= transactions.reduce(0) { $0 + $1.amount }
                data.append(ChartData(date: date, balance: runningBalance))
            }
        case .year:
            for monthOffset in 0..<12 {
                let date = calendar.date(byAdding: .month, value: -monthOffset, to: now)!
                let transactions = sortedTransactions.filter { calendar.isDate($0.wrappedDate, equalTo: date, toGranularity: .month) }
                runningBalance -= transactions.reduce(0) { $0 + $1.amount }
                data.append(ChartData(date: date, balance: runningBalance))
            }
        }
        return data.reversed()
    }
    
    private func getCategoryData() -> [CategoryData] {
        let expenses = transactions.filter { $0.isExpense }
        let grouped = Dictionary(grouping: expenses) { $0.wrappedCategory }
        let total = expenses.reduce(0) { $0 + abs($1.amount) }
        return grouped.map { key, value in
            let amount = value.reduce(0) { $0 + abs($1.amount) }
            return CategoryData(
                category: key,
                amount: amount,
                percentage: total > 0 ? (amount / total) * 100 : 0
            )
        }.sorted { $0.amount > $1.amount }
    }
    
    private func getAverageDailySpending() -> Double {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let expenses = transactions.filter { $0.isExpense && $0.wrappedDate >= thirtyDaysAgo }
        let total = expenses.reduce(0) { $0 + abs($1.amount) }
        return total / 30
    }
    
    private func getTopCategory() -> (name: String, percentage: Double) {
        let categories = getCategoryData()
        return (categories.first?.category ?? "No Data", categories.first?.percentage ?? 0)
    }
}

// MARK: - Subviews
struct TotalBalanceCard: View {
    let totalBalance: Double
    
    var body: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Total Balance", systemImage: "dollarsign.circle.fill")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(totalBalance.formattedCurrency)
                    .font(.system(.largeTitle, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(totalBalance >= 0 ? .primary : .red)
            }
        }
    }
}

struct IncomeCard: View {
    let amount: Double
    
    var body: some View {
        DashboardCard {
            StatisticTile(
                title: "Income",
                value: amount.formattedCurrency,
                icon: "arrow.down.circle.fill",
                color: .green
            )
        }
    }
}

struct ExpenseCard: View {
    let amount: Double
    
    var body: some View {
        DashboardCard {
            StatisticTile(
                title: "Expenses",
                value: amount.formattedCurrency,
                icon: "arrow.up.circle.fill",
                color: .red
            )
        }
    }
}

struct BalanceTrendChart: View {
    @Binding var selectedPeriod: ChartPeriod
    let chartData: [ChartData]
    let colorScheme: ColorScheme
    
    var body: some View {
        DashboardCard {
            VStack(spacing: 16) {
                HStack {
                    Text("Balance Trend")
                        .font(.headline)
                    
                    Spacer()
                    
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(ChartPeriod.allCases, id: \.self) {
                            Text($0.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                }
                
                Chart(chartData) { data in
                    LineMark(
                        x: .value("Date", data.date),
                        y: .value("Balance", data.balance)
                    )
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .foregroundStyle(colorScheme == .dark ? .blue : .indigo)
                    
                    AreaMark(
                        x: .value("Date", data.date),
                        y: .value("Balance", data.balance)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.indigo.opacity(0.2), .indigo.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: selectedPeriod.calendarComponent)) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: selectedPeriod.dateFormat)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text(formatAmount(amount))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .frame(height: 200)
            }
        }
    }
    // Helper function to format Y-axis values
    private func formatAmount(_ value: Double) -> String {
        if abs(value) >= 1_000_000 {
            return String(format: "%.0fM", value / 1_000_000)
        } else if abs(value) >= 1_000 {
            return String(format: "%.0fK", value / 1_000)
        } else {
            return String(format: "%.0f", value)
        }
    }
}

struct RecentTransactionsSection: View {
    let transactions: FetchedResults<Transaction>
    
    var body: some View {
        DashboardCard {
            VStack(spacing: 12) {
                HStack {
                    Text("Recent Transactions")
                        .font(.headline)
                    
                    Spacer()
                    
                    NavigationLink(destination: TransactionsListView(transactions: groupTransactionsByDate(), searchText: "")) {
                        Text("See All")
                            .font(.subheadline)
                    }
                }
                
                if transactions.isEmpty {
                    EmptyStateView(
                        title: "No Transactions Yet",
                        message: "",
                        systemImage: "empty_transaction"
                    )
                } else {
                    VStack(spacing: 12) {
                        ForEach(transactions.prefix(3)) { transaction in
                            DashboardTransactionRow(transaction: transaction)
                            
                            if transaction != transactions.prefix(3).last {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
    }
    // Helper function to group transactions by date
    private func groupTransactionsByDate() -> [(date: Date, transactions: [Transaction])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: transactions) { transaction in
            calendar.startOfDay(for: transaction.wrappedDate)
        }
        
        return grouped.map { (key, value) in
            (date: key, transactions: value.sorted { $0.wrappedDate > $1.wrappedDate })
        }.sorted { $0.date > $1.date }
    }
}


struct SpendingAnalyticsSection: View {
    let categoryData: [CategoryData]
    let averageSpending: Double
    let topCategory: (name: String, percentage: Double)
    
    var body: some View {
        DashboardCard {
            VStack(spacing: 20) {
                Text("Spending Analytics")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Chart(categoryData) { data in
                    SectorMark(
                        angle: .value("Spending", data.amount),
                        innerRadius: .ratio(0.6),
                        angularInset: 2
                    )
                    .foregroundStyle(by: .value("Category", data.category))
                    .annotation(position: .overlay) {
                        Text("\(Int(data.percentage))%")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                    }
                }
                .frame(height: 200)
                .chartLegend(position: .bottom, alignment: .center)
                
                HStack(spacing: 16) {
                    TrendCard(
                        title: "Daily Average",
                        value: averageSpending.formattedCurrency,
                        trend: "Last 30 days"
                    )
                    
                    TrendCard(
                        title: "Top Category",
                        value: topCategory.name,
                        trend: "\(Int(topCategory.percentage))% of total"
                    )
                }
            }
        }
    }
}

// MARK: - Helper Components
struct DashboardCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.secondarySystemGroupedBackground)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct StatisticTile: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: icon)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            Spacer()
        }
        .foregroundColor(color)
    }
}

struct DashboardTransactionRow: View {
    @ObservedObject var transaction: Transaction
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: transaction.categoryIcon)
                .frame(width: 40, height: 40)
                .background(transaction.categoryColor.opacity(0.2))
                .foregroundColor(transaction.categoryColor)
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.wrappedCategory)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if !transaction.wrappedNote.isEmpty {
                    Text(transaction.wrappedNote)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(transaction.amount.formattedCurrency)
                    .font(.subheadline)
                    .foregroundColor(transaction.isIncome ? .green : .red)
                
                Text(transaction.wrappedDate, format: .dateTime.day().month())
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct TrendCard: View {
    let title: String
    let value: String
    let trend: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text(trend)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.tertiarySystemGroupedBackground)
        .cornerRadius(8)
    }
}

// MARK: - Data Models
struct ChartData: Identifiable {
    let id = UUID()
    let date: Date
    let balance: Double
}

struct CategoryData: Identifiable {
    let id = UUID()
    let category: String
    let amount: Double
    let percentage: Double
}

enum ChartPeriod: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
    
    var calendarComponent: Calendar.Component {
        switch self {
        case .week: return .day
        case .month: return .day
        case .year: return .month
        }
    }
    
    var dateFormat: Date.FormatStyle {
        switch self {
        case .week: return .dateTime.day().month()
        case .month: return .dateTime.day().month()
        case .year: return .dateTime.month(.abbreviated)
        }
    }
}

// MARK: - Extensions
extension Double {
    var formattedCurrency: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self)) ?? ""
    }
}

extension Transaction {
    var wrappedDate: Date { date ?? Date() }
    var wrappedCategory: String { category ?? "Uncategorized" }
    var wrappedNote: String { note ?? "" }
    var isIncome: Bool { amount > 0 }
    var isExpense: Bool { amount < 0 }
    var isThisMonth: Bool {
        Calendar.current.isDate(wrappedDate, equalTo: Date(), toGranularity: .month)
    }
    
    var categoryColor: Color {
        switch wrappedCategory {
        case "Food": return .orange
        case "Transport": return .blue
        case "Entertainment": return .purple
        case "Shopping": return .pink
        case "Utilities": return .green
        default: return .gray
        }
    }
    
    var categoryIcon: String {
        switch wrappedCategory {
        case "Food": return "fork.knife"
        case "Transport": return "car.fill"
        case "Entertainment": return "film"
        case "Shopping": return "cart.fill"
        case "Utilities": return "wrench.fill"
        default: return "questionmark"
        }
    }
}

extension Color {
    static let systemGroupedBackground = Color(UIColor.systemGroupedBackground)
    static let secondarySystemGroupedBackground = Color(UIColor.secondarySystemGroupedBackground)
    static let tertiarySystemGroupedBackground = Color(UIColor.tertiarySystemGroupedBackground)
}

// MARK: - Preview
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
