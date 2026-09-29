package rules

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"time"
)

const maxRuleSetBytes = 8 << 20

// Cache stores downloaded rule resources separately from tower.json.
type Cache struct {
	dir    string
	client *http.Client
}

func NewCache(dir string) *Cache {
	return &Cache{
		dir: dir,
		client: &http.Client{
			Timeout: 25 * time.Second,
			CheckRedirect: func(req *http.Request, via []*http.Request) error {
				if len(via) >= 5 || req.URL.Scheme != "https" {
					return fmt.Errorf("unsafe or excessive redirect")
				}
				return nil
			},
		},
	}
}

func (c *Cache) path(rawURL string) string {
	sum := sha256.Sum256([]byte(rawURL))
	return filepath.Join(c.dir, hex.EncodeToString(sum[:])+".list")
}

func (c *Cache) Lines(rawURL string) ([]string, error) {
	b, err := os.ReadFile(c.path(rawURL))
	if err != nil {
		return nil, err
	}
	return strings.Split(string(b), "\n"), nil
}

func (c *Cache) Has(rawURL string) bool {
	_, err := os.Stat(c.path(rawURL))
	return err == nil
}

func (c *Cache) Remove(rawURL string) {
	_ = os.Remove(c.path(rawURL))
}

func (c *Cache) Download(rawURL string) error {
	u, err := url.Parse(strings.TrimSpace(rawURL))
	if err != nil || u.Scheme != "https" || u.Host == "" || u.User != nil {
		return fmt.Errorf("规则集地址必须是无凭据的 HTTPS URL")
	}
	req, err := http.NewRequestWithContext(context.Background(), http.MethodGet, u.String(), nil)
	if err != nil {
		return err
	}
	req.Header.Set("User-Agent", "Tower/0.1")
	resp, err := c.client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("下载规则集失败：HTTP %d", resp.StatusCode)
	}
	limited, err := io.ReadAll(io.LimitReader(resp.Body, maxRuleSetBytes+1))
	if err != nil {
		return err
	}
	if len(limited) > maxRuleSetBytes {
		return fmt.Errorf("规则集超过 %d 字节限制", maxRuleSetBytes)
	}
	if len(strings.TrimSpace(string(limited))) == 0 {
		return fmt.Errorf("规则集内容为空")
	}
	if err := os.MkdirAll(c.dir, 0o755); err != nil {
		return err
	}
	tmp, err := os.CreateTemp(c.dir, ".rules-*.tmp")
	if err != nil {
		return err
	}
	name := tmp.Name()
	defer os.Remove(name)
	if err := tmp.Chmod(0o644); err != nil {
		_ = tmp.Close()
		return err
	}
	if _, err := tmp.Write(limited); err != nil {
		_ = tmp.Close()
		return err
	}
	if err := tmp.Sync(); err != nil {
		_ = tmp.Close()
		return err
	}
	if err := tmp.Close(); err != nil {
		return err
	}
	if err := os.Rename(name, c.path(u.String())); err != nil {
		return err
	}
	return nil
}
