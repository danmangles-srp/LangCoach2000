// "Send to Anki" affordance on a recording's word log (M4, T4.5, FR-1.3.3).
// Runs the Type 1 (English↔Uzbek) + Type 2 (image→Uzbek) export for the
// recording's parsed pairs, surfaces the aggregate result (added / skipped /
// failed / queued images), retries on failure (idempotent — re-export skips
// already-added notes via the first-field guard), shows an "install AnkiDroid"
// CTA when AnkiDroid is absent, and keeps the offline image-generation queue
// visible (pending count + reconnect hint, NFR-2.1.3).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rivendell/core/logging/app_logger.dart';
import 'package:rivendell/core/logging/app_logger_provider.dart';
import 'package:rivendell/features/anki/application/anki_export_providers.dart';
import 'package:rivendell/features/anki/application/anki_export_service.dart';
import 'package:rivendell/features/anki/application/anki_providers.dart';
import 'package:rivendell/features/metrics/application/metrics_providers.dart';
import 'package:rivendell/features/metrics/domain/metric_kind.dart';
import 'package:rivendell/features/wordlog/domain/vocab_pair.dart';
import 'package:rivendell/l10n/app_strings.dart';

enum _Phase { idle, busy, done, error, notInstalled }

class AnkiExportButton extends ConsumerStatefulWidget {
  const AnkiExportButton({
    required this.recordingName,
    required this.pairs,
    super.key,
  });

  final String recordingName;
  final List<VocabPair> pairs;

  @override
  ConsumerState<AnkiExportButton> createState() => _AnkiExportButtonState();
}

class _AnkiExportButtonState extends ConsumerState<AnkiExportButton> {
  _Phase _phase = _Phase.idle;
  AnkiExportResult? _result;

  /// The underlying failure message when [_phase] is error. Surfaced (was
  /// swallowed) so a blind "Send failed" becomes diagnosable — the usual cause
  /// is AnkiDroid API permission not granted to Rivendell.
  String? _errorDetail;

  Future<void> _send() async {
    setState(() {
      _phase = _Phase.busy;
      _errorDetail = null;
    });
    try {
      final installed = await ref.read(ankiGatewayProvider).isInstalled();
      if (!installed) {
        if (mounted) _showNotInstalledDialog();
        if (mounted) setState(() => _phase = _Phase.notInstalled);
        return;
      }
      final service = await ref.read(ankiExportServiceProvider.future);
      final type1 = await service.exportType1(
        tag: widget.recordingName,
        pairs: widget.pairs,
      );
      final type2 = await service.exportType2(pairs: widget.pairs);
      final added = type1.added + type2.added;
      // FR-1.5.1: count newly added cards as flashcards reviewed. Fire-and-
      // forget — a metrics miss must never block or surface in the export UI.
      if (added > 0) {
        unawaited(
          ref
              .read(metricsRepositoryProvider.future)
              .then((m) => m.record(MetricKind.flashcardsReviewed, added))
              .catchError((Object _) {}),
        );
      }
      if (mounted) {
        setState(() {
          _result = AnkiExportResult(
            added: added,
            skipped: type1.skipped + type2.skipped,
            failed: type1.failed + type2.failed,
            pending: type2.pending,
          );
          _phase = _Phase.done;
        });
      }
    } on Object catch (e, st) {
      final detail = _describe(e);
      ref.read(appLoggerProvider).e(LogTag.anki, 'export failed: $detail\n$st');
      if (mounted) {
        setState(() {
          _result = null;
          _errorDetail = detail;
          _phase = _Phase.error;
        });
      }
    }
  }

  /// Reduce a thrown error to a short, user-visible message. PlatformException
  /// carries the Kotlin-side detail in PlatformException.message; fall back to
  /// the code, then toString.
  String _describe(Object error) {
    if (error is PlatformException) {
      final msg = error.message;
      if (msg != null && msg.isNotEmpty) return msg;
      return error.code;
    }
    return error.toString();
  }

  /// The surfaced error looks like AnkiDroid refusing the content-provider
  /// query for lack of the READ_WRITE_DATABASE permission grant. Drives the
  /// actionable hint (the usual cause is granting Rivendell in AnkiDroid's API
  /// settings, or the manifest permission not yet declared on the installed
  /// build).
  bool get _looksLikePermissionError {
    final d = _errorDetail;
    if (d == null) return false;
    final lower = d.toLowerCase();
    return lower.contains('permission not granted') ||
        lower.contains('read_write_database') ||
        lower.contains('securityexception');
  }

  void _showNotInstalledDialog() {
    final strings = AppStrings.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.ankiNotInstalledTitle),
        content: Text(strings.ankiNotInstalledBody),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(strings.ankiGotIt),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final result = _result;
    final busy = _phase == _Phase.busy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_phase == _Phase.notInstalled)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    strings.ankiNotInstalledTitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        FilledButton.icon(
          onPressed: busy ? null : _send,
          icon: busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send_rounded),
          label: Text(busy ? strings.ankiSending : strings.ankiSend),
        ),
        if (result != null) ...[
          const SizedBox(height: 10),
          _ResultStatus(result: result),
          if (result.failed > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: busy ? null : _send,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(strings.ankiRetry),
                ),
              ),
            ),
          if (result.pending > 0) ...[
            const SizedBox(height: 4),
            Text(
              strings.ankiPendingHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
        if (_phase == _Phase.error && result == null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  strings.ankiSendFailed,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: busy ? null : _send,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(strings.ankiRetry),
              ),
            ],
          ),
          if (_errorDetail != null) ...[
            const SizedBox(height: 4),
            // Selectable so the user can copy the real cause into a bug report.
            SelectableText(
              _errorDetail!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (_looksLikePermissionError) ...[
            const SizedBox(height: 6),
            Text(
              strings.ankiPermissionHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _ResultStatus extends StatelessWidget {
  const _ResultStatus({required this.result});

  final AnkiExportResult result;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final chips = <Widget>[
      _CountChip(
        label: strings.ankiAdded(result.added),
        foreground: theme.colorScheme.primary,
      ),
      if (result.skipped > 0)
        _CountChip(
          label: strings.ankiSkipped(result.skipped),
          foreground: theme.colorScheme.onSurfaceVariant,
        ),
      if (result.failed > 0)
        _CountChip(
          label: strings.ankiFailed(result.failed),
          foreground: theme.colorScheme.error,
        ),
      if (result.pending > 0)
        _CountChip(
          label: strings.ankiPending(result.pending),
          foreground: theme.colorScheme.tertiary,
        ),
    ];
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(spacing: 6, runSpacing: 6, children: chips),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, required this.foreground});

  final String label;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
