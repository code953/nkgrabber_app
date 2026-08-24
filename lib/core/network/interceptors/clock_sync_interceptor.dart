/// Clock sync interceptor.
///
/// Extracts `serverTime` from response bodies and computes the rolling
/// offset between server and local clocks. Stores `serverClockOffsetMs`
/// for use in time-sensitive operations.
library;

import 'package:dio/dio.dart';

class ClockSyncInterceptor extends Interceptor {
  ClockSyncInterceptor({required this.onOffsetUpdated});

  final void Function(int offsetMs) onOffsetUpdated;

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      // serverTime may be at the top level or inside the `data` envelope.
      final inner = data['data'];
      final serverTimeStr = (data['serverTime'] as String?) ??
          (inner is Map<String, dynamic>
              ? inner['serverTime'] as String?
              : null);
      if (serverTimeStr != null) {
        final serverTime = DateTime.tryParse(serverTimeStr);
        if (serverTime != null) {
          final localTime = DateTime.now().toUtc();
          final offsetMs = serverTime.difference(localTime).inMilliseconds;
          onOffsetUpdated(offsetMs);
        }
      }
    }
    handler.next(response);
  }
}
