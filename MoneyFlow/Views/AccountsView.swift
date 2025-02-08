import SwiftUI
import CoreData

import SwiftUI

// Main view for displaying and managing accounts
struct AccountsView: View {
    // Core Data context for managing persistence
    @Environment(\.managedObjectContext) private var viewContext
    
    // FetchRequest to fetch and observe Account entities from Core Data
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Account.name, ascending: true)],
        animation: .default
    )
    private var accounts: FetchedResults<Account>
    
    // State variables to manage sheet presentations
    @State private var showingAddAccount = false
    @State private var showingTransfer = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background color for the entire view
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Action buttons for "Add Account" and "Transfer"
                    HStack(spacing: 12) {
                        Button(action: { showingAddAccount = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Account")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(.regularMaterial)
                            .foregroundColor(.primary)
                            .overlay {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        Button(action: { showingTransfer = true }) {
                            HStack {
                                Image(systemName: "arrow.left.arrow.right.circle.fill")
                                Text("Transfer")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                .ultraThinMaterial.opacity(accounts.count < 2 ? 0.5 : 1.0)
                            )
                            .foregroundColor(accounts.count < 2 ? .secondary : .primary)
                            .overlay {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(accounts.count < 2) // Disable "Transfer" if less than 2 accounts
                    }
                    .padding(.horizontal)

                    // Display empty state if no accounts exist
                    if accounts.isEmpty {
                        EmptyStateView(
                            title: "No Accounts Yet",
                            message: "Add your first bank account or wallet to get started",
                            systemImage: "empty_account"
                        )
                        .padding(.top, 40)
                    } else {
                        // Display accounts in a scrollable list
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(accounts) { account in
                                    NavigationLink(destination: AccountDetailView(account: account)) {
                                        AccountCard(account: account)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.top, 16)
            }
            .navigationTitle("Accounts")
            // Sheet for adding an account
            .sheet(isPresented: $showingAddAccount) {
                AddAccountView()
                    .environment(\.managedObjectContext, viewContext)
            }
            // Sheet for transferring funds
            .sheet(isPresented: $showingTransfer) {
                AddTransferView()
                    .environment(\.managedObjectContext, viewContext)
            }
            // Refreshable content for saving Core Data changes
            .refreshable {
                try? viewContext.save()
            }
        }
    }
}

// Card view to display individual account details
struct AccountCard: View {
    @ObservedObject var account: Account
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 16) {
            // Icon for account type with background color
            Circle()
                .fill(getAccountTypeColor().opacity(0.15))
                .frame(width: 48, height: 48)
                .overlay {
                    Image(systemName: getAccountTypeIcon())
                        .font(.title3)
                        .foregroundStyle(getAccountTypeColor())
                }
            
            // Account name and type
            VStack(alignment: .leading, spacing: 4) {
                Text(account.name ?? "Unnamed Account")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(account.type?.capitalized ?? "Unknown Type")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Account balance, styled based on value
            Text("$\(account.balance, specifier: "%.2f")")
                .font(.headline)
                .foregroundStyle(account.balance >= 0 ? .primary : Color.red)
        }
        .padding(16)
        .background(.regularMaterial)
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // Get color based on account type
    private func getAccountTypeColor() -> Color {
        switch account.type {
        case "checking": return Color(hex: "4A90E2") // Elegant blue
        case "savings": return Color(hex: "50C878")  // Emerald green
        case "credit": return Color(hex: "FF6B6B")   // Soft red
        case "cash": return Color(hex: "FFB347")     // Muted orange
        case "investment": return Color(hex: "9B6B9E") // Subtle purple
        default: return Color(hex: "8E8E93")         // Neutral gray
        }
    }

    // Get icon based on account type
    private func getAccountTypeIcon() -> String {
        switch account.type {
        case "checking": return "dollarsign.circle.fill"
        case "savings": return "banknote.fill"
        case "credit": return "creditcard.fill"
        case "cash": return "money.bill.fill"
        case "investment": return "chart.line.uptrend.xyaxis.circle.fill"
        default: return "questionmark.circle.fill"
        }
    }
}

// Helper extension for creating colors from hex values
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
