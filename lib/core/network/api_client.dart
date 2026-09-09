/// Placeholder for the future Rust API client.
///
/// Do not implement actual HTTP/WebSocket calls in Phase 1. The class exists
/// to define a seam where a REST client and a WebSocket player-sync client will
/// be injected in later phases.
class RustApiClient {
  const RustApiClient._();

  static final RustApiClient instance = const RustApiClient._();
}
