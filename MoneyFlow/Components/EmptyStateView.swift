//
//  EmptyStateView.swift
//  MoneyFlow
//
//  Created by Sadat Ahmed on 20/11/24.
//

import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
                .frame(height: 200)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    EmptyView()
}
