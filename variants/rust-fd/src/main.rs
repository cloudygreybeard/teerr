use std::env;
use std::fs::File;
use std::io::{self, Read, Write};
use std::os::fd::FromRawFd;
use std::process::ExitCode;

fn main() -> ExitCode {
    let stdin = io::stdin();
    let stdout = io::stdout();

    let mut stdin = stdin.lock();
    let mut stdout = stdout.lock();

    // Parse optional FD argument, default to stderr (fd 2)
    let target_fd: i32 = env::args()
        .nth(1)
        .and_then(|s| s.parse().ok())
        .unwrap_or(2);

    // SAFETY: We trust the user to provide a valid, open file descriptor.
    // If invalid, writes will fail and we'll exit with an error.
    let mut target: Box<dyn Write> = if target_fd == 2 {
        Box::new(io::stderr().lock())
    } else {
        Box::new(unsafe { File::from_raw_fd(target_fd) })
    };

    let mut buf = [0u8; 8192];

    loop {
        match stdin.read(&mut buf) {
            Ok(0) => return ExitCode::SUCCESS,
            Ok(n) => {
                if stdout.write_all(&buf[..n]).is_err() {
                    return ExitCode::FAILURE;
                }
                if target.write_all(&buf[..n]).is_err() {
                    return ExitCode::FAILURE;
                }
            }
            Err(_) => return ExitCode::FAILURE,
        }
    }
}
