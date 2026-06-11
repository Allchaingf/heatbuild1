import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var store: AppStore
    @State private var selectedDate = Date()
    @State private var showAdd = false
    @State private var currentMonth = Date()

    var eventsOnDate: [CalendarEvent] {
        store.calendarEvents.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }

    var datesWithEvents: Set<String> {
        Set(store.calendarEvents.map { dateKey($0.date) })
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Month navigation
                    HStack {
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                            }
                        } label: {
                            Image(systemName: "chevron.left").foregroundColor(.accentBlue)
                        }
                        Spacer()
                        Text(currentMonth.formatted(.dateTime.month(.wide).year()))
                            .font(AppFont.semibold(17))
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                            }
                        } label: {
                            Image(systemName: "chevron.right").foregroundColor(.accentBlue)
                        }
                    }
                    .padding(.horizontal, 16)

                    // Calendar grid
                    CalendarGrid(
                        month: currentMonth,
                        selectedDate: $selectedDate,
                        datesWithEvents: datesWithEvents
                    )
                    .padding(.horizontal, 16)

                    // Today button
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            selectedDate = Date()
                            currentMonth = Date()
                        }
                    } label: {
                        Text("Today")
                    }
                    .buttonStyle(SmallSecondaryButtonStyle())

                    // Events for selected date
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: selectedDate.formatted(date: .long, time: .omitted), action: nil)
                            .padding(.horizontal, 4)

                        if eventsOnDate.isEmpty {
                            HStack(spacing: 10) {
                                Image(systemName: "calendar.badge.exclamationmark").foregroundColor(.textInactive)
                                Text("No events").font(AppFont.medium(14)).foregroundColor(.textInactive)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.cardWhite))
                            .cardShadow()
                        } else {
                            ForEach(eventsOnDate) { event in
                                EventCard(event: event)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 16)
            }
            .background(Color.bgPrimary)
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus.circle.fill").font(.system(size: 22)).foregroundColor(.accentBlue)
                    }
                }
            }
        }
        .sheet(isPresented: $showAdd) { AddEventView(defaultDate: selectedDate) }
    }

    func dateKey(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(c.year ?? 0)-\(c.month ?? 0)-\(c.day ?? 0)"
    }
}

// MARK: - Calendar Grid
struct CalendarGrid: View {
    let month: Date
    @Binding var selectedDate: Date
    let datesWithEvents: Set<String>

    var days: [Date?] {
        var result: [Date?] = []
        let cal = Calendar.current
        guard let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: month)),
              let range = cal.range(of: .day, in: .month, for: month) else { return [] }
        let firstWeekday = (cal.component(.weekday, from: monthStart) - cal.firstWeekday + 7) % 7
        for _ in 0..<firstWeekday { result.append(nil) }
        for d in range { result.append(cal.date(byAdding: .day, value: d - 1, to: monthStart)) }
        return result
    }

    let weekdays = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                ForEach(weekdays, id: \.self) { d in
                    Text(d).font(AppFont.caption()).foregroundColor(.textInactive).frame(maxWidth: .infinity)
                }
            }

            let cols = Array(repeating: GridItem(.flexible()), count: 7)
            LazyVGrid(columns: cols, spacing: 6) {
                ForEach(0..<days.count, id: \.self) { idx in
                    if let date = days[idx] {
                        DayCell(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                            isToday: Calendar.current.isDateInToday(date),
                            hasEvent: datesWithEvents.contains(dateKey(date))
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedDate = date
                            }
                        }
                    } else {
                        Color.clear.frame(height: 36)
                    }
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardWhite))
        .cardShadow()
    }

    func dateKey(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(c.year ?? 0)-\(c.month ?? 0)-\(c.day ?? 0)"
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasEvent: Bool

    var day: Int { Calendar.current.component(.day, from: date) }

    var body: some View {
        ZStack {
            if isSelected {
                Circle().fill(Color.accentBlue).frame(width: 34, height: 34)
            } else if isToday {
                Circle().stroke(Color.accentBlue, lineWidth: 1.5).frame(width: 34, height: 34)
            }

            VStack(spacing: 2) {
                Text("\(day)")
                    .font(AppFont.medium(14))
                    .foregroundColor(isSelected ? .white : isToday ? .accentBlue : .textPrimary)
                if hasEvent {
                    Circle()
                        .fill(isSelected ? Color.white : Color.accentOrange)
                        .frame(width: 4, height: 4)
                }
            }
        }
        .frame(height: 36)
    }
}

// MARK: - Event Card
struct EventCard: View {
    @EnvironmentObject var store: AppStore
    let event: CalendarEvent

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(event.type.color)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 3) {
                Text(event.title).font(AppFont.medium(14)).foregroundColor(.textPrimary)
                HStack(spacing: 6) {
                    Text(event.date.formatted(date: .omitted, time: .shortened))
                        .font(AppFont.caption()).foregroundColor(.textInactive)
                    StatusBadge(text: event.type.rawValue, color: event.type.color)
                }
                if !event.notes.isEmpty {
                    Text(event.notes).font(AppFont.caption()).foregroundColor(.textSecondary)
                }
            }

            Spacer()

            Button {
                store.deleteCalendarEvent(event.id)
            } label: {
                Image(systemName: "trash").font(.system(size: 14)).foregroundColor(.textInactive)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.cardWhite))
        .cardShadow()
    }
}

// MARK: - Add Event
struct AddEventView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) var dismiss
    let defaultDate: Date
    @State private var title = ""
    @State private var date: Date
    @State private var type: CalendarEvent.EventType = .check
    @State private var notes = ""
    @State private var showError = false

    init(defaultDate: Date) {
        self.defaultDate = defaultDate
        _date = State(initialValue: defaultDate)
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Event Title", text: $title)
                    DatePicker("Date & Time", selection: $date)
                    Picker("Type", selection: $type) {
                        ForEach(CalendarEvent.EventType.allCases, id: \.self) { Text($0.rawValue) }
                    }
                    TextEditor(text: $notes).frame(minHeight: 60)
                        .overlay(notes.isEmpty ? Text("Notes").foregroundColor(.textInactive).padding(.top, 8).padding(.leading, 4) : nil, alignment: .topLeading)
                }
                if showError { Section { Text("Please enter a title.").foregroundColor(.statusError) } }
            }
            .navigationTitle("Add Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss.wrappedValue.dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { showError = true; return }
                        let event = CalendarEvent(projectId: store.selectedProjectId, title: title, date: date, type: type, notes: notes)
                        store.addCalendarEvent(event)
                        dismiss.wrappedValue.dismiss()
                    }
                    .font(AppFont.semibold(15)).foregroundColor(.accentBlue)
                }
            }
        }
    }
}
