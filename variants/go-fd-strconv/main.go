package main

import (
	"io"
	"os"
	"strconv"
)

func main() {
	target := os.Stderr
	if len(os.Args) > 1 {
		if fd, err := strconv.Atoi(os.Args[1]); err == nil {
			target = os.NewFile(uintptr(fd), "target")
		}
	}

	w := io.MultiWriter(os.Stdout, target)
	if _, err := io.Copy(w, os.Stdin); err != nil {
		os.Exit(1)
	}
}
