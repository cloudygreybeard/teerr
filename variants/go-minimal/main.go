package main

import (
	"io"
	"os"
)

func main() {
	w := io.MultiWriter(os.Stdout, os.Stderr)
	if _, err := io.Copy(w, os.Stdin); err != nil {
		os.Exit(1)
	}
}
