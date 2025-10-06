//go:build !linux
// +build !linux

package main

func chown(destPath string, ostat interface{}) error {
	return nil
}
