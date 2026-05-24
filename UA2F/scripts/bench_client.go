package main

import (
	"context"
	"encoding/binary"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/url"
	"os"
	"strconv"
	"time"
)

type workerResult struct {
	latenciesSec []float64
	statusCounts map[string]int
	errors       int
	errorSamples []string
	bytesSent    int64
	bytesRecv    int64
}

type clientOutput struct {
	Requests     int            `json:"requests"`
	Completed    int            `json:"completed"`
	Errors       int            `json:"errors"`
	ErrorSamples []string       `json:"error_samples"`
	DurationSec  float64        `json:"duration_sec"`
	LatenciesSec []float64      `json:"latencies_sec"`
	StatusCounts map[string]int `json:"status_counts"`
	BytesSent    int64          `json:"bytes_sent"`
	BytesRecv    int64          `json:"bytes_recv"`
	BytesTotal   int64          `json:"bytes_total"`
}

type clientArgs struct {
	kind        string
	host        string
	port        int
	proxyHost   string
	proxyPort   int
	requests    int
	concurrency int
	timeout     time.Duration
	pathPrefix  string
}

func parseArgs() clientArgs {
	var timeout float64
	args := clientArgs{}
	flag.StringVar(&args.kind, "kind", "", "request path: direct, http-proxy, or socks5")
	flag.StringVar(&args.host, "host", "", "origin server host")
	flag.IntVar(&args.port, "port", 0, "origin server port")
	flag.StringVar(&args.proxyHost, "proxy-host", "", "proxy host")
	flag.IntVar(&args.proxyPort, "proxy-port", 0, "proxy port")
	flag.IntVar(&args.requests, "requests", 0, "total request count")
	flag.IntVar(&args.concurrency, "concurrency", 1, "concurrent workers")
	flag.Float64Var(&timeout, "timeout", 10.0, "per-request timeout seconds")
	flag.StringVar(&args.pathPrefix, "path-prefix", "/bench", "request path prefix")
	flag.Parse()

	args.timeout = time.Duration(timeout * float64(time.Second))
	if args.kind != "direct" && args.kind != "http-proxy" && args.kind != "socks5" {
		fatalf("invalid --kind %q", args.kind)
	}
	if args.host == "" || args.port <= 0 {
		fatalf("--host and --port are required")
	}
	if args.kind != "direct" && (args.proxyHost == "" || args.proxyPort <= 0) {
		fatalf("--proxy-host and --proxy-port are required for %s", args.kind)
	}
	if args.requests < 0 {
		fatalf("--requests cannot be negative")
	}
	if args.concurrency < 1 {
		fatalf("--concurrency must be positive")
	}
	if args.timeout <= 0 {
		fatalf("--timeout must be positive")
	}
	return args
}

func fatalf(format string, args ...any) {
	fmt.Fprintf(os.Stderr, format+"\n", args...)
	os.Exit(2)
}

func main() {
	args := parseArgs()
	output, err := run(args)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	encoder := json.NewEncoder(os.Stdout)
	if err := encoder.Encode(output); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func run(args clientArgs) (clientOutput, error) {
	if args.requests == 0 {
		return clientOutput{
			Requests:     0,
			ErrorSamples: []string{},
			LatenciesSec: []float64{},
			StatusCounts: map[string]int{},
		}, nil
	}

	concurrency := args.concurrency
	if concurrency > args.requests {
		concurrency = args.requests
	}

	client, transport, err := makeHTTPClient(args, concurrency)
	if err != nil {
		return clientOutput{}, err
	}
	defer transport.CloseIdleConnections()

	counts := make([]int, concurrency)
	starts := make([]int, concurrency)
	for i := range counts {
		counts[i] = args.requests / concurrency
		if i < args.requests%concurrency {
			counts[i]++
		}
		if i > 0 {
			starts[i] = starts[i-1] + counts[i-1]
		}
	}

	results := make(chan workerResult, concurrency)
	started := time.Now()
	for i := 0; i < concurrency; i++ {
		go worker(args, client, counts[i], starts[i], results)
	}

	output := clientOutput{
		Requests:     args.requests,
		ErrorSamples: []string{},
		LatenciesSec: []float64{},
		StatusCounts: map[string]int{},
	}
	for i := 0; i < concurrency; i++ {
		result := <-results
		output.LatenciesSec = append(output.LatenciesSec, result.latenciesSec...)
		output.Errors += result.errors
		output.BytesSent += result.bytesSent
		output.BytesRecv += result.bytesRecv
		output.ErrorSamples = append(output.ErrorSamples, result.errorSamples...)
		for status, count := range result.statusCounts {
			output.StatusCounts[status] += count
		}
	}
	output.DurationSec = time.Since(started).Seconds()
	output.Completed = len(output.LatenciesSec)
	if len(output.ErrorSamples) > 20 {
		output.ErrorSamples = output.ErrorSamples[:20]
	}
	output.BytesTotal = output.BytesSent + output.BytesRecv
	return output, nil
}

func makeHTTPClient(args clientArgs, concurrency int) (*http.Client, *http.Transport, error) {
	dialer := &net.Dialer{
		Timeout:   args.timeout,
		KeepAlive: 30 * time.Second,
	}
	transport := &http.Transport{
		DialContext:           dialer.DialContext,
		DisableCompression:    true,
		ForceAttemptHTTP2:     false,
		MaxConnsPerHost:       concurrency,
		MaxIdleConns:          concurrency * 2,
		MaxIdleConnsPerHost:   concurrency,
		IdleConnTimeout:       30 * time.Second,
		ResponseHeaderTimeout: args.timeout,
		ExpectContinueTimeout: time.Second,
	}

	switch args.kind {
	case "http-proxy":
		proxy, err := url.Parse(fmt.Sprintf("http://%s:%d", args.proxyHost, args.proxyPort))
		if err != nil {
			return nil, nil, err
		}
		transport.Proxy = http.ProxyURL(proxy)
	case "socks5":
		proxyAddr := net.JoinHostPort(args.proxyHost, strconv.Itoa(args.proxyPort))
		transport.DialContext = func(ctx context.Context, network string, address string) (net.Conn, error) {
			return socks5DialContext(ctx, dialer, proxyAddr, network, address)
		}
	}

	return &http.Client{Transport: transport, Timeout: args.timeout}, transport, nil
}

func worker(args clientArgs, client *http.Client, count int, startIndex int, results chan<- workerResult) {
	result := workerResult{
		statusCounts: map[string]int{},
	}
	for i := 0; i < count; i++ {
		index := startIndex + i
		started := time.Now()
		status, sent, received, err := makeRequest(args, client, index)
		if err != nil {
			result.errors++
			if len(result.errorSamples) < 10 {
				result.errorSamples = append(result.errorSamples, err.Error())
			}
			continue
		}

		result.latenciesSec = append(result.latenciesSec, time.Since(started).Seconds())
		result.statusCounts[strconv.Itoa(status)]++
		result.bytesSent += sent
		result.bytesRecv += received
	}
	results <- result
}

func makeRequest(args clientArgs, client *http.Client, index int) (int, int64, int64, error) {
	path := fmt.Sprintf("%s/%d", args.pathPrefix, index)
	targetURL := fmt.Sprintf("http://%s:%d%s", args.host, args.port, path)
	ua := fmt.Sprintf("UA-BENCH/%d", index)

	request, err := http.NewRequest(http.MethodGet, targetURL, nil)
	if err != nil {
		return 0, 0, 0, err
	}
	request.Header.Set("User-Agent", ua)
	request.Header.Set("Accept", "*/*")
	request.Header.Set("Accept-Encoding", "identity")
	request.Header.Set("Connection", "keep-alive")

	response, err := client.Do(request)
	if err != nil {
		return 0, 0, 0, err
	}
	defer response.Body.Close()

	bodyBytes, err := io.Copy(io.Discard, response.Body)
	if err != nil {
		return 0, 0, 0, err
	}

	return response.StatusCode, estimateRequestBytes(args, path, targetURL, ua), estimateResponseBytes(response, bodyBytes), nil
}

func estimateRequestBytes(args clientArgs, path string, targetURL string, ua string) int64 {
	target := path
	if args.kind == "http-proxy" {
		target = targetURL
	}
	raw := fmt.Sprintf(
		"GET %s HTTP/1.1\r\nHost: %s:%d\r\nUser-Agent: %s\r\nAccept: */*\r\nAccept-Encoding: identity\r\nConnection: keep-alive\r\n\r\n",
		target,
		args.host,
		args.port,
		ua,
	)
	return int64(len(raw))
}

func estimateResponseBytes(response *http.Response, bodyBytes int64) int64 {
	total := int64(len(response.Proto + " " + response.Status + "\r\n"))
	for key, values := range response.Header {
		for _, value := range values {
			total += int64(len(key) + len(": ") + len(value) + len("\r\n"))
		}
	}
	return total + 2 + bodyBytes
}

func socks5DialContext(ctx context.Context, dialer *net.Dialer, proxyAddr string, network string, address string) (net.Conn, error) {
	if network != "tcp" && network != "tcp4" && network != "tcp6" {
		return nil, fmt.Errorf("unsupported SOCKS5 network %q", network)
	}
	conn, err := dialer.DialContext(ctx, "tcp", proxyAddr)
	if err != nil {
		return nil, err
	}

	if deadline, ok := ctx.Deadline(); ok {
		_ = conn.SetDeadline(deadline)
		defer conn.SetDeadline(time.Time{})
	}
	if err := socks5Handshake(conn, address); err != nil {
		_ = conn.Close()
		return nil, err
	}
	return conn, nil
}

func socks5Handshake(conn net.Conn, address string) error {
	if _, err := conn.Write([]byte{0x05, 0x01, 0x00}); err != nil {
		return err
	}
	reply := []byte{0, 0}
	if _, err := io.ReadFull(conn, reply); err != nil {
		return err
	}
	if reply[0] != 0x05 || reply[1] != 0x00 {
		return fmt.Errorf("SOCKS5 auth negotiation failed: %v", reply)
	}

	host, portText, err := net.SplitHostPort(address)
	if err != nil {
		return err
	}
	port, err := strconv.Atoi(portText)
	if err != nil || port < 0 || port > 65535 {
		return fmt.Errorf("invalid SOCKS5 target port %q", portText)
	}

	request := []byte{0x05, 0x01, 0x00}
	ip := net.ParseIP(host)
	if ip4 := ip.To4(); ip4 != nil {
		request = append(request, 0x01)
		request = append(request, ip4...)
	} else if ip16 := ip.To16(); ip16 != nil {
		request = append(request, 0x04)
		request = append(request, ip16...)
	} else {
		if len(host) > 255 {
			return errors.New("SOCKS5 target host is too long")
		}
		request = append(request, 0x03, byte(len(host)))
		request = append(request, []byte(host)...)
	}
	portBytes := []byte{0, 0}
	binary.BigEndian.PutUint16(portBytes, uint16(port))
	request = append(request, portBytes...)

	if _, err := conn.Write(request); err != nil {
		return err
	}
	header := []byte{0, 0, 0, 0}
	if _, err := io.ReadFull(conn, header); err != nil {
		return err
	}
	if header[0] != 0x05 || header[1] != 0x00 {
		return fmt.Errorf("SOCKS5 connect failed: %v", header)
	}

	var skip int
	switch header[3] {
	case 0x01:
		skip = 4
	case 0x03:
		size := []byte{0}
		if _, err := io.ReadFull(conn, size); err != nil {
			return err
		}
		skip = int(size[0])
	case 0x04:
		skip = 16
	default:
		return fmt.Errorf("SOCKS5 unknown address type: %d", header[3])
	}
	if skip > 0 {
		if _, err := io.CopyN(io.Discard, conn, int64(skip)); err != nil {
			return err
		}
	}
	if _, err := io.CopyN(io.Discard, conn, 2); err != nil {
		return err
	}
	return nil
}
