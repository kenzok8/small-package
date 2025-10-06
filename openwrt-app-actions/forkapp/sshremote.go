package main

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"io"
	"net"
	"os"
	"path"
	"path/filepath"
	"strings"
	"time"

	"github.com/kballard/go-shellquote"
	"github.com/mholt/archiver/v4"
	"golang.org/x/crypto/ssh"
)

func NewSSHClient(remote, sshPort, username, password string) (*ssh.Client, error) {
	c, err := net.DialTimeout("tcp", remote+":"+sshPort, time.Second*5)
	if err != nil {
		return nil, err
	}
	sconn, chans, reqs, err := ssh.NewClientConn(c, remote, &ssh.ClientConfig{
		User: username,
		Auth: []ssh.AuthMethod{
			ssh.Password(password),
		},
		HostKeyCallback: ssh.InsecureIgnoreHostKey(),
		Timeout:         time.Second * 5,
	})
	sshConn := ssh.NewClient(sconn, chans, reqs)
	return sshConn, err
}

func SshDirExists(sshConn *ssh.Client, remoteDir string) (bool, error) {
	session, err := sshConn.NewSession()
	if err != nil {
		return false, err
	}
	defer session.Close()
	var errMsg bytes.Buffer
	var output bytes.Buffer
	session.Stderr = &errMsg
	session.Stdout = &output
	err = session.Run(fmt.Sprintf("[ -d \"%s\" ] && echo Ok", remoteDir))
	if err != nil {
		return false, err
	}
	if strings.Contains(output.String(), "Ok") {
		return true, nil
	}
	return false, nil
}

func SshFileExists(sshConn *ssh.Client, remoteDir string) (bool, error) {
	session, err := sshConn.NewSession()
	if err != nil {
		return false, err
	}
	defer session.Close()
	var errMsg bytes.Buffer
	var output bytes.Buffer
	session.Stderr = &errMsg
	session.Stdout = &output
	err = session.Run(fmt.Sprintf("[ -f \"%s\" ] && echo Ok", remoteDir))
	if err != nil {
		return false, err
	}
	if strings.Contains(output.String(), "Ok") {
		return true, nil
	}
	return false, nil
}

func SshCreateDir(sshConn *ssh.Client, remotePath string) error {
	session, err := sshConn.NewSession()
	if err != nil {
		return err
	}
	defer session.Close()

	return session.Run("mkdir -p " + remotePath)
}

func SshFetchFile(sshConn *ssh.Client, remotePath string) ([]byte, error) {
	session, err := sshConn.NewSession()
	if err != nil {
		return nil, err
	}
	defer session.Close()
	var errMsg bytes.Buffer
	var output bytes.Buffer
	session.Stderr = &errMsg
	session.Stdout = &output
	err = session.Run(fmt.Sprintf("cat \"%s\"", remotePath))
	if err != nil {
		oute := errMsg.Bytes()
		if len(oute) == 0 {
			return nil, err
		}
		return nil, errors.New(string(oute))
	}
	outb := output.Bytes()
	return outb, nil
}

func SshCopy(session *ssh.Session, size int64, mode os.FileMode, fileName string, contents io.Reader, destinationPath string) error {
	return sshCopy(session, size, mode, fileName, contents, destinationPath)
}

func SshCopyPath(session *ssh.Session, filePath, destinationPath string) error {
	f, err := os.Open(filePath)
	if err != nil {
		return err
	}
	defer f.Close()
	s, err := f.Stat()
	if err != nil {
		return err
	}
	return sshCopy(session, s.Size(), s.Mode().Perm(), path.Base(filePath), f, destinationPath)
}

func sshCopy(session *ssh.Session, size int64, mode os.FileMode, fileName string, contents io.Reader, destination string) error {
	defer session.Close()
	w, err := session.StdinPipe()

	if err != nil {
		return err
	}

	cmd := shellquote.Join("scp", "-t", destination)
	if err := session.Start(cmd); err != nil {
		w.Close()
		return err
	}

	errors := make(chan error)

	go func() {
		errors <- session.Wait()
	}()

	fmt.Fprintf(w, "C%#o %d %s\n", mode, size, fileName)
	io.Copy(w, contents)
	fmt.Fprint(w, "\x00")
	w.Close()

	return <-errors
}

func SshCopyDirectory(sshConn *ssh.Client, srcDir, dest, installScript string) error {
	baseName := filepath.Base(srcDir)
	var files []archiver.File
	var err error
	if installScript != "" && Exists(installScript) {
		files, err = archiver.FilesFromDisk(nil, map[string]string{
			srcDir:        baseName,
			installScript: path.Join(baseName, filepath.Base(installScript)),
		})
	} else {
		files, err = archiver.FilesFromDisk(nil, map[string]string{
			srcDir: baseName,
		})
	}
	if err != nil {
		return err
	}

	// we can use the CompressedArchive type to gzip a tarball
	// (compression is not required; you could use Tar directly)
	format := archiver.CompressedArchive{
		Compression: nil,
		Archival:    archiver.Tar{},
	}

	session, err := sshConn.NewSession()
	if err != nil {
		return err
	}
	defer session.Close()
	w, err := session.StdinPipe()

	if err != nil {
		return err
	}

	cmd := shellquote.Join("tar", "xC", dest, "-f", "-")
	if err := session.Start(cmd); err != nil {
		w.Close()
		return err
	}

	errors := make(chan error)

	go func() {
		errors <- session.Wait()
	}()

	// create the archive
	go func() {
		err = format.Archive(context.Background(), w, files)
		w.Close()
	}()

	err1 := <-errors
	if err1 != nil {
		return err1
	}
	return err
}

func SshRunCmd(sshConn *ssh.Client, cmd string) ([]byte, error) {
	session, err := sshConn.NewSession()
	if err != nil {
		return nil, err
	}
	defer session.Close()
	var errMsg bytes.Buffer
	var output bytes.Buffer
	session.Stderr = &errMsg
	session.Stdout = &output
	err = session.Run(cmd)
	if err != nil {
		oute := errMsg.Bytes()
		if len(oute) == 0 {
			return nil, err
		}
		return nil, errors.New(string(oute))
	}
	outb := output.Bytes()
	return outb, nil
}
