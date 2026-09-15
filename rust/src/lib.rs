//! Rust side of the Muse Player bridge.
//!
//! `flutter_rust_bridge` code generation will scan the modules under `api`
//! and generate the Dart-facing bindings. The data structures in
//! `api::bridge_models` are deliberately plain structs/enums so FRB can copy
//! them across the FFI boundary as values instead of opaque Rust handles.

pub mod api;
