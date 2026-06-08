import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ScheduleSheet extends StatefulWidget {
  final String deviceId;
  final String deviceName;

  const ScheduleSheet({
    super.key,
    required this.deviceId,
    required this.deviceName,
  });

  @override
  State<ScheduleSheet> createState() => _ScheduleSheetState();
}

class _ScheduleSheetState extends State<ScheduleSheet> {
  final user = FirebaseAuth.instance.currentUser;
  final dbRef = FirebaseDatabase.instance.ref();
  final Color primaryRed = const Color(0xFF8B0000);

  TimeOfDay? _onTime;
  TimeOfDay? _offTime;
  bool _enabled = false;
  bool _loading = true;

  /// Returns the device's current UTC offset as a readable string, e.g. "UTC+8"
  String get _timezoneLabel {
    final offset = DateTime.now().timeZoneOffset;
    final hours = offset.inMinutes ~/ 60;
    final minutes = offset.inMinutes.abs() % 60;
    final sign = hours >= 0 ? '+' : '-';
    if (minutes == 0) return 'UTC$sign${hours.abs()}';
    return 'UTC$sign${hours.abs()}:${minutes.toString().padLeft(2, '0')}';
  }

  /// Returns the raw offset in minutes (e.g. +480 for UTC+8)
  int get _timezoneOffsetMinutes => DateTime.now().timeZoneOffset.inMinutes;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    final snap = await dbRef
        .child('schedules')
        .child(user!.uid)
        .child(widget.deviceId)
        .get();

    if (snap.exists) {
      final data = snap.value as Map<dynamic, dynamic>;

      // If schedule was saved with a different timezone offset, warn the user
      final savedOffset = data['timezone_offset_minutes'] as int?;
      final currentOffset = _timezoneOffsetMinutes;

      if (savedOffset != null && savedOffset != currentOffset) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Timezone changed! Schedule was saved in a different timezone. '
                    'Please review and re-save.',
              ),
              backgroundColor: Colors.orange[800],
              duration: const Duration(seconds: 5),
            ),
          );
        });
      }

      final onParts  = (data['on_time']  as String).split(':');
      final offParts = (data['off_time'] as String).split(':');
      setState(() {
        _onTime  = TimeOfDay(hour: int.parse(onParts[0]),  minute: int.parse(onParts[1]));
        _offTime = TimeOfDay(hour: int.parse(offParts[0]), minute: int.parse(offParts[1]));
        _enabled = data['enabled'] ?? false;
      });
    }
    setState(() => _loading = false);
  }

  Future<void> _pickTime({required bool isOn}) async {
    final initial = isOn
        ? (_onTime  ?? const TimeOfDay(hour: 7,  minute: 0))
        : (_offTime ?? const TimeOfDay(hour: 22, minute: 0));

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: primaryRed),
        ),
        child: child!,
      ),
    );

    if (picked == null) return;
    setState(() {
      if (isOn) _onTime  = picked;
      else       _offTime = picked;
    });
  }

  String _fmt(TimeOfDay? t) {
    if (t == null) return 'Not set';
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _toHHmm(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';

  Future<void> _save() async {
    if (_onTime == null || _offTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set both on and off times.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await dbRef
        .child('schedules')
        .child(user!.uid)
        .child(widget.deviceId)
        .set({
      'on_time':                   _toHHmm(_onTime!),
      'off_time':                  _toHHmm(_offTime!),
      'enabled':                   _enabled,
      'device_id':                 widget.deviceId,
      'timezone_label':            _timezoneLabel,            // e.g. "UTC+8"
      'timezone_offset_minutes':   _timezoneOffsetMinutes,    // e.g. 480
    });

    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    await dbRef
        .child('schedules')
        .child(user!.uid)
        .child(widget.deviceId)
        .remove();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 16, 24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: _loading
          ? const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()))
          : Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title row
          Row(
            children: [
              Icon(Icons.schedule, color: primaryRed),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Schedule — ${widget.deviceName}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryRed,
                  ),
                ),
              ),
              // Enable toggle
              Row(
                children: [
                  Text(
                    _enabled ? 'On' : 'Off',
                    style: TextStyle(
                      color: _enabled ? primaryRed : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Switch(
                    value: _enabled,
                    onChanged: (v) => setState(() => _enabled = v),
                    activeColor: primaryRed,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Timezone info row
          Row(
            children: [
              Icon(Icons.public, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                'Times saved in your device timezone ($_timezoneLabel)',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Time pickers
          Row(
            children: [
              Expanded(child: _timeTile(label: 'Turn ON',  time: _onTime,  isOn: true)),
              const SizedBox(width: 12),
              Expanded(child: _timeTile(label: 'Turn OFF', time: _offTime, isOn: false)),
            ],
          ),
          const SizedBox(height: 28),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryRed,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Save Schedule',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),

          // Remove schedule (only if one exists)
          if (_onTime != null || _offTime != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _delete,
                child: Text(
                  'Remove Schedule',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _timeTile({
    required String label,
    required TimeOfDay? time,
    required bool isOn,
  }) {
    return GestureDetector(
      onTap: () => _pickTime(isOn: isOn),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isOn ? Colors.red[50] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOn ? primaryRed.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              isOn ? Icons.lightbulb_outlined : Icons.lightbulb_outline,
              color: isOn ? primaryRed : Colors.grey[500],
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _fmt(time),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isOn ? primaryRed : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to change',
              style: TextStyle(fontSize: 11, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }
}