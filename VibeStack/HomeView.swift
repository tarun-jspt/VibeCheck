import SwiftUI
import SwiftData

// MARK: - Design tokens

enum DS {
    static let bg          = Color(red: 0.11, green: 0.11, blue: 0.13)
    static let cardBase    = Color(red: 0.17, green: 0.17, blue: 0.20)
    static let cardBorder  = Color.white.opacity(0.07)
    static let textPrimary = Color.white
    static let textMuted   = Color.white.opacity(0.45)
    static let fabGradient = LinearGradient(
        colors: [Color(red: 1.0, green: 0.55, blue: 0.25),
                 Color(red: 0.78, green: 0.29, blue: 0.95)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let cardHeight: CGFloat = 88
    static let cardCorner: CGFloat = 22
    static let stackPeek:  CGFloat = 10
}

// MARK: - Vibe Card (geometry-stamped)

struct VibeCard: View {
    let entry: VibeEntry
    let namespace: Namespace.ID

    var body: some View {
        let accent = vibeIntensityColor(entry.intensity)

        HStack(spacing: 16) {

            // Emoji bubble — matched for hero transition
            ZStack {
                Circle()
                    .fill(accent.opacity(0.18))
                    .matchedGeometryEffect(id: "bubble-\(entry.id)", in: namespace)
                    .frame(width: 52, height: 52)
                Image(entry.moodID)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 26)
                    .matchedGeometryEffect(id: "emoji-\(entry.id)", in: namespace)
            }

            // Note + intensity pip row
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.note.isEmpty ? "No note" : entry.note)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(entry.note.isEmpty ? DS.textMuted : DS.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { pip in
                        Capsule()
                            .fill(Double(pip) <= entry.intensity
                                  ? accent : DS.textMuted.opacity(0.3))
                            .frame(width: Double(pip) <= entry.intensity ? 14 : 8, height: 4)
                            .matchedGeometryEffect(id: "pip-\(entry.id)-\(pip)", in: namespace)
                    }
                }
            }

            Spacer(minLength: 0)

            // Timestamp — matched for hero transition
            Text(vibeRelativeTimestamp(entry.timestamp))
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(DS.textMuted)
                .fixedSize()
                .matchedGeometryEffect(id: "time-\(entry.id)", in: namespace)
        }
        .padding(.horizontal, 18)
        .frame(height: DS.cardHeight)
        .vibeGlass(cornerRadius: DS.cardCorner)
        // Left intensity accent stripe
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 3)
                .fill(accent)
                .frame(width: 4)
                .padding(.vertical, 18)
                .clipShape(RoundedRectangle(cornerRadius: DS.cardCorner, style: .continuous))
        }
        .matchedGeometryEffect(id: "card-\(entry.id)", in: namespace)
    }
}

// MARK: - Stack scroll modifier

struct StackScrollEffect: ViewModifier {
    let index: Int
    let cardHeight: CGFloat

    func body(content: Content) -> some View {
        content
            .scrollTransition(.animated(.spring(response: 0.4, dampingFraction: 0.85))) { view, phase in
                view
                    .scaleEffect(
                        phase.isIdentity ? 1.0 : (phase.value < 0 ? max(0.88, 1 + phase.value * 0.07) : 1.0),
                        anchor: .top
                    )
                    .offset(y: phase.value < 0 ? phase.value * 18 : 0)
                    .opacity(phase.isIdentity ? 1.0 : (phase.value < 0 ? max(0.0, 1 + phase.value * 1.4) : 1.0))
            }
    }
}

extension View {
    func stackScrollEffect(index: Int, cardHeight: CGFloat = DS.cardHeight) -> some View {
        modifier(StackScrollEffect(index: index, cardHeight: cardHeight))
    }
}

// MARK: - Empty State

struct VibeEmptyState: View {
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // 3D-style sparkles icon with layered glow
            ZStack {
                // Outer glow ring
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.78, green: 0.29, blue: 0.95).opacity(0.25),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)

                // Icon backing circle
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.22), Color.white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color(red: 0.78, green: 0.29, blue: 0.95).opacity(0.4),
                            radius: 24, y: 8)

                // Sparkles icon — layered for pseudo-3D depth
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 42, weight: .thin))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white.opacity(0.3), .white.opacity(0.08)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .offset(x: 2, y: 2)   // shadow layer

                Image(systemName: "wand.and.stars")
                    .font(.system(size: 42, weight: .thin))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.85, blue: 1.0),
                                     Color(red: 0.78, green: 0.29, blue: 0.95)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(.bottom, 32)

            // Headline
            Text("No Vibes Stacked Yet")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(DS.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 10)

            // Subheadline
            Text("Your emotional stack is empty.\nStart building your vibe history.")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(DS.textMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.bottom, 36)

            // CTA button
            Button(action: onStart) {
                HStack(spacing: 10) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Start Your First Stack")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 16)
                .background(DS.fabGradient, in: Capsule())
                .shadow(
                    color: Color(red: 1.0, green: 0.45, blue: 0.2).opacity(0.5),
                    radius: 16, y: 6
                )
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }
}

// MARK: - HomeView

struct HomeView: View {
    @Query(sort: \VibeEntry.timestamp, order: .reverse) private var entries: [VibeEntry]
    @Environment(\.modelContext) private var modelContext

    @State private var showAddVibe    = false
    @State private var fabPressed     = false
    @State private var selectedEntry: VibeEntry? = nil
    @State private var showDetail     = false
    @State private var searchText     = ""
    @State private var showInsights   = false
    @State private var showHistory   = false

    @Namespace private var cardNamespace

    // MARK: Filtered list

    /// Matches against note text OR the emoji character itself.
    private var filteredEntries: [VibeEntry] {
        guard !searchText.isEmpty else { return entries }
        let q = searchText.lowercased()
        return entries.filter {
            $0.note.lowercased().contains(q) ||
            ($0.moodEmoji.contains(searchText))
        }
    }

    // MARK: Haptics

    private let warningHaptic = UINotificationFeedbackGenerator()

    // MARK: Body

    var body: some View {
        ZStack {
            NavigationStack {
                ZStack(alignment: .bottom) {
                    
                    // ── Animated bloom background ──────────────────────────
                    VibeBloomView(entries: entries)
                    // Present Insights using modern API
                    .navigationDestination(isPresented: $showInsights) {
                        InsightsView()
                            .preferredColorScheme(.dark)
                    }
                    .navigationDestination(isPresented: $showHistory) {
                        HistoryView()
                            .preferredColorScheme(.dark)
                    }
                    
                    // ── Content area ───────────────────────────────────────
                    Group {
                        if entries.isEmpty {
                            // Empty state — before any search is possible
                            VibeEmptyState(onStart: {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                showAddVibe = true
                            })
                            .transition(.opacity.combined(with: .scale(scale: 0.96)))
                            
                        } else if filteredEntries.isEmpty {
                            // Search returned no results
                            VStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 36, weight: .thin))
                                    .foregroundStyle(DS.textMuted)
                                Text("No vibes match “\(searchText)”")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundStyle(DS.textMuted)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .transition(.opacity)
                            
                        } else {
                            // Main card list
                            List {
                                ForEach(Array(filteredEntries.enumerated()), id: \.element.id) { idx, entry in
                                    // Wrap card in a plain row that kills List chrome
                                    VibeCard(entry: entry, namespace: cardNamespace)
                                        .stackScrollEffect(index: idx)
                                    // Hide source card while detail is open
                                        .opacity(showDetail && selectedEntry?.id == entry.id ? 0 : 1)
                                        .onTapGesture {
                                            guard !showDetail else { return }
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            selectedEntry = entry
                                            withAnimation(.vibeSpring) { showDetail = true }
                                        }
                                    // ── Swipe-to-delete ───────────────
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                deleteEntry(entry)
                                            } label: {
                                                Label("Delete", systemImage: "trash.fill")
                                            }
                                            .tint(Color(red: 1.0, green: 0.27, blue: 0.27))
                                        }
                                    // Kill default List row styling
                                        .listRowBackground(Color.clear)
                                        .listRowSeparator(.hidden)
                                        .listRowInsets(EdgeInsets(top: DS.stackPeek / 2,
                                                                  leading: 20,
                                                                  bottom: DS.stackPeek / 2,
                                                                  trailing: 20))
                                }
                                
                                // Bottom padding row so FAB doesn't obscure last card
                                Color.clear
                                    .frame(height: 90)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                            }
                            // ── List styling ──────────────────────────────
                            .listStyle(.plain)
                            .scrollContentBackground(.hidden)   // let MeshGradient show through
                            .scrollBounceBehavior(.always)
                        }
                    }
                    .animation(.vibeSpring, value: entries.count)
                    .animation(.vibeSpring, value: searchText)
                    
                    // ── FAB ───────────────────────────────────────────────
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        showAddVibe = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(DS.fabGradient)
                                .frame(width: 64, height: 64)
                                .shadow(color: Color(red: 1.0, green: 0.45, blue: 0.2).opacity(0.55),
                                        radius: 18, y: 8)
                            Image(systemName: "plus")
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundStyle(.white)
                                .rotationEffect(.degrees(fabPressed ? 45 : 0))
                        }
                        .scaleEffect(fabPressed ? 0.93 : 1.0)
                        .animation(.vibeSpring, value: fabPressed)
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in fabPressed = true }
                            .onEnded   { _ in fabPressed = false }
                    )
                    .padding(.bottom, 32)
                    // Hide FAB behind detail overlay
                    .opacity(showDetail ? 0 : 1)
                }
                // ── Navigation chrome ──────────────────────────────────────
                .navigationTitle("How are you today?")
                .navigationBarTitleDisplayMode(.large)
                .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbar {
                    // History button on the left (leading)
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            showHistory = true
                        } label: {
                            Label("History", systemImage: "calendar")
                        }
                    }
                    // Insights button on the right (trailing)
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showInsights = true
                        } label: {
                            Image(systemName: "chart.bar.xaxis")
                        }
                    }
                }
//                // ── Search ────────────────────────────────────────────────
//                .searchable(
//                    text: $searchText,
//                    placement: .navigationBarDrawer(displayMode: .automatic),
//                    prompt: "Search notes or emoji…"
//                )
//                // Style the search bar to match glassmorphic theme
//                .onAppear {
//                    let appearance = UISearchBar.appearance()
//                    appearance.barTintColor = UIColor(
//                        red: 0.17, green: 0.17, blue: 0.20, alpha: 0.85
//                    )
//                    appearance.tintColor = UIColor(
//                        red: 1.0, green: 0.55, blue: 0.25, alpha: 1.0
//                    )
//                    // Dim placeholder text
//                    UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self])
//                        .attributedPlaceholder = NSAttributedString(
//                            string: "Search notes or emoji…",
//                            attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.4)]
//                        )
//                }
                // ── Sheets ────────────────────────────────────────────────
                .sheet(isPresented: $showAddVibe) {
                    AddVibeView()
                }
                // Deep-link from widget
                .onOpenURL { url in
                    if url.scheme == "vibecheck", url.host == "addvibe" {
                        showAddVibe = true
                    }
                }
            } // Navigation Stack
            // ── Detail overlay — outside NavigationStack, covers nav bar & search ──
            if showDetail, let entry = selectedEntry {
                VibeDetailView(
                    entry: entry,
                    namespace: cardNamespace,
                    isPresented: $showDetail
                )
                .ignoresSafeArea()
                .transition(.opacity)
                .zIndex(20)
            }
        } // outer ZStack
        .preferredColorScheme(.dark)
    }

    // MARK: - Delete

    private func deleteEntry(_ entry: VibeEntry) {
        warningHaptic.prepare()
        warningHaptic.notificationOccurred(.warning)
        withAnimation(.vibeSpring) {
            modelContext.delete(entry)
        }
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .modelContainer(for: VibeEntry.self, inMemory: true)
}

