// notification_test_screen.dart
// ⚠️  DEBUG ONLY — remove before releasing to production.
//
// Access from profile screen or add a route to it.
// Lets you fire every notification type instantly without waiting
// for the real triggers (hours away).
//
// How to use:
//   1. Add route in main.dart: '/notif-test': (_) => const NotificationTestScreen()
//   2. OR add a temporary button in ProfileScreen:
//      _menuTile(Icons.notifications, 'Test Notifications',
//        onTap: () => Navigator.push(context, MaterialPageRoute(
//          builder: (_) => const NotificationTestScreen())))

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../services/notification_service.dart';
import '../ui/appcolors.dart';

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});
  @override State<NotificationTestScreen> createState() => _State();
}

class _State extends State<NotificationTestScreen> {
  final _plugin = FlutterLocalNotificationsPlugin();
  String _log = 'Tap a button to fire a notification.\n\n'
      '📱 On a physical device: look at the notification shade.\n'
      '🖥️  On Android emulator: pull down from top.\n'
      '🍎 On iOS simulator: you must use a physical device for '
      'notifications to appear (iOS simulator does NOT show them).';

  void _addLog(String msg) =>
      setState(() => _log = '${DateTime.now().toIso8601String().substring(11,19)}  $msg\n\n$_log');

  // ── fire immediate ─────────────────────────────────────────────────────────
  Future<void> _fireImmediate(String title, String body, int id) async {
    try {
      await _plugin.show(id, title, body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel', 'Test Notifications',
            importance: Importance.max, priority: Priority.high,
            playSound: true),
          iOS: DarwinNotificationDetails(),
        ));
      _addLog('✅  Fired: "$title"');
    } catch (e) {
      _addLog('❌  Error: $e');
    }
  }

  // ── fire in N seconds ──────────────────────────────────────────────────────
  Future<void> _fireIn(int seconds, String title, String body, int id) async {
    try {
      await _plugin.zonedSchedule(
        id, title, body,
        tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds)),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel', 'Test Notifications',
            importance: Importance.max, priority: Priority.high),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      _addLog('⏳  Scheduled in ${seconds}s: "$title"\n   Lock screen & wait...');
    } catch (e) {
      _addLog('❌  Error: $e\n   Make sure SCHEDULE_EXACT_ALARM permission is granted.');
    }
  }

  // ── check pending ──────────────────────────────────────────────────────────
  Future<void> _checkPending() async {
    final pending = await _plugin.pendingNotificationRequests();
    if (pending.isEmpty) {
      _addLog('📭  No pending scheduled notifications.');
    } else {
      final lines = pending.map((n) => '  [${n.id}] ${n.title}').join('\n');
      _addLog('📬  ${pending.length} pending:\n$lines');
    }
  }

  Future<void> _cancelAll() async {
    await _plugin.cancelAll();
    _addLog('🗑️  All notifications cancelled.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('🔔 Notification Tester',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
            ),
            child: const Text('DEBUG',
                style: TextStyle(color: Colors.redAccent,
                    fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _section('Immediate (fires right now)'),
                _btn('🎉 Quiz Win notification', Colors.amber, () =>
                  _fireImmediate('Quest Complete! 🎉',
                    'You earned 35 XP on "The Entry Point"!', 1)),
                _btn('🔥 Streak warning', Colors.orange, () =>
                  _fireImmediate('Streak Alert! 🔥',
                    'Your 7-day streak is at risk! 5 mins keeps it alive.', 2)),
                _btn('👋 Miss-you nudge', Colors.purpleAccent, () =>
                  _fireImmediate('We miss you! 👋',
                    'The Logic Jungle misses you 🦫 Take a quick quiz?', 3)),
                _btn('💎 Motivation', AppColors.primary, () =>
                  _fireImmediate('Keep the momentum! 💎',
                    "You're already ahead today! Squeeze in one more quiz?", 4)),

                const SizedBox(height: 20),
                _section('Scheduled (background test)'),
                _btn('⏳ Fire in 10 seconds', Colors.cyanAccent, () =>
                  _fireIn(10, 'Scheduled test 🕐',
                    'This fired 10 seconds after you tapped! Lock screen & wait.', 10)),
                _btn('⏳ Fire in 30 seconds', Colors.tealAccent, () =>
                  _fireIn(30, 'Inactivity nudge 🦫',
                    "Don't break your streak — one quick quiz!", 11)),

                const SizedBox(height: 20),
                _section('Diagnostics'),
                _btn('📬 Check pending notifications', Colors.white54, _checkPending),
                _btn('🗑️  Cancel all pending', Colors.redAccent, _cancelAll),
                _btn('🔄 Re-initialize service', Colors.white38, () async {
                  await NotificationService().init();
                  _addLog('✅  NotificationService.init() called.');
                }),

                const SizedBox(height: 20),
                _section('Log'),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1117),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Text(_log,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontFamily: 'monospace',
                          fontSize: 12,
                          height: 1.5)),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(title.toUpperCase(),
        style: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2)),
  );

  Widget _btn(String label, Color color, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ),
    );
}
