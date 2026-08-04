import '../privacy/privacy_state.dart';
import 'analytics_event.dart';

final class AnalyticsEnvelope {
  const AnalyticsEnvelope({
    required this.event,
    required this.trackingIdentifier,
  });

  final AnalyticsEvent event;
  final String? trackingIdentifier;

  Map<String, Object?> toJson() => <String, Object?>{
    ...event.toJson(),
    if (trackingIdentifier != null) 'tracking_identifier': trackingIdentifier,
  };
}

/// External analytics boundary. Production SDKs can implement this later.
abstract interface class AnalyticsAdapter {
  Future<void> sendBatch(List<AnalyticsEnvelope> batch);
}

/// Launch-safe adapter for builds without analytics transport.
final class NoOpAnalyticsAdapter implements AnalyticsAdapter {
  const NoOpAnalyticsAdapter();

  @override
  Future<void> sendBatch(List<AnalyticsEnvelope> batch) async {}
}

/// Deterministic adapter for unit tests and local development.
final class FakeAnalyticsAdapter implements AnalyticsAdapter {
  FakeAnalyticsAdapter({this.shouldFail = false});

  final bool shouldFail;
  final List<List<AnalyticsEnvelope>> batches = <List<AnalyticsEnvelope>>[];

  @override
  Future<void> sendBatch(List<AnalyticsEnvelope> batch) async {
    if (shouldFail) throw StateError('Configured fake analytics failure');
    batches.add(List<AnalyticsEnvelope>.unmodifiable(batch));
  }
}

enum AnalyticsFlushStatus {
  sent,
  empty,
  skippedOffline,
  skippedConsent,
  failed,
}

final class AnalyticsFlushResult {
  const AnalyticsFlushResult(this.status, {this.sentCount = 0});

  final AnalyticsFlushStatus status;
  final int sentCount;
}

/// Bounded local analytics buffer with a failure-isolated adapter boundary.
final class AnalyticsService {
  AnalyticsService({required this.adapter, this.maxBufferSize = 500})
    : assert(maxBufferSize > 0);

  final AnalyticsAdapter adapter;
  final int maxBufferSize;
  final List<AnalyticsEnvelope> _buffer = <AnalyticsEnvelope>[];

  int get pendingCount => _buffer.length;
  List<AnalyticsEnvelope> get pendingEvents =>
      List<AnalyticsEnvelope>.unmodifiable(_buffer);

  /// Records locally even when offline or consent is currently unavailable.
  ///
  /// The raw tracking candidate is never retained before both consent and ATT
  /// (on iOS) allow it.
  void record(
    AnalyticsEvent event, {
    required PrivacyState privacy,
    String? trackingIdentifier,
  }) {
    if (_buffer.length == maxBufferSize) {
      _buffer.removeAt(0);
    }
    _buffer.add(
      AnalyticsEnvelope(
        event: event,
        trackingIdentifier: privacy.filterTrackingIdentifier(
          trackingIdentifier,
        ),
      ),
    );
  }

  /// Sends the current snapshot without ever throwing into app navigation.
  Future<AnalyticsFlushResult> flush({
    required bool isOnline,
    required PrivacyState privacy,
  }) async {
    if (_buffer.isEmpty) {
      return const AnalyticsFlushResult(AnalyticsFlushStatus.empty);
    }
    if (!isOnline) {
      return const AnalyticsFlushResult(AnalyticsFlushStatus.skippedOffline);
    }
    if (!privacy.hasConsent) {
      return const AnalyticsFlushResult(AnalyticsFlushStatus.skippedConsent);
    }

    final batch = List<AnalyticsEnvelope>.unmodifiable(_buffer);
    try {
      await adapter.sendBatch(batch);
    } on Object {
      return const AnalyticsFlushResult(AnalyticsFlushStatus.failed);
    }

    // Events recorded while the adapter was awaiting remain queued.
    _buffer.removeRange(0, batch.length);
    return AnalyticsFlushResult(
      AnalyticsFlushStatus.sent,
      sentCount: batch.length,
    );
  }
}
