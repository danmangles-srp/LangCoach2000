// Fal.ai API-key settings section (FR-1.3.4). Embedded in the Settings screen.
// Mirrors the weekly-report credentials block: the field hydrates blank (a
// typed key never lingers in widget state past Save), a status helper shows
// whether a key is stored, and Save/Clear commit immediately to the
// SQLCipher KV store so the queue picks up a rotation on the next drain.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rivendell/core/database/kv_repository.dart';
import 'package:rivendell/features/ai_image/platform/ai_image_providers.dart';
import 'package:rivendell/features/settings/application/settings_providers.dart';
import 'package:rivendell/l10n/app_strings.dart';

class FalApiKeySettingsSection extends ConsumerStatefulWidget {
  const FalApiKeySettingsSection({super.key});

  @override
  ConsumerState<FalApiKeySettingsSection> createState() =>
      _FalApiKeySettingsSectionState();
}

class _FalApiKeySettingsSectionState
    extends ConsumerState<FalApiKeySettingsSection> {
  late final TextEditingController _key;
  bool _hydrated = false;
  bool _saving = false;
  bool _obscure = true;
  bool _isSet = false;

  @override
  void initState() {
    super.initState();
    _key = TextEditingController();
  }

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  Future<void> _hydrate(KvRepository repo) async {
    if (_hydrated) return;
    final stored = await readFalApiKey(repo);
    _isSet = stored != null && stored.isNotEmpty;
    _hydrated = true;
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final strings = AppStrings.of(context);
    try {
      final repo = await ref.read(settingsRepositoryProvider.future);
      await writeFalApiKey(repo, _key.text.trim());
      _isSet = _key.text.trim().isNotEmpty;
      _key.clear();
      if (mounted) setState(() => _saving = false);
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(strings.settingsAiImageKeySaved)),
      );
    } on Object {
      if (mounted) setState(() => _saving = false);
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Save failed')),
      );
    }
  }

  Future<void> _clear() async {
    final repo = await ref.read(settingsRepositoryProvider.future);
    await writeFalApiKey(repo, '');
    _isSet = false;
    _key.clear();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final repoAsync = ref.watch(settingsRepositoryProvider);

    if (repoAsync.hasValue && !_hydrated) {
      _hydrate(repoAsync.requireValue);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
          child: Text(
            strings.settingsAiImageTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _key,
            obscureText: _obscure,
            keyboardType: TextInputType.visiblePassword,
            decoration: InputDecoration(
              labelText: strings.settingsAiImageKeyLabel,
              helperText: _isSet
                  ? strings.settingsAiImageKeyHelp
                  : strings.settingsAiImageKeyNotSet,
              helperMaxLines: 2,
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            children: [
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save_rounded),
                label: Text(strings.settingsAiImageKeySave),
              ),
              const SizedBox(width: 8),
              if (_isSet)
                TextButton.icon(
                  onPressed: _saving ? null : _clear,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(strings.settingsAiImageKeyClear),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
