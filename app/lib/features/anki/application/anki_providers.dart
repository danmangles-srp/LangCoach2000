// Riverpod wiring for the Anki feature (M4, T4.1). The gateway is a singleton
// over the AnkiDroid channel; downstream export services (T4.2 / T4.4) and the
// export UI (T4.5) read it here.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rivendell/features/anki/application/anki_gateway.dart';
import 'package:rivendell/features/anki/platform/ankidroid_gateway_service.dart';

final ankiGatewayProvider = Provider<AnkiGateway>(
  (_) => AnkiDroidGatewayService(),
);
