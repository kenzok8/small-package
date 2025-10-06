package main

import (
	"fmt"
	"io"
	"os"
	"path/filepath"
)

type ChangePathFunc func(srcFile, dstFile string) string
type CopyFunc func(srcFile, dstFile string, overwrite bool) error

func CopyDirectory(scrDir, dest string, overwrite bool, changePathFn ChangePathFunc, cpFn CopyFunc) error {
	entries, err := os.ReadDir(scrDir)
	if err != nil {
		return err
	}
	for _, entry := range entries {
		sourcePath := filepath.Join(scrDir, entry.Name())
		fileInfo, err := os.Stat(sourcePath)
		if err != nil {
			return err
		}

		ostat := fileInfo.Sys()
		destPath := filepath.Join(dest, entry.Name())
		destPath = changePathFn(sourcePath, destPath)

		switch fileInfo.Mode() & os.ModeType {
		case os.ModeDir:
			if err = CreateIfNotExists(destPath, 0755); err != nil {
				return err
			}
			if err = CopyDirectory(sourcePath, destPath, overwrite, changePathFn, cpFn); err != nil {
				return err
			}
		case os.ModeSymlink:
			if err = CopySymLink(sourcePath, destPath); err != nil {
				return err
			}
		default:
			if err = cpFn(sourcePath, destPath, overwrite); err != nil {
				return err
			}
		}

		err = chown(destPath, ostat)
		if err != nil {
			return err
		}

		fInfo, err := entry.Info()
		if err != nil {
			return err
		}

		isSymlink := fInfo.Mode()&os.ModeSymlink != 0
		if !isSymlink {
			if err := os.Chmod(destPath, fInfo.Mode()); err != nil {
				return err
			}
		}
	}
	return nil
}

func Copy(srcFile, dstFile string, overwrite bool) error {
	if !overwrite && Exists(dstFile) {
		return nil
	}
	out, err := os.Create(dstFile)
	if err != nil {
		return err
	}

	defer out.Close()

	in, err := os.Open(srcFile)
	if err != nil {
		return err
	}

	defer in.Close()

	_, err = io.Copy(out, in)
	if err != nil {
		return err
	}

	return nil
}

func Exists(filePath string) bool {
	if _, err := os.Stat(filePath); os.IsNotExist(err) {
		return false
	}

	return true
}

func CreateIfNotExists(dir string, perm os.FileMode) error {
	if Exists(dir) {
		return nil
	}

	if err := os.MkdirAll(dir, perm); err != nil {
		return fmt.Errorf("failed to create directory: '%s', error: '%s'", dir, err.Error())
	}

	return nil
}

func CopySymLink(source, dest string) error {
	link, err := os.Readlink(source)
	if err != nil {
		return err
	}
	return os.Symlink(link, dest)
}
