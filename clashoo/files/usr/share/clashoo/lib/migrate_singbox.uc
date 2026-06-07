#!/usr/bin/ucode

'use strict';

import { readfile, writefile } from 'fs';

// Standalone sing-box config version-migration, used by the init.d core-only
// path to upgrade an imported config (momo/homeproxy/etc.) to the format the
// current sing-box core accepts, WITHOUT clashoo normalize/takeover.
//
// IMPORTANT: migrate_singbox() below is kept byte-for-byte in sync with the
// copy in luci-app-clashoo/.../luci.clashoo (the UI "migrate" button). If you
// change one, change the other.

function migrate_singbox(cfg) {
  // --- Fix DNS servers: address-based → type-based, remove detour ---
  if (cfg.dns && cfg.dns.servers) {
    cfg.dns.servers = map(cfg.dns.servers || [], function(srv) {
      let addr = srv.address || '';
      let new_srv = {};
      let skip = { address: 1, detour: 1, address_resolver: 1, address_strategy: 1 };
      for (let k in srv) if (!skip[k]) new_srv[k] = srv[k];

      if (addr === 'fakeip') {
        new_srv.type = 'fakeip';
      } else if (addr === 'local' || addr === '') {
        new_srv.type = new_srv.type || 'local';
      } else if (match(addr, /^rcode:\/\//) || addr === 'rcode') {
        new_srv._rcode = true;  // mark for removal, handled via dns rule action
      } else if (match(addr, /^h3:\/\//)) {
        let host = replace(replace(addr, /^h3:\/\//, ''), /\/.*$/, '');
        new_srv.type = 'h3'; new_srv.server = host;
      } else if (match(addr, /^https:\/\//)) {
        let host = replace(replace(addr, /^https:\/\//, ''), /\/.*$/, '');
        new_srv.type = 'https'; new_srv.server = host;
      } else if (match(addr, /^tls:\/\//)) {
        new_srv.type = 'tls'; new_srv.server = replace(addr, /^tls:\/\//, '');
      } else if (match(addr, /^tcp:\/\//)) {
        new_srv.type = 'tcp'; new_srv.server = replace(addr, /^tcp:\/\//, '');
      } else if (addr && !new_srv.type) {
        new_srv.type = 'udp'; new_srv.server = addr;  // plain IP → UDP
      } else if (addr) {
        new_srv.address = addr;  // unknown format, keep as-is
      }
      return new_srv;
    });
  }

  // --- Remove rcode servers (unsupported in 1.12+ new format), convert referencing rules to reject ---
  let rcode_tags = {};
  if (cfg.dns && cfg.dns.servers) {
    let good = [];
    for (let srv in cfg.dns.servers) {
      if (srv._rcode) rcode_tags[srv.tag] = true;
      else push(good, srv);
    }
    cfg.dns.servers = good;
  }
  if (cfg.dns && cfg.dns.rules && length(keys(rcode_tags)) > 0) {
    cfg.dns.rules = map(cfg.dns.rules || [], function(rule) {
      if (rule.server && rcode_tags[rule.server]) {
        let r = {};
        for (let k in rule) if (k !== 'server' && k !== 'action') r[k] = rule[k];
        r.action = 'reject';
        return r;
      }
      return rule;
    });
  }

  // --- Remove legacy dns.fakeip.enabled (1.12+ fakeip is configured via type:"fakeip" server) ---
  if (cfg.dns && cfg.dns.fakeip) {
    let fp = cfg.dns.fakeip;
    let new_fp = {};
    for (let k in fp) if (k !== 'enabled') new_fp[k] = fp[k];
    if (length(keys(new_fp)) > 0) cfg.dns.fakeip = new_fp;
    else delete cfg.dns['fakeip'];
  }

  // --- Fix DNS rules: add action:"route" when server is set ---
  if (cfg.dns && cfg.dns.rules) {
    cfg.dns.rules = map(cfg.dns.rules || [], function(rule) {
      if (rule.server && !rule.action) {
        let r = {};
        for (let k in rule) r[k] = rule[k];
        r.action = 'route';
        return r;
      }
      return rule;
    });
  }

  // --- Fix legacy special outbounds (block / dns types) ---
  let special = {};
  if (cfg.outbounds) {
    let kept = [];
    for (let ob in cfg.outbounds) {
      if (ob.type === 'block' || ob.type === 'dns') {
        special[ob.tag] = ob.type;
      } else {
        push(kept, ob);
      }
    }
    cfg.outbounds = kept;
  }

  // Patch route rules that pointed to removed special outbounds
  if (cfg.route && cfg.route.rules && length(keys(special)) > 0) {
    cfg.route.rules = map(cfg.route.rules || [], function(rule) {
      let sp = rule.outbound && special[rule.outbound];
      if (!sp) return rule;
      let r = {};
      for (let k in rule) if (k !== 'outbound') r[k] = rule[k];
      r.action = (sp === 'dns') ? 'hijack-dns' : 'reject';
      return r;
    });
  }

  // --- Migrate geoip/geosite database refs to rule_set (removed in sing-box 1.12) ---
  let needed_rule_sets = {};

  let migrate_geo_rule = function(rule) {
    let has_geo = rule.geoip || rule.geosite;
    if (!has_geo) return rule;
    let r = {};
    let new_rs = [];
    for (let k in rule) {
      if (k === 'geoip') {
        for (let n in rule[k]) {
          let tag = 'geoip-' + n;
          needed_rule_sets[tag] = 'https://cdn.jsdelivr.net/gh/SagerNet/sing-geoip@rule-set/geoip-' + n + '.srs';
          push(new_rs, tag);
        }
      } else if (k === 'geosite') {
        for (let n in rule[k]) {
          let tag = 'geosite-' + n;
          needed_rule_sets[tag] = 'https://cdn.jsdelivr.net/gh/SagerNet/sing-geosite@rule-set/geosite-' + n + '.srs';
          push(new_rs, tag);
        }
      } else {
        r[k] = rule[k];
      }
    }
    // Merge new rule_set tags with any existing ones
    let existing_rs = type(r.rule_set) === 'array' ? r.rule_set :
                      (r.rule_set ? [r.rule_set] : []);
    for (let t in new_rs) push(existing_rs, t);
    r.rule_set = existing_rs;
    return r;
  };

  if (cfg.route && cfg.route.rules)
    cfg.route.rules = map(cfg.route.rules, migrate_geo_rule);
  if (cfg.dns && cfg.dns.rules)
    cfg.dns.rules = map(cfg.dns.rules, migrate_geo_rule);

  // 选 download_detour：模板和 subconverter 输出的 srs URL 都已用 gh-proxy.com（大陆直连可达），
  // 所以必须走 DIRECT。绝不能选机场代理：首启动 rule_set 还没载入，机场域名解析会被未匹配
  // 的 DNS rules 反复递归 → deadline → sing-box FATAL。
  let pick_dl_detour = function() {
    if (cfg.outbounds) {
      for (let ob in cfg.outbounds) {
        if (ob && ob.type === 'direct' && ob.tag) return ob.tag;
      }
    }
    return 'DIRECT';
  };

  // Add rule_set download entries for each referenced geo tag
  if (length(keys(needed_rule_sets)) > 0) {
    if (!cfg.route) cfg.route = {};
    if (!cfg.route.rule_set) cfg.route.rule_set = [];
    let existing_tags = {};
    for (let rs in cfg.route.rule_set) existing_tags[rs.tag] = true;
    let dl_detour = pick_dl_detour();
    for (let tag in keys(needed_rule_sets)) {
      if (!existing_tags[tag]) {
        push(cfg.route.rule_set, {
          tag: tag,
          type: 'remote',
          format: 'binary',
          url: needed_rule_sets[tag],
          download_detour: dl_detour
        });
      }
    }
  }

  // --- Remove deprecated 'outbound' DNS rule items (fatal in sing-box 1.13) ---
  // Replacement: set route.default_domain_resolver to the plain IP-based resolver
  let dns_resolver_tag = '';
  if (cfg.dns && cfg.dns.servers) {
    for (let srv in cfg.dns.servers) {
      if ((srv.type === 'udp' || srv.type === 'local') && srv.server &&
          match(srv.server, /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/)) {
        dns_resolver_tag = srv.tag;
        break;
      }
    }
  }
  if (cfg.dns && cfg.dns.rules) {
    let filtered = [];
    for (let rule in cfg.dns.rules) {
      if (!rule.outbound) push(filtered, rule);
    }
    cfg.dns.rules = filtered;
  }
  // Set route.default_domain_resolver (replaces outbound:any DNS routing)
  if (dns_resolver_tag) {
    if (!cfg.route) cfg.route = {};
    if (!cfg.route.default_domain_resolver)
      cfg.route.default_domain_resolver = dns_resolver_tag;
  }

  // --- Fix DNS servers with domain-name server field: add domain_resolver ---
  // sing-box 1.12+ requires domain_resolver when server= is a hostname (not IP)
  if (cfg.dns && cfg.dns.servers && dns_resolver_tag) {
    let domain_types = { https: 1, h3: 1, tls: 1, tcp: 1 };
    cfg.dns.servers = map(cfg.dns.servers, function(srv) {
      if (!domain_types[srv.type]) return srv;
      if (!srv.server || match(srv.server, /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/)) return srv;
      if (srv.domain_resolver) return srv;
      let r = {};
      for (let k in srv) r[k] = srv[k];
      r.domain_resolver = dns_resolver_tag;
      return r;
    });
  }

  // --- Fix DNS rules referencing non-existent server tags → action: reject ---
  if (cfg.dns && cfg.dns.servers && cfg.dns.rules) {
    let valid_servers = {};
    for (let srv in cfg.dns.servers) valid_servers[srv.tag] = true;
    cfg.dns.rules = map(cfg.dns.rules, function(rule) {
      if (!rule.server || valid_servers[rule.server]) return rule;
      let r = {};
      for (let k in rule) if (k !== 'server' && k !== 'action') r[k] = rule[k];
      r.action = 'reject';
      return r;
    });
  }

  // --- 修 reject method: sing-box 1.14 拒收 "dropped"，只接受 "default"/"drop" ---
  if (cfg.dns && cfg.dns.rules) {
    cfg.dns.rules = map(cfg.dns.rules, function(rule) {
      if (rule.action !== 'reject' || !rule.method) return rule;
      let m = rule.method;
      if (m === 'dropped') m = 'drop';
      if (m !== 'default' && m !== 'drop') {
        // 未知值直接去掉，让 sing-box 用默认 (default → NXDOMAIN)
        let r = {};
        for (let k in rule) if (k !== 'method') r[k] = rule[k];
        return r;
      }
      if (m === rule.method) return rule;
      let r = {};
      for (let k in rule) r[k] = rule[k];
      r.method = m;
      return r;
    });
  }

  // --- Migrate TUN inbound inet4_address/inet6_address → address array (1.12+),
  // and strip legacy inbound fields removed in 1.13 (sniff / sniff_override_destination /
  // sniff_timeout / domain_strategy). 若任意 inbound 原本启用过 sniff，则在 route.rules
  // 顶部补一条 { "action": "sniff" } 规则，等价表达。 ---
  let had_sniff = false;
  if (cfg.inbounds) {
    cfg.inbounds = map(cfg.inbounds, function(ib) {
      let r = {};
      let addrs = [];
      for (let k in ib) {
        if (k === 'inet4_address') {
          if (type(ib[k]) === 'array') { for (let a in ib[k]) push(addrs, a); }
          else push(addrs, ib[k]);
        } else if (k === 'inet6_address') {
          if (type(ib[k]) === 'array') { for (let a in ib[k]) push(addrs, a); }
          else push(addrs, ib[k]);
        } else if (k === 'sniff') {
          if (ib[k]) had_sniff = true;
        } else if (k === 'sniff_override_destination' || k === 'sniff_timeout' ||
                   k === 'domain_strategy') {
          // drop — moved to route.rules actions in 1.13
        } else {
          r[k] = ib[k];
        }
      }
      if (length(addrs) > 0) r.address = addrs;
      return r;
    });
  }
  if (had_sniff) {
    if (!cfg.route) cfg.route = {};
    if (!cfg.route.rules) cfg.route.rules = [];
    let has_sniff_rule = false;
    for (let rl in cfg.route.rules)
      if (rl.action === 'sniff') { has_sniff_rule = true; break; }
    if (!has_sniff_rule) {
      let new_rules = [ { action: 'sniff' } ];
      for (let rl in cfg.route.rules) push(new_rules, rl);
      cfg.route.rules = new_rules;
    }
  }

  // --- sing-box 1.14 强制要求 route.default_domain_resolver；缺失时补一个，
  //     首选 dns.final，否则 dns.servers 的第一个有 tag 的 server。 ---
  if (cfg.route && !cfg.route.default_domain_resolver) {
    let resolver_tag = '';
    if (cfg.dns && cfg.dns.final) resolver_tag = cfg.dns.final;
    else if (cfg.dns && cfg.dns.servers) {
      for (let srv in cfg.dns.servers)
        if (srv.tag) { resolver_tag = srv.tag; break; }
    }
    if (resolver_tag)
      cfg.route.default_domain_resolver = { server: resolver_tag };
  }

  // --- Remove dangling outbound references from selectors/urltest，并剔除"机场伪节点" ---
  // 1. subconverter 可能引用不存在的 tag（如 REJECT）
  // 2. 机场塞的 "Traffic: xxx GB | yyy GB" / "Expire: 2026-08-15" / "剩余流量"
  //    等伪节点是真 SS/Vmess outbound（参与 sing-box 解析、让 UI 能抽流量到期），
  //    但服务端不真转发；放进 selector 后 selector 默认选第一个 / urltest 选最快
  //    （同源 0ms），所有国外流量会被吸到伪节点 → 表现为"国内通、国外 out"。
  let is_pseudo_tag = function(t) {
    if (!t) return false;
    return match(t, /^Traffic[：:]/) ||
           match(t, /^Expire[：:]/) ||
           match(t, /剩余流量|剩余[：:]/) ||
           match(t, /距离下次重置/) ||
           match(t, /到期(时间|日期)?[：:]/) ||
           match(t, /官网[：:]|网站[：:]|套餐[：:]?|客服[：:]/) ||
           match(t, /QQ[群]?[：:]/) ||
           match(t, /Telegram|TG群|官方群/) ||
           match(t, /续费|订阅地址|流量重置/);
  };
  if (cfg.outbounds) {
    let defined_tags = {};
    for (let ob in cfg.outbounds) defined_tags[ob.tag] = true;
    cfg.outbounds = map(cfg.outbounds, function(ob) {
      if ((ob.type !== 'selector' && ob.type !== 'urltest' && ob.type !== 'loadbalance') ||
          !ob.outbounds) return ob;
      let valid = [];
      for (let t in ob.outbounds) {
        if (!defined_tags[t]) continue;
        if (is_pseudo_tag(t)) continue;
        push(valid, t);
      }
      if (length(valid) === length(ob.outbounds)) return ob;
      let r = {};
      for (let k in ob) r[k] = ob[k];
      r.outbounds = valid;
      return r;
    });
  }

  // --- 强制覆盖所有 remote rule_set 的 download_detour ---
  // subconverter 常输出 download_detour="♻️ 自动选择"，但首启动时机场代理还不可用
  // → urltest 测速死锁 → "fetch rule-set: deadline exceeded" → sing-box FATAL。
  // 模板/转换器写入的 srs URL 都用 gh-proxy.com（大陆直连可达），必须无条件覆盖成 DIRECT。
  if (cfg.route && cfg.route.rule_set) {
    let dl_detour = pick_dl_detour();
    cfg.route.rule_set = map(cfg.route.rule_set, function(rs) {
      if (!rs || rs.type !== 'remote') return rs;
      let r = {};
      for (let k in rs) r[k] = rs[k];
      r.download_detour = dl_detour;
      return r;
    });
  }

  return cfg;
}


// ---- CLI entry: ucode migrate_singbox.uc <config.json> ----
let _path = ARGV[0] || '';
if (!_path) { print("missing path\n"); exit(1); }
let _raw = readfile(_path);
if (!_raw) { print("read failed\n"); exit(1); }
let _cfg = json(_raw);
if (!_cfg) { print("json parse failed\n"); exit(1); }
let _before = sprintf('%J', _cfg);
_cfg = migrate_singbox(_cfg);
let _after = sprintf('%J', _cfg);
if (_before === _after) { print("nochange\n"); exit(0); }
if (writefile(_path, _after) === null) { print("write failed\n"); exit(1); }
print("migrated\n");
