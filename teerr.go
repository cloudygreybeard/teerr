// teerr copies standard input to both standard output and standard error.
//
// Usage:
//
//	teerr              # duplicate stdin to stdout and stderr
//	teerr 3            # duplicate stdin to stdout and fd 3
//	teerr --version    # print version and exit
//	teerr --help       # print usage and exit
//
// teerr is a replacement for the shell construct:
//
//	tee >(cat >&2)
//
// but faster and with fewer keystrokes.
package main

import (
	"fmt"
	"io"
	"os"
)

// Set via ldflags at build time
var (
	version = "dev"
	commit  = "none"
	date    = "unknown"
)

const usage = `teerr - copy stdin to stdout and stderr

Usage:
  teerr [fd]
  teerr --version
  teerr --help

Arguments:
  fd    File descriptor to write to instead of stderr (default: 2)

Examples:
  value=$(command | teerr)     # capture and echo to stderr
  generate | teerr | consume   # observe pipeline flow
  command | teerr 3            # write to fd 3 instead of stderr

teerr is equivalent to: tee >(cat >&2)
`

func main() {
	if len(os.Args) > 1 {
		switch os.Args[1] {
		case "-V", "--version", "version":
			fmt.Printf("teerr %s (%s, %s)\n", version, commit, date)
			return
		case "-h", "--help", "help":
			fmt.Print(usage)
			return
		}
	}

	target := os.Stderr
	if len(os.Args) > 1 {
		if fd, ok := atoi(os.Args[1]); ok {
			target = os.NewFile(uintptr(fd), "target")
		}
	}

	w := io.MultiWriter(os.Stdout, target)
	if _, err := io.Copy(w, os.Stdin); err != nil {
		os.Exit(1)
	}
}

// atoi parses a non-negative integer from a string.
// Returns (0, false) if the string is empty or contains non-digits.
func atoi(s string) (int, bool) {
	if s == "" {
		return 0, false
	}
	n := 0
	for _, c := range s {
		if c < '0' || c > '9' {
			return 0, false
		}
		n = n*10 + int(c-'0')
	}
	return n, true
}
