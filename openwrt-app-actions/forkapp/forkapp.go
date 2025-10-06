package main

import (
	"errors"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path"
	"path/filepath"
	"strings"

	"github.com/urfave/cli"
)

func doForkApp(fromPath, toPath, fromApp, toApp string, replaces []string, force bool) error {
	p := len("luci-app-")
	fromApp = fromApp[p:]
	toApp = toApp[p:]
	if !Exists(toPath) {
		os.Mkdir(toPath, 0755)
	}
	toLen := len(toPath)
	changePathFn := func(src, dst string) string {
		return dst[:toLen] + strings.ReplaceAll(dst[toLen:], fromApp, toApp)
	}
	cpFn := func(srcFile, dstFile string, overwrite bool) error {
		if !overwrite && Exists(dstFile) {
			return nil
		}
		out, err := os.Create(dstFile)
		if err != nil {
			return err
		}
		defer out.Close()

		b, err := ioutil.ReadFile(srcFile)
		if err != nil {
			return err
		}
		rlt := strings.ReplaceAll(string(b), fromApp, toApp)
		for _, repl := range replaces {
			ss := strings.Split(repl, "/")
			if len(ss) == 2 {
				rlt = strings.ReplaceAll(rlt, ss[0], ss[1])
			}
		}
		_, err = out.WriteString(rlt)
		if err != nil {
			fmt.Println(dstFile, "failed")
		} else {
			fmt.Println(dstFile, "ok")
		}
		return err
	}
	return CopyDirectory(fromPath, toPath, force, changePathFn, cpFn)
}

func uploadOrInstall(c *cli.Context) error {
	fromPath := c.String("from")
	toPath := c.String("to")
	if fromPath == "" {
		return errors.New("invalid fromPath")
	}
	if toPath == "" {
		return errors.New("invalid toPath")
	}
	if c.String("ip") == "" {
		return errors.New("invalid ip")
	}
	pwd := c.String("pwd")
	if pwd == "" {
		pwd = "password"
	}
	port := c.String("port")
	if port == "" {
		port = "22"
	}
	if !Exists(fromPath) {
		return errors.New("fromPath not found")
	}
	install := c.Bool("install")
	sshConn, err := NewSSHClient(c.String("ip"), port, "root", pwd)
	if err != nil {
		return err
	}
	if b, err := SshDirExists(sshConn, toPath); err != nil {
		return err
	} else if !b {
		return errors.New(fmt.Sprintf("to: %s not found", toPath))
	}
	defer sshConn.Close()
	scriptPath := c.String("script")
	err = SshCopyDirectory(sshConn, fromPath, toPath, scriptPath)
	if err != nil {
		return err
	}
	if install {
		targetScript := path.Join(toPath, filepath.Base(fromPath), filepath.Base(scriptPath))
		if b, err := SshFileExists(sshConn, targetScript); err != nil || !b {
			fmt.Println("Path:", targetScript, "not found")
			return nil
		}
		cmd := fmt.Sprintf("cd \"%s\" && ./%s", path.Join(toPath, filepath.Base(fromPath)), filepath.Base(scriptPath))
		var rlt []byte
		rlt, err = SshRunCmd(sshConn, cmd)
		if err != nil || !strings.Contains(string(rlt), "Ok") {
			fmt.Println("Run", cmd, "failed")
		}
	}
	return err
}

func main() {
	var cliApp *cli.App
	cliApp = &cli.App{
		Name:  "forkApp",
		Usage: "fork a luci app",
		Action: func(c *cli.Context) error {
			cli.ShowAppHelp(c)
			return nil
		},
		Commands: []cli.Command{
			{
				Name:    "fork",
				Aliases: []string{"forkApp", "forkapp"},
				Flags: []cli.Flag{
					cli.StringFlag{
						Name:  "from",
						Usage: "-from ../luci-app-plex",
					},
					cli.StringFlag{
						Name:  "to",
						Usage: "-to luci-app-ittools",
					},
					cli.BoolFlag{
						Name:  "force",
						Usage: "-force true",
					},
					cli.StringSliceFlag{
						Name:  "replace",
						Usage: "-replace Plex/ITTools",
					},
				},
				Action: func(c *cli.Context) error {
					fromPath := c.String("from")
					toPath := c.String("to")
					if fromPath == "" {
						return errors.New("invalid fromPath")
					}
					if toPath == "" {
						return errors.New("invalid toPath")
					}
					if !Exists(fromPath) {
						return errors.New("fromPath not found")
					}
					fromApp := filepath.Base(fromPath)
					if !strings.HasPrefix(fromApp, "luci-app-") {
						return errors.New("dir name should be luci-app-xxx")
					}
					toApp := filepath.Base(toPath)
					if !strings.HasPrefix(toApp, "luci-app-") {
						return errors.New("dir name should be luci-app-xxx")
					}
					if !Exists(filepath.Dir(toPath)) {
						return errors.New(fmt.Sprintf("toPath: %s not found", filepath.Dir(toPath)))
					}
					return doForkApp(fromPath, toPath, fromApp, toApp, c.StringSlice("replace"), c.Bool("force"))
				},
			},
			{
				Name:    "upload",
				Aliases: []string{"u"},
				Flags: []cli.Flag{
					cli.StringSliceFlag{
						Name:  "from",
						Usage: "../luci-app-plex",
					},
					cli.StringSliceFlag{
						Name:  "to",
						Usage: "/root",
					},
					cli.StringFlag{
						Name:  "ip",
						Usage: "-ip 192.168.100.1",
					},
					cli.StringFlag{
						Name:  "port",
						Usage: "-port 22",
					},
					cli.StringFlag{
						Name:  "pwd",
						Usage: "-pwd password",
					},
					cli.BoolFlag{
						Name:  "install",
						Usage: "-install true",
					},
					cli.StringFlag{
						Name:  "script",
						Usage: "-script ../tools/simple-instal.sh",
					},
				},
				Action: func(c *cli.Context) error {
					return uploadOrInstall(c)
				},
			},
		},
	}

	err := cliApp.Run(os.Args)
	if err != nil {
		log.Fatal(err)
	}
}
