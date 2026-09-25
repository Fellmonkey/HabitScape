import '../../../core/utils/date_helpers.dart';

/// How many times per week the echo card may sit at the top of the Today
/// board before it moves back to the reflection block.
const maxEchoAtTopPerWeek = 2;

/// Preferences key counting this week's top-echo showings.
String echoTopKeyForWeek(DateTime today) =>
    'echo_top_count_${weekStartOf(today).unixSeconds}';

/// Whether the echo may appear at the top after it has been shown [count]
/// times this week.
bool shouldEchoAtTop(int count) => count < maxEchoAtTopPerWeek;
