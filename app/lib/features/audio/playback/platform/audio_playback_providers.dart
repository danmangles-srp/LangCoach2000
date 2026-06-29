// Provider wiring for the playback service (T1.5). Android gets the real
// background handler via audio_service; every other host gets the placeholder
// so the app still renders. The controller overrides this in tests with a fake
// that drives synthetic [PlaybackState]s.

import 'dart:io' show Platform;

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rivendell/core/logging/app_logger_provider.dart';
import 'package:rivendell/features/audio/playback/application/audio_playback_service.dart';
import 'package:rivendell/features/audio/playback/platform/placeholder_audio_playback_service.dart';
import 'package:rivendell/features/audio/playback/platform/rivendell_audio_handler.dart';
import 'package:rivendell/features/audio/playback/platform/rivendell_audio_playback_service.dart';

final audioPlaybackServiceProvider = FutureProvider<AudioPlaybackService>((
  ref,
) async {
  final logger = ref.watch(appLoggerProvider);

  if (!Platform.isAndroid) {
    final placeholder = PlaceholderAudioPlaybackService(logger: logger);
    ref.onDispose(placeholder.dispose);
    return placeholder;
  }

  final handler = await AudioService.init(
    builder: () => RivendellAudioHandler(logger: logger),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.rivendell.app.audio',
      androidNotificationChannelName: 'Rivendell playback',
      androidNotificationOngoing: true,
    ),
  );
  final service = RivendellAudioPlaybackService(audioHandler: handler);
  ref.onDispose(service.dispose);
  return service;
});
