//! Integration tests for the real `rodio` playback path.
//!
//! These run against an actual output device, so every test **skips** (rather
//! than fails) when none can be opened — CI machines and headless servers have
//! no sound card, and that must not make the suite red. The `ClockEngine`
//! covers the same state-machine behaviour without hardware, in
//! `src/audio/clock.rs` and `src/player.rs`.
//!
//! Device access is serialised: cpal streams are a global resource, and several
//! tests racing to open one is exactly the kind of flake that makes an audio
//! suite untrustworthy.

use std::path::Path;
use std::sync::Mutex;
use std::time::Duration;

use muse_backend::audio::{AudioEngine, AudioSource, RodioEngine};

/// Serialises device access across the test threads.
static DEVICE_LOCK: Mutex<()> = Mutex::new(());

/// Opens the real engine, or `None` when the machine has no output device.
fn engine() -> Option<RodioEngine> {
    match RodioEngine::open() {
        Ok(engine) => Some(engine),
        Err(error) => {
            eprintln!("skipping rodio engine test (no output device): {error}");
            None
        }
    }
}

/// Writes a sine-wave WAV of `seconds` length.
///
/// A generated file keeps the repository free of audio assets and gives the
/// decoder something real to chew on.
fn write_wav(path: &Path, seconds: f32) {
    let spec = hound::WavSpec {
        channels: 1,
        sample_rate: 44_100,
        bits_per_sample: 16,
        sample_format: hound::SampleFormat::Int,
    };

    let mut writer = hound::WavWriter::create(path, spec).expect("create wav");
    let total = (44_100.0 * seconds) as u32;
    for index in 0..total {
        let t = index as f32 / 44_100.0;
        let sample = (t * 440.0 * std::f32::consts::TAU).sin() * 0.2;
        writer
            .write_sample((sample * f32::from(i16::MAX)) as i16)
            .expect("write sample");
    }
    writer.finalize().expect("finalize wav");
}

fn file_source(path: &Path, seconds: u64) -> AudioSource {
    AudioSource::File {
        path: path.to_path_buf(),
        duration: Duration::from_secs(seconds),
    }
}

#[test]
fn plays_a_file_and_reports_progress() {
    let _guard = DEVICE_LOCK.lock().unwrap_or_else(|e| e.into_inner());
    let Some(engine) = engine() else { return };

    let dir = tempfile::tempdir().expect("temp dir");
    let path = dir.path().join("tone.wav");
    write_wav(&path, 5.0);

    // Silence the suite: the point is the API, not the noise.
    engine.set_volume(0.0);
    engine
        .load(&file_source(&path, 5), Duration::ZERO)
        .expect("load the wav");

    assert_eq!(engine.position(), Duration::ZERO);
    assert!(!engine.is_finished());
    assert_eq!(engine.name(), "rodio");

    engine.play().expect("play");
    std::thread::sleep(Duration::from_millis(400));

    let position = engine.position();
    assert!(
        position > Duration::ZERO,
        "the playhead should have moved, got {position:?}"
    );

    engine.pause().expect("pause");
    let frozen = engine.position();
    std::thread::sleep(Duration::from_millis(200));
    let after_pause = engine.position();

    // The output callback notices the pause on its next run, so a few
    // milliseconds of audio can still be delivered. What must not happen is the
    // playhead *continuing* to move.
    assert!(
        after_pause >= frozen,
        "the playhead must not jump backwards when pausing"
    );
    assert!(
        after_pause - frozen < Duration::from_millis(50),
        "a paused playhead should settle, moved {:?} -> {:?}",
        frozen,
        after_pause
    );

    engine.stop().expect("stop");
}

#[test]
fn seek_moves_the_playhead() {
    let _guard = DEVICE_LOCK.lock().unwrap_or_else(|e| e.into_inner());
    let Some(engine) = engine() else { return };

    let dir = tempfile::tempdir().expect("temp dir");
    let path = dir.path().join("tone.wav");
    write_wav(&path, 5.0);

    engine.set_volume(0.0);
    engine
        .load(&file_source(&path, 5), Duration::ZERO)
        .expect("load the wav");

    engine.seek(Duration::from_millis(2_000)).expect("seek");
    let position = engine.position();
    assert!(
        position >= Duration::from_millis(1_800),
        "expected to land near 2s, got {position:?}"
    );
    assert!(!engine.is_finished());

    engine.stop().expect("stop");
}

#[test]
fn a_finished_track_is_reported_as_finished() {
    let _guard = DEVICE_LOCK.lock().unwrap_or_else(|e| e.into_inner());
    let Some(engine) = engine() else { return };

    let dir = tempfile::tempdir().expect("temp dir");
    let path = dir.path().join("short.wav");
    write_wav(&path, 0.3);

    engine.set_volume(0.0);
    engine
        .load(&file_source(&path, 1), Duration::ZERO)
        .expect("load the wav");
    engine.play().expect("play");

    // Well past the 300ms of audio plus decoder/device latency.
    std::thread::sleep(Duration::from_millis(1_200));
    assert!(
        engine.is_finished(),
        "a consumed source must report finished"
    );

    engine.stop().expect("stop");
}

#[test]
fn a_bad_load_leaves_the_current_track_playing() {
    let _guard = DEVICE_LOCK.lock().unwrap_or_else(|e| e.into_inner());
    let Some(engine) = engine() else { return };

    let dir = tempfile::tempdir().expect("temp dir");
    let good = dir.path().join("good.wav");
    write_wav(&good, 5.0);

    engine.set_volume(0.0);
    engine
        .load(&file_source(&good, 5), Duration::ZERO)
        .expect("load the wav");
    engine.play().expect("play");
    std::thread::sleep(Duration::from_millis(400));
    let playing = engine.position();
    assert!(playing > Duration::ZERO);

    // The file does not exist, so preparing the source fails before the engine
    // is touched. `PlayerHub` relies on this to reject a command with no
    // rollback.
    let missing = file_source(&dir.path().join("missing.wav"), 5);
    assert!(
        engine.load(&missing, Duration::ZERO).is_err(),
        "loading a missing file must fail"
    );

    std::thread::sleep(Duration::from_millis(300));
    let still_playing = engine.position();
    assert!(
        still_playing > playing,
        "the original track should have kept playing ({playing:?} -> {still_playing:?})"
    );
    assert!(!engine.is_finished());

    engine.stop().expect("stop");
}

#[test]
fn silence_placeholders_are_playable_and_seekable() {
    let _guard = DEVICE_LOCK.lock().unwrap_or_else(|e| e.into_inner());
    let Some(engine) = engine() else { return };

    // The seed catalog has no files; the hub feeds the engine this instead.
    let source = AudioSource::Silence {
        duration: Duration::from_secs(10),
    };
    engine.set_volume(0.0);
    engine.load(&source, Duration::ZERO).expect("load silence");

    engine.seek(Duration::from_millis(3_000)).expect("seek");
    assert!(
        engine.position() >= Duration::from_millis(2_800),
        "silence must support seeking like any other source"
    );
    assert!(!engine.is_finished());

    engine.play().expect("play");
    std::thread::sleep(Duration::from_millis(300));
    assert!(engine.position() > Duration::from_millis(3_000));

    engine.stop().expect("stop");
}

#[test]
fn loading_at_a_position_starts_there() {
    let _guard = DEVICE_LOCK.lock().unwrap_or_else(|e| e.into_inner());
    let Some(engine) = engine() else { return };

    let dir = tempfile::tempdir().expect("temp dir");
    let path = dir.path().join("tone.wav");
    write_wav(&path, 5.0);

    engine.set_volume(0.0);
    engine
        .load(&file_source(&path, 5), Duration::from_millis(2_500))
        .expect("load at a position");

    let position = engine.position();
    assert!(
        position >= Duration::from_millis(2_300),
        "expected to start near 2.5s, got {position:?}"
    );

    engine.stop().expect("stop");
}
