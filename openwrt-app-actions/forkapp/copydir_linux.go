//go:build linux
// +build linux

package main

import (
	"os"
	"syscall"
)

func chown(destPath string, ostat interface{}) error {
	stat, ok := ostat.(*syscall.Stat_t)
	if ok {
		if err := os.Lchown(destPath, int(stat.Uid), int(stat.Gid)); err != nil {
			return err
		}
	}
	return nil
}
