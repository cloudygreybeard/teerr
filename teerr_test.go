package main

import (
	"bytes"
	"io"
	"os"
	"testing"
)

func TestTeerrCopiesToStdoutAndStderr(t *testing.T) {
	input := "hello, world\n"

	// Save originals
	oldStdin := os.Stdin
	oldStdout := os.Stdout
	oldStderr := os.Stderr
	oldArgs := os.Args
	defer func() {
		os.Stdin = oldStdin
		os.Stdout = oldStdout
		os.Stderr = oldStderr
		os.Args = oldArgs
	}()

	// Reset args to just the program name
	os.Args = []string{"teerr"}

	// Pipes for stdin, stdout, stderr
	inR, inW, err := os.Pipe()
	if err != nil {
		t.Fatal(err)
	}
	outR, outW, err := os.Pipe()
	if err != nil {
		t.Fatal(err)
	}
	errR, errW, err := os.Pipe()
	if err != nil {
		t.Fatal(err)
	}

	os.Stdin = inR
	os.Stdout = outW
	os.Stderr = errW

	// Write input
	go func() {
		_, _ = io.WriteString(inW, input)
		inW.Close()
	}()

	main()

	// Close writers so reads complete
	outW.Close()
	errW.Close()

	var stdoutBuf, stderrBuf bytes.Buffer
	_, _ = io.Copy(&stdoutBuf, outR)
	_, _ = io.Copy(&stderrBuf, errR)

	if stdoutBuf.String() != input {
		t.Fatalf("stdout mismatch: got %q, want %q", stdoutBuf.String(), input)
	}

	if stderrBuf.String() != input {
		t.Fatalf("stderr mismatch: got %q, want %q", stderrBuf.String(), input)
	}
}

func TestAtoi(t *testing.T) {
	tests := []struct {
		input string
		want  int
		ok    bool
	}{
		{"0", 0, true},
		{"1", 1, true},
		{"2", 2, true},
		{"10", 10, true},
		{"123", 123, true},
		{"", 0, false},
		{"abc", 0, false},
		{"12abc", 0, false},
		{"-1", 0, false},
		{"1.5", 0, false},
	}

	for _, tt := range tests {
		got, ok := atoi(tt.input)
		if got != tt.want || ok != tt.ok {
			t.Errorf("atoi(%q) = (%d, %v), want (%d, %v)", tt.input, got, ok, tt.want, tt.ok)
		}
	}
}
