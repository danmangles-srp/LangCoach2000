// WeeklyReportRenderer (T6.4, FR-1.5.3). Pure Dart — turns a weekly
// [DashboardSnapshot] into a self-contained, custom-styled HTML string suitable
// for SMTP dispatch (T6.5). Inline CSS throughout so the report renders in
// mail clients that strip <style> blocks; the brand accent (#2E7D6B) matches
// the app seed color so the email reads as the same product.
//
// Pure data-in → HTML-out, no I/O. Fully unit-tested without a device.

import 'package:intl/intl.dart';

import 'package:rivendell/features/metrics/application/metrics_aggregation_service.dart';
import 'package:rivendell/features/metrics/domain/metrics_aggregator.dart';

/// Localized labels for the weekly report. Defaults to English; the scheduler
/// (T6.6) can pass locale-specific copy from the l10n bundle when it wires the
/// renderer into the dispatch flow.
class WeeklyReportLabels {
  const WeeklyReportLabels({
    required this.title,
    required this.intro,
    required this.lessonDuration,
    required this.journalingOutput,
    required this.completedQueueItems,
    required this.flashcardsReviewed,
    required this.weekOf,
  });

  final String title;
  final String intro;
  final String lessonDuration;
  final String journalingOutput;
  final String completedQueueItems;
  final String flashcardsReviewed;
  final String weekOf;

  static const en = WeeklyReportLabels(
    title: 'Rivendell Weekly Report',
    intro: "Here's how your study week looked.",
    lessonDuration: 'Lesson time',
    journalingOutput: 'Vocab logs',
    completedQueueItems: 'Reviews done',
    flashcardsReviewed: 'Flashcards',
    weekOf: 'Week of',
  );
}

/// Render a weekly [DashboardSnapshot] as a styled HTML email body.
class WeeklyReportRenderer {
  const WeeklyReportRenderer({this.brandHex = '#2E7D6B'});

  /// Brand accent color (hex string, upper-case) used for headers + bars.
  final String brandHex;

  String render(
    DashboardSnapshot snapshot, {
    WeeklyReportLabels labels = WeeklyReportLabels.en,
  }) {
    final headerRange = _formatRange(
      snapshot.window.from,
      snapshot.window.until,
    );
    final sections = [
      _section(
        labels.lessonDuration,
        snapshot.lessonDuration,
        isDuration: true,
      ),
      _section(labels.journalingOutput, snapshot.journalingOutput),
      _section(labels.completedQueueItems, snapshot.completedQueueItems),
      _section(labels.flashcardsReviewed, snapshot.flashcardsReviewed),
    ].join();

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${_escape(labels.title)}</title>
</head>
<body style="margin:0;padding:0;background:#f4f6f5;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;color:#1c2826;">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#f4f6f5;">
    <tr><td align="center" style="padding:24px 12px;">
      <table role="presentation" width="560" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 1px 3px rgba(28,40,38,0.08);">
        <tr><td style="background:$brandHex;padding:28px 32px;">
          <h1 style="margin:0;color:#ffffff;font-size:22px;font-weight:600;letter-spacing:0.2px;">${_escape(labels.title)}</h1>
          <p style="margin:6px 0 0;color:#e8f3f0;font-size:13px;">${_escape(labels.weekOf)} $headerRange</p>
        </td></tr>
        <tr><td style="padding:24px 32px 8px 32px;">
          <p style="margin:0 0 20px 0;color:#5a6b68;font-size:14px;line-height:1.5;">${_escape(labels.intro)}</p>
          $sections
        </td></tr>
        <tr><td style="padding:8px 32px 28px 32px;">
          <p style="margin:0;color:#9aa8a5;font-size:12px;text-align:center;">Sent by Rivendell</p>
        </td></tr>
      </table>
    </td></tr>
  </table>
</body>
</html>''';
  }

  String _section(
    String label,
    MetricSeries series, {
    bool isDuration = false,
  }) {
    final total = isDuration
        ? _formatDuration(series.total)
        : '${series.total}';
    final max = series.points.fold<int>(0, (m, p) => p.value > m ? p.value : m);
    final rows = [
      for (final p in series.points) _row(p, max, isDuration: isDuration),
    ].join();
    return '''
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin:0 0 20px 0;">
  <tr>
    <td style="padding:0 0 8px 0;">
      <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
        <tr>
          <td style="color:#1c2826;font-size:15px;font-weight:600;">${_escape(label)}</td>
          <td align="right" style="color:$brandHex;font-size:20px;font-weight:600;">$total</td>
        </tr>
      </table>
    </td>
  </tr>
  $rows
</table>''';
  }

  String _row(MetricSeriesPoint point, int max, {required bool isDuration}) {
    final value = isDuration ? _formatDuration(point.value) : '${point.value}';
    // Avoid divide-by-zero; a zero week still gets a faint baseline track.
    final pct = max > 0 ? (point.value * 100) ~/ max : 0;
    final label = DateFormat('MMM d').format(point.bucketStart);
    return '''
<tr class="week-row">
  <td style="padding:2px 0;">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
      <tr>
        <td style="width:64px;color:#5a6b68;font-size:12px;vertical-align:middle;">${_escape(label)}</td>
        <td style="padding:0 8px;vertical-align:middle;">
          <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#eef3f1;border-radius:6px;height:10px;"><tr><td style="width:$pct%;background:$brandHex;border-radius:6px;height:10px;font-size:0;line-height:0;">&nbsp;</td></tr></table>
        </td>
        <td align="right" style="width:56px;color:#1c2826;font-size:12px;font-weight:500;vertical-align:middle;">$value</td>
      </tr>
    </table>
  </td>
</tr>''';
  }

  static String _formatRange(DateTime from, DateTime until) {
    final fmt = DateFormat('MMM d, y');
    return '${fmt.format(from)} – ${fmt.format(until)}';
  }

  static String _formatDuration(int ms) {
    if (ms <= 0) return '0m';
    final mins = ms ~/ 60000;
    if (mins < 60) return '${mins}m';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  static String _escape(String raw) {
    return raw
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }
}
