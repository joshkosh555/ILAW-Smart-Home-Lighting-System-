import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';


// ─────────────────────────────────────────────
// 🔑 OpenRouter config
// ─────────────────────────────────────────────
const String _openRouterApiKey = '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';
const String _openRouterModel  = 'openrouter/owl-alpha';



// ── Animated Lumi Robot Widget ─────────────────
class LumiRobot extends StatefulWidget {
  final double size;
  const LumiRobot({super.key, this.size = 60});

  @override
  State<LumiRobot> createState() => _LumiRobotState();
}

class _LumiRobotState extends State<LumiRobot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(
          painter: LumiPainter(_ctrl.value),
        ),
      ),
    );
  }
}

// ── CustomPainter ──────────────────────────────
class LumiPainter extends CustomPainter {
  final double t; // 0.0 → 1.0, repeating
  LumiPainter(this.t);

  static const Color _dark = Color(0xFF8B0000);
  static const Color _mid  = Color(0xFFAA1111);

  @override
  void paint(Canvas canvas, Size size) {
    final double tick = t * 2 * pi;
    final double scale = size.width / 100.0;

    canvas.save();
    canvas.scale(scale, scale);

    final double floatY = sin(tick) * 3;
    canvas.translate(0, floatY);

    final cx = 50.0;

    // ── Antenna ──────────────────────────────────
    final antPaint = Paint()
      ..color = _dark
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx, 14), Offset(cx, 4), antPaint);

    // Antenna glow pulse
    final double pulse = (sin(tick * 3) + 1) / 2;
    final glowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      ..color = Color.fromRGBO(255, 80, 80, 0.5 + pulse * 0.4);
    canvas.drawCircle(Offset(cx, 2), 4, glowPaint);

    final ballPaint = Paint()..color = Color.lerp(
        const Color(0xFFFF6666), const Color(0xFFFF2222), pulse)!;
    canvas.drawCircle(Offset(cx, 2), 2.5, ballPaint);

    // ── Head ─────────────────────────────────────
    _roundRect(canvas, cx - 20, 14, 40, 28, 7, _dark);

    // ── Eyes ─────────────────────────────────────
    // Blink: blink every ~3s, duration ~0.2s
    final double blinkPhase = (t * 3) % 1.0;
    final bool blink = blinkPhase > 0.9;
    final double eyeScaleY = blink ? max(0.05, 1 - (blinkPhase - 0.9) / 0.1 * 2) : 1.0;

    for (final ex in [cx - 8.0, cx + 8.0]) {
      // Eye white
      canvas.save();
      canvas.scale(1, eyeScaleY);
      final wPaint = Paint()..color = Colors.white;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(ex, 24 / eyeScaleY), width: 10, height: 10),
        wPaint,
      );
      // Pupil
      final pPaint = Paint()..color = const Color(0xFFFF3333);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(ex + 0.5, 25 / eyeScaleY), width: 6, height: 6),
        pPaint,
      );
      // Eye shine
      final sPaint = Paint()..color = Colors.white.withOpacity(0.7);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(ex + 1.5, 23 / eyeScaleY), width: 3, height: 2),
        sPaint,
      );
      canvas.restore();
    }

    // ── Smile ─────────────────────────────────────
    final smilePaint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path();
    path.moveTo(cx - 8, 38);
    path.quadraticBezierTo(cx, 43, cx + 8, 38);
    canvas.drawPath(path, smilePaint);

    // ── Neck ──────────────────────────────────────
    _roundRect(canvas, cx - 5, 42, 10, 5, 2, _dark);

    // ── Body ──────────────────────────────────────
    _roundRect(canvas, cx - 22, 47, 44, 36, 8, _dark);
    _roundRect(canvas, cx - 15, 52, 30, 22, 5, _mid);

    // ── Chest lights (animated) ────────────────────
    final lights = [
      (_mid.withRed(255).withGreen(40).withBlue(80),  cx - 10.0, 0.0),
      (const Color(0xFFFFAA33), cx,        1.0),
      (const Color(0xFF44EE88), cx + 10.0, 2.1),
    ];
    for (final (color, lx, phase) in lights) {
      final lp = (sin(tick * 3 + phase) + 1) / 2;
      final lGlow = Paint()
        ..color = color.withOpacity(0.35 + lp * 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawCircle(Offset(lx, 63), 5, lGlow);
      final lPaint = Paint()..color = color.withOpacity(0.6 + lp * 0.4);
      canvas.drawCircle(Offset(lx, 63), 3, lPaint);
    }

    // ── Arms (swinging) ───────────────────────────
    final double swing = sin(tick) * 4;
    canvas.save();
    canvas.translate(0, swing);
    _roundRect(canvas, cx - 38, 47, 14, 28, 6, _dark);
    canvas.restore();
    canvas.save();
    canvas.translate(0, -swing);
    _roundRect(canvas, cx + 24, 47, 14, 28, 6, _dark);
    canvas.restore();

    // Arm joints
    final jointPaint = Paint()..color = _mid;
    canvas.drawCircle(Offset(cx - 31, 47 + swing), 4.5, jointPaint);
    canvas.drawCircle(Offset(cx + 31, 47 - swing), 4.5, jointPaint);

    // ── Legs ──────────────────────────────────────
    _roundRect(canvas, cx - 18, 83, 13, 14, 4, _mid);
    _roundRect(canvas, cx + 5,  83, 13, 14, 4, _mid);

    // ── Feet ──────────────────────────────────────
    _roundRect(canvas, cx - 21, 94, 17, 8, 3, _dark);
    _roundRect(canvas, cx + 4,  94, 17, 8, 3, _dark);

    canvas.restore();

    // ── Shadow ────────────────────────────────────
    final shadowScale = 0.85 + sin(tick) * 0.1;
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.99),
        width:  size.width * 0.55 * shadowScale,
        height: size.height * 0.06,
      ),
      shadowPaint,
    );
  }

  void _roundRect(Canvas c, double x, double y, double w, double h, double r, Color color) {
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(LumiPainter old) => old.t != t;
}
// ─────────────────────────────────────────────
// 📊 Usage data model
// ─────────────────────────────────────────────
class DeviceUsage {
  final String id;
  final String name;
  final String room;
  final bool   status;
  final double realHoursPerDay;
  final double hoursThisMonth;
  final double avgHoursPerDay30;
  final double trendDelta;

  const DeviceUsage({
    required this.id,
    required this.name,
    required this.room,
    required this.status,
    required this.realHoursPerDay,
    required this.hoursThisMonth,
    required this.avgHoursPerDay30,
    required this.trendDelta,
  });
}

// ─────────────────────────────────────────────
// 🔴 Floating AI Button
// ─────────────────────────────────────────────
class AiAssistantFab extends StatefulWidget {
  const AiAssistantFab({super.key});

  @override
  State<AiAssistantFab> createState() => _AiAssistantFabState();
}

class _AiAssistantFabState extends State<AiAssistantFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double>   _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: GestureDetector(
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const AiAssistantSheet(),
        ),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: const Color(0xFF8B0000), width: 2.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B0000).withOpacity(0.4),
                blurRadius: 16,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Center(child: LumiRobot(size: 44)),
              Positioned(
                right: 3,
                top: 3,
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 📋 AI Assistant Bottom Sheet
// ─────────────────────────────────────────────
class AiAssistantSheet extends StatefulWidget {
  const AiAssistantSheet({super.key});

  // ── Static methods callable from anywhere ──
  static Future<void> recordLightOn(String uid, String deviceId) async {
    await FirebaseDatabase.instance
        .ref('timestamps/$uid/$deviceId')
        .update({
      'lastTurnedOn': ServerValue.timestamp,
      'status': true,
      // ✅ removed 'todayHours': 0.0  ← was resetting hours every ON
    });
  }

  static Future<void> recordLightOff(String uid, String deviceId) async {
    final ref  = FirebaseDatabase.instance.ref('timestamps/$uid/$deviceId');
    final snap = await ref.get();

    if (!snap.exists || snap.value is! Map) return;

    final data         = Map<String, dynamic>.from(snap.value as Map);
    final onTs         = (data['lastTurnedOn'] as num?)?.toInt() ?? 0;
    final offTs        = DateTime.now().millisecondsSinceEpoch;
    final sessionHours = onTs > 0 ? (offTs - onTs) / 3600000.0 : 0.0;

    // ✅ read from accumulatedToday (not usage_log)
    final prevAccumulated = (data['accumulatedToday'] as num?)?.toDouble() ?? 0.0;
    final newAccumulated  = prevAccumulated + sessionHours;

    final today  = _todayKey();
    final logRef = FirebaseDatabase.instance.ref('usage_log/$uid/$deviceId/$today');

    await Future.wait([
      ref.update({
        'lastTurnedOff':    offTs,
        'status':           false,
        'accumulatedToday': newAccumulated,  // ✅ single source of truth
      }),
      logRef.set(newAccumulated),            // ✅ mirrors to usage_log for history
    ]);
  }

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  State<AiAssistantSheet> createState() => _AiAssistantSheetState();
}

class _AiAssistantSheetState extends State<AiAssistantSheet>
    with SingleTickerProviderStateMixin {
  final user  = FirebaseAuth.instance.currentUser;
  final dbRef = FirebaseDatabase.instance.ref();

  static const Color _red      = Color(0xFF8B0000);
  static const Color _redLight = Color(0xFFB71C1C);
  static const Color _cardBg   = Color(0xFFF9F9F9);
  static const Color _greenDot = Color(0xFF4CAF50);

  bool   _isLoading    = false;
  bool   _hasGenerated = false;
  String _aiResponse   = '';

  double _currentMonthlyCost   = 0;
  double _projectedMonthlyCost = 0;
  double _totalKwhThisMonth    = 0;
  int    _devicesOn            = 0;

  late AnimationController _fadeController;
  late Animation<double>   _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // ── Fetch enriched devices ─────────────────────
  Future<List<DeviceUsage>> _fetchEnrichedDevices() async {
    final uid = user!.uid;
    final now = DateTime.now();

    DataSnapshot? devicesSnap;
    DataSnapshot? timestampsSnap;
    DataSnapshot? logSnap;

    try { devicesSnap    = await dbRef.child('devices/$uid').get(); }    catch (e) { debugPrint('devices error: $e'); }
    try { timestampsSnap = await dbRef.child('timestamps/$uid').get(); } catch (e) { debugPrint('timestamps error: $e'); }
    try { logSnap        = await dbRef.child('usage_log/$uid').get(); }  catch (e) { debugPrint('usage_log error: $e'); }

    if (devicesSnap == null || !devicesSnap.exists || devicesSnap.value is! Map) return [];

    final devicesRaw    = Map<dynamic, dynamic>.from(devicesSnap.value as Map);
    final timestampsMap = (timestampsSnap != null && timestampsSnap.exists && timestampsSnap.value is Map)
        ? Map<dynamic, dynamic>.from(timestampsSnap.value as Map)
        : <dynamic, dynamic>{};
    final logMap        = (logSnap != null && logSnap.exists && logSnap.value is Map)
        ? Map<dynamic, dynamic>.from(logSnap.value as Map)
        : <dynamic, dynamic>{};

    final List<DeviceUsage> result = [];

    for (final entry in devicesRaw.entries) {
      final id = entry.key.toString();
      if (entry.value is! Map) continue;

      final d   = Map<String, dynamic>.from(entry.value as Map);
      final ts  = (timestampsMap[id] is Map)
          ? Map<String, dynamic>.from(timestampsMap[id] as Map)
          : <String, dynamic>{};
      final log = (logMap[id] is Map)
          ? Map<String, dynamic>.from(logMap[id] as Map)
          : <String, dynamic>{};

      final bool isOn = d['status'] == true;

      // ✅ Step 1: Start with completed sessions saved on last OFF
      final double accumulatedToday = (ts['accumulatedToday'] as num?)?.toDouble() ?? 0.0;
      double liveHours = 0.0;
      if (isOn && ts['lastTurnedOn'] != null) {
        final onTs = (ts['lastTurnedOn'] as num?)?.toInt() ?? 0;
        if (onTs > 0) liveHours = (DateTime.now().millisecondsSinceEpoch - onTs) / 3600000.0;
      }

      final double todayHours = accumulatedToday + liveHours;


      // ✅ Step 3: Loop starts at i=1 (yesterday and before) — today handled separately
      double totalHours30   = todayHours; // today already included here
      double totalHoursThis = todayHours; // today already included here
      double week1Hours     = todayHours; // i=0 (today) counts toward week1
      double week2Hours     = 0;

      for (int i = 1; i < 30; i++) { // ✅ Start at 1, not 0
        final day = now.subtract(Duration(days: i));
        final key = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        final h   = (log[key] as num?)?.toDouble() ?? 0.0;

        totalHours30 += h;
        if (day.month == now.month) totalHoursThis += h;
        if (i < 7)             week1Hours += h;  // days 1–6
        if (i >= 7 && i < 14) week2Hours += h;  // days 7–13
      }
      // ✅ No more totalHoursThis += todayHours at the end

      result.add(DeviceUsage(
        id:               id,
        name:             d['name']?.toString()  ?? 'Unknown',
        room:             d['room']?.toString()  ?? 'Unknown',
        status:           isOn,
        realHoursPerDay:  todayHours,
        hoursThisMonth:   totalHoursThis,
        avgHoursPerDay30: totalHours30 / 30.0,
        trendDelta:       (week1Hours / 7.0) - (week2Hours / 7.0),
      ));
    }

    return result;
  }

  // ── Calculate summary stats ────────────────────
  void _calcStats(List<DeviceUsage> devices) {
    const double watt     = 9.0;
    const double rate     = 10.0;
    final now             = DateTime.now();
    final daysInMonth     = DateTime(now.year, now.month + 1, 0).day;
    final dayOfMonth      = now.day;

    double kwhSoFar = 0;
    int    on       = 0;

    for (final d in devices) {
      kwhSoFar += d.hoursThisMonth * watt / 1000.0;
      if (d.status) on++;
    }

    _devicesOn            = on;
    _totalKwhThisMonth    = kwhSoFar;
    _currentMonthlyCost   = kwhSoFar * rate;

    final dailyRate       = dayOfMonth > 0 ? _currentMonthlyCost / dayOfMonth : 0.0;
    _projectedMonthlyCost = dailyRate * daysInMonth.toDouble();
  }

  // ── Build prompt ───────────────────────────────
  String _buildPrompt(List<DeviceUsage> devices) {
    const double watt = 9.0;
    const double rate = 10.0;
    final now         = DateTime.now();
    final dayOfMonth  = now.day;
    final daysLeft    = DateTime(now.year, now.month + 1, 0).day - dayOfMonth;

    final rooms = <String, Map<String, dynamic>>{};
    for (final d in devices) {
      rooms.putIfAbsent(d.room, () => {'total': 0, 'on': 0, 'kwhMonth': 0.0, 'trend': 0.0});
      rooms[d.room]!['total'] = (rooms[d.room]!['total'] as int) + 1;
      if (d.status) rooms[d.room]!['on'] = (rooms[d.room]!['on'] as int) + 1;
      rooms[d.room]!['kwhMonth'] = (rooms[d.room]!['kwhMonth'] as double) + d.hoursThisMonth * watt / 1000;
      rooms[d.room]!['trend']    = (rooms[d.room]!['trend'] as double) + d.trendDelta;
    }

    final roomLines = rooms.entries.map((e) {
      final kwh   = (e.value['kwhMonth'] as double).toStringAsFixed(2);
      final cost  = ((e.value['kwhMonth'] as double) * rate).toStringAsFixed(2);
      final trend = e.value['trend'] as double;
      final arrow = trend > 0.3 ? '⬆ using more' : trend < -0.3 ? '⬇ using less' : '➡ stable';
      return '  • ${e.key}: ${e.value['on']}/${e.value['total']} ON | ${kwh} kWh | ₱${cost} | trend: $arrow';
    }).join('\n');

    final deviceLines = devices.map((d) {
      final todayKwh  = (d.realHoursPerDay * watt / 1000).toStringAsFixed(3);
      final monthCost = (d.hoursThisMonth * watt / 1000 * rate).toStringAsFixed(2);
      final trend     = d.trendDelta > 0.5 ? '📈' : d.trendDelta < -0.5 ? '📉' : '➡';
      return '  • ${d.name} [${d.room}] — ${d.status ? "🟢 ON" : "⚫ OFF"} | today: ${d.realHoursPerDay.toStringAsFixed(1)}h ($todayKwh kWh) | month so far: ₱$monthCost $trend';
    }).join('\n');

    return '''
You are Lumi, a smart home energy assistant. Be warm, specific, and use emojis.

TODAY: Day $dayOfMonth of month ($daysLeft days left)
ACTUAL USAGE DATA (real hours tracked):
- Devices: ${devices.length} total | $_devicesOn currently ON
- kWh used this month: ${_totalKwhThisMonth.toStringAsFixed(2)}
- Cost so far: ₱${_currentMonthlyCost.toStringAsFixed(2)}
- Projected month-end bill: ₱${_projectedMonthlyCost.toStringAsFixed(2)}
- Rate: ₱10/kWh, 9W LED bulbs

ROOMS (actual usage):
$roomLines

EACH DEVICE (real tracked hours):
$deviceLines

Reply with ONLY these 4 sections (short and friendly):

📊 This Month — mention actual kWh, current cost (₱${_currentMonthlyCost.toStringAsFixed(2)}), and projected bill (₱${_projectedMonthlyCost.toStringAsFixed(2)})
💡 Room Tips — one specific tip per room based on their actual trend data
📈 Trending — call out any device using significantly more or less than last week
⚡ Quick Win — the single easiest action to save the most money before month-end

Max 220 words. Reference real numbers. Sound like a helpful friend.
''';
  }

  // ── Generate recommendations ───────────────────
  Future<void> _generateRecommendations() async {
    setState(() { _isLoading = true; _aiResponse = ''; _hasGenerated = false; });

    try {
      final devices = await _fetchEnrichedDevices();

      if (devices.isEmpty) {
        setState(() {
          _aiResponse   = '⚠️ No lights found yet!\nAdd some lights on the Dashboard first.';
          _hasGenerated = true;
          _isLoading    = false;
        });
        _fadeController.forward(from: 0);
        return;
      }

      _calcStats(devices);

      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $_openRouterApiKey',
          'HTTP-Referer':  'https://ilaw-app.com',
          'X-Title':       'Lumi Energy Assistant',
        },
        body: jsonEncode({
          'model':    _openRouterModel,
          'messages': [{'role': 'user', 'content': _buildPrompt(devices)}],
          'max_tokens':  500,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data    = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        setState(() { _aiResponse = content.trim(); _hasGenerated = true; });
        _fadeController.forward(from: 0);
      } else {
        setState(() {
          _aiResponse   = '❌ API Error ${response.statusCode}.\n${response.body}';
          _hasGenerated = true;
        });
        _fadeController.forward(from: 0);
      }
    } catch (e) {
      setState(() { _aiResponse = '❌ Error:\n$e'; _hasGenerated = true; });
      _fadeController.forward(from: 0);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── Build UI ───────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Container(
      height: mq.size.height * 0.92,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft:  Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          if (_hasGenerated && !_isLoading) _buildStatsBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  if (!_hasGenerated && !_isLoading) _buildIntroSection(),
                  if (_isLoading)                    _buildLoadingSection(),
                  if (_hasGenerated && !_isLoading)  _buildResponseSection(),
                ],
              ),
            ),
          ),
          _buildActionButton(mq),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
          colors: [_red, _redLight],
        ),
        borderRadius: BorderRadius.only(
          topLeft:  Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)],
            ),
            child: ClipOval(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: LumiRobot(size: 44),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Lumi',
                  style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 7, height: 7,
                      decoration: const BoxDecoration(color: _greenDot, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    const Text('Online · Smart Energy Advisor',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBanner() {
    return Container(
      color: const Color(0xFFFFF5F5),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statChip('⚡', '${_totalKwhThisMonth.toStringAsFixed(1)} kWh', 'This month'),
          _statChip('₱', _currentMonthlyCost.toStringAsFixed(0), 'Cost so far'),
          _statChip('📅', '₱${_projectedMonthlyCost.toStringAsFixed(0)}', 'Projected'),
          _statChip('💡', '$_devicesOn ON', 'Right now'),
        ],
      ),
    );
  }

  Widget _statChip(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 2),
        Text(value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _red),
        ),
        Text(label,
          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildIntroSection() {
    final items = [
      ('⏱', 'Real hours tracked per device'),
      ('📈', 'Week-over-week usage trends'),
      ('₱',  'Exact cost per room & device'),
      ('📅', 'Projected month-end bill'),
    ];

    return Column(
      children: [
        const SizedBox(height: 14),
        Container(
          width: 116, height: 116,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFFF0F0),
            boxShadow: [
              BoxShadow(color: _red.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 6)),
            ],
          ),
          child: Center(child: LumiRobot(size: 82)),
        ),
        const SizedBox(height: 18),
        const Text("Hi, I'm Lumi! 👋",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          "I track your real usage data and give you a true picture of your electricity bill.",
          style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.55),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5F5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFCDD2), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.analytics_outlined, color: _red, size: 18),
                  SizedBox(width: 8),
                  Text("What I analyze:",
                    style: TextStyle(fontWeight: FontWeight.bold, color: _red, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(item.$1, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Text(item.$2, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                  ],
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSection() {
    return Column(
      children: [
        const SizedBox(height: 60),
        Stack(
          alignment: Alignment.center,
          children: [
            const SizedBox(
              width: 88, height: 88,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(_red),
              ),
            ),
            Container(
              width: 68, height: 68,
              decoration: const BoxDecoration(color: Color(0xFFFFF0F0), shape: BoxShape.circle),
              child: Center(child: LumiRobot(size: 48)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Lumi is analyzing your data...',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _red),
        ),
        const SizedBox(height: 8),
        Text('Checking real usage hours & trends',
          style: TextStyle(fontSize: 13, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildResponseSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: const BoxDecoration(color: Color(0xFFFFF0F0), shape: BoxShape.circle),
                child: Center(child: LumiRobot(size: 26)),
              ),
              const SizedBox(width: 10),
              const Text('Lumi',
                style: TextStyle(fontWeight: FontWeight.bold, color: _red, fontSize: 14),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('AI',
                  style: TextStyle(color: _red, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: const BorderRadius.only(
                topRight:    Radius.circular(16),
                bottomLeft:  Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: const Color(0xFFEEEEEE)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              _aiResponse,
              style: const TextStyle(fontSize: 14, height: 1.65, color: Color(0xFF2C2C2C)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.verified_outlined, size: 13, color: Colors.grey),
              const SizedBox(width: 5),
              Text('Based on your actual tracked usage data',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(MediaQueryData mq) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, mq.padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : _generateRecommendations,
          icon: Icon(
            _hasGenerated ? Icons.refresh_rounded : Icons.bolt_rounded,
            color: Colors.white,
            size: 20,
          ),
          label: Text(
            _hasGenerated ? 'Refresh Analysis' : 'Analyze My Usage',
            style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _red,
            disabledBackgroundColor: Colors.grey[200],
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}