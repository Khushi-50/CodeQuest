import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

// Notification IDs
const int _kStreakNudgeId = 101;
const int _kMissYouId = 102;
const int _kKeepGoingId = 103;
const int _kInactivityId = 104; // used by homem.dart's scheduleInactivityNudge
const int _kQuizWinIdBase = 200;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ── INIT ───────────────────────────────────────────────────────────────────
  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  // ── CALLED ON EVERY APP OPEN (smart scheduling) ────────────────────────────
  Future<void> onAppOpen({
    required bool didActivityToday,
    required int streak,
  }) async {
    // Cancel stale notifications from previous session
    await _plugin.cancel(_kStreakNudgeId);
    await _plugin.cancel(_kMissYouId);
    await _plugin.cancel(_kKeepGoingId);
    await _plugin.cancel(_kInactivityId);

    if (didActivityToday) {
      // Already active today — schedule a softer "keep going" nudge
      await _scheduleMotivation();
    } else if (streak > 0) {
      // Has a streak but hasn't done anything today → urgent 8-hour warning
      await _scheduleStreakWarning(hoursFromNow: 8, streak: streak);
    } else {
      // Cold / new user — gentle miss-you in 24h
      await _scheduleMissYou(hoursFromNow: 24);
    }
  }

  // ── CALLED WHEN APP GOES TO BACKGROUND ────────────────────────────────────
  Future<void> onAppBackground({
    required bool didActivityToday,
    required int streak,
  }) async {
    if (!didActivityToday && streak > 0) {
      await _plugin.cancel(_kStreakNudgeId);
      await _scheduleStreakWarning(hoursFromNow: 4, streak: streak);
    }
  }

  // ── USED BY homem.dart (legacy compatibility) ──────────────────────────────
  /// Cancel the inactivity nudge — call when app opens so stale ones are cleared.
  Future<void> cancelNudge() async {
    await _plugin.cancel(_kInactivityId);
    await _plugin.cancel(_kStreakNudgeId);
    await _plugin.cancel(_kMissYouId);
    await _plugin.cancel(_kKeepGoingId);
  }

  /// Schedule a generic inactivity nudge 23h from now.
  /// Used by homem.dart's initState so the old home screen still compiles.
  Future<void> scheduleInactivityNudge() async {
    const messages = [
      "The Logic Jungle misses you! 🦫 Tap for a quick quiz.",
      "Your capybara is waiting. Come back for 5 mins? 🦫",
      "Don't let your skills go rusty — play a round! 🎯",
    ];
    final body = messages[Random().nextInt(messages.length)];

    try {
      await _plugin.zonedSchedule(
        _kInactivityId,
        "CodeQuest is calling! 👋",
        body,
        tz.TZDateTime.now(tz.local).add(const Duration(hours: 23)),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'nudge_channel',
            'Daily Reminders',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // Silently fail on emulator / permission not granted
    }
  }

  // ── INSTANT WIN NOTIFICATION ───────────────────────────────────────────────
  Future<void> showQuizWin({
    required String topicName,
    required int xpEarned,
  }) async {
    final messages = [
      'You just earned $xpEarned XP on "$topicName"! 🚀',
      'Logic unlocked: $topicName. +$xpEarned XP added! 🧠',
      'One step closer to the leaderboard! +$xpEarned XP 🏆',
      'Your brain just got an upgrade. +$xpEarned XP ✨',
    ];
    final body = messages[Random().nextInt(messages.length)];

    try {
      await _plugin.show(
        _kQuizWinIdBase + Random().nextInt(50),
        'Quest Complete! 🎉',
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'quiz_win_channel',
            'Quiz Wins',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (_) {}
  }

  // ── PRIVATE SCHEDULERS ─────────────────────────────────────────────────────

  Future<void> _scheduleStreakWarning({
    required int hoursFromNow,
    required int streak,
  }) async {
    final messages = [
      "Your $streak-day streak is at risk! 🔥 Just 5 mins keeps it alive.",
      "Don't lose your $streak-day streak! Quick quiz before midnight?",
      "$streak days strong — don't let today break it! 💪",
    ];
    final body = messages[Random().nextInt(messages.length)];

    try {
      await _plugin.zonedSchedule(
        _kStreakNudgeId,
        "Streak Alert! 🔥",
        body,
        tz.TZDateTime.now(tz.local).add(Duration(hours: hoursFromNow)),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'streak_channel',
            'Streak Reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {}
  }

  Future<void> _scheduleMotivation() async {
    final messages = [
      "You're already ahead today! Squeeze in one more quiz? 🎯",
      "Great session! One more lesson and you could climb the leaderboard. 📈",
      "You're on a roll! Keep building that momentum. 🚀",
    ];
    final body = messages[Random().nextInt(messages.length)];

    try {
      await _plugin.zonedSchedule(
        _kKeepGoingId,
        "Keep the momentum! 💎",
        body,
        tz.TZDateTime.now(tz.local).add(const Duration(hours: 6)),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'motivation_channel',
            'Motivation',
            importance: Importance.low,
            priority: Priority.low,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {}
  }

  Future<void> _scheduleMissYou({required int hoursFromNow}) async {
    final messages = [
      "The Logic Jungle misses you! 🦫 Take a quick quiz?",
      "Your capybara is lonely. Come back for 5 mins? 🦫",
      "Did you forget about CodeQuest? We saved your progress!",
    ];
    final body = messages[Random().nextInt(messages.length)];

    try {
      await _plugin.zonedSchedule(
        _kMissYouId,
        "We miss you! 👋",
        body,
        tz.TZDateTime.now(tz.local).add(Duration(hours: hoursFromNow)),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'nudge_channel',
            'Daily Reminders',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {}
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
