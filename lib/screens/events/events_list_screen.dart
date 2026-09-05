import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/theme.dart';
import '../../services/upload_service.dart';
import 'event_detail_screen.dart';
import 'event_calendar_screen.dart';

class EventsListScreen extends StatefulWidget {
  const EventsListScreen({super.key});

  @override
  State<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen> {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  String search = "";
  String locationFilter = "All";
  String dateFilter = "All";
  String typeFilter = "All";

  // ================= COLORS PER TYPE =================
  Color _getTypeColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'workshop':
        return AppColors.warning;
      case 'webinar':
        return AppColors.jobAccent;
      case 'meetup':
        return AppColors.success;
      case 'conference':
        return AppColors.eventAccent;
      default:
        return AppColors.primary;
    }
  }

  // ================= DATE FILTER =================
  bool _matchesDateFilter(String eventDate) {
    final now = DateTime.now();
    final parsed = DateTime.tryParse(eventDate);
    if (parsed == null) return true;

    if (dateFilter == "Today") {
      return parsed.year == now.year &&
          parsed.month == now.month &&
          parsed.day == now.day;
    }

    if (dateFilter == "This Week") {
      final start = now.subtract(Duration(days: now.weekday - 1));
      final end = start.add(const Duration(days: 6));
      return parsed.isAfter(start.subtract(const Duration(days: 1))) &&
          parsed.isBefore(end.add(const Duration(days: 1)));
    }

    if (dateFilter == "Upcoming") {
      return parsed.isAfter(now);
    }

    return true;
  }

  // ================= ADD EVENT DIALOG =================
  void _openAddEventDialog() {
    final theme = Theme.of(context);
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final linkCtrl = TextEditingController();

    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    String selectedLocation = "Online";
    String selectedType = "Workshop";
    File? eventImage;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            backgroundColor: theme.cardColor,
            title: const Text("Add Event"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  _input("Event Title", titleCtrl, context),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                    child: _pickerBox(
                        selectedDate == null
                            ? "Select Date"
                            : "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}",
                        Icons.calendar_today,
                        context),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedTime = picked);
                      }
                    },
                    child: _pickerBox(
                        selectedTime == null
                            ? "Select Time"
                            : selectedTime!.format(context),
                        Icons.access_time,
                        context),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedLocation,
                    dropdownColor: theme.cardColor,
                    decoration: _dropdownDecoration(context),
                    items: ["Online", "Offline"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedLocation = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    dropdownColor: theme.cardColor,
                    decoration: _dropdownDecoration(context),
                    items: ["Workshop", "Meetup", "Webinar", "Conference"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedType = v!),
                  ),
                  const SizedBox(height: 12),
                  _input("Description", descCtrl, context, maxLines: 3),
                  const SizedBox(height: 12),
                  _input("Event Link", linkCtrl, context),
                  
                  const SizedBox(height: 12),

                  // IMAGE SELECTOR
                  InkWell(
                    onTap: () async {
                      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                      if (picked != null) {
                        setDialogState(() => eventImage = File(picked.path));
                      }
                    },
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: eventImage == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary),
                                SizedBox(height: 4),
                                Text("Add Event Image", style: TextStyle(fontSize: 12)),
                              ],
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.file(eventImage!, fit: BoxFit.cover),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary),
                onPressed: () async {
                  if (titleCtrl.text.isEmpty ||
                      selectedDate == null ||
                      selectedTime == null) {
                    return;
                  }

                  final user = FirebaseAuth.instance.currentUser!;
                  final snap = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .get();

                  String? imageUrl;
                  if (eventImage != null) {
                    imageUrl = await UploadService.uploadImage(eventImage!);
                  }

                  await FirebaseFirestore.instance.collection('events').add({
                    'title': titleCtrl.text.trim(),
                    'date':
                    "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}",
                    'time': selectedTime!.format(context),
                    'location': selectedLocation,
                    'type': selectedType,
                    'description': descCtrl.text.trim(),
                    'link': linkCtrl.text.trim(),
                    'imageUrl': imageUrl,
                    'ownerId': user.uid,
                    'ownerName': snap.data()?['name'] ?? "Alumni",
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                  Navigator.pop(context);
                },
                child: const Text("Post Event",
                    style: TextStyle(color: Colors.black)),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _pickerBox(String text, IconData icon, BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 10),
          Text(text),
        ],
      ),
    );
  }

  InputDecoration _dropdownDecoration(BuildContext context) {
    final theme = Theme.of(context);
    return InputDecoration(
      filled: true,
      fillColor: theme.scaffoldBackgroundColor,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none),
    );
  }

  Widget _input(String hint, TextEditingController c, BuildContext context,
      {int maxLines = 1}) {
    final theme = Theme.of(context);
    return TextField(
      controller: c,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: theme.scaffoldBackgroundColor,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
      ),
    );
  }

  Widget _filter(String label, String value, List<String> options,
      Function(String) onSelect, BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      onSelected: onSelect,
      color: theme.cardColor,
      itemBuilder: (_) =>
          options.map((e) => PopupMenuItem(value: e, child: Text(e))).toList(),
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Text(value == "All" ? label : value),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 18),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Events"),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month,
                color: AppColors.primary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const EventsCalendarScreen()),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          // SEARCH
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => search = v),
              decoration: InputDecoration(
                hintText: "Search event or location",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
              ),
            ),
          ),

          // FILTERS
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _filter("Location", locationFilter,
                    ["All", "Online", "Offline"],
                        (v) => setState(() => locationFilter = v), context),
                const SizedBox(width: 10),
                _filter("Date", dateFilter,
                    ["All", "Today", "This Week", "Upcoming"],
                        (v) => setState(() => dateFilter = v), context),
                const SizedBox(width: 10),
                _filter("Type", typeFilter,
                    ["All", "Workshop", "Meetup", "Webinar", "Conference"],
                        (v) => setState(() => typeFilter = v), context),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // EVENT LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('events')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                final events = snap.data!.docs.where((doc) {
                  final d = doc.data() as Map<String, dynamic>;

                  final searchMatch =
                      (d['title'] ?? "")
                          .toLowerCase()
                          .contains(search.toLowerCase()) ||
                          (d['location'] ?? "")
                              .toLowerCase()
                              .contains(search.toLowerCase());

                  final locMatch = locationFilter == "All" ||
                      d['location'] == locationFilter;

                  final dateMatch = dateFilter == "All" ||
                      _matchesDateFilter(d['date'] ?? "");

                  final typeMatch =
                      typeFilter == "All" || d['type'] == typeFilter;

                  return searchMatch && locMatch && dateMatch && typeMatch;
                }).toList();

                if (events.isEmpty) {
                  return Center(
                    child: Text(
                      "No events found",
                      style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: events.length,
                  itemBuilder: (_, i) {
                    final doc = events[i];
                    final d = doc.data() as Map<String, dynamic>;
                    final type = d['type'] ?? "Event";
                    final typeColor = _getTypeColor(type);

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                EventDetailScreen(eventId: doc.id),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: typeColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(Icons.event,
                                  color: typeColor),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d['title'] ?? "",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${d['date']} • ${d['location']}",
                                    style: TextStyle(
                                      color: theme.textTheme.bodyMedium?.color,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: typeColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                type,
                                style: TextStyle(
                                  color: typeColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: _openAddEventDialog,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text(
          "Post Event",
          style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
