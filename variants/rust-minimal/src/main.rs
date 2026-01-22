use std::io::{self, Read, Write};
use std::process::ExitCode;

fn main() -> ExitCode {
    let stdin = io::stdin();
    let stdout = io::stdout();
    let stderr = io::stderr();

    let mut stdin = stdin.lock();
    let mut stdout = stdout.lock();
    let mut stderr = stderr.lock();

    let mut buf = [0u8; 8192];

    loop {
        match stdin.read(&mut buf) {
            Ok(0) => return ExitCode::SUCCESS,
            Ok(n) => {
                if stdout.write_all(&buf[..n]).is_err() {
                    return ExitCode::FAILURE;
                }
                if stderr.write_all(&buf[..n]).is_err() {
                    return ExitCode::FAILURE;
                }
            }
            Err(_) => return ExitCode::FAILURE,
        }
    }
}
