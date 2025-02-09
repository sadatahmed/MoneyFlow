import SwiftUI
import Charts
import CoreData

// MARK: - Constants
private enum Constants {
    static let cardCornerRadius: CGFloat = 20
    static let gridColumns = [GridItem(.flexible()), GridItem(.flexible())]
    static let shadowRadius: CGFloat = 10
}

// MARK: - Trend Direction
enum TrendDirection {
    case positive, negative
    
    var icon: String {
        switch self {
        case .positive: return "arrow.up.circle.fill"
        case .negative: return "arrow.down.circle.fill"
        }
    }
}

// MARK: - Main Accounts View
struct AccountsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Account.name, ascending: true)],
        animation: .default
    ) private var accounts: FetchedResults<Account>
    
    @State private var showingAddAccount = false
    @State private var showingTransfer = false
    @State private var selectedTab = "all"
    @State private var isRefreshing = false
    
    // Computed properties
    private var totalBalance: Double { accounts.reduce(0) { $0 + $1.balance } }
    private var accountTypes: [String] { Array(Set(accounts.compactMap { $0.type })).sorted() }
    private var canTransfer: Bool { accounts.count >= 2 }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        BalanceCardView(totalBalance: totalBalance)
                            .padding(.top)
                        
                        QuickActionsSection(
                            showAddAccount: $showingAddAccount,
                            showTransfer: $showingTransfer,
                            canTransfer: canTransfer
                        )
                        
                        AccountTypeFilter(selectedTab: $selectedTab, types: accountTypes)
                        
                        accountsContent
                    }
                    .padding(.bottom)
                }
                .refreshable { handleRefresh() }
            }
            .navigationTitle("Accounts")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingAddAccount, content: addAccountSheet)
            .sheet(isPresented: $showingTransfer, content: transferSheet)
        }
    }
    
    // MARK: - View Components
    @ViewBuilder
    private var accountsContent: some View {
        if accounts.isEmpty {
            EmptyStateView(
                title: "No Accounts Yet",
                message: "Add your first account to start managing your finances",
                systemImage: "plus.circle.fill"
            )
            .padding(.top, 40)
        } else {
            AccountsGridView(accounts: accounts, selectedType: selectedTab)
        }
    }
    
    private func addAccountSheet() -> some View {
        AddAccountView().environment(\.managedObjectContext, viewContext)
    }
    
    private func transferSheet() -> some View {
        AddTransferView().environment(\.managedObjectContext, viewContext)
    }
    
    // MARK: - Methods
    private func handleRefresh() {
        isRefreshing = true
        try? viewContext.save()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isRefreshing = false
        }
    }
}

// MARK: - Balance Card View
struct BalanceCardView: View {
    let totalBalance: Double
    @Environment(\.colorScheme) private var colorScheme
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Account.name, ascending: true)],
        animation: .default
    ) private var accounts: FetchedResults<Account>
    
    // Predefined vibrant colors for better contrast
    private let chartColors: [Color] = [
        Color(red: 0.33, green: 0.63, blue: 1.0),   // Blue
        Color(red: 0.95, green: 0.3, blue: 0.3),    // Red
        Color(red: 0.3, green: 0.85, blue: 0.5),    // Green
        Color(red: 0.6, green: 0.4, blue: 1.0),     // Purple
        Color(red: 1.0, green: 0.7, blue: 0.3),     // Orange
        Color(red: 0.4, green: 0.8, blue: 0.8),     // Teal
        Color(red: 0.9, green: 0.5, blue: 0.7),     // Pink
        Color(red: 0.5, green: 0.8, blue: 0.3),     // Lime
        Color(red: 0.7, green: 0.4, blue: 0.7),     // Violet
        Color(red: 0.9, green: 0.6, blue: 0.3)      // Golden
    ]
    
    var body: some View {
        VStack(spacing: 15) {
            DonutChartView(
                totalAmount: totalBalance,
                accounts: Array(accounts),
                colors: chartColors
            )
            .frame(height: 300)
            .padding(.vertical)
        }
        .padding(25)
        .frame(maxWidth: .infinity)
        .background(cardBackground)
        .padding(.horizontal)
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: Constants.cardCornerRadius)
            .fill(colorScheme == .dark ? Color(.secondarySystemBackground) : .white)
            .shadow(
                color: colorScheme == .dark ? .clear : .black.opacity(0.1),
                radius: Constants.shadowRadius,
                y: 5
            )
    }
}

// MARK: - Donut Chart View
struct DonutChartView: View {
    let totalAmount: Double
    let accounts: [Account]
    let colors: [Color]
    
    private var accountsData: [AccountData] {
        accounts.enumerated().map { index, account in
            let balance = Double(account.balance) ?? 0
            let percentage = (balance / totalAmount) * 100
            return AccountData(
                name: account.name ?? "Unknown",
                balance: balance,
                percentage: percentage,
                color: colors[index % colors.count]
            )
        }
    }
    
    var body: some View {
        ZStack {
            // Donut chart
            Chart(accountsData) { account in
                SectorMark(
                    angle: .value("Balance", account.balance),
                    innerRadius: .ratio(0.75),
                    outerRadius: .ratio(0.95)
                )
                .foregroundStyle(account.color)
                .cornerRadius(8)
            }
            .chartBackground { _ in
                Color.clear
            }
            
            // Percentage labels
            ForEach(accountsData) { account in
                PercentageBadge(
                    percentage: account.percentage,
                    angle: calculateMidAngle(for: account),
                    color: account.color
                )
            }
            
            // Center content
            VStack(spacing: 4) {
                Text("Total Balance")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("$")
                        .font(.system(size: 20, weight: .medium))
                    Text(String(format: "%.2f", totalAmount))
                        .font(.system(size: 32, weight: .semibold))
                }
                .foregroundColor(.primary)
            }
            .padding()
        }
    }
    
    private func calculateMidAngle(for account: AccountData) -> Angle {
        let precedingTotal = accountsData
            .prefix(while: { $0.id != account.id })
            .reduce(0.0) { $0 + $1.balance }
        
        let startPercentage = precedingTotal / totalAmount
        let midPercentage = startPercentage + (account.balance / totalAmount / 2)
        return .degrees(midPercentage * 360 - 90)
    }
}

// MARK: - Percentage Badge
struct PercentageBadge: View {
    let percentage: Double
    let angle: Angle
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            if percentage >= 5 {
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let radius: CGFloat = min(geometry.size.width, geometry.size.height) / 2 + 10
                
                // Calculate badge position with adjusted offset
                let badgeOffset: CGFloat = 20 // Offset for the badge from the donut
                let basePosition = CGPoint(
                    x: center.x + CGFloat(cos(angle.radians)) * radius,
                    y: center.y + CGFloat(sin(angle.radians)) * radius
                )
                
                // Calculate additional offset based on angle quadrant
                let additionalOffset = calculateAdditionalOffset(angle: angle)
                let finalPosition = CGPoint(
                    x: basePosition.x + additionalOffset.x,
                    y: basePosition.y + additionalOffset.y
                )
                
                Text("\(Int(round(percentage)))%")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                    .frame(minWidth: 45) // Ensure consistent width for badges
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.8))
                            .shadow(color: color.opacity(0.2), radius: 4, y: 2)
                            .blur(radius: 0.5)
                    )
                    .position(x: finalPosition.x, y: finalPosition.y)
            }
        }
    }
    
    // Calculate additional offset based on angle to better position badges
    private func calculateAdditionalOffset(angle: Angle) -> CGPoint {
        let degrees = (angle.degrees + 90).truncatingRemainder(dividingBy: 360)
        let radians = degrees * .pi / 180
        
        // Adjust these values to fine-tune badge positioning
        let offsetDistance: CGFloat = 15
        
        return CGPoint(
            x: CGFloat(cos(radians)) * offsetDistance,
            y: CGFloat(sin(radians)) * offsetDistance
        )
    }
}

// MARK: - Helper Data Model
struct AccountData: Identifiable {
    let id = UUID()
    let name: String
    let balance: Double
    let percentage: Double
    let color: Color
}

// MARK: - Statistic View
struct StatisticView: View {
    let title: String
    let value: String
    let trend: TrendDirection
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(trendColor)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(statisticBackground)
        .shadow(
            color: colorScheme == .dark ? .clear : .black.opacity(0.1),
            radius: 16,
            x: 0,
            y: 8
        )
    }
    
    private var trendColor: Color {
        trend == .positive ?
        (colorScheme == .dark ? .green : .blue) :
        (colorScheme == .dark ? .red : .orange)
    }
    
    private var statisticBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.tertiarySystemBackground))
    }
}

// MARK: - Quick Actions Section
struct QuickActionsSection: View {
    @Binding var showAddAccount: Bool
    @Binding var showTransfer: Bool
    let canTransfer: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                QuickActionButton(
                    title: "Add Account",
                    icon: "plus.circle.fill",
                    gradient: actionButtonColors(for: .blue),
                    action: { showAddAccount = true },
                    colorScheme: colorScheme
                )
                
                QuickActionButton(
                    title: "Transfer",
                    icon: "arrow.left.arrow.right.circle.fill",
                    gradient: actionButtonColors(for: .purple),
                    isDisabled: !canTransfer,
                    action: { showTransfer = true },
                    colorScheme: colorScheme
                )
                
                QuickActionButton(
                    title: "Statistics",
                    icon: "chart.pie.fill",
                    gradient: actionButtonColors(for: .orange),
                    action: {},
                    colorScheme: colorScheme
                )
            }
            .padding(.horizontal)
        }
    }
    
    private func actionButtonColors(for base: Color) -> [Color] {
        colorScheme == .dark ?
        [base, base.opacity(0.7)] :
        [base, base.opacity(0.8)]
    }
}

// MARK: - Quick Action Icon View
struct QuickActionIconView: View {
    let systemName: String
    let colors: [Color]
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.tertiarySystemBackground))
                .overlay(gradientOverlay)
                .frame(width: 48, height: 48)
            
            CFGradientIconView(
                systemName: systemName,
                colors: [.white, .white.opacity(0.8)],
                size: 24
            )
        }
    }
    
    private var gradientOverlay: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .opacity(colorScheme == .dark ? 0.9 : 0.8)
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let title: String
    let icon: String
    let gradient: [Color]
    var isDisabled: Bool = false
    let action: () -> Void
    var colorScheme: ColorScheme

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                QuickActionIconView(systemName: icon, colors: gradient)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(width: 110)
            .padding(.vertical, 16)
            .background(buttonBackground)
        }
        .opacity(isDisabled ? 0.5 : 1)
        .disabled(isDisabled)
    }

    private var buttonBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

// MARK: - Account Type Filter
struct AccountTypeFilter: View {
    @Binding var selectedTab: String
    let types: [String]
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                FilterTab(title: "All", isSelected: selectedTab == "all") {
                    withAnimation { selectedTab = "all" }
                }
                
                ForEach(types, id: \.self) { type in
                    FilterTab(title: type.capitalized, isSelected: selectedTab == type) {
                        withAnimation { selectedTab = type }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Accounts Grid View
struct AccountsGridView: View {
    let accounts: FetchedResults<Account>
    let selectedType: String

    private var filteredAccounts: [Account] {
        selectedType == "all" ? Array(accounts) : accounts.filter { $0.type == selectedType }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(0..<Int(ceil(Double(filteredAccounts.count) / 4.0)), id: \.self) { pageIndex in
                    VStack(spacing: 15) {
                        let startIndex = pageIndex * 4
                        let endIndex = min(startIndex + 4, filteredAccounts.count)
                        let pageAccounts = Array(filteredAccounts[startIndex..<endIndex])
                        
                        ForEach(0..<2) { row in
                            HStack(spacing: 15) {
                                ForEach(0..<2) { col in
                                    let index = row * 2 + col
                                    if index < pageAccounts.count {
                                        NavigationLink(destination: AccountDetailView(account: pageAccounts[index])) {
                                            ModernAccountCard(account: pageAccounts[index])
                                        }
                                        .buttonStyle(PressableButtonStyle())
                                    } else {
                                        Color.clear
                                            .frame(width: UIScreen.main.bounds.width / 2 - 22.5)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom)
    }
}

// MARK: - Filter Tab
struct FilterTab: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? selectedColor : unselectedColor)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(background)
                .overlay(border)
        }
    }
    
    private var selectedColor: Color {
        colorScheme == .dark ? .white : .primary
    }
    
    private var unselectedColor: Color {
        colorScheme == .dark ? .gray : .secondary
    }
    
    private var background: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(isSelected ? Color(.secondarySystemBackground) : Color(.tertiarySystemBackground))
    }
    
    private var border: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(Color.secondary.opacity(colorScheme == .dark ? 0.2 : 0.1), lineWidth: 1)
    }
}

// MARK: - Modern Account Card
struct ModernAccountCard: View {
    @ObservedObject var account: Account
    @State private var isPressed = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                headerSection
                Spacer()
                detailsSection
            }
            .padding(16)
            .frame(height: 170)
            .background(cardBackground)
            .overlay(cardBorder)
            .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.05), radius: 10, y: 5)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }
    
    private var headerSection: some View {
        HStack(spacing: 12) {
            AccountIconView(type: account.type ?? "unknown")
            VStack(alignment: .leading, spacing: 4) {
                Text(account.type?.capitalized ?? "Unknown")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(account.name?.uppercased() ?? "Unnamed Account")
                .font(.headline)
                .lineLimit(1)
            
            Text(account.balance.currencyFormat)
                .font(.system(.title3, design: .rounded))
                .foregroundColor(account.balance >= 0 ? .primary : .red)
        }
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: Constants.cardCornerRadius)
            .fill(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground))
    }
    
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: Constants.cardCornerRadius)
            .stroke(Color.primary.opacity(0.05), lineWidth: 1)
    }
}

// MARK: - Account Icon View
struct AccountIconView: View {
    let type: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemBackground))
                .overlay(gradientOverlay)
                .frame(width: 44, height: 44)
            
            CFGradientIconView(
                systemName: AccountTypeConfig.icon(for: type),
                colors: gradientColors,
                size: 24
            )
        }
    }
    
    private var gradientColors: [Color] {
        colorScheme == .dark ?
        [.white.opacity(0.9), .white.opacity(0.7)] :
        [.white, .white.opacity(0.8)]
    }
    
    private var gradientOverlay: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(AngularGradient(
                colors: AccountTypeConfig.gradient(for: type, scheme: colorScheme),
                center: .bottomTrailing
            ))
            .opacity(colorScheme == .dark ? 0.9 : 0.8)
    }
}

// MARK: - Account Type Configuration
struct AccountTypeConfig {
    static func gradient(for type: String, scheme: ColorScheme) -> [Color] {
        let baseColors: [Color]
        switch type.lowercased() {
        case "checking":
            baseColors = [.blue, scheme == .dark ? .blue.opacity(0.7) : .blue]
        case "savings":
            baseColors = [.green, scheme == .dark ? .green.opacity(0.7) : .green]
        case "credit":
            baseColors = [.red, scheme == .dark ? .red.opacity(0.7) : .red]
        case "cash":
            baseColors = [.orange, scheme == .dark ? .orange.opacity(0.7) : .orange]
        case "investment":
            baseColors = [.purple, scheme == .dark ? .purple.opacity(0.7) : .purple]
        default:
            baseColors = [.gray, scheme == .dark ? .gray.opacity(0.7) : .gray]
        }
        return baseColors
    }
    
    static func icon(for type: String) -> String {
        switch type.lowercased() {
        case "checking": return "dollarsign.circle.fill"
        case "savings": return "banknote.fill"
        case "credit": return "creditcard.fill"
        case "cash": return "money.bill.fill"
        case "investment": return "chart.line.uptrend.xyaxis.circle.fill"
        default: return "questionmark.circle.fill"
        }
    }
}

// MARK: - Gradient Icon View
struct CFGradientIconView: View {
    let systemName: String
    let colors: [Color]
    var size: CGFloat = 20

    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .mask {
            Image(systemName: systemName)
                .font(.system(size: size, weight: .semibold))
        }
    }
}

// MARK: - Custom Button Style
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}


/***
// Custom ViewModifier to handle press events [We are not using this code for now]
struct PressEventsModifier: ViewModifier {
    let onPress: () -> Void
    let onRelease: () -> Void

    // A gesture state to track the press
    @GestureState private var isPressedGesture = false

    func body(content: Content) -> some View {
        // Create a gesture that detects immediate touch events.
        let pressGesture = DragGesture(minimumDistance: 0)
            .updating($isPressedGesture) { (_, state, _) in
                // Mark as pressed when the gesture is active.
                state = true
            }
            .onEnded { _ in
                // Call the release callback when the gesture ends.
                onRelease()
            }

        return content
            // Optionally, adjust view properties based on the gesture state.
            .scaleEffect(isPressedGesture ? 0.97 : 1)
            // Attach the gesture.
            .gesture(pressGesture)
            // Trigger the onPress callback when the gesture state changes.
            .onChange(of: isPressedGesture) { newValue in
                if newValue {
                    onPress()
                }
            }
    }
}

// Extend View to include the pressEvents modifier
extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.modifier(PressEventsModifier(onPress: onPress, onRelease: onRelease))
    }
}
*/
