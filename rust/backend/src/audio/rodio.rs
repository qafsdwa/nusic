//! `rodio`-backed playback: the real sound output.

use std::fs::File;
use std::num::{NonZeroU16, NonZeroU32};
use std::sync::atomic::{AtomicBool, Ordering};
use std::time::Duration;

use rodio::source::Zero;
use rodio::{Decoder, DeviceSinkBuilder, MixerDeviceSink, Player};

use super::{AudioEngine, AudioError, AudioSource};

/// Sample format used for generated silence.
///
/// The mixer resamples to whatever the device runs at, so these only have to be
/// a sane, non-zero rate/channel count.
const SILENCE_SAMPLE_RATE: u32 = 44_100;
const SILENCE_CHANNELS: u16 = 2;

/// A source, already opened and ready to hand to the player.
///
/// Building this *before* touching the player is what makes
/// [`RodioEngine::load`] atomic: a missing or undecodable file fails here, while
/// the previous track is still playing.
enum Prepared {
    File(Decoder<File>),
    Silence(Zero),
}

/// Playback through the default `cpal` output device.
pub struct RodioEngine {
    /// Held for the lifetime of the engine. Dropping the sink tears down the
    /// output stream and silences playback, so it must outlive the player.
    _sink: MixerDeviceSink,
    player: Player,
    /// `Player::empty` is also true before the first load, so it cannot be used
    /// on its own to mean "finished".
    loaded: AtomicBool,
}

impl RodioEngine {
    /// Opens the default output device and starts its stream.
    pub fn open() -> Result<Self, AudioError> {
        let mut sink = DeviceSinkBuilder::open_default_sink()
            .map_err(|error| AudioError::DeviceUnavailable(error.to_string()))?;
        // Playback normally ends via `stop` or drop, and the default notice
        // would only add noise to the logs.
        sink.log_on_drop(false);

        let player = Player::connect_new(sink.mixer());
        Ok(Self {
            _sink: sink,
            player,
            loaded: AtomicBool::new(false),
        })
    }

    /// Opens the file or builds the silence source.
    ///
    /// Returns before playback is disturbed; see [`Prepared`].
    fn prepare(source: &AudioSource) -> Result<Prepared, AudioError> {
        match source {
            AudioSource::File { path, .. } => {
                let file = File::open(path).map_err(|error| AudioError::Open {
                    path: path.display().to_string(),
                    message: error.to_string(),
                })?;
                // `Decoder::new` sniffs the container, so every format the
                // build enables (symphonia-all) is handled by one call.
                let decoder = Decoder::new(file).map_err(|error| AudioError::Decode {
                    path: path.display().to_string(),
                    message: error.to_string(),
                })?;
                Ok(Prepared::File(decoder))
            }
            AudioSource::Silence { duration } => {
                let frames = duration.as_secs_f64() * f64::from(SILENCE_SAMPLE_RATE);
                let samples = (frames * f64::from(SILENCE_CHANNELS)).max(0.0) as usize;
                Ok(Prepared::Silence(Zero::new_samples(
                    NonZeroU16::new(SILENCE_CHANNELS).expect("channel count is non-zero"),
                    NonZeroU32::new(SILENCE_SAMPLE_RATE).expect("sample rate is non-zero"),
                    samples,
                )))
            }
        }
    }
}

impl AudioEngine for RodioEngine {
    fn load(&self, source: &AudioSource, position: Duration) -> Result<(), AudioError> {
        // Prepare first: if this fails, the current track keeps playing and the
        // caller can reject the command without a rollback.
        let prepared = Self::prepare(source)?;

        // `clear` drops whatever was queued and leaves the player paused.
        self.player.clear();
        match prepared {
            Prepared::File(decoder) => self.player.append(decoder),
            Prepared::Silence(silence) => self.player.append(silence),
        }
        self.loaded.store(true, Ordering::SeqCst);

        if position > Duration::ZERO {
            if let Err(error) = self.player.try_seek(position) {
                // Both the decoder and the silence source support seeking, so
                // this is unexpected; starting from the beginning is still far
                // better than failing the whole load.
                tracing::warn!(
                    %error,
                    ?position,
                    "could not seek after loading; starting from the beginning"
                );
            }
        }

        // `clear` paused the player; `load` is documented to leave it paused.
        self.player.pause();
        Ok(())
    }

    fn play(&self) -> Result<(), AudioError> {
        self.player.play();
        Ok(())
    }

    fn pause(&self) -> Result<(), AudioError> {
        self.player.pause();
        Ok(())
    }

    fn stop(&self) -> Result<(), AudioError> {
        self.loaded.store(false, Ordering::SeqCst);
        self.player.stop();
        Ok(())
    }

    fn seek(&self, position: Duration) -> Result<(), AudioError> {
        self.player.try_seek(position).map_err(|error| {
            tracing::warn!(%error, ?position, "audio engine could not seek");
            AudioError::SeekUnsupported
        })
    }

    fn set_volume(&self, volume: f32) {
        self.player.set_volume(volume.clamp(0.0, 1.0));
    }

    fn position(&self) -> Duration {
        self.player.get_pos()
    }

    fn is_finished(&self) -> bool {
        // `empty` turns true once the queued source has been consumed; `loaded`
        // distinguishes that from "nothing was ever loaded".
        self.loaded.load(Ordering::SeqCst) && self.player.empty()
    }

    fn name(&self) -> &'static str {
        "rodio"
    }
}
