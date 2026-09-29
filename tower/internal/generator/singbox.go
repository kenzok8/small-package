package generator

import (
	"encoding/json"
	"strconv"
	"strings"

	"github.com/kenzok8/tower/internal/model"
)

const singBoxDirectTag = "DIRECT"

// generateSingBox renders a sing-box JSON configuration (sing-box MT / Hiddify).
func generateSingBox(opts Options) string {
	nodeTags := uniquedNames(opts.Nodes)

	outbounds := []any{}

	// Policy groups: a select group, a url-test group, and DIRECT.
	outbounds = append(outbounds, map[string]any{
		"tag":       selectGroupName,
		"type":      "selector",
		"outbounds": append(append([]string{}, nodeTags...), singBoxDirectTag),
	})
	outbounds = append(outbounds, map[string]any{
		"tag":       autoGroupName,
		"type":      "urltest",
		"url":       "https://www.gstatic.com/generate_204",
		"interval":  "300s",
		"tolerance": 50,
		"outbounds": nodeTags,
	})
	outbounds = append(outbounds, map[string]any{
		"tag":  singBoxDirectTag,
		"type": "direct",
	})

	// Node outbounds.
	for i, n := range opts.Nodes {
		tag := nodeTags[i]
		if ob := singBoxOutbound(n, tag); ob != nil {
			outbounds = append(outbounds, ob)
		}
	}

	config := map[string]any{
		"log": map[string]any{"level": "warn", "timestamp": true},
		"inbounds": []any{
			map[string]any{
				"type":         "tun",
				"tag":          "tun-in",
				"address":      []string{"172.19.0.1/30", "fdfe:dcba:9876::1/126"},
				"auto_route":   true,
				"strict_route": true,
				"stack":        "mixed",
			},
		},
		"outbounds": outbounds,
		"route": map[string]any{
			"final":                 selectGroupName,
			"auto_detect_interface": true,
		},
	}

	b, err := json.MarshalIndent(config, "", "  ")
	if err != nil {
		return "{}\n"
	}
	return string(b) + "\n"
}

// singBoxOutbound serializes one proxy node to a sing-box outbound object.
func singBoxOutbound(node model.ProxyNode, tag string) map[string]any {
	outbound := map[string]any{
		"tag":         tag,
		"server":      node.Server,
		"server_port": node.Port,
	}

	switch node.Kind {
	case model.KindShadowsocks:
		outbound["type"] = "shadowsocks"
		outbound["method"] = firstNonEmpty(node.Cipher, "aes-256-gcm")
		outbound["password"] = node.Password
		if node.Plugin == "v2ray-plugin" {
			outbound["plugin"] = "v2ray-plugin"
			opts := []string{"mode=websocket"}
			if node.PluginMux != nil {
				opts = append(opts, "mux="+map[bool]string{true: "1", false: "0"}[*node.PluginMux])
			}
			if node.TLS {
				opts = append(opts, "tls")
			}
			if node.HostHeader != "" {
				opts = append(opts, "host="+node.HostHeader)
			}
			if p := node.ExportablePath(); p != "" {
				opts = append(opts, "path="+p)
			}
			outbound["plugin_opts"] = strings.Join(opts, ";")
		} else if mode := simpleObfsMode(node); mode != "" {
			outbound["plugin"] = "obfs-local"
			opts := []string{"obfs=" + mode}
			if node.ObfsParam != "" {
				opts = append(opts, "obfs-host="+node.ObfsParam)
			}
			outbound["plugin_opts"] = strings.Join(opts, ";")
		}
	case model.KindShadowsocksR:
		outbound["type"] = "shadowsocksr"
		outbound["method"] = firstNonEmpty(node.Cipher, "aes-256-cfb")
		outbound["password"] = node.Password
		outbound["protocol"] = firstNonEmpty(node.ProtocolName, "origin")
		if node.ProtocolParam != "" {
			outbound["protocol_param"] = node.ProtocolParam
		}
		outbound["obfs"] = firstNonEmpty(node.Obfs, "plain")
		if node.ObfsParam != "" {
			outbound["obfs_param"] = node.ObfsParam
		}
	case model.KindVMess:
		outbound["type"] = "vmess"
		outbound["uuid"] = exportableUUID(node.UUID)
		outbound["security"] = singBoxVMessSecurity(node)
		outbound["alter_id"] = 0
	case model.KindVLESS:
		outbound["type"] = "vless"
		outbound["uuid"] = exportableUUID(node.UUID)
		if node.Flow != "" {
			outbound["flow"] = node.Flow
		}
	case model.KindTrojan:
		outbound["type"] = "trojan"
		outbound["password"] = node.Password
	case model.KindHysteria2:
		outbound["type"] = "hysteria2"
		outbound["password"] = node.Password
		if t, p := hysteria2Obfs(node); t != "" {
			outbound["obfs"] = map[string]any{"type": t, "password": p}
		}
	case model.KindHysteria:
		outbound["type"] = "hysteria"
		outbound["auth_str"] = node.Password
		outbound["up_mbps"] = ptrInt(node.UpMbps, 50)
		outbound["down_mbps"] = ptrInt(node.DownMbps, 100)
		if node.Obfs != "" && !strings.EqualFold(node.Obfs, "none") {
			outbound["obfs"] = node.Obfs
		}
	case model.KindTUIC:
		outbound["type"] = "tuic"
		outbound["uuid"] = exportableUUID(node.UUID)
		outbound["password"] = node.Password
		if node.CongestionControl != "" {
			outbound["congestion_control"] = node.CongestionControl
		}
		if node.UDPRelayMode != "" {
			outbound["udp_relay_mode"] = node.UDPRelayMode
		}
	case model.KindWireGuard:
		outbound["type"] = "wireguard"
		var addresses []string
		if v := node.WireGuardIPv4; v != "" {
			if !strings.Contains(v, "/") {
				v += "/32"
			}
			addresses = append(addresses, v)
		}
		if v := node.WireGuardIPv6; v != "" {
			if !strings.Contains(v, "/") {
				v += "/128"
			}
			addresses = append(addresses, v)
		}
		outbound["local_address"] = addresses
		outbound["private_key"] = node.WireGuardPrivateKey
		outbound["peer_public_key"] = node.WireGuardPublicKey
		if node.WireGuardPreSharedKey != "" {
			outbound["pre_shared_key"] = node.WireGuardPreSharedKey
		}
		if b := wireGuardReservedBytes(node); len(b) > 0 {
			outbound["reserved"] = b
		}
		if node.WireGuardMTU != nil {
			outbound["mtu"] = *node.WireGuardMTU
		}
	case model.KindAnyTLS:
		outbound["type"] = "anytls"
		outbound["password"] = node.Password
		if node.IdleSessionCheckInterval != nil {
			outbound["idle_session_check_interval"] = strconv.Itoa(*node.IdleSessionCheckInterval) + "s"
		}
		if node.IdleSessionTimeout != nil {
			outbound["idle_session_timeout"] = strconv.Itoa(*node.IdleSessionTimeout) + "s"
		}
		if node.MinIdleSession != nil {
			outbound["min_idle_session"] = *node.MinIdleSession
		}
	case model.KindSnell:
		outbound["type"] = "snell"
		outbound["psk"] = node.Password
		outbound["version"] = 4
		if strings.EqualFold(node.Obfs, "http") {
			outbound["obfs_mode"] = "http"
			if node.ObfsParam != "" {
				outbound["obfs_host"] = node.ObfsParam
			}
		}
	case model.KindSOCKS5:
		outbound["type"] = "socks"
		outbound["version"] = "5"
		if node.Username != "" {
			outbound["username"] = node.Username
		}
		if node.Password != "" {
			outbound["password"] = node.Password
		}
	case model.KindHTTP:
		outbound["type"] = "http"
		if node.Username != "" {
			outbound["username"] = node.Username
		}
		if node.Password != "" {
			outbound["password"] = node.Password
		}
	default:
		return nil
	}

	if tls := singBoxTLS(node); tls != nil {
		outbound["tls"] = tls
	}
	if transport := singBoxTransport(node); transport != nil {
		outbound["transport"] = transport
	}
	return outbound
}

// singBoxTLS builds the TLS block for outbounds that carry one.
func singBoxTLS(node model.ProxyNode) map[string]any {
	switch node.Kind {
	case model.KindShadowsocks, model.KindSnell, model.KindWireGuard:
		return nil
	}
	alwaysSecure := node.Kind == model.KindTrojan || node.Kind == model.KindHysteria ||
		node.Kind == model.KindHysteria2 || node.Kind == model.KindTUIC || node.Kind == model.KindAnyTLS
	if !node.TLS && !alwaysSecure {
		return nil
	}

	tls := map[string]any{
		"enabled":     true,
		"server_name": firstNonEmpty(node.SNI, node.HostHeader, node.Server),
		"insecure":    node.SkipCertificateVerification,
	}
	if alpn := csv(node.ALPN); len(alpn) > 0 {
		tls["alpn"] = alpn
	}
	if node.UsesReality() {
		reality := map[string]any{"enabled": true, "public_key": node.RealityPublicKey}
		if node.RealityShortID != "" {
			reality["short_id"] = node.RealityShortID
		}
		tls["reality"] = reality
		tls["utls"] = map[string]any{"enabled": true, "fingerprint": firstNonEmpty(node.Fingerprint, "chrome")}
	}
	return tls
}

// singBoxTransport builds the V2Ray transport block for vmess/vless/trojan.
func singBoxTransport(node model.ProxyNode) map[string]any {
	switch node.Kind {
	case model.KindVMess, model.KindVLESS, model.KindTrojan:
	default:
		return nil
	}
	transport := node.Transport
	if transport == "" || transport == "tcp" {
		return nil
	}
	switch transport {
	case "ws":
		ws := map[string]any{"type": "ws"}
		if p := node.ExportablePath(); p != "" {
			ws["path"] = p
		}
		if h := exportableTransportHost(node); h != "" {
			ws["headers"] = map[string]any{"Host": h}
		}
		return ws
	case "grpc":
		grpc := map[string]any{"type": "grpc"}
		if node.Path != "" {
			grpc["service_name"] = strings.TrimPrefix(node.Path, "/")
		}
		return grpc
	case "h2", "http":
		http := map[string]any{"type": "http"}
		if p := node.ExportablePath(); p != "" {
			http["path"] = p
		}
		if node.HostHeader != "" {
			http["host"] = []string{node.HostHeader}
		}
		return http
	case "httpupgrade":
		up := map[string]any{"type": "httpupgrade"}
		if p := node.ExportablePath(); p != "" {
			up["path"] = p
		}
		if node.HostHeader != "" {
			up["host"] = node.HostHeader
		}
		return up
	}
	return nil
}

// singBoxVMessSecurity picks a concrete cipher; sing-box rejects "auto".
func singBoxVMessSecurity(node model.ProxyNode) string {
	accepted := map[string]bool{
		"auto": true, "none": true, "zero": true, "aes-128-gcm": true,
		"chacha20-poly1305": true, "aes-128-ctr": true,
	}
	cipher := strings.ToLower(node.Cipher)
	if accepted[cipher] && cipher != "auto" {
		return cipher
	}
	return "auto"
}
