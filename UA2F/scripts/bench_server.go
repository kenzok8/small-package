package main

import (
	"bytes"
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"os/signal"
	"sort"
	"strconv"
	"sync"
	"syscall"
	"time"
)

type statsStore struct {
	mu         sync.Mutex
	requests   int
	userAgents map[string]int
}

type statsSnapshot struct {
	Requests   int            `json:"requests"`
	UserAgents map[string]int `json:"user_agents"`
}

func newStatsStore() *statsStore {
	return &statsStore{userAgents: map[string]int{}}
}

func (s *statsStore) reset() {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.requests = 0
	s.userAgents = map[string]int{}
}

func (s *statsStore) record(userAgent string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.requests++
	s.userAgents[userAgent]++
}

func (s *statsStore) snapshot() statsSnapshot {
	s.mu.Lock()
	defer s.mu.Unlock()

	type pair struct {
		ua    string
		count int
	}
	pairs := make([]pair, 0, len(s.userAgents))
	for ua, count := range s.userAgents {
		pairs = append(pairs, pair{ua: ua, count: count})
	}
	sort.Slice(pairs, func(i, j int) bool {
		if pairs[i].count == pairs[j].count {
			return pairs[i].ua < pairs[j].ua
		}
		return pairs[i].count > pairs[j].count
	})
	if len(pairs) > 10 {
		pairs = pairs[:10]
	}

	agents := make(map[string]int, len(pairs))
	for _, item := range pairs {
		agents[item.ua] = item.count
	}
	return statsSnapshot{
		Requests:   s.requests,
		UserAgents: agents,
	}
}

func main() {
	addr := flag.String("addr", "10.250.0.1:18080", "benchmark HTTP listen address")
	controlAddr := flag.String("control-addr", "127.0.0.1:18081", "stats/control HTTP listen address")
	bodyBytes := flag.Int("body-bytes", 4096, "response body size")
	flag.Parse()

	if *bodyBytes < 0 {
		fmt.Fprintln(os.Stderr, "--body-bytes cannot be negative")
		os.Exit(2)
	}

	stats := newStatsStore()
	body := bytes.Repeat([]byte("x"), *bodyBytes)
	benchmarkServer := &http.Server{
		Addr:              *addr,
		Handler:           benchmarkHandler(stats, body),
		ReadHeaderTimeout: 5 * time.Second,
		ErrorLog:          log.New(io.Discard, "", 0),
	}
	controlServer := &http.Server{
		Addr:              *controlAddr,
		Handler:           controlHandler(stats),
		ReadHeaderTimeout: 5 * time.Second,
		ErrorLog:          log.New(io.Discard, "", 0),
	}

	errs := make(chan error, 2)
	go func() {
		errs <- benchmarkServer.ListenAndServe()
	}()
	go func() {
		errs <- controlServer.ListenAndServe()
	}()

	signals := make(chan os.Signal, 1)
	signal.Notify(signals, syscall.SIGINT, syscall.SIGTERM)

	select {
	case sig := <-signals:
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		_ = benchmarkServer.Shutdown(ctx)
		_ = controlServer.Shutdown(ctx)
		<-time.After(10 * time.Millisecond)
		fmt.Fprintf(os.Stderr, "stopped on %s\n", sig)
	case err := <-errs:
		if err != nil && err != http.ErrServerClosed {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(1)
		}
	}
}

func benchmarkHandler(stats *statsStore, body []byte) http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
			return
		}

		stats.record(r.Header.Get("User-Agent"))
		w.Header().Set("Content-Type", "application/octet-stream")
		w.Header().Set("Content-Length", strconv.Itoa(len(body)))
		w.Header().Set("Connection", "keep-alive")
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write(body)
	})
	return mux
}

func controlHandler(stats *statsStore) http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("/__ua_bench_reset", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost && r.Method != http.MethodGet {
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
			return
		}
		stats.reset()
		writeJSON(w, map[string]bool{"ok": true})
	})
	mux.HandleFunc("/__ua_bench_stats", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
			return
		}
		writeJSON(w, stats.snapshot())
	})
	return mux
}

func writeJSON(w http.ResponseWriter, value any) {
	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(value); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
}
