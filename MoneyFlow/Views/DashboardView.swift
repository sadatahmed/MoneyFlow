import SwiftUI
import CoreData
import Charts

struct DashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.date, ascending: false)],
        animation: .default)
    private var transactions: FetchedResults<Transaction>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Account.name, ascending: true)],
        animation: .default)
    private var accounts: FetchedResults<Account>
    
    @State private var selectedChartPeriod = "week"
    private let chartPeriods = ["week", "month", "year"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Total Balance Card
                    DashboardCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Total Balance", systemImage: "creditcard.fill")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Text("$\(calculateTotalBalance(), specifier: "%.2f")")
                                .font(.system(.title, design: .rounded))
                                .bold()
                                .foregroundStyle(calculateTotalBalance() >= 0 ? .primary : Color.red)
                        }
                    }
                    
                    // Monthly Overview
                    HStack(spacing: 16) {
                        // Income Card
                        DashboardCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Income", systemImage: "arrow.down.circle.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                Text("$\(calculateMonthlyIncome(), specifier: "%.2f")")
                                    .font(.system(.title3, design: .rounded))
                                    .bold()
                                    .foregroundStyle(.green)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Expenses Card
                        DashboardCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Expenses", systemImage: "arrow.up.circle.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                Text("$\(abs(calculateMonthlyExpenses()), specifier: "%.2f")")
                                    .font(.system(.title3, design: .rounded))
                                    .bold()
                                    .foregroundStyle(.red)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Recent Transactions
                    DashboardCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Recent Transactions", systemImage: "clock.fill")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            if transactions.isEmpty {
                                HStack {
                                    Spacer()
                                    VStack(spacing: 8) {
                                        Image(systemName: "tray.fill")
                                            .font(.title)
                                            .foregroundStyle(.secondary)
                                        Text("No transactions yet")
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 20)
                                    Spacer()
                                }
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(Array(transactions.prefix(3))) { transaction in
                                        DashboardTransactionRow(transaction: transaction)
                                        if transaction != transactions.prefix(3).last {
                                            Divider()
                                                .background(Color(.separator))
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Analytics Section
                    DashboardCard {
                        VStack(alignment: .leading, spacing: 16) {
                            // Header
                            HStack {
                                HStack(spacing: 8) {
                                    Image(systemName: "chart.xyaxis.line")
                                    Text("Balance Trend")
                                }
                                .font(.headline)
                                
                                Spacer()
                                
                                Menu {
                                    ForEach(chartPeriods, id: \.self) { period in
                                        Button(period.capitalized) {
                                            selectedChartPeriod = period
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(selectedChartPeriod.capitalized)
                                            .foregroundStyle(.blue)
                                        Image(systemName: "chevron.down")
                                            .foregroundStyle(.blue)
                                            .font(.caption)
                                    }
                                }
                            }
                            
                            // Balance Chart
                            Chart {
                                ForEach(getChartData(), id: \.date) { data in
                                    LineMark(
                                        x: .value("Date", data.date),
                                        y: .value("Balance", data.balance)
                                    )
                                    .foregroundStyle(Color.blue)
                                    .interpolationMethod(.catmullRom)
                                    
                                    AreaMark(
                                        x: .value("Date", data.date),
                                        y: .value("Balance", data.balance)
                                    )
                                    .foregroundStyle(
                                        .linearGradient(
                                            colors: [
                                                Color.blue.opacity(0.2),
                                                Color.blue.opacity(0.05)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                }
                            }
                            .frame(height: 180)
                            .chartYAxis {
                                AxisMarks(position: .leading) { value in
                                    if let balance = value.as(Double.self) {
                                        AxisGridLine()
                                            .foregroundStyle(Color.gray.opacity(0.1))
                                        AxisValueLabel {
                                            Text("\(formatAxisValue(balance))K")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                            .chartXAxis {
                                AxisMarks { value in
                                    if let date = value.as(Date.self) {
                                        AxisGridLine()
                                            .foregroundStyle(Color.gray.opacity(0.1))
                                        AxisValueLabel {
                                            Text(formatDate(date))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                            
                            // Spending by Category
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Spending by Category")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                Chart(getCategoryData(), id: \.category) { data in
                                    SectorMark(
                                        angle: .value("Amount", abs(data.amount)),
                                        innerRadius: .ratio(0.618),
                                        angularInset: 1.5
                                    )
                                    .foregroundStyle(by: .value("Category", data.category))
                                    .annotation(position: .overlay) {
                                        Text(data.percentage)
                                            .font(.caption2)
                                            .foregroundStyle(.white)
                                    }
                                }
                                .frame(height: 200)
                                .chartLegend(position: .bottom)
                            }
                            
                            // Trends
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Trends")
                                    .font(.headline)
                                
                                HStack(spacing: 16) {
                                    TrendCard(
                                        title: "Avg. Daily Spending",
                                        value: getAverageDailySpending(),
                                        trend: getDailySpendingTrend()
                                    )
                                    
                                    TrendCard(
                                        title: "Most Spent On",
                                        value: getTopCategory().0,
                                        trend: String(format: "%.1f%%", getTopCategory().1)
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .navigationTitle("Dashboard")
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
    }
    
    private func calculateTotalBalance() -> Double {
        // Sum of all account balances
        return accounts.reduce(0) { $0 + $1.balance }
    }
    
    private func calculateMonthlyIncome() -> Double {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        return transactions
            .filter { transaction in
                guard let date = transaction.date else { return false }
                return date >= startOfMonth && date <= endOfMonth && transaction.amount > 0
            }
            .reduce(0) { $0 + $1.amount }
    }
    
    private func calculateMonthlyExpenses() -> Double {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        return transactions
            .filter { transaction in
                guard let date = transaction.date else { return false }
                return date >= startOfMonth && date <= endOfMonth && transaction.amount < 0
            }
            .reduce(0) { $0 + $1.amount }
    }
    
    // Helper methods for chart data
    private func getChartData() -> [ChartData] {
        let calendar = Calendar.current
        let now = Date()
        var chartData: [ChartData] = []
        var runningBalance = calculateTotalBalance()
        
        // Get all transactions sorted by date
        let sortedTransactions = transactions.sorted {
            ($0.date ?? Date()) > ($1.date ?? Date())
        }
        
        switch selectedChartPeriod {
        case "week":
            // Last 7 days data
            for day in 0..<7 {
                let date = calendar.date(byAdding: .day, value: -day, to: now)!
                let dayStart = calendar.startOfDay(for: date)
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
                
                // Calculate balance for this day
                let dayTransactions = sortedTransactions.filter { transaction in
                    guard let transactionDate = transaction.date else { return false }
                    return transactionDate >= dayStart && transactionDate < dayEnd
                }
                
                // Subtract the day's transactions from running balance
                for transaction in dayTransactions {
                    runningBalance -= transaction.amount
                }
                
                let dayData = getDataForDate(date)
                chartData.append(ChartData(
                    date: date,
                    balance: runningBalance,
                    income: dayData.income,
                    expenses: dayData.expenses
                ))
            }
            
        case "month":
            // Last 30 days data
            for day in 0..<30 {
                let date = calendar.date(byAdding: .day, value: -day, to: now)!
                let dayStart = calendar.startOfDay(for: date)
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
                
                let dayTransactions = sortedTransactions.filter { transaction in
                    guard let transactionDate = transaction.date else { return false }
                    return transactionDate >= dayStart && transactionDate < dayEnd
                }
                
                for transaction in dayTransactions {
                    runningBalance -= transaction.amount
                }
                
                let dayData = getDataForDate(date)
                chartData.append(ChartData(
                    date: date,
                    balance: runningBalance,
                    income: dayData.income,
                    expenses: dayData.expenses
                ))
            }
            
        case "year":
            // Last 12 months data
            for month in 0..<12 {
                let date = calendar.date(byAdding: .month, value: -month, to: now)!
                let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
                let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!
                
                let monthTransactions = sortedTransactions.filter { transaction in
                    guard let transactionDate = transaction.date else { return false }
                    return transactionDate >= monthStart && transactionDate < monthEnd
                }
                
                for transaction in monthTransactions {
                    runningBalance -= transaction.amount
                }
                
                let monthData = getDataForDate(date, groupBy: .month)
                chartData.append(ChartData(
                    date: date,
                    balance: runningBalance,
                    income: monthData.income,
                    expenses: monthData.expenses
                ))
            }
            
        default:
            break
        }
        
        return chartData.reversed()
    }
    
    private func getDataForDate(_ date: Date, groupBy: Calendar.Component = .day) -> ChartData {
        let calendar = Calendar.current
        let dateInterval = calendar.dateInterval(of: groupBy, for: date)!
        
        let dayTransactions = transactions.filter { transaction in
            guard let transactionDate = transaction.date else { return false }
            return calendar.isDate(transactionDate, equalTo: date, toGranularity: groupBy)
        }
        
        let income = dayTransactions
            .filter { $0.amount > 0 }
            .reduce(0) { $0 + $1.amount }
        
        let expenses = abs(dayTransactions
            .filter { $0.amount < 0 }
            .reduce(0) { $0 + $1.amount })
        
        // Calculate balance for this date
        let balance = dayTransactions.reduce(0) { $0 + $1.amount }
        
        return ChartData(
            date: date,
            balance: balance,
            income: income,
            expenses: expenses
        )
    }
    
    private func getCategoryData() -> [CategoryData] {
        let expensesByCategory = Dictionary(grouping: transactions.filter { $0.amount < 0 }) { $0.category ?? "Uncategorized" }
        let totalExpenses = abs(transactions.filter { $0.amount < 0 }.reduce(0) { $0 + $1.amount })
        
        return expensesByCategory.map { category, transactions in
            let amount = abs(transactions.reduce(0) { $0 + $1.amount })
            let percentage = String(format: "%.0f%%", (amount / totalExpenses) * 100)
            return CategoryData(category: category, amount: amount, percentage: percentage)
        }.sorted { $0.amount > $1.amount }
    }
    
    private func getAverageDailySpending() -> String {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date())!
        
        let recentExpenses = transactions.filter { transaction in
            guard let date = transaction.date else { return false }
            return date >= thirtyDaysAgo && transaction.amount < 0
        }
        
        let totalExpenses = abs(recentExpenses.reduce(0) { $0 + $1.amount })
        let averageDaily = totalExpenses / 30
        
        return String(format: "$%.2f", averageDaily)
    }
    
    private func getDailySpendingTrend() -> String {
        // Calculate trend compared to previous period
        // Positive percentage means spending increased
        return "+5.2%" // Placeholder
    }
    
    private func getTopCategory() -> (String, Double) {
        let expensesByCategory = Dictionary(grouping: transactions.filter { $0.amount < 0 }) { $0.category ?? "Uncategorized" }
        let totalExpenses = abs(transactions.filter { $0.amount < 0 }.reduce(0) { $0 + $1.amount })
        
        let topCategory = expensesByCategory.max { a, b in
            abs(a.value.reduce(0) { $0 + $1.amount }) < abs(b.value.reduce(0) { $0 + $1.amount })
        }
        
        if let category = topCategory {
            let amount = abs(category.value.reduce(0) { $0 + $1.amount })
            let percentage = (amount / totalExpenses) * 100
            return (category.key, percentage)
        }
        
        return ("None", 0)
    }
    
    private func formatAxisValue(_ value: Double) -> String {
        if abs(value) >= 1000 {
            return String(format: "%.1fK", value / 1000)
        }
        return String(format: "%.0f", value)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = selectedChartPeriod == "week" ? "dd/MM" : "MM/yy"
        return formatter.string(from: date)
    }
    
    private func getBalanceRange() -> ClosedRange<Double> {
        let data = getChartData()
        let balances = data.map { $0.balance }
        let minBalance = balances.min() ?? 0
        let maxBalance = balances.max() ?? 0
        let padding = (maxBalance - minBalance) * 0.1
        
        return (minBalance - padding)...(maxBalance + padding)
    }
    
    // Add this helper function for category colors
    private func getCategoryColor(_ category: String) -> Color {
        switch category {
        case "Transport": return .blue
        case "Entertainment": return .green
        case "Shopping": return .orange
        case "Food": return .purple
        case "Transfer": return .red
        default: return .gray
        }
    }
}

struct DashboardCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color(.separator).opacity(0.1), lineWidth: 1)
            }
            .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.05), radius: 10)
    }
}

struct DashboardTransactionRow: View {
    @ObservedObject var transaction: Transaction
    
    var body: some View {
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
            
            // Transaction Details
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.category ?? "Uncategorized")
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                if let note = transaction.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Amount and Date
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(transaction.amount, specifier: "%.2f")")
                    .font(.system(.body, design: .rounded))
                    .bold()
                    .foregroundStyle(transaction.amount >= 0 ? .green : .red)
                
                if let date = transaction.date {
                    Text(date, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .contentShape(Rectangle())
    }
    
    private func getCategoryColor() -> Color {
        switch transaction.category {
        case "Food": return .orange
        case "Transport": return .blue
        case "Entertainment": return .purple
        case "Shopping": return .green
        case "Bills": return .red
        default: return .gray
        }
    }
    
    private func getCategoryIcon() -> String {
        switch transaction.category {
        case "Food": return "fork.knife"
        case "Transport": return "car.fill"
        case "Entertainment": return "tv.fill"
        case "Shopping": return "cart.fill"
        case "Bills": return "doc.text.fill"
        default: return "questionmark"
        }
    }
}

// Data structures for charts
struct ChartData {
    let date: Date
    let balance: Double
    
    // We'll keep these for other analytics
    let income: Double
    let expenses: Double
}

struct CategoryData {
    let category: String
    let amount: Double
    let percentage: String
}

// Trend Card Component
struct TrendCard: View {
    let title: String
    let value: String
    let trend: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.subheadline)
                .bold()
            
            Text(trend)
                .font(.caption2)
                .foregroundStyle(trend.hasPrefix("-") ? .red : .green)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }
}
