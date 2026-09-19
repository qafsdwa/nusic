//! Runtime configuration, read from the environment.
//!
//! Phase 1 has no config file of its own: the documented base URL is fixed at
//! `http://127.0.0.1:8080`, so the few knobs that matter are environment
//! variables. That keeps `cargo run` working with zero setup while still
//! letting a developer point the backend at a real music folder.

use std::env;
use std::net::{IpAddr, Ipv4Addr, SocketAddr};
use std::path::PathBuf;

/// Default port, matching `assets/config/app_config.json`.
pub const DEFAULT_PORT: u16 = 8080;

/// Environment variable holding the port to listen on.
pub const ENV_PORT: &str = "MUSE_BACKEND_PORT";
/// Environment variable holding the bind address.
pub const ENV_HOST: &str = "MUSE_BACKEND_HOST";
/// Environment variable pointing at a folder of audio files to scan.
pub const ENV_MUSIC_DIR: &str = "MUSE_MUSIC_DIR";
/// Environment variable overriding the base URL used in cover links.
pub const ENV_PUBLIC_BASE_URL: &str = "MUSE_PUBLIC_BASE_URL";
/// Environment variable selecting the audio backend.
pub const ENV_AUDIO: &str = "MUSE_AUDIO";

/// Which playback backend to use.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum AudioMode {
    /// Use real output when a device is available, otherwise a virtual clock.
    #[default]
    Auto,
    /// Prefer real output. Falls back to the virtual clock, with an error log,
    /// when no device can be opened.
    Rodio,
    /// Never touch a sound card; the playhead is virtual. Useful on headless
    /// machines and in tests.
    Silent,
}

impl AudioMode {
    fn parse(value: &str) -> Option<Self> {
        match value.trim().to_ascii_lowercase().as_str() {
            "auto" => Some(Self::Auto),
            "rodio" | "device" => Some(Self::Rodio),
            "silent" | "clock" | "none" => Some(Self::Silent),
            _ => None,
        }
    }
}

/// Fully resolved startup configuration.
#[derive(Debug, Clone)]
pub struct Config {
    /// Address the HTTP server binds to.
    pub bind: SocketAddr,
    /// Music directory to scan, when one was configured.
    pub music_dir: Option<PathBuf>,
    /// Base URL the client uses, embedded in absolute cover links.
    ///
    /// Kept separate from [`Self::bind`] because the bind address is often
    /// `0.0.0.0` while clients need a reachable host.
    pub public_base_url: String,
    /// Playback backend.
    pub audio: AudioMode,
}

impl Config {
    /// Reads the configuration from the process environment.
    pub fn from_env() -> Self {
        let host = env::var(ENV_HOST)
            .ok()
            .and_then(|value| value.parse::<IpAddr>().ok())
            // Loopback only by default: this server exposes local files, so
            // binding to every interface has to be an explicit opt-in.
            .unwrap_or(IpAddr::V4(Ipv4Addr::LOCALHOST));

        let port = env::var(ENV_PORT)
            .ok()
            .and_then(|value| value.parse::<u16>().ok())
            .unwrap_or(DEFAULT_PORT);

        let public_base_url = env::var(ENV_PUBLIC_BASE_URL)
            .ok()
            .filter(|value| !value.trim().is_empty())
            .unwrap_or_else(|| format!("http://127.0.0.1:{port}"));

        let audio = env::var(ENV_AUDIO)
            .ok()
            .filter(|value| !value.trim().is_empty())
            .and_then(|value| match AudioMode::parse(&value) {
                Some(mode) => Some(mode),
                None => {
                    eprintln!("ignoring {ENV_AUDIO}={value:?}: expected auto, rodio or silent");
                    None
                }
            })
            .unwrap_or_default();

        Self {
            bind: SocketAddr::new(host, port),
            music_dir: env::var(ENV_MUSIC_DIR)
                .ok()
                .filter(|value| !value.trim().is_empty())
                .map(PathBuf::from),
            public_base_url,
            audio,
        }
    }
}

impl Default for Config {
    fn default() -> Self {
        Self {
            bind: SocketAddr::new(IpAddr::V4(Ipv4Addr::LOCALHOST), DEFAULT_PORT),
            music_dir: None,
            public_base_url: format!("http://127.0.0.1:{DEFAULT_PORT}"),
            audio: AudioMode::Auto,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn default_matches_the_documented_base_url() {
        let config = Config::default();
        assert_eq!(config.bind.to_string(), "127.0.0.1:8080");
        assert_eq!(config.public_base_url, "http://127.0.0.1:8080");
        assert!(config.music_dir.is_none());
        assert_eq!(config.audio, AudioMode::Auto);
    }

    #[test]
    fn audio_mode_parses_the_documented_spellings() {
        assert_eq!(AudioMode::parse("rodio"), Some(AudioMode::Rodio));
        assert_eq!(AudioMode::parse(" SILENT "), Some(AudioMode::Silent));
        assert_eq!(AudioMode::parse("auto"), Some(AudioMode::Auto));
        assert_eq!(AudioMode::parse("speakers"), None);
    }
}
