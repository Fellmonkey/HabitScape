import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/settings/exposure.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
  });

  group('echo placement', () {
    test(
      'is always placed at the top — stable, never moved by a quota',
      () async {
        final monday = DateTime.utc(2026, 10, 26);
        final exposure = Exposure(prefs, today: monday);

        expect(exposure.echoAtTop, isTrue);
        await exposure.recordEchoShown(atTop: true);
        expect(exposure.echoAtTop, isTrue);
        await exposure.recordEchoShown(atTop: true);
        expect(exposure.echoAtTop, isTrue);
      },
    );

    test(
      'recordEchoShown charges the cooldown and optionally the top quota',
      () async {
        final monday = DateTime.utc(2026, 10, 26);
        final exposure = Exposure(prefs, today: monday);

        await exposure.recordEchoShown(atTop: true);

        // Shown today: the card stays up; the next day starts the cooldown.
        expect(exposure.echoCardVisible, isTrue);
        expect(exposure.echoTopCount, 1);
        expect(prefs.getInt(Exposure.echoLastShownKey), monday.unixSeconds);
      },
    );

    test(
      'recordEchoShown with atTop:false never touches the weekly quota',
      () async {
        final exposure = Exposure(prefs, today: DateTime.utc(2026, 10, 26));

        await exposure.recordEchoShown(atTop: false);

        expect(exposure.echoCardVisible, isTrue);
        expect(exposure.echoTopCount, 0);
      },
    );
  });

  group('echo cadence', () {
    test('stays available every day once recorded', () async {
      final day = DateTime.utc(2026, 1, 1);
      final exposure = Exposure(prefs, today: day);

      expect(exposure.echoCardVisible, isTrue);
      await exposure.recordEchoCardShown();
      // Recorded today — the card stays up for the rest of today.
      expect(exposure.echoCardVisible, isTrue);

      final tomorrow = Exposure(prefs, today: day.add(const Duration(days: 1)));
      expect(tomorrow.echoCardVisible, isTrue);
    });

    test('records seen dates newest first, without duplicates', () async {
      final exposure = Exposure(prefs, today: DateTime.utc(2026, 1, 5));

      await exposure.recordEchoSeen(100);
      await exposure.recordEchoSeen(200);
      await exposure.recordEchoSeen(100);

      expect(exposure.seenEchoDates, {100, 200});
      expect(prefs.getStringList(Exposure.echoSeenDatesKey), ['100', '200']);
    });
  });

  group('first use and hints', () {
    test('records first use once and measures days from it', () async {
      final first = Exposure(prefs, today: DateTime.utc(2026, 1, 1));
      await first.recordFirstUse();

      final later = Exposure(prefs, today: DateTime.utc(2026, 1, 5));
      await later.recordFirstUse(); // never moves the first day

      expect(later.firstUseDate, DateTime.utc(2026, 1, 1));
      expect(later.daysSinceFirstUse, 4);
    });

    test('reading a hint decision does not record first use', () {
      final exposure = Exposure(prefs, today: DateTime.utc(2026, 1, 4));

      expect(exposure.hintVisible(key: 'echo', minDays: 3), isFalse);
      expect(prefs.getInt(Exposure.firstUseKey), isNull);
    });

    test('a hint appears after its minDays and can be dismissed', () async {
      final first = Exposure(prefs, today: DateTime.utc(2026, 1, 1));
      await first.recordFirstUse();

      final early = Exposure(prefs, today: DateTime.utc(2026, 1, 3));
      expect(early.hintVisible(key: 'echo', minDays: 3), isFalse);

      final mature = Exposure(prefs, today: DateTime.utc(2026, 1, 4));
      expect(mature.hintVisible(key: 'echo', minDays: 3), isTrue);

      await mature.dismissHint('echo');
      expect(mature.hintVisible(key: 'echo', minDays: 3), isFalse);
      expect(mature.dismissedHints, {'echo'});
    });

    test('dismissing twice keeps one entry', () async {
      final exposure = Exposure(prefs, today: DateTime.utc(2026, 1, 1));

      await exposure.dismissHint('echo');
      await exposure.dismissHint('echo');

      expect(prefs.getStringList(Exposure.dismissedHintsKey), ['echo']);
    });
  });
}
