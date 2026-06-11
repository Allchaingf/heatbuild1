import SwiftUI

struct RecommendationsView: View {
    @EnvironmentObject var store: AppStore
    @State private var appeared = false

    var activeRecs: [Recommendation] {
        store.recommendations.filter { !$0.isDismissed }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 14) {
                    if activeRecs.isEmpty {
                        EmptyStateCard(icon: "lightbulb", title: "No recommendations", subtitle: "Recommendations will appear based on your climate data") {
                            if let pid = store.selectedProjectId {
                                store.generateRecommendations(for: pid)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    } else {
                        ForEach(Array(activeRecs.enumerated()), id: \.element.id) { idx, rec in
                            RecommendationCard(rec: rec)
                                .padding(.horizontal, 16)
                                .offset(y: appeared ? 0 : 20)
                                .opacity(appeared ? 1 : 0)
                                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(idx) * 0.06), value: appeared)
                        }
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Color.bgPrimary)
            .navigationTitle("Recommendations")
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { appeared = true }
        }
        .onDisappear { appeared = false }
    }
}

struct RecommendationCard: View {
    @EnvironmentObject var store: AppStore
    let rec: Recommendation
    @State private var actionTaken = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(rec.type.color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: rec.type.icon)
                        .font(.system(size: 18))
                        .foregroundColor(rec.type.color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(rec.type.rawValue)
                        .font(AppFont.caption())
                        .foregroundColor(rec.type.color)
                    Text(rec.title)
                        .font(AppFont.semibold(15))
                        .foregroundColor(.textPrimary)
                }
            }

            Text(rec.description)
                .font(AppFont.body())
                .foregroundColor(.textSecondary)
                .lineSpacing(3)

            Divider()

            HStack(spacing: 10) {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        store.addRecommendationToTasks(rec)
                        actionTaken = true
                    }
                } label: {
                    Label(rec.isAddedToTasks ? "Added!" : "Add to Tasks", systemImage: rec.isAddedToTasks ? "checkmark.circle.fill" : "plus.circle")
                        .font(AppFont.semibold(13))
                        .foregroundColor(rec.isAddedToTasks ? .statusDone : .white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 9).fill(rec.isAddedToTasks ? Color.statusDone.opacity(0.15) : Color.accentBlue))
                }
                .buttonStyle(.plain)
                .disabled(rec.isAddedToTasks)

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        store.dismissRecommendation(rec.id)
                    }
                } label: {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 18))
                        .foregroundColor(.textInactive)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardWhite))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(rec.type.color.opacity(0.15), lineWidth: 1))
        .cardShadow()
    }
}
