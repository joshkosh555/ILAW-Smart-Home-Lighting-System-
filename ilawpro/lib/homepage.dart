import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ai_assistant.dart';
import 'package:get/get.dart';
import "loginpage.dart";
import 'schedule_sheet.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser;
  int _selectedIndex = 0;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();
  final TextEditingController _roomNameController = TextEditingController();
  final Color primaryRed = const Color(0xFF8B0000);
  final dbRef = FirebaseDatabase.instance.ref();
  int _selectedLedId = 1;
  Timer? _scheduleTimer;

  @override
  void initState() {
    super.initState();
    _startScheduleChecker();
  }

  @override
  void dispose() {
    _scheduleTimer?.cancel();
    super.dispose();
  }

  List<Widget> get _pages => [
    _dashboardPage(),
    _profilePage(),
  ];

  Future<void> signout() async {
    await FirebaseAuth.instance.signOut();
    Get.offAll(() => const LoginPage());
  }

  // ── Add Room Dialog ────────────────────────────
  Future<void> _addRoom() async {
    _roomNameController.clear();
    List<int> selectedLights = [];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: primaryRed,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      "Add New Room",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Room Name
                TextField(
                  controller: _roomNameController,
                  decoration: const InputDecoration(
                    labelText: 'Room Name',
                    border: OutlineInputBorder(),
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),

                // Light Selection
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Assign Lights',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700]),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [1, 2, 3].map((id) {
                    final selected = selectedLights.contains(id);
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              if (selected) {
                                selectedLights.remove(id);
                              } else {
                                selectedLights.add(id);
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selected ? primaryRed : Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color:
                                selected ? primaryRed : Colors.grey[300]!,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.lightbulb,
                                    color: selected
                                        ? Colors.white
                                        : Colors.grey[400],
                                    size: 28),
                                const SizedBox(height: 4),
                                Text(
                                  'Light $id',
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Cancel",
                          style:
                          TextStyle(color: Colors.black, fontSize: 16)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        final roomName = _roomNameController.text.trim();
                        if (roomName.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Room name is required!'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        if (selectedLights.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Please select at least one light!'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // Register each selected light as a device under the room
                        for (final ledId in selectedLights) {
                          final deviceId = 'led$ledId';
                          await dbRef
                              .child('devices')
                              .child(user!.uid)
                              .child(deviceId)
                              .set({
                            'name': 'Light $ledId',
                            'room': roomName,
                            'status': false,
                            'user_id': user!.uid,
                            'led_id': ledId,
                          });
                        }

                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryRed,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 26, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("Add Room",
                          style:
                          TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Edit Room Dialog ───────────────────────────
  /// [room] is the current room name.
  /// [currentLights] is the list of led IDs (1,2,3) already in that room.
  Future<void> _editRoom(
      String room, List<Map<String, dynamic>> roomDevices) async {
    _roomNameController.text = room;

    // Pre-fill currently assigned lights
    List<int> selectedLights =
    roomDevices.map((d) => d['led_id'] as int).toList();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: primaryRed,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      "Edit Room",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Room Name
                TextField(
                  controller: _roomNameController,
                  decoration: const InputDecoration(
                    labelText: 'Room Name',
                    border: OutlineInputBorder(),
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),

                // Light Selection
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Assign Lights',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700]),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [1, 2, 3].map((id) {
                    final selected = selectedLights.contains(id);
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              if (selected) {
                                selectedLights.remove(id);
                              } else {
                                selectedLights.add(id);
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selected ? primaryRed : Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color:
                                selected ? primaryRed : Colors.grey[300]!,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.lightbulb,
                                    color: selected
                                        ? Colors.white
                                        : Colors.grey[400],
                                    size: 28),
                                const SizedBox(height: 4),
                                Text(
                                  'Light $id',
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Cancel",
                          style:
                          TextStyle(color: Colors.black, fontSize: 16)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        final newRoomName = _roomNameController.text.trim();
                        if (newRoomName.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Room name is required!'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        if (selectedLights.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Please select at least one light!'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // 1. Remove devices that were de-selected
                        for (final device in roomDevices) {
                          final ledId = device['led_id'] as int;
                          if (!selectedLights.contains(ledId)) {
                            await dbRef
                                .child('devices')
                                .child(user!.uid)
                                .child(device['id'])
                                .remove();
                          }
                        }

                        // 2. Update room name & add newly selected lights
                        final existingLedIds =
                        roomDevices.map((d) => d['led_id'] as int).toSet();

                        for (final ledId in selectedLights) {
                          final deviceId = 'led$ledId';
                          if (existingLedIds.contains(ledId)) {
                            // Already exists — just update room name
                            await dbRef
                                .child('devices')
                                .child(user!.uid)
                                .child(deviceId)
                                .update({'room': newRoomName});
                          } else {
                            // Newly added light
                            await dbRef
                                .child('devices')
                                .child(user!.uid)
                                .child(deviceId)
                                .set({
                              'name': 'Light $ledId',
                              'room': newRoomName,
                              'status': false,
                              'user_id': user!.uid,
                              'led_id': ledId,
                            });
                          }
                        }

                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryRed,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 26, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("Save",
                          style:
                          TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Existing helpers (unchanged) ───────────────

  Future<void> _registerLight() async {
    _nameController.clear();
    _roomController.clear();

    await showDialog(
      context: context,
      builder: (_) => Dialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: primaryRed,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: const Center(
                  child: Text(
                    "Add New Light",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Light Name',
                  border: OutlineInputBorder(),
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _roomController,
                decoration: const InputDecoration(
                  labelText: 'Room',
                  border: OutlineInputBorder(),
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedLedId,
                decoration: const InputDecoration(
                  labelText: 'Light Selection',
                  border: OutlineInputBorder(),
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                items: [1, 2, 3]
                    .map((id) => DropdownMenuItem(
                  value: id,
                  child: Text('Light $id'),
                ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedLedId = val!),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel",
                        style:
                        TextStyle(color: Colors.black, fontSize: 16)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      if (_nameController.text.isEmpty ||
                          _roomController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                            Text('Light Name and Room are required!'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      String deviceId = 'led$_selectedLedId';
                      await dbRef
                          .child('devices')
                          .child(user!.uid)
                          .child(deviceId)
                          .set({
                        'name': _nameController.text,
                        'room': _roomController.text,
                        'status': false,
                        'user_id': user!.uid,
                        'led_id': _selectedLedId,
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryRed,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 26, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("Add",
                        style:
                        TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editDevice(
      String id, Map<String, dynamic> device) async {
    _nameController.text = device['name'];
    _roomController.text = device['room'];

    await showDialog(
      context: context,
      builder: (_) => Dialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: primaryRed,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: const Center(
                  child: Text(
                    "Edit Light",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Light Name',
                  border: OutlineInputBorder(),
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _roomController,
                decoration: const InputDecoration(
                  labelText: 'Room',
                  border: OutlineInputBorder(),
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel",
                        style:
                        TextStyle(color: Colors.black, fontSize: 16)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      await dbRef
                          .child('devices')
                          .child(user!.uid)
                          .child(id)
                          .update({
                        'name': _nameController.text,
                        'room': _roomController.text,
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryRed,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 26, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("Save",
                        style:
                        TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleDevice(String id, bool status) async {
    await dbRef.child('devices').child(user!.uid).child(id).update({
      'status': status,
    });
    if (status) {
      await AiAssistantSheet.recordLightOn(user!.uid, id);
    } else {
      await AiAssistantSheet.recordLightOff(user!.uid, id);
    }
  }

  Future<void> _toggleRoom(String room, bool status) async {
    final snapshot =
    await dbRef.child('devices').child(user!.uid).get();
    final devices =
        snapshot.value as Map<dynamic, dynamic>? ?? {};

    devices.forEach((key, value) {
      if (value['room'] == room) {
        dbRef
            .child('devices')
            .child(user!.uid)
            .child(key)
            .update({'status': status});
        if (status) {
          AiAssistantSheet.recordLightOn(user!.uid, key.toString());
        } else {
          AiAssistantSheet.recordLightOff(user!.uid, key.toString());
        }
      }
    });
  }

  Future<void> _toggleRoomBySchedule(
      String room,
      bool status,
      ) async {
    final snapshot =
    await dbRef.child('devices').child(user!.uid).get();

    final devices =
        snapshot.value as Map<dynamic, dynamic>? ?? {};

    for (final entry in devices.entries) {
      final key = entry.key.toString();
      final value = entry.value;

      if (value['room'] == room) {
        await dbRef
            .child('devices')
            .child(user!.uid)
            .child(key)
            .update({
          'status': status,
        });

        if (status) {
          await AiAssistantSheet.recordLightOn(
              user!.uid, key);
        } else {
          await AiAssistantSheet.recordLightOff(
              user!.uid, key);
        }
      }
    }
  }

  Future<void> _deleteDevice(String id) async {
    await dbRef
        .child('devices')
        .child(user!.uid)
        .child(id)
        .remove();
  }

  /// Deletes ALL devices belonging to a room.
  Future<void> _deleteRoom(List<Map<String, dynamic>> roomDevices) async {
    for (final device in roomDevices) {
      await dbRef
          .child('devices')
          .child(user!.uid)
          .child(device['id'])
          .remove();
    }
  }

  void _startScheduleChecker() {
    _checkSchedules();
    final now = DateTime.now();
    final secondsUntilNextMinute = 60 - now.second;
    Future.delayed(Duration(seconds: secondsUntilNextMinute), () {
      if (!mounted) return;
      _checkSchedules();
      _scheduleTimer =
          Timer.periodic(const Duration(seconds: 60), (_) {
            _checkSchedules();
          });
    });
  }

  String _lastTriggeredMinute = '';

  Future<void> _checkSchedules() async {
    final now = DateTime.now();
    final currentTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final currentOffsetMinutes = now.timeZoneOffset.inMinutes;

    if (currentTime == _lastTriggeredMinute) return;

    final snap = await dbRef.child('schedules').child(user!.uid).get();
    if (!snap.exists) return;

    final schedules = snap.value as Map<dynamic, dynamic>;
    bool triggered = false;

    // Track which device IDs were already handled by a device-level schedule
    final Set<String> handledDeviceIds = {};

    // ── Pass 1: Device-level schedules first ──────────────────
    for (final entry in schedules.entries) {
      final scheduleKey = entry.key.toString();
      if (scheduleKey.startsWith('room_')) continue; // skip rooms

      final data = entry.value as Map<dynamic, dynamic>;
      if (data['enabled'] != true) continue;

      final savedOffset = data['timezone_offset_minutes'] as int?;
      final effectiveOnTime  = _shiftTime(data['on_time']  as String, savedOffset, currentOffsetMinutes);
      final effectiveOffTime = _shiftTime(data['off_time'] as String, savedOffset, currentOffsetMinutes);

      final bool shouldTurnOn  = currentTime == effectiveOnTime;
      final bool shouldTurnOff = currentTime == effectiveOffTime;
      if (!shouldTurnOn && !shouldTurnOff) continue;

      // Toggle only this specific device
      await dbRef
          .child('devices')
          .child(user!.uid)
          .child(scheduleKey)
          .update({'status': shouldTurnOn});

      if (shouldTurnOn) {
        await AiAssistantSheet.recordLightOn(user!.uid, scheduleKey);
      } else {
        await AiAssistantSheet.recordLightOff(user!.uid, scheduleKey);
      }

      handledDeviceIds.add(scheduleKey); // mark as handled
      triggered = true;
    }

    // ── Pass 2: Room-level schedules (skip already-handled devices) ──
    for (final entry in schedules.entries) {
      final scheduleKey = entry.key.toString();
      if (!scheduleKey.startsWith('room_')) continue; // skip devices

      final data = entry.value as Map<dynamic, dynamic>;
      if (data['enabled'] != true) continue;

      final savedOffset = data['timezone_offset_minutes'] as int?;
      final effectiveOnTime  = _shiftTime(data['on_time']  as String, savedOffset, currentOffsetMinutes);
      final effectiveOffTime = _shiftTime(data['off_time'] as String, savedOffset, currentOffsetMinutes);

      final bool shouldTurnOn  = currentTime == effectiveOnTime;
      final bool shouldTurnOff = currentTime == effectiveOffTime;
      if (!shouldTurnOn && !shouldTurnOff) continue;

      final roomName = scheduleKey.substring(5); // strip "room_"

      // Get all devices in this room
      final snapshot = await dbRef.child('devices').child(user!.uid).get();
      final devices = snapshot.value as Map<dynamic, dynamic>? ?? {};

      for (final deviceEntry in devices.entries) {
        final deviceId = deviceEntry.key.toString();
        final deviceData = deviceEntry.value;

        if (deviceData['room'] != roomName) continue;

        // Skip — this device has its own schedule firing right now
        if (handledDeviceIds.contains(deviceId)) continue;

        await dbRef
            .child('devices')
            .child(user!.uid)
            .child(deviceId)
            .update({'status': shouldTurnOn});

        if (shouldTurnOn) {
          await AiAssistantSheet.recordLightOn(user!.uid, deviceId);
        } else {
          await AiAssistantSheet.recordLightOff(user!.uid, deviceId);
        }
      }
      triggered = true;
    }

    if (triggered) _lastTriggeredMinute = currentTime;
  }

  String _shiftTime(
      String hhmm, int? savedOffsetMinutes, int currentOffsetMinutes) {
    if (savedOffsetMinutes == null ||
        savedOffsetMinutes == currentOffsetMinutes) {
      return hhmm;
    }
    final parts = hhmm.split(':');
    final totalMinutes =
        int.parse(parts[0]) * 60 + int.parse(parts[1]);
    final utcMinutes = totalMinutes - savedOffsetMinutes;
    final shiftedMinutes =
        (utcMinutes + currentOffsetMinutes) % 1440;
    final normalised =
    shiftedMinutes < 0 ? shiftedMinutes + 1440 : shiftedMinutes;
    final h = (normalised ~/ 60).toString().padLeft(2, '0');
    final m = (normalised % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  // ── Dashboard page ─────────────────────────────
  Widget _dashboardPage() {
    final devicesStream =
        dbRef.child('devices').child(user!.uid).onValue;

    final schedulesStream =
        dbRef.child('schedules').child(user!.uid).onValue;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "D A S H B O A R D",
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
        backgroundColor: primaryRed,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: devicesStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.snapshot.value
          as Map<dynamic, dynamic>?;

          if (data == null || data.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'No devices yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  _addRoomButton(),
                ],
              ),
            );
          }

          return StreamBuilder<DatabaseEvent>(
            stream: schedulesStream,
            builder: (context, scheduleSnapshot) {

              final schedules =
                  scheduleSnapshot.data?.snapshot.value
                  as Map<dynamic, dynamic>? ?? {};

              final docs = data.entries
                  .map((e) => {
                'id': e.key,
                'name': e.value['name'],
                'room': e.value['room'],
                'status': e.value['status'] ?? false,
                'led_id': e.value['led_id'] ?? 1,
              })
                  .toList();

              final rooms =
              docs.map((e) => e['room'] as String).toSet().toList();

              return Padding(
                padding: const EdgeInsets.all(12.0),
                child: ListView(
                  children: [
                    ...rooms.map((room) {

                      final roomDevices = docs
                          .where((d) => d['room'] == room)
                          .toList()
                          .cast<Map<String, dynamic>>();

                      return Card(
                        color:
                        roomDevices.every((d) => d['status'] == true)
                            ? Colors.red[50]
                            : Colors.white,
                        margin:
                        const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [

                              // ── Room header row ──────────────
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [

                                  Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [

                                      Text(
                                        room,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: primaryRed,
                                        ),
                                      ),

                                      Builder(
                                        builder: (_) {

                                          final roomSchedule =
                                          schedules['room_$room']
                                          as Map<dynamic, dynamic>?;

                                          String roomScheduleText =
                                              'No schedule';

                                          if (roomSchedule != null &&
                                              roomSchedule['enabled'] == true) {

                                            roomScheduleText =
                                            'ON: ${roomSchedule['on_time']} | OFF: ${roomSchedule['off_time']}';
                                          }

                                          return Text(
                                            roomScheduleText,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),

                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Switch(
                                        value: roomDevices.every(
                                                (d) => d['status'] == true),
                                        onChanged: (value) =>
                                            _toggleRoom(room, value),
                                        activeColor: primaryRed,
                                      ),

                                      // Room-level menu (Edit / Delete)
                                      PopupMenuButton<String>(
                                        icon: const Icon(
                                            Icons.more_vert,
                                            color: Colors.black),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(12),
                                        ),
                                        elevation: 8,
                                        color: Colors.white,
                                        itemBuilder: (context) => [

                                          PopupMenuItem<String>(
                                            value: 'edit_room',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit, color: primaryRed),
                                                const SizedBox(width: 10),
                                                const Text(
                                                  'Edit Room',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          const PopupMenuDivider(),

                                          PopupMenuItem<String>(
                                            value: 'schedule_room',
                                            child: Row(
                                              children: [
                                                Icon(Icons.schedule, color: primaryRed),
                                                const SizedBox(width: 10),
                                                const Text(
                                                  'Schedule',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          const PopupMenuDivider(),

                                          const PopupMenuItem<String>(
                                            value: 'delete_room',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.delete,
                                                  color: Color(0xFF8B0000),
                                                ),
                                                SizedBox(width: 10),
                                                Text(
                                                  'Delete Room',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        onSelected: (value) {

                                          if (value == 'edit_room') {
                                            _editRoom(room, roomDevices);
                                          }

                                          if (value == 'schedule_room') {
                                            showModalBottomSheet(
                                              context: context,
                                              isScrollControlled: true,
                                              backgroundColor: Colors.transparent,
                                              builder: (_) => ScheduleSheet(
                                                deviceId: 'room_$room',
                                                deviceName: room,
                                              ),
                                            );
                                          }

                                          if (value == 'delete_room') {
                                            _deleteRoom(roomDevices);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // ── Device list ──────────────────
                              Column(
                                children:
                                roomDevices.map((device) {

                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,

                                    leading: Icon(
                                      Icons.lightbulb,
                                      color: device['status']
                                          ? primaryRed
                                          : Colors.grey[400],
                                    ),

                                    tileColor: device['status']
                                        ? Colors.red[50]
                                        : Colors.white,

                                    title: Text(
                                      device['name'],
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    subtitle: Builder(
                                      builder: (_) {

                                        final schedule =
                                        schedules[device['id']]
                                        as Map<dynamic, dynamic>?;

                                        String scheduleText =
                                            'No schedule';

                                        if (schedule != null &&
                                            schedule['enabled'] == true) {

                                          scheduleText =
                                          'ON: ${schedule['on_time']} | OFF: ${schedule['off_time']}';
                                        }

                                        return Text(
                                          scheduleText,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        );
                                      },
                                    ),

                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [

                                        Switch(
                                          value: device['status'],
                                          onChanged: (value) =>
                                              _toggleDevice(
                                                  device['id'], value),
                                          activeColor: primaryRed,
                                        ),

                                        PopupMenuButton<String>(
                                          icon: const Icon(
                                              Icons.more_vert,
                                              color: Colors.black),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(12),
                                          ),
                                          elevation: 8,
                                          color: Colors.white,
                                          itemBuilder: (context) => [

                                            PopupMenuItem<String>(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit,
                                                      color: primaryRed),
                                                  const SizedBox(width: 10),
                                                  const Text('Edit',
                                                      style: TextStyle(
                                                          fontSize: 16,
                                                          color:
                                                          Colors.black)),
                                                ],
                                              ),
                                            ),

                                            const PopupMenuDivider(),

                                            PopupMenuItem<String>(
                                              value: 'schedule',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.schedule,
                                                      color: primaryRed),
                                                  const SizedBox(width: 10),
                                                  const Text('Schedule',
                                                      style: TextStyle(
                                                          fontSize: 16,
                                                          color:
                                                          Colors.black)),
                                                ],
                                              ),
                                            ),

                                            const PopupMenuDivider(),

                                            const PopupMenuItem<String>(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete,
                                                      color:
                                                      Color(0xFF8B0000)),
                                                  SizedBox(width: 10),
                                                  Text('Delete',
                                                      style: TextStyle(
                                                          fontSize: 16,
                                                          color:
                                                          Colors.black)),
                                                ],
                                              ),
                                            ),
                                          ],

                                          onSelected: (value) {

                                            if (value == 'edit') {
                                              _editDevice(
                                                  device['id'], device);
                                            }

                                            if (value == 'schedule') {
                                              showModalBottomSheet(
                                                context: context,
                                                isScrollControlled: true,
                                                backgroundColor:
                                                Colors.transparent,
                                                builder: (_) => ScheduleSheet(
                                                  deviceId: device['id'],
                                                  deviceName: device['name'],
                                                ),
                                              );
                                            }

                                            if (value == 'delete') {
                                              _deleteDevice(device['id']);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  );

                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 8),

                    // ── Bottom action buttons ──────────
                    _addRoomButton(),

                    const SizedBox(height: 10),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _addRoomButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _addRoom,
        icon: const Icon(Icons.meeting_room, color: Colors.white),
        label: const Text(
          'Add New Room',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRed,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }



  // ── Profile page ───────────────────────────────
  Widget _profilePage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "P R O F I L E",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: primaryRed,
      ),
      body: SafeArea(
        child: Container(
          color: Colors.white,
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Column(
                  children: [
                    Icon(Icons.account_circle,
                        size: 120, color: primaryRed),
                    const SizedBox(height: 10),
                    Text(
                      user?.email ?? 'User',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: ElevatedButton(
                  onPressed: signout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryRed,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("L O G  O U T",
                      style: TextStyle(
                          color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Main build ─────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _pages[_selectedIndex],
          if (_selectedIndex == 0)
            const Positioned(
              right: 16,
              bottom: 16,
              child: AiAssistantFab(),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: primaryRed,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      floatingActionButton: null,
    );
  }
}