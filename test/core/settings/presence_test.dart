import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/settings/presence.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
  });

  group('echo placement', () {
    test('caps top showings per week and resets on Monday', () async {
      final monday = DateTime.utc(2026, 10, 26);
      final presence = Presence(prefs, today: monday);

      expect(presence.echoAtTop, isTrue);
      await presence.recordEchoTop();
      expect(presence.echoTopCount, 1);
      expect(presence.echoAtTop, isTrue);

      await presence.recordEchoTop();
      expect(presence.echoTopCount, 2);
      expect(presence.echoAtTop, isFalse);

      await presence.recordEchoTop(); // the cap is a no-op
      expect(presence.echoTopCount, 2);

      final nextMonday = Presence(
        prefs,
        today: monday.add(const Duration(days: 7)),
      );
      expect(nextMonday.echoTopCount, 0);
      expect(nextMonday.echoAtTop, isTrue);
    });
  });

  group('echo cadence', () {
    test('hides the card for the cooldown, then shows it again', () async {
      final day = DateTime.utc(2026, 1, 1);
      final presence = Presence(prefs, today: day);

      expect(presence.echoCardVisible, isTrue);
      await presence.recordEchoCardShown();
      expect(presence.echoCardVisible, isFalse);

      final tomorrow = Presence(prefs, today: day.add(const Duration(days: 1)));
      expect(tomorrow.echoCardVisible, isFalse);

      final afterCooldown = Presence(
        prefs,
        today: day.add(const Duration(days: Presence.echoCooldownDays)),
      );
      expect(afterCooldown.echoCardVisible, isTrue);
    });

    test('records seen dates newest first, without duplicates', () async {
      final presence = Presence(prefs, today: DateTime.utc(2026, 1, 5));

      await presence.recordEchoSeen(100);
      await presence.recordEchoSeen(200);
      await presence.recordEchoSeen(100);

      expect(presence.seenEchoDates, {100, 200});
      expect(prefs.getStringList(Presence.echoSeenDatesKey), ['100', '200']);
    });
  });

  group('first use and hints', () {
    test('records first use once and measures days from it', () async {
      final first = Presence(prefs, today: DateTime.utc(2026, 1, 1));
      await first.recordFirstUse();

      final later = Presence(prefs, today: DateTime.utc(2026, 1, 5));
      await later.recordFirstUse(); // never moves the first day

      expect(later.firstUseDate, DateTime.utc(2026, 1, 1));
      expect(later.daysSinceFirstUse, 4);
    });

    test('reading a hint decision does not record first use', () {
      final presence = Presence(prefs, today: DateTime.utc(2026, 1, 4));

      expect(presence.hintVisible(key: 'echo', minDays: 3), isFalse);
      expect(prefs.getInt(Presence.firstUseKey), isNull);
    });

    test('a hint appears after its minDays and can be dismissed', () async {
      final first = Presence(prefs, today: DateTime.utc(2026, 1, 1));
      await first.recordFirstUse();

      final early = Presence(prefs, today: DateTime.utc(2026, 1, 3));
      expect(early.hintVisible(key: 'echo', minDays: 3), isFalse);

      final mature = Presence(prefs, today: DateTime.utc(2026, 1, 4));
      expect(mature.hintVisible(key: 'echo', minDays: 3), isTrue);

      await mature.dismissHint('echo');
      expect(mature.hintVisible(key: 'echo', minDays: 3), isFalse);
      expect(mature.dismissedHints, {'echo'});
    });

    test('dismissing twice keeps one entry', () async {
      final presence = Presence(prefs, today: DateTime.utc(2026, 1, 1));

      await presence.dismissHint('echo');
      await presence.dismissHint('echo');

      expect(prefs.getStringList(Presence.dismissedHintsKey), ['echo']);
    });
  });
}
