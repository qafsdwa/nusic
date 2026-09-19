use lofty::file::{FileType, TaggedFileExt};
use lofty::prelude::*;
use lofty::probe::Probe;

fn main() {
    for path in std::env::args().skip(1) {
        println!("=== {path} ===");
        match lofty::read_from_path(&path) {
            Ok(t) => print_tagged("read_from_path", &t),
            Err(e) => println!("  read_from_path ERR: {e}"),
        }
        match Probe::open(&path) {
            Ok(p) => match p.guess_file_type() {
                Ok(p) => match p.read() {
                    Ok(t) => print_tagged("guessed", &t),
                    Err(e) => println!("  guessed ERR: {e}"),
                },
                Err(e) => println!("  guess ERR: {e}"),
            },
            Err(e) => println!("  open ERR: {e}"),
        }
        match Probe::open(&path) {
            Ok(p) => match p.set_file_type(FileType::Mp4).read() {
                Ok(t) => print_tagged("forced-mp4", &t),
                Err(e) => println!("  forced-mp4 ERR: {e}"),
            },
            Err(e) => println!("  open ERR: {e}"),
        }
    }
}

fn print_tagged(label: &str, t: &lofty::file::TaggedFile) {
    let tag = t.primary_tag().or_else(|| t.first_tag());
    println!(
        "  [{label}] type={:?} dur={:?} title={:?} artist={:?} album={:?} pics={}",
        t.file_type(),
        t.properties().duration(),
        tag.and_then(|x| x.title().map(|s| s.to_string())),
        tag.and_then(|x| x.artist().map(|s| s.to_string())),
        tag.and_then(|x| x.album().map(|s| s.to_string())),
        tag.map(|x| x.pictures().len()).unwrap_or(0),
    );
}
