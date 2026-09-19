//! Process-wide state shared by every FFI call.
//!
//! The app has exactly one library and one player, so the FFI surface is a set
//! of free functions over a lazily-initialised singleton rather than an opaque
//! handle the Dart side has to thread through.

use std::path::Path;
use std::sync::{Arc, OnceLock};
use std::time::Duration;

use crate::audio::{open_default_engine, AudioEngine};
use crate::library::{self, Library};
use crate::online::OnlineService;
use crate::player::PlayerHub;

/// How often the FFI runtime samples the engine. Matches the HTTP front-end so
/// both paths push state at the same cadence.
const TICK: Duration = Duration::from_millis(250);

/// The one library and player behind the FFI surface.
pub struct Runtime {
    pub library: Arc<Library>,
    pub player: Arc<PlayerHub>,
    /// Built on first use, so an app that never searches online pays neither
    /// the HTTP client nor the extra runtime thread.
    online: OnceLock<Result<Arc<OnlineService>, String>>,
}

impl Runtime {
    /// The online layer, initialising it on first call.
    ///
    /// A failure is cached and returned verbatim: online search is an addition
    /// to the local library, so a broken setup must not take the player down.
    pub fn online(&self) -> Result<&Arc<OnlineService>, String> {
        self.online
            .get_or_init(|| OnlineService::open().map(Arc::new))
            .as_ref()
            .map_err(Clone::clone)
    }
}

static RUNTIME: OnceLock<Runtime> = OnceLock::new();

/// Builds the library and player, and starts the sampling thread.
///
/// Idempotent: calling it twice is a no-op, which matters because Flutter may
/// re-create providers without the process restarting.
pub fn init(music_dir: Option<&str>, volume: f64) -> Result<(), String> {
    if RUNTIME.get().is_some() {
        return Ok(());
    }

    let library = library::load(
        music_dir.map(Path::new),
        // Cover URLs are meaningless without the HTTP server; the value is kept
        // only because `Library` still populates it.
        "http://127.0.0.1:8080",
    );
    let engine: Arc<dyn AudioEngine> = open_default_engine();
    let player = PlayerHub::new(library.clone(), engine);

    // `Library` always has at least the seed catalog, so there is always a
    // first track to set a volume on.
    player
        .apply(crate::models::PlayerCommand::SetVolume { volume })
        .map_err(|error| error.to_string())?;

    let ticker = player.clone();
    let _ = RUNTIME.set(Runtime {
        library,
        player,
        online: OnceLock::new(),
    });

    std::thread::Builder::new()
        .name("muse-ffi-ticker".to_owned())
        .spawn(move || loop {
            std::thread::sleep(TICK);
            ticker.tick();
        })
        .map_err(|error| format!("cannot start the player ticker: {error}"))?;

    Ok(())
}

/// The initialised runtime, or an error if [`init`] has not run.
pub fn current() -> Result<&'static Runtime, String> {
    RUNTIME
        .get()
        .ok_or_else(|| "rust runtime is not initialised; call init() first".to_owned())
}
