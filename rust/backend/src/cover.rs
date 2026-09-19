//! Deterministic generated cover art.
//!
//! `docs/backend-api.md` serves covers from `GET /covers/{id}.jpg`, so the
//! backend has to produce bytes for that URL. Extracting embedded art with
//! `lofty` would tie covers to the source files and leave untagged files with a
//! 404, so instead every song gets a stable, procedurally drawn JPEG derived
//! from its id.
//!
//! Determinism matters: the same song must render the same cover on every
//! request and across restarts, otherwise the UI would flicker between two
//! different images on each refresh. A FNV-1a hash of the song id (the same
//! algorithm as the Flutter side's `stableArtworkHash`) seeds every choice.

use std::collections::HashMap;
use std::sync::{Arc, Mutex};

use image::codecs::jpeg::JpegEncoder;
use image::ExtendedColorType;

/// Edge length of generated covers, in pixels.
pub const COVER_SIZE: u32 = 512;

/// JPEG quality. High enough to hide banding in the gradient, low enough that a
/// cover stays a few tens of kilobytes.
const COVER_QUALITY: u8 = 82;

/// Cache of rendered covers, keyed by song id.
///
/// Rendering is a few milliseconds, but the UI asks for the same handful of
/// covers on every list rebuild, so caching keeps those requests off the CPU.
#[derive(Default)]
pub struct CoverCache {
    entries: Mutex<HashMap<String, Arc<[u8]>>>,
}

impl CoverCache {
    /// Returns the JPEG for `id`, rendering and caching it on first use.
    pub fn get_or_render(&self, id: &str) -> Arc<[u8]> {
        if let Some(hit) = self.entries.lock().unwrap().get(id) {
            return Arc::clone(hit);
        }

        // Rendered outside the lock: two threads may race on the same id, but
        // both produce identical bytes, so the extra work is harmless and
        // holding the mutex across the encode is not.
        let bytes: Arc<[u8]> = render_cover(id).into();

        let mut entries = self.entries.lock().unwrap();
        Arc::clone(entries.entry(id.to_owned()).or_insert(bytes))
    }

    /// Number of cached covers; used by tests.
    pub fn len(&self) -> usize {
        self.entries.lock().unwrap().len()
    }

    pub fn is_empty(&self) -> bool {
        self.len() == 0
    }
}

/// Renders the cover for `seed_key` as JPEG bytes.
pub fn render_cover(seed_key: &str) -> Vec<u8> {
    let seed = fnv1a(seed_key);
    let hue = (seed % 360) as f64;

    let top = Hsl::new(hue, 0.52, 0.30).to_rgb();
    let bottom = Hsl::new((hue + 62.0) % 360.0, 0.58, 0.62).to_rgb();

    // Decorative disc: position, size and tint all come from disjoint bits of
    // the hash so two songs with adjacent ids still get visibly different art.
    let unit = |shift: u32| ((seed >> shift) & 0xFFFF) as f64 / 65_535.0;
    let disc = Disc {
        cx: (0.18 + 0.64 * unit(0)) * COVER_SIZE as f64,
        cy: (0.16 + 0.42 * unit(16)) * COVER_SIZE as f64,
        radius: (0.10 + 0.09 * unit(32)) * COVER_SIZE as f64,
        color: Hsl::new((hue + 185.0) % 360.0, 0.72, 0.74).to_rgb(),
        glow: 0.30 + 0.25 * unit(48),
    };

    let mut pixels = vec![0u8; (COVER_SIZE * COVER_SIZE * 3) as usize];

    for y in 0..COVER_SIZE {
        for x in 0..COVER_SIZE {
            let fx = x as f64;
            let fy = y as f64;

            // Diagonal gradient, normalised to 0..1 across the square.
            let t = ((fx + fy) / (2.0 * (COVER_SIZE as f64 - 1.0))).clamp(0.0, 1.0);
            let base = top.lerp(&bottom, t);

            // Soft-edged disc: solid inside, fading over the glow band.
            let distance = ((fx - disc.cx).powi(2) + (fy - disc.cy).powi(2)).sqrt();
            let edge = ((disc.radius + disc.radius * disc.glow - distance)
                / (disc.radius * disc.glow).max(1.0))
            .clamp(0.0, 1.0);
            // Smoothstep keeps the falloff from reading as a hard band.
            let alpha = edge * edge * (3.0 - 2.0 * edge);

            let color = base.lerp(&disc.color, alpha);
            let offset = ((y * COVER_SIZE + x) * 3) as usize;
            pixels[offset] = color.r;
            pixels[offset + 1] = color.g;
            pixels[offset + 2] = color.b;
        }
    }

    let mut jpeg = Vec::new();
    let mut encoder = JpegEncoder::new_with_quality(&mut jpeg, COVER_QUALITY);
    // Encoding a fixed-size RGB buffer cannot fail, but falling back to the
    // empty vector keeps a broken encoder from panicking the whole server.
    if encoder
        .encode(&pixels, COVER_SIZE, COVER_SIZE, ExtendedColorType::Rgb8)
        .is_err()
    {
        return Vec::new();
    }
    jpeg
}

struct Disc {
    cx: f64,
    cy: f64,
    radius: f64,
    color: Rgb,
    glow: f64,
}

#[derive(Clone, Copy)]
struct Rgb {
    r: u8,
    g: u8,
    b: u8,
}

impl Rgb {
    fn lerp(self, other: &Rgb, t: f64) -> Rgb {
        let t = t.clamp(0.0, 1.0);
        let mix = |a: u8, b: u8| (a as f64 + (b as f64 - a as f64) * t).round() as u8;
        Rgb {
            r: mix(self.r, other.r),
            g: mix(self.g, other.g),
            b: mix(self.b, other.b),
        }
    }
}

/// Minimal HSL color used to pick pleasant, hash-derived cover palettes.
struct Hsl {
    h: f64,
    s: f64,
    l: f64,
}

impl Hsl {
    fn new(h: f64, s: f64, l: f64) -> Self {
        Self { h, s, l }
    }

    fn to_rgb(&self) -> Rgb {
        let c = (1.0 - (2.0 * self.l - 1.0).abs()) * self.s;
        let h_prime = self.h / 60.0;
        let x = c * (1.0 - (h_prime % 2.0 - 1.0).abs());
        let (r1, g1, b1) = match h_prime as u32 {
            0 => (c, x, 0.0),
            1 => (x, c, 0.0),
            2 => (0.0, c, x),
            3 => (0.0, x, c),
            4 => (x, 0.0, c),
            _ => (c, 0.0, x),
        };
        let m = self.l - c / 2.0;
        let to_u8 = |v: f64| ((v + m) * 255.0).round().clamp(0.0, 255.0) as u8;
        Rgb {
            r: to_u8(r1),
            g: to_u8(g1),
            b: to_u8(b1),
        }
    }
}

/// FNV-1a 64-bit, matching the Flutter side's `stableArtworkHash` algorithm so
/// both ends derive the same ordering from a song id.
pub fn fnv1a(input: &str) -> u64 {
    const OFFSET_BASIS: u64 = 0xcbf2_9ce4_8422_2325;
    const PRIME: u64 = 0x0000_0100_0000_01b3;

    input.bytes().fold(OFFSET_BASIS, |hash, byte| {
        (hash ^ u64::from(byte)).wrapping_mul(PRIME)
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn fnv1a_is_stable_and_distinguishes_ids() {
        assert_eq!(fnv1a("song_001"), fnv1a("song_001"));
        assert_ne!(fnv1a("song_001"), fnv1a("song_002"));
    }

    #[test]
    fn renders_a_jpeg_with_soi_marker() {
        let bytes = render_cover("song_001");
        assert!(bytes.len() > 1024, "cover should not be trivially small");
        // JPEG files start with the SOI marker 0xFFD8.
        assert_eq!(&bytes[..2], &[0xFF, 0xD8]);
    }

    #[test]
    fn rendering_is_deterministic() {
        assert_eq!(render_cover("song_003"), render_cover("song_003"));
    }

    #[test]
    fn cache_returns_identical_bytes() {
        let cache = CoverCache::default();
        let first = cache.get_or_render("song_001");
        let second = cache.get_or_render("song_001");
        assert!(Arc::ptr_eq(&first, &second));
        assert_eq!(cache.len(), 1);
    }
}
