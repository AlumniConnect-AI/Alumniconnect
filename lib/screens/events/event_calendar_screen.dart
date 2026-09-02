import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../config/theme.dart';

class EventsCalendarScreen extends StatefulWidget {
  const EventsCalendarScreen({super.key});

  @override
  State<EventsCalendarScreen> createState() =>
      _EventsCalendarScreenState();
}

class _EventsCalendarScreenState extends State<EventsCalendarScreen> {
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;
  List<Map<String, dynamic>> events = [];

  Future<void> loadEvents(DateTime day) async {
    final snap =
    await FirebaseFirestore.instance.collection('events').get();

    final dateStr =
        "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";

    setState(() {
      events = snap.docs
          .map((d) => d.data())
          .where((e) => e['date'] == dateStr)
          .toList();
    });
  }

  @override
  void initState() {
    super.initState();
    loadEvents(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Events Calendar"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: focusedDay,
            firstDay: DateTime(2020),
            lastDay: DateTime(2035),
            selectedDayPredicate: (d) => isSameDay(d, selectedDay),
            onDaySelected: (s, f) {
              setState(() {
                selectedDay = s;
                focusedDay = f;
              });
              loadEvents(s);
            },
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
              leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.primary),
              rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.primary),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
              weekendStyle: TextStyle(color: AppColors.primary),
            ),
            calendarStyle: CalendarStyle(
              defaultTextStyle: TextStyle(color: theme.textTheme.bodyLarge?.color),
              weekendTextStyle: TextStyle(color: AppColors.primary),
              outsideTextStyle: TextStyle(color: theme.textTheme.bodySmall?.color ?? Colors.grey),
              todayDecoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.3),
                  shape: BoxShape.circle),
              selectedDecoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle),
              markerDecoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle),
            ),
          ),
          const Divider(),
          Expanded(
            child: events.isEmpty
                ? Center(
                child: Text("No events on this day",
                    style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color)))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: events.length,
              itemBuilder: (_, i) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.event, color: AppColors.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            events[i]['title'] ?? "",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${events[i]['time'] ?? ''} • ${events[i]['location'] ?? ''}",
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
