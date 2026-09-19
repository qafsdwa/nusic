use std::fs::File;
use std::time::Instant;

use symphonia::core::codecs::DecoderOptions;
use symphonia::core::formats::FormatOptions;
use symphonia::core::io::MediaSourceStream;
use symphonia::core::meta::MetadataOptions;
use symphonia::core::probe::Hint;

fn main() {
    for path in std::env::args().skip(1) {
        println!("=== {path} ===");
        let start = Instant::now();
        let file = File::open(&path).unwrap();
        let len = file.metadata().map(|m| m.len()).unwrap_or(0);
        let mss = MediaSourceStream::new(Box::new(file), Default::default());
        let mut hint = Hint::new();
        if let Some(ext) = std::path::Path::new(&path)
            .extension()
            .and_then(|e| e.to_str())
        {
            hint.with_extension(ext);
        }
        let fmt_opts = FormatOptions {
            enable_gapless: true,
            ..Default::default()
        };
        let mut probed = symphonia::default::get_probe()
            .format(&hint, mss, &fmt_opts, &MetadataOptions::default())
            .unwrap();
        let track = probed.format.default_track().unwrap();
        let tb = track.codec_params.time_base;
        let mut dec = symphonia::default::get_codecs()
            .make(&track.codec_params, &DecoderOptions::default())
            .unwrap();
        let mut last_end = 0u64;
        let mut total_samples = 0u64;
        let mut packets = 0u64;
        while let Ok(p) = probed.format.next_packet() {
            packets += 1;
            if let Some(ts) = p.ts().checked_add(p.dur()) {
                last_end = last_end.max(ts);
            }
            if let Ok(buf) = dec.decode(&p) {
                total_samples += buf.frames() as u64;
            }
        }
        let from_ts = tb.map(|tb| tb.calc_time(last_end));
        println!("  packets={packets} last_end_ts={last_end} total_frames={total_samples}");
        println!("  tb={:?} from_ts={:?}", tb, from_ts);
        if let Some(t) = from_ts {
            println!("  duration={:.3}s", t.seconds as f64 + t.frac);
        }
        println!(
            "  scan took {:?} for {} MB",
            start.elapsed(),
            len / 1024 / 1024
        );
    }
}
