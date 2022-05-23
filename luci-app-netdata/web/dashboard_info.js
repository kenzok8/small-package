// SPDX-License-Identifier: GPL-3.0-or-later
// 翻译 By Jason
// Codacy declarations
/* global NETDATA */

var netdataDashboard = window.netdataDashboard || {};

// Informational content for the various sections of the GUI (menus, sections, charts, etc.)

// ----------------------------------------------------------------------------
// Menus

netdataDashboard.menu = {
    'system': {
        title: '系统概览',
        icon: '<i class="fas fa-bookmark"></i>',
        info: '一眼掌握系统效能关键指标。'
    },

    'services': {
        title: '系统服务',
        icon: '<i class="fas fa-cogs"></i>',
        info: '系统服务的使用情况。 '+
        'netdata 以 CGROUPS 监视所有系统服务。 '+
        '<a href="https://en.wikipedia.org/wiki/Cgroups" target="_blank">cgroups</a> ' +
        '(the resources accounting used by containers).'
    },

    'ap': {
        title: 'AP接入点',
        icon: '<i class="fas fa-wifi"></i>',
        info: '系统上找到的接入点（即AP模式下的无线接口）的指标。'
    },

    'tc': {
        title: 'Quality服务',
        icon: '<i class="fas fa-globe"></i>',
        info: 'Netdata使用其收集和可视化<code>tc</code>类利用率 ' +
            '<a href="https://github.com/netdata/netdata/blob/master/collectors/tc.plugin/tc-qos-helper.sh.in" target="_blank">Tc-helper插件</a>. ' +
            '如果您也使用<a href="http://firehol.org/#fireqos" target="_blank">FireQOS</a>来设置QoS， ' +
            'Netdata会自动收集接口和类名。如果您的QoS配置包含间接费用 ' +
            '计算，这里显示的值将包括这些开销（相同的总带宽 ' +
            '“网络接口”部分中报告的接口将低于总带宽 ' +
            '这里报告了）。与界面相比，QoS数据收集可能略有时差 ' +
            '（QoS数据收集使用BASH脚本，因此数据收集的转移几毫秒 ' +
            '应该有正当理由）。'
    },

    'net': {
        title: '网络接口',
        icon: '<i class="fas fa-sitemap"></i>',
        info: '<p>运转 <a href="https://www.kernel.org/doc/html/latest/networking/statistics.html" target="_blank">网路介面的效能指标。</a>.</p>'+
        '<p>Netdata检索读取<code>/proc/net/dev</code>文件和<code>/sys/class/net/</code>目录的数据。</p>'
    },

    'Infiniband': {
        title: 'Infiniband端口',
        icon: '<i class="fas fa-sitemap"></i>',
        info: '<p>绩效和例外统计 '+
        '<a href="https://en.wikipedia.org/wiki/InfiniBand" target="_blank">Infiniband</a> 端口。 '+
        '单个端口和硬件计数器描述可以在 '+
        '<a href="https://community.mellanox.com/s/article/understanding-mlx5-linux-counters-and-status-parameters" target="_blank">Mellanox知识库</a>.'
    },

    'wireless': {
        title: '无线接口',
        icon: '<i class="fas fa-wifi"></i>',
        info: '无线接口的性能指标。'
    },

    'ip': {
        title: '网络堆栈',
        icon: '<i class="fas fa-cloud"></i>',
        info: function (os) {
            if (os === "linux")
                return '系统网络堆栈的指标。这些指标从<code>/proc/net/netstat</code>收集，或将<code>kprobes</code>附加到内核函数，适用于IPv4和IPv6流量，并与内核网络堆栈的操作有关。';
            else
                return '系统网络堆栈的指标。';
        }
    },

    'ipv4': {
        title: 'IPv4网路',
        icon: '<i class="fas fa-cloud"></i>',
        info: 'IPv4效能指标。' +
            '<a href="https://en.wikipedia.org/wiki/IPv4" target="_blank">Internet Protocol version 4 (IPv4)</a> 是 ' +
            '互联网协议（IP）的第四版。它是基于标准的核心协议之一 ' +
            '互联网上的互联网工作方法。IPv4是一种用于数据包交换的无连接协议' +
            '网络。它以最佳努力交付模式运作，因为它不保证交付，也不保证交付 ' +
            '它确保正确的顺序或避免重复交付。这些方面，包括数据完整性，' +
            '由上层传输协议（如传输控制协议（TCP））解决。'
    },

    'ipv6': {
        title: 'IPv6网路',
        icon: '<i class="fas fa-cloud"></i>',
        info: 'IPv6效能指标。 <a href="https://en.wikipedia.org/wiki/IPv6" target="_blank">Internet Protocol version 6 (IPv6)</a> 是互联网协议（IP）的最新版本，该通信协议为网络上的计算机和跨互联网的路由流量提供识别和定位系统。IPv6是由互联网工程特别工作组（IETF）开发的，旨在处理长期预计的IPv4地址用尽问题。IPv6旨在取代IPv4。'
    },

    'sctp': {
        title: 'SCTP 网路',
        icon: '<i class="fas fa-cloud"></i>',
        info: '<p><a href="https://en.wikipedia.org/wiki/Stream_Control_Transmission_Protocol" target="_blank">流控传输协议（SCTP）</a> '+
        '是一种计算机网络协议，在传输层运行，其作用类似于流行的 '+
        '协议TCP和UDP。SCTP提供了UDP和TCP的一些功能：它像UDP一样面向消息 '+
        '并确保具有TCP等拥塞控制的消息的可靠、无序传输。 '+
        '它与这些协议不同，它提供了多寻址和冗余路径，以提高弹性和可靠性。</p>'+
        '<p>Netdata收集读取<code>/proc/net/sctp/snmp</code>文件的SCTP指标。</p>'
    },

    'ipvs': {
        title: 'IP 虚拟服务器',
        icon: '<i class="fas fa-eye"></i>',
        info: '<p><a href="http://www.linuxvirtualserver.org/software/ipvs.html" target="_blank">IPVS (IP Virtual Server)</a> '+
        '在Linux内核内实现传输层负载平衡，即所谓的第4层切换。 '+
        '在主机上运行的IPVS在一组真实服务器的前部充当负载平衡器， '+
        '它可以将基于TCP/UDP的服务请求定向到真正的服务器， '+
        '并使真实服务器的服务在单个IP地址上显示为虚拟服务。</p>'+
        '<p>Netdata收集摘要统计数据，阅读<code>/proc/net/ip_vs_stats</code>。 '+
        '要显示服务及其服务器的统计信息，请运行<code>ipvsadm -Ln --stats</code> '+
        '或<code>ipvsadm -Ln --rate</code>用于费率统计。'+
        '有关详细信息，请参阅 <a href="https://linux.die.net/man/8/ipvsadm" target="_blank">ipvsadm(8)</a>.</p>'
    },

    'netfilter': {
        title: '防火墙(netfilter)',
        icon: '<i class="fas fa-shield-alt"></i>',
        info: 'netfilter组件的性能指标。'
    },

    'ipfw': {
        title: '防火墙(ipfw)',
        icon: '<i class="fas fa-shield-alt"></i>',
        info: 'ipfw规则的计数器和内存使用情况。'
    },

    'cpu': {
        title: 'CPUs',
        icon: '<i class="fas fa-bolt"></i>',
        info: '系统中每一个 CPU 的详细资讯。全部 CPU 的总量可以到 <a href="#menu_system">系统概览</a> 区段查看。'
    },

    'mem': {
        title: '记忆体',
        icon: '<i class="fas fa-microchip"></i>',
        info: '系统记忆体管理的详细资讯。'
    },

    'disk': {
        title: '磁碟',
        icon: '<i class="fas fa-hdd"></i>',
        info: '系统中所有磁碟效能资讯图表。特别留意：这是以 <code>iostat -x</code>所取得的效能数据做为呈现。在预设情况下，netdata 不会显示单一分割区与未挂载的虚拟磁碟效能图表。若仍想要显示，可以修改 netdata 设定档中的相关设定。'
    },

    'mount': {
        title: 'Mount Points',
        icon: '<i class="fas fa-hdd"></i>',
        info: ''
    },

    'mdstat': {
        title: 'MD arrays',
        icon: '<i class="fas fa-hdd"></i>',
        info: '<p>RAID 设备是由两个或更多真实块设备创建的虚拟设备。 '+
        '<a href="https://man7.org/linux/man-pages/man4/md.4.html" target="_blank">Linux软件RAID</a>设备是 '+
        '通过md（多设备）设备驱动程序实现。</p>'+
        '<p>Netdata监控MD数组的当前状态，读取<a href="https://raid.wiki.kernel.org/index.php/Mdstat" target="_blank">/proc/mdstat</a>和 '+
        '<code>/sys/block/%s/md/mismatch_cnt</code> 档案</p>'
    },

    'sensors': {
        title: '感测器',
        icon: '<i class="fas fa-leaf"></i>',
        info: '系统已配置相关感测器的读数。'
    },

    'ipmi': {
        title: 'IPMI',
        icon: '<i class="fas fa-leaf"></i>',
        info: '智能平台管理接口（IPMI）是一套自主计算机子系统的计算机接口规范，独立于主机系统的CPU、固件（BIOS或UEFI）和操作系统提供管理和监控功能。'
    },

    'samba': {
        title: 'Samba',
        icon: '<i class="fas fa-folder-open"></i>',
        info: '此系统的Samba文件共享操作的绩效指标。Samba是Windows服务的实现，包括Windows SMB协议文件共享。'
    },

    'nfsd': {
        title: 'NFS服器器',
        icon: '<i class="fas fa-folder-open"></i>',
        info: '网络文件服务器的绩效指标。 '+
        '<a href="https://en.wikipedia.org/wiki/Network_File_System" target="_blank">NFS</a> '+
        '是一种分布式文件系统协议，允许客户端计算机上的用户通过网络访问文件， '+
        '就像访问本地存储一样。 '+
        '与许多其他协议一样，NFS基于开放网络计算远程过程调用（ONC RPC）系统。'
    },

    'nfs': {
        title: 'NFS客户端',
        icon: '<i class="fas fa-folder-open"></i>',
        info: '绩效指标 '+
        '<a href="https://en.wikipedia.org/wiki/Network_File_System" target="_blank">NFS</a> '+
        '该系统作为NFS客户端的操作。'
    },

    'zfs': {
        title: 'ZFS文件系统',
        icon: '<i class="fas fa-folder-open"></i>',
        info: '绩效指标 '+
        '<a href="https://en.wikipedia.org/wiki/ZFS#Caching_mechanisms" target="_blank">ZFS ARC and L2ARC</a>. '+
        'ZFS档案系统的效能指标。以下图表呈现来自 '+
        '<a href="https://github.com/openzfs/zfs/blob/master/cmd/arcstat/arcstat.in" target="_blank">arcstat.py</a> 与 '+
        '<a href="https://github.com/openzfs/zfs/blob/master/cmd/arc_summary/arc_summary3" target="_blank">arc_summary.py</a>的效能数据。'
    },

    'zfspool': {
        title: 'ZFS pools',
        icon: '<i class="fas fa-database"></i>',
        info: 'ZFS的状态。'
    },

    'btrfs': {
        title: 'BTRFS文件系统',
        icon: '<i class="fas fa-folder-open"></i>',
        info: 'BTRFS 档案系统磁碟空间使用指标。'
    },

    'apps': {
        title: '应用程序',
        icon: '<i class="fas fa-heartbeat"></i>',
        info: '每个应用程序的统计数据使用 '+
        '<a href="https://learn.netdata.cloud/docs/agent/collectors/apps.plugin" target="_blank">apps.plugin</a>. '+
        '这个插件会浏览所有流程，并汇总 '+
        '<a href="https://learn.netdata.cloud/docs/agent/collectors/apps.plugin#configuration" target="_blank">application groups</a>. '+
        '该插件还计算退出子项的资源。 '+
        '因此，对于shell脚本等进程，报告的值包括命令使用的资源 '+
        '这些脚本在每个时间范围内运行。',
        height: 1.5
    },

    'groups': {
        title: '用户组',
        icon: '<i class="fas fa-user"></i>',
        info: '每个用户组的统计数据使用 '+
        '<a href="https://learn.netdata.cloud/docs/agent/collectors/apps.plugin" target="_blank">apps.plugin</a>. '+
        '此插件浏览所有流程，并汇总每个用户组的统计数据。 '+
        '该插件还计算退出子项的资源。 '+
        '因此，对于shell脚本等进程，报告的值包括命令使用的资源 '+
        '这些脚本在每个时间范围内运行。',
        height: 1.5
    },

    'users': {
        title: '用户',
        icon: '<i class="fas fa-users"></i>',
        info: '每个用户的统计数据是使用 '+
        '<a href="https://learn.netdata.cloud/docs/agent/collectors/apps.plugin" target="_blank">apps.plugin</a>. '+
        '此插件浏览所有流程，并汇总每个用户的统计数据。 '+
        '该插件还计算退出子项的资源。 '+
        '因此，对于shell脚本等进程，报告的值包括命令使用的资源 '+
        '这些脚本在每个时间范围内运行。',
        height: 1.5
    },

    'netdata': {
        title: 'Netdata监视',
        icon: '<i class="fas fa-chart-bar"></i>',
        info: 'netdata本身与外挂程式的效能数据。'
    },

    'aclk_test': {
        title: 'ACLK试验发报',
        info: '用于内部执行集成测试。'
    },

    'example': {
        title: '范例图表',
        info: '范例图表，展示外挂程式的架构之用。'
    },

    'cgroup': {
        title: '',
        icon: '<i class="fas fa-th"></i>',
        info: '容器资源使用率指标。netdata 从 <b>cgroups</b> (abbreviated from <b>control groups</b> 的缩写)中读取这些资讯，cgroups 是 Linux 核心的一个功能，做限制与计算程序集中的资源使用率 (CPU、记忆体、磁碟 I/O、网路...等等)。<b>cgroups</b> 与 <b>namespaces</b> (程序之间的隔离) 结合提供了我们所说的：<b>容器</b>。'
    },

    'cgqemu': {
        title: '',
        icon: '<i class="fas fa-th-large"></i>',
        info: 'QEMU 虚拟机资源使用率效能指标。QEMU (Quick Emulator) 是自由与开源的虚拟机器平台，提供硬体虚拟化功能。'
    },

    'fping': {
        title: 'fping',
        icon: '<i class="fas fa-exchange-alt"></i>',
        info: '网络延迟统计，通过<b>fping</b>。<b>fping</b>是一个向网络主机发送ICMP回声探针的程序，类似于<code>ping</code>，但在ping多个主机时性能要好得多。3.15之后的fping版本可以直接用作netdata插件。'
    },

    'gearman': {
        title: 'Gearman',
        icon: '<i class="fas fa-tasks"></i>',
        info: 'Gearman是一个工作服务器，允许您并行工作，加载平衡处理，并在语言之间调用函数。'
    },

    'ioping': {
        title: 'ioping',
        icon: '<i class="fas fa-exchange-alt"></i>',
        info: '磁盘延迟统计，通过<b>ioping</b>。<b>ioping</b>是一个从/到磁盘读取/写入数据探针的程序。'
    },

    'httpcheck': {
        title: 'Http Check',
        icon: '<i class="fas fa-heartbeat"></i>',
        info: '使用HTTP检查进行Web服务可用性和延迟监控。此插件是端口检查插件的专用版本。'
    },

    'memcached': {
        title: 'memcached',
        icon: '<i class="fas fa-database"></i>',
        info: '<b>memcached</b>的绩效指标。Memcached是一个通用的分布式内存缓存系统。它通常用于通过在RAM中缓存数据和对象来加快动态数据库驱动的网站，以减少外部数据源（如数据库或API）必须读取的次数。'
    },

    'monit': {
        title: 'monit',
        icon: '<i class="fas fa-database"></i>',
        info: '<b>monit</b>中的检查状态。Monit是一个用于管理和监控Unix系统上的流程、程序、文件、目录和文件系统的实用工具。Monit进行自动维护和维修，并在错误情况下执行有意义的因果行为。'
    },

    'mysql': {
        title: 'MySQL',
        icon: '<i class="fas fa-database"></i>',
        info: '开源关系数据库管理系统（RDBMS）<b>mysql</b>的绩效指标。'
    },

    'postgres': {
        title: 'Postgres',
        icon: '<i class="fas fa-database"></i>',
        info: '对象关系数据库（ORDBMS）<b>PostgresSQL</b>的性能指标。'
    },

    'redis': {
        title: 'Redis',
        icon: '<i class="fas fa-database"></i>',
        info: '<b>redis</b>的绩效指标。Redis（远程字典服务器）是一个实现数据结构服务器的软件项目。它是开源的、联网的、内存的，并存储具有可选耐用性的密钥。'
    },

    'rethinkdbs': {
        title: 'RethinkDB',
        icon: '<i class="fas fa-database"></i>',
        info: '<b>rethinkdb</b>的绩效指标。RethinkDB是第一个为实时应用程序构建的开源可扩展数据库'
    },

    'retroshare': {
        title: 'RetroShare',
        icon: '<i class="fas fa-share-alt"></i>',
        info: '<b>RetroShare</b>的绩效指标。RetroShare是基于基于GNU隐私保护（GPG）的朋友对朋友网络的加密文件共享、无服务器电子邮件、即时消息、在线聊天和BBS的开源软件。'
    },

    'riakkv': {
        title: 'Riak KV',
        icon: '<i class="fas fa-database"></i>',
        info: '<b>Riak KV</b>的指标，分布式键值存储。'
    },

    'ipfs': {
        title: 'IPFS',
        icon: '<i class="fas fa-folder-open"></i>',
        info: 'InterPlanetary File System（IPFS）的绩效指标，IPFS是一种内容可寻址的点对点超媒体分发协议。'
    },

    'phpfpm': {
        title: 'PHP-FPM',
        icon: '<i class="fas fa-eye"></i>',
        info: '<b>PHP-FPM</b>的绩效指标，PHP的替代FastCGI实现。'
    },

    'pihole': {
        title: 'Pi-hole',
        icon: '<i class="fas fa-ban"></i>',
        info: '<a href="https://pi-hole.net/" target="_blank">Pi-hole</a>的指标，一个互联网广告的黑洞。' +
            ' Pi-Hole API返回的指标都来自过去24小时。'
    },

    'portcheck': {
        title: '端口检查',
        icon: '<i class="fas fa-heartbeat"></i>',
        info: '使用端口检查来监控服务可用性和延迟。'
    },

    'postfix': {
        title: 'postfix',
        icon: '<i class="fas fa-envelope"></i>',
        info: undefined
    },

    'dovecot': {
        title: 'Dovecot',
        icon: '<i class="fas fa-envelope"></i>',
        info: undefined
    },

    'hddtemp': {
        title: 'HDD Temp',
        icon: '<i class="fas fa-thermometer-half"></i>',
        info: undefined
    },

    'nginx': {
        title: 'nginx',
        icon: '<i class="fas fa-eye"></i>',
        info: undefined
    },

    'apache': {
        title: 'Apache',
        icon: '<i class="fas fa-eye"></i>',
        info: undefined
    },

    'lighttpd': {
        title: 'Lighttpd',
        icon: '<i class="fas fa-eye"></i>',
        info: undefined
    },

    'web_log': {
        title: undefined,
        icon: '<i class="fas fa-file-alt"></i>',
        info: '从服务器日志文件中提取的信息。<code>web_log</code>插件逐步解析服务器日志文件，以实时提供关键服务器性能指标的细分。对于Web服务器，可以选择使用扩展日志文件格式（对于<code>nginx</code>和<code>apache</code>），为请求和响应提供计时信息和带宽。<code>web_log</code>插件也可以配置为按URL模式提供请求的细分（检查<a href="https://github.com/netdata/netdata/blob/master/collectors/python.d.plugin/web_log/web_log.conf" target="_blank"><code>/etc/netdata/python.d/web_log.conf</code></a>）。'
    },

    'named': {
        title: 'named',
        icon: '<i class="fas fa-tag"></i>',
        info: undefined
    },

    'squid': {
        title: 'squid',
        icon: '<i class="fas fa-exchange-alt"></i>',
        info: undefined
    },

    'nut': {
        title: 'UPS',
        icon: '<i class="fas fa-battery-half"></i>',
        info: undefined
    },

    'apcupsd': {
        title: 'UPS',
        icon: '<i class="fas fa-battery-half"></i>',
        info: undefined
    },

    'smawebbox': {
        title: 'Solar Power',
        icon: '<i class="fas fa-sun"></i>',
        info: undefined
    },

    'fronius': {
        title: 'Fronius',
        icon: '<i class="fas fa-sun"></i>',
        info: undefined
    },

    'stiebeleltron': {
        title: 'Stiebel Eltron',
        icon: '<i class="fas fa-thermometer-half"></i>',
        info: undefined
    },

    'snmp': {
        title: 'SNMP',
        icon: '<i class="fas fa-random"></i>',
        info: undefined
    },

    'go_expvar': {
        title: 'Go - expvars',
        icon: '<i class="fas fa-eye"></i>',
        info: '<a href="https://golang.org/pkg/expvar/" target="_blank">expvar软件包</a> 公开的运行Go应用程序的统计数据。'
    },

    'chrony': {
        icon: '<i class="fas fa-clock"></i>',
        info: '关于系统时钟性能的计时参数。'
    },

    'couchdb': {
        icon: '<i class="fas fa-database"></i>',
        info: '<b><a href="https://couchdb.apache.org/" target="_blank">CouchDB</a></b>的性能指标，该数据库是基于JSON文档的开源数据库，具有HTTP API和多主复制。'
    },

    'beanstalk': {
        title: 'Beanstalkd',
        icon: '<i class="fas fa-tasks"></i>',
        info: '使用从beanstalkc提取的数据提供有关<b><a href="http://kr.github.io/beanstalkd/" target="_blank">beanstalkd</a></b>服务器和该服务器上可用的任何管道的统计数据'
    },

    'rabbitmq': {
        title: 'RabbitMQ',
        icon: '<i class="fas fa-comments"></i>',
        info: '<b><a href="https://www.rabbitmq.com/" target="_blank">RabbitMQ</a></b>开源消息代理的性能数据。'
    },

    'ceph': {
        title: 'Ceph',
        icon: '<i class="fas fa-database"></i>',
        info: '提供<b><a href="http://ceph.com/" target="_blank">ceph</a></b>集群服务器的统计数据，开源分布式存储系统。'
    },

    'ntpd': {
        title: 'ntpd',
        icon: '<i class="fas fa-clock"></i>',
        info: '提供网络时间协议守护程序<b><a href="http://www.ntp.org/" target="_blank">ntpd</a></b>的内部变量的统计信息，并可选包括配置的对等变量（如果在模块配置中启用）。本模块介绍了<b><a href="http://doc.ntp.org/current-stable/ntpq.html">ntpq</a></b>（标准NTP查询程序）所示的绩效指标，使用NTP模式6个UDP数据包与NTP服务器通信。'
    },

    'spigotmc': {
        title: 'Spigot MC',
        icon: '<i class="fas fa-eye"></i>',
        info: '为<b><a href="https://www.spigotmc.org/" target="_blank">Spigot Minecraft</a></b>服务器提供基本性能统计信息。'
    },

    'unbound': {
        title: 'Unbound',
        icon: '<i class="fas fa-tag"></i>',
        info: undefined
    },

    'boinc': {
        title: 'BOINC',
        icon: '<i class="fas fa-microchip"></i>',
        info: '为<b><a href="http://boinc.berkeley.edu/" target="_blank">BOINC</a></b>分布式计算客户端提供任务计数。'
    },

    'w1sensor': {
        title: '1-Wire Sensors',
        icon: '<i class="fas fa-thermometer-half"></i>',
        info: '来自<a href="https://en.wikipedia.org/wiki/1-Wire" target="_blank">1-Wire</a>传感器的数据。目前会自动检测到温度传感器。'
    },

    'logind': {
        title: 'Logind',
        icon: '<i class="fas fa-user"></i>',
        info: undefined
    },

    'powersupply': {
        title: '电源',
        icon: '<i class="fas fa-battery-half"></i>',
        info: '各种系统电源的统计数据。从<a href="https://www.kernel.org/doc/Documentation/power/power_supply_class.txt" target="_blank">Linux电源类</a>收集的数据。'
    },

    'xenstat': {
        title: 'Xen Node',
        icon: '<i class="fas fa-server"></i>',
        info: 'Xen节点的一般统计信息。使用<b>xenstat</b>库</a>收集的数据。'
    },

    'xendomain': {
        title: '',
        icon: '<i class="fas fa-th-large"></i>',
        info: 'Xen域资源利用率指标。Netdata使用<b>xenstat</b>库读取此信息，该库允许访问虚拟机的资源使用信息（CPU、内存、磁盘I/O、网络）。'
    },

    'wmi': {
        title: 'wmi',
        icon: '<i class="fas fa-server"></i>',
        info: undefined
    },

    'perf': {
        title: 'Perf Counters',
        icon: '<i class="fas fa-tachometer-alt"></i>',
        info: '性能监控计数器（PMC）。使用使用硬件性能监控单元（PMU）的<b>perf_event_open()</b>系统调用收集的数据。'
    },

    'vsphere': {
        title: 'vSphere',
        icon: '<i class="fas fa-server"></i>',
        info: 'ESXI主机和虚拟机的性能统计。使用<code><a href="https://github.com/vmware/govmomi">govmomi</a></code>库从<a href="https://www.vmware.com/vcenter-server.html" target="_blank">VMware vCenter Server</a>收集的数据。'
    },

    'vcsa': {
        title: 'VCSA',
        icon: '<i class="fas fa-server"></i>',
        info: 'vCenter Server设备运行状况统计。从<a href="https://vmware.github.io/vsphere-automation-sdk-rest/vsphere/index.html#SVC_com.vmware.appliance.health" target="_blank">健康API</a>收集的数据。'
    },

    'zookeeper': {
        title: 'Zookeeper',
        icon: '<i class="fas fa-database"></i>',
        info: '提供<b><a href="https://zookeeper.apache.org/" target="_blank">Zookeeper</a></b>服务器的健康统计数据。使用<code><a href="https://zookeeper.apache.org/doc/r3.5.5/zookeeperAdmin.html#sc_zkCommands">mntr</a></code>命令通过命令端口收集的数据。'
    },

    'hdfs': {
        title: 'HDFS',
        icon: '<i class="fas fa-folder-open"></i>',
        info: '提供<b><a href="https://hadoop.apache.org/docs/r3.2.0/hadoop-project-dist/hadoop-hdfs/HdfsDesign.html" target="_blank">Hadoop分布式文件系统</a></b>性能统计信息。模块通过<code>HDFS</code>守护进程的Web界面收集<code>Java管理扩展</code>上的指标。'
    },

    'am2320': {
        title: 'AM2320 Sensor',
        icon: '<i class="fas fa-thermometer-half"></i>',
        info: '外部AM2320传感器的读数。'
    },

    'scaleio': {
        title: 'ScaleIO',
        icon: '<i class="fas fa-database"></i>',
        info: 'ScaleIO各个组件的性能和健康统计。通过VxFlex OS Gateway REST API收集的数据。'
    },

    'squidlog': {
        title: 'Squid log',
        icon: '<i class="fas fa-file-alt"></i>',
        info: undefined
    },

    'cockroachdb': {
        title: 'CockroachDB',
        icon: '<i class="fas fa-database"></i>',
        info: '各种<code>CockroachDB</code>组件的性能和健康状况统计。'
    },

    'ebpf': {
        title: 'eBPF',
        icon: '<i class="fas fa-heartbeat"></i>',
        info: '使用<code>eBPF</code>监控系统调用、内部函数、字节读取、字节写入和错误。'
    },

    'filesystem': {
        title: 'Filesystem',
        icon: '<i class="fas fa-hdd"></i>',
    },

    'vernemq': {
        title: 'VerneMQ',
        icon: '<i class="fas fa-comments"></i>',
        info: '<b><a href="https://vernemq.com/" target="_blank">VerneMQ</a></b>开源MQTT经纪人的性能数据。'
    },

    'pulsar': {
        title: 'Pulsar',
        icon: '<i class="fas fa-comments"></i>',
        info: '<b><a href="http://pulsar.apache.org/" target="_blank">Apache Pulsar</a></b>pub-sub消息系统的摘要、命名空间和主题性能数据。'
    },

    'anomalies': {
        title: 'Anomalies',
        icon: '<i class="fas fa-flask"></i>',
        info: '与关键系统指标相关的异常分数。高异常概率表示奇怪的行为，并可能触发经过训练的模型的异常预测。有关更多详细信息，请阅读<a href="https://github.com/netdata/netdata/tree/master/collectors/python.d.plugin/anomalies" target="_blank">异常收集器文档</a>。'
    },

    'alarms': {
        title: 'Alarms',
        icon: '<i class="fas fa-bell"></i>',
        info: '显示警报随时间推移状态的图表。更多详细信息<a href="https://github.com/netdata/netdata/blob/master/collectors/python.d.plugin/alarms/README.md" target="_blank">此处</a>。'
    },

    'statsd': { 
        title: 'StatsD',
        icon: '<i class="fas fa-chart-line"></i>',
        info:'StatsD是一个行业标准技术堆栈，用于监控应用程序和检测任何软件以提供自定义指标。Netdata允许用户在不同图表中组织指标，并轻松可视化任何应用程序指标。在<a href="https://learn.netdata.cloud/docs/agent/collectors/statsd.plugin" target="_blank">Netdata Learn</a>上阅读更多信息。'
    },

    'supervisord': {
        title: 'Supervisord',
        icon: '<i class="fas fa-tasks"></i>',
        info: '<b><a href="http://supervisord.org/" target="_blank">主管</a></b>控制的每组流程的详细统计数据。' +
        'Netdata使用<a href="http://supervisord.org/api.html#supervisor.rpcinterface.SupervisorNamespaceRPCInterface.getAllProcessInfo" target="_blank"><code>getAllProcessInfo</code></a>方法收集这些指标。'
    },

    'systemdunits': {
        title: 'systemd units',
        icon: '<i class="fas fa-cogs"></i>',
        info: '<b>systemd</b>在11种不同类型的不同实体之间提供了一个依赖系统，称为“单位”。 ' +
        '单元封装了与系统启动和维护相关的各种对象。 ' +
        '单元可能是<code>活动</code>（表示启动、绑定、插入，具体取决于单元类型）， ' +
        '或<code>不活跃</code>（意味着停止、未绑定、断开连接）， ' +
        '以及在激活或停用的过程中，即在两种状态之间（这些状态称为<code>激活</code>，<code>停用</code>）。 ' +
        '特殊的<code>失败</code>状态也可用，这与<code>不活跃</code>非常相似，并在服务以某种方式失败时（进程在退出时、崩溃、操作超时或重新启动过多后返回错误代码）时输入。 ' +
        '有关详细信息，请参阅<a href="https://www.freedesktop.org/software/systemd/man/systemd.html" target="_blank"> systemd(1)</a>。'
    },
    
    'changefinder': {
        title: 'ChangeFinder',
        icon: '<i class="fas fa-flask"></i>',
        info: '使用机器学习在线更改点检测。更多详细信息<a href="https://github.com/netdata/netdata/blob/master/collectors/python.d.plugin/changefinder/README.md" target="_blank">此处</a>。'
    },

    'zscores': {
        title: 'Z-Scores',
        icon: '<i class="fas fa-exclamation"></i>',
        info: 'Z scores与关键系统指标相关的分数。'
    },

    'anomaly_detection': {
        title: 'Anomaly Detection',
        icon: '<i class="fas fa-brain"></i>',
        info: '与异常检测、<code>异常</code>尺寸增加或高于通常<code>异常率</code>相关的图表可能是一些异常行为的迹象。有关更多详细信息，请阅读我们的<a href="https://learn.netdata.cloud/guides/monitor/anomaly-detection" target="_blank">异常检测指南</a>。'
    },

    'fail2ban': {
        title: 'Fail2ban',
        icon: '<i class="fas fa-shield-alt"></i>',
        info: 'Netdata通过读取Fail2ban日志文件来跟踪当前的监狱状态。'
    },
};


// ----------------------------------------------------------------------------
// submenus

// information to be shown, just below each submenu

// information about the submenus
netdataDashboard.submenu = {
    'web_log.squid_bandwidth': {
        title: '频宽',
        info: 'squid响应的带宽（<code>发送</code>）。此图表可能会出现异常的峰值，因为带宽是在服务器保存日志行时核算的，即使服务日志行所需的时间跨度更长。我们建议使用QoS（例如<a href="http://firehol.org/#fireqos" target="_blank">FireQOS</a>）来准确核算服务器带宽。'
    },

    'web_log.squid_responses': {
        title: '回应',
        info: '与squid发送的回复相关的信息。'
    },

    'web_log.squid_requests': {
        title: '请求',
        info: 'squid收到的与请求相关的信息。'
    },

    'web_log.squid_hierarchy': {
        title: '等级制度',
        info: '用于服务请求的squid层次结构的绩效指标。'
    },

    'web_log.squid_squid_transport': {
        title: '运输'
    },

    'web_log.squid_squid_cache': {
        title: '缓存',
        info: 'squid缓存性能的性能指标。'
    },

    'web_log.squid_timings': {
        title: 'timings',
        info: 'squid请求的持续时间。可能会报告不切实际的激增，因为squid会在请求完成后记录请求的总时间。特别是对于HTTPS，客户端从代理获取隧道，并直接与上游服务器交换请求，因此squid无法评估单个请求并报告隧道打开的总时间。'
    },

    'web_log.squid_clients': {
        title: 'clients'
    },

    'web_log.bandwidth': {
        info: '请求（<code>接收</code>）和响应（<code>发送</code>）的带宽。<code>接收</code>需要扩展日志格式（没有它，Web服务器日志没有此信息）。此图表可能会出现异常的峰值，因为带宽是在Web服务器保存日志行时核算的，即使服务日志行所需的时间跨度更长。我们建议使用QoS（例如<a href="http://firehol.org/#fireqos" target="_blank">FireQOS</a>）来准确核算Web服务器带宽。'
    },

    'web_log.urls': {
        info: '<a href="https://github.com/netdata/netdata/blob/master/collectors/python.d.plugin/web_log/web_log.conf" target="_blank"><code>/etc/netdata/python.d/web_log.conf</code></a>中定义的每个<code>URL模式</code>的请求数量。该图表计算与定义的URL模式匹配的所有请求，独立于Web服务器响应代码（即成功和失败）。'
    },

    'web_log.clients': {
        info: '显示访问Web服务器的唯一客户端IP数量的图表。'
    },

    'web_log.timings': {
        info: 'Web服务器响应时间-Web服务器准备和响应请求所需的时间。这需要扩展日志格式，其含义特定于Web服务器。对于大多数Web服务器来说，这计入了从收到完整请求到发送响应最后一个字节的时间。因此，它包括响应的网络延迟，但它不包括请求的网络延迟。'
    },

    'mem.ksm': {
        title: 'deduper (ksm)',
        info: '<a href="https://en.wikipedia.org/wiki/Kernel_same-page_merging" target="_blank">Kernel同页合并</a> '+
        '（KSM）性能监控，从<code>/sys/kernel/mm/ksm/</code>中的几个文件中读取。 '+
        'KSM是Linux内核中节省内存的重复数据删除功能。 '+
        'KSM守护进程ksmd定期扫描已注册的用户内存区域， '+
        '寻找内容相同的页面，这些页面可以替换为单个受写保护的页面。'
    },

    'mem.hugepages': {
        info: 'Hugepages是一项功能，允许内核利用现代硬件架构的多个页面大小功能。内核创建了多页虚拟内存，从物理RAM和交换进行映射。CPU架构中有一个名为“翻译Lookaside缓冲区”（TLB）的机制，用于管理虚拟内存页面与实际物理内存地址的映射。TLB是一个有限的硬件资源，因此使用默认页面大小的大量物理内存会消耗TLB并增加处理开销。通过使用大型页面，内核能够创建更大大小的页面，每个页面消耗TLB中的单个资源。大型页面被固定在物理RAM上，无法交换/分页。'
    },

    'mem.numa': {
        info: 'Non-Uniform Memory Access (NUMA) 是一种记忆体存取分隔设计，在 NUMA 之下，一个处理器存取自己管理的的记忆体，将比非自己管理的记忆体 (另一个处理器所管理的记忆体或是共用记忆体) 具有更快速的效能。在 <a href="https://www.kernel.org/doc/Documentation/numastat.txt" target="_blank">Linux 核心文件</a> 中有详细说明这些指标。'
    },

    'mem.ecc': {
        info: '<p><a href="https://en.wikipedia.org/wiki/ECC_memory" target="_blank">ECC内存</a>'+
        '是一种使用错误更正代码（ECC）进行检测的计算机数据存储 '+
        '并纠正内存中发生的n位数据损坏。 '+
        '通常，ECC内存保持对单位错误的免疫记忆系统： '+
        '从每个单词读取的数据始终与写入它的数据相同， '+
        '即使实际存储的位数之一被翻转到错误的状态。</p>'+
        '<p>内存错误可分为两类：'+
        '<b>软错误</b>，随机损坏位数，但不留下物理损坏。 '+
        '软错误本质上是短暂的，不可重复，可能是由于电 '+
        '磁干扰。 '+
        '<b>硬错误</b>，它以可重复的方式损坏位，因为 '+
        '物理/硬件缺陷或环境问题。'
    },

    'mem.pagetype': {
        info: '内存统计数据可从 '+
        '<a href="https://en.wikipedia.org/wiki/Buddy_memory_allocation" target="_blank">记忆分配器</a>。'+
        'buddy分配器是系统内存分配器。 '+
        '整个内存空间被分割成物理页面，这些页面按 '+
        'NUMA节点，区域， '+
        '<a href="https://lwn.net/Articles/224254/" target="_blank">迁移类型</a>，以及块的大小。 '+
        '通过根据页面的移动能力对其进行分组， '+
        '内核可以回收页面块中的页面，以满足高阶分配。 '+
        '当内核或应用程序请求一些内存时，好友分配器会提供与请求最近的页面匹配。'
    },

    'ip.ecn': {
        info: '<a href="https://en.wikipedia.org/wiki/Explicit_Congestion_Notification" target="_blank">显式拥堵通知（ECN）</a> '+
        '是IP和TCP的扩展，允许在不丢失数据包的情况下端到端通知网络拥塞。 '+
        'ECN是一项可选功能，可以在两个支持ECN的端点之间使用，当 '+
        '基础网络基础设施也支持它。'
    },

    'ip.multicast': {
        info: '<a href="https://en.wikipedia.org/wiki/Multicast" target="_blank">IP多播</a>是一种技术 '+
        'IP 网络上的一对多通信。 '+
        '多播高效地使用网络基础设施，要求源只发送一次数据包， '+
        '即使它需要交付给大量接收器。 '+
        '网络中的节点仅在必要时负责复制数据包以到达多个接收器。'
    },
    'ip.broadcast': {
        info: '在计算机网络中， '+
        '<a href="https://en.wikipedia.org/wiki/Broadcasting_(networking)" target="_blank">广播</a>是指传输网络上每台设备都将接收的数据包。 '+
        '在实践中，广播范围仅限于广播领域。'
    },

    'netfilter.conntrack': {
        title: 'connection tracker',
        info: 'Netfilter connection tracker 效能指标。Connection tracker 会追踪这台主机上所有的连接，包括流入与流出。工作原理是将所有开启的连接都储存到资料库，以追踪网路、位址转换与连接目标。'
    },

    'netfilter.nfacct': {
        title: 'bandwidth accounting',
        info: '以下信息使用<code>nfacct.plugin</code>阅读。'
    },

    'netfilter.synproxy': {
        title: 'DDoS保护',
        info: 'DDoS保护性能指标。<a href="https://github.com/firehol/firehol/wiki/Working-with-SYNPROXY" target="_blank">SYNPROXY</a> '+
        '是TCP SYN数据包代理。 '+
        '它用于保护任何TCP服务器（如Web服务器）免受SYN洪水和类似的DDoS攻击。 '+
        'SYNPROXY拦截新的TCP连接，并使用syncookie处理最初的3向握手 '+
        '而不是连接来建立连接。 '+
        '它经过优化，可以利用所有可用的CPUs处理数百万个数据包，而无需 '+
        '连接之间的任何并发锁定。 '+
        '它可用于任何类型的TCP流量（甚至加密）， '+
        '因为它不会干扰内容本身。'
    },

    'ipfw.dynamic_rules': {
        title: 'dynamic rules',
        info: '由相应的有状态防火墙规则创建的动态规则数量。'
    },

    'system.softnet_stat': {
        title: 'softnet',
        info: function (os) {
            if (os === 'linux')
                return '<p>与网络接收工作相关的CPU SoftIRQ的统计数据。 '+
                '每个CPU内核的细分可以在<a href="#menu_cpu_submenu_softnet_stat">CPU/softnet统计</a>上找到。 '+
                '有关识别网络驱动程序相关问题并进行故障诊断的更多信息，请参阅 '+
                '<a href="https://access.redhat.com/sites/default/files/attachments/20150325_network_performance_tuning.pdf" target="_blank">红帽企业Linux网络性能调优指南</a>。</p>'+
                '<p><b>已处理</b> - 处理数据包。 '+
                '<b>已删除</b> - 由于网络设备积压已满，数据包已丢失。 '+
                '<b>挤压</b> - 网络设备预算消耗或达到时限的次数， '+
                '但还有更多工作要做。 '+
                '<b>ReceivedRPS</b> - 这个CPU被唤醒通过处理器间中断处理数据包的次数。 '+
                '<b>流量限制计数</b> - 达到流量限制的次数（流量限制是可选的 '+
                '接收数据包转向功能）。</p>';
            else
                return '与网络接收工作相关的CPU SoftIRQ的统计数据。';
        }
    },

    'system.clock synchronization': {
        info: '<a href="https://en.wikipedia.org/wiki/Network_Time_Protocol" target="_blank">NTP</a> '+
        '允许您自动将系统时间与远程服务器同步。 '+
        '这通过与已知具有准确时间的服务器同步来保持机器时间的准确性。'
    },

    'cpu.softnet_stat': {
        title: 'softnet',
        info: function (os) {
            if (os === 'linux')
                return '<p>与网络接收工作相关的CPU SoftIRQ的统计数据。 '+
                '所有CPU内核的总和可在<a href="#menu_system_submenu_softnet_stat">系统/软网统计</a>中找到。 '+
                '有关识别网络驱动程序相关问题并进行故障诊断的更多信息，请参阅 '+
                '<a href="https://access.redhat.com/sites/default/files/attachments/20150325_network_performance_tuning.pdf" target="_blank">红帽企业Linux网络性能调优指南</a>。</p>'+
                '<p><b>已处理</b> - 处理数据包。 '+
                '<b>已删除</b> - 由于网络设备积压已满，数据包已丢失。 '+
                '<b>挤压</b> - 网络设备预算消耗或达到时限的次数， '+
                '但还有更多工作要做。 '+
                '<b>ReceivedRPS</b> - 这个CPU被唤醒通过处理器间中断处理数据包的次数。 '+
                '<b>流量限制计数</b> - 达到流量限制的次数（流量限制是可选的 '+
                '接收数据包转向功能）。</p>';
            else
                return '与网络接收工作相关的每个CPU核心SoftIRQ的统计数据。所有CPU内核的总和可在<a href="#menu_system_submenu_softnet_stat">系统/软网统计</a>中找到。';
        }
    },

    'go_expvar.memstats': {
        title: 'memory statistics',
        info: '运行时内存统计。有关每个图表和值的更多信息，请参阅<a href="https://golang.org/pkg/runtime/#MemStats" target="_blank">runtime.MemStats</a>文档。'
    },

    'couchdb.dbactivity': {
        title: 'db activity',
        info: '整个数据库为整个服务器读取和写入。这包括任何外部HTTP流量，以及在集群中执行的内部复制流量，以确保节点一致性。'
    },

    'couchdb.httptraffic': {
        title: 'http traffic breakdown',
        info: '所有HTTP流量，按请求类型（<tt>GET</tt>、<tt>PUT</tt>、<tt>POST</tt>等）和响应状态代码（<tt>200</tt>、<tt>201</tt>、<tt>4xx</tt>等）<br/><br/>此处的任何<tt>5xx</tt>错误都表示可能存在CouchDB错误；请查看日志文件以了解更多信息。'
    },

    'couchdb.ops': {
        title: 'server operations'
    },

    'couchdb.perdbstats': {
        title: 'per db statistics',
        info: '每个数据库的统计数据。这包括<a href="http://docs.couchdb.org/en/latest/api/database/common.html#get--db" target="_blank">每个数据库3个大小的图表</a>：活动（数据库中实时数据的大小）、外部（数据库内容的未压缩大小）和文件（磁盘上文件的大小，不包括任何视图和索引）。它还包括每个数据库的文件数量和删除的文件数量。'
    },

    'couchdb.erlang': {
        title: 'erlang statistics',
        info: '有关托管CouchDB的Erlang VM状态的详细信息。这些仅适用于高级用户。峰值消息队列的高值（>10e6）通常表示重载条件。'
    },

    'ntpd.system': {
        title: 'system',
        info: '阅读列表广告牌<code>ntpq -c rl</code>所示的系统变量统计信息。系统变量被分配为零的关联ID，也可以显示在readvar广告牌<code>ntpq -c“rv 0”</code>中。这些变量用于<a href="http://doc.ntp.org/current-stable/discipline.html" target="_blank">时钟纪律算法</a>，以计算最低和最稳定的偏移量。'
    },

    'ntpd.peers': {
        title: 'peers',
        info: '在<code>/etc/ntp.conf</code>中配置的每个对等变量的统计信息，如readvar广告牌<code>ntpq -c“rv &lt;association&gt;”</code>所示，而每个对等方都分配了一个非零关联ID，如<code>ntpq -c“apeers”</code>所示。该模块定期扫描新的/更改的对等机（默认：每60秒一次）。<b>ntpd</b>从可用对等机中选择最佳对等机来同步时钟。至少需要3名同行才能正确识别最佳同行。'
    },

    'mem.page_cache': {
        title: 'page cache (eBPF)',
        info: '监控对用于操作<a href="https://en.wikipedia.org/wiki/Page_cache" target="_blank">Linux页面缓存</a>的函数的调用。当与应用程序的集成<a href="https://learn.netdata.cloud/guides/troubleshoot/monitor-debug-applications-ebpf" target="_blank">启用</a>时，Netdata还根据<a href="#menu_apps_submenu_page_cache">应用程序</a>显示页面缓存操作。'
    },

    'apps.page_cache': {
        title: 'page cache (eBPF)',
        info: 'Netdata还在<a href="#menu_mem_submenu_page_cache">内存子菜单</a>中对这些图表进行了摘要。'
    },

    'filesystem.vfs': {
        title: 'vfs (eBPF)',
        info: '监控对用于操作<a href="https://learn.netdata.cloud/docs/agent/collectors/ebpf.plugin#vfs" target="_blank">文件系统</a>的调用。当与应用程序的集成<a href="https://learn.netdata.cloud/guides/troubleshoot/monitor-debug-applications-ebpf" target="_blank">启用</a>时，Netdata还根据<a href="#menu_apps_submenu_vfs">应用程序</a>显示虚拟文件系统。'
    },

    'apps.vfs': {
        title: 'vfs (eBPF)',
        info: 'Netdata还在<a href="#menu_filesystem_submenu_vfs">文件系统子菜单</a>中对这些图表进行了摘要。'
    },

    'filesystem.ext4_latency': {
        title: 'ext4 latency (eBPF)',
        info: '延迟是完成事件所需的时间。我们计算调用和返回时间之间的差异，这跨越磁盘I/O、文件系统操作（锁定、I/O）、运行队列延迟以及与监控操作相关的所有事件。基于BCC工具中的eBPF <a href="http://www.brendangregg.com/blog/2016-10-06/linux-bcc-ext4dist-ext4slower.html" target="_blank">ext4dist</a>。'
    },

    'filesystem.xfs_latency': {
        title: 'xfs latency (eBPF)',
        info: '延迟是完成事件所需的时间。我们计算调用和返回时间之间的差异，这跨越磁盘I/O、文件系统操作（锁定、I/O）、运行队列延迟以及与监控操作相关的所有事件。基于BCC工具中的eBPF <a href="https://github.com/iovisor/bcc/blob/master/tools/xfsdist_example.txt" target="_blank">xfsdist</a>。'
    },

    'filesystem.nfs_latency': {
        title: 'nfs latency (eBPF)',
        info: '延迟是完成事件所需的时间。我们计算调用和返回时间之间的差异，这跨越磁盘I/O、文件系统操作（锁定、I/O）、运行队列延迟以及与监控操作相关的所有事件。基于BCC工具中的eBPF <a href="https://github.com/iovisor/bcc/blob/master/tools/nfsdist_example.txt" target="_blank">nfsdist</a>。'
    },

    'filesystem.zfs_latency': {
        title: 'zfs latency (eBPF)',
        info: '延迟是完成事件所需的时间。我们计算调用和返回时间之间的差异，这跨越磁盘I/O、文件系统操作（锁定、I/O）、运行队列延迟以及与监控操作相关的所有事件。基于BCC工具中的eBPF <a href="https://github.com/iovisor/bcc/blob/master/tools/zfsdist_example.txt" target="_blank">zfsdist</a>。'
    },

    'filesystem.btrfs_latency': {
        title: 'btrfs latency (eBPF)',
        info: '延迟是完成事件所需的时间。我们计算调用和返回时间之间的差异，获得最终结果的对数，并将一个值相加到各自的bin。基于BCC工具中的eBPF <a href="https://github.com/iovisor/bcc/blob/master/tools/btrfsdist_example.txt" target="_blank">btrfsdist</a>。'
    },

    'filesystem.file_access': {
        title: 'file access (eBPF)',
        info: '当与应用程序的集成<a href="https://learn.netdata.cloud/guides/troubleshoot/monitor-debug-applications-ebpf" target="_blank">启用</a>时，Netdata还根据<a href="#menu_apps_submenu_file_access">应用程序</a>显示文件访问权限。'
    },

    'apps.file_access': {
        title: 'file access (eBPF)',
        info: 'Netdata还在<a href="#menu_filesystem_submenu_file_access">文件系统子菜单</a>上提供了此图表的摘要（有关<a href="https://learn.netdata.cloud/docs/agent/collectors/ebpf.plugin#file" target="_blank">eBPF插件文件图表部分</a>的更多详细信息）。'
    },

    'ip.kernel': {
        title: 'kernel functions (eBPF)',
        info: '当<code>ebpf.plugin</code>在主机上运行时，会制作下一个图表。当与应用程序的集成<a href="https://learn.netdata.cloud/guides/troubleshoot/monitor-debug-applications-ebpf" target="_blank">启用</a>时，Netdata还根据<a href="#menu_apps_submenu_net">应用程序</a>显示对内核函数的调用。'
    },

    'apps.net': {
        title: 'network',
        info: 'Netdata还总结了<a href="#menu_ip_submenu_kernel">网络堆栈子菜单</a>中的eBPF图表。'
    },

    'system.ipc semaphores': {
        info: '系统V信号量是一种进程间通信（IPC）机制。 '+
        'It allows processes or threads within a process to synchronize their actions. '+
        '它们通常用于监控共享内存段等系统资源的可用性。 ' +
        '有关详细信息，请参阅<a href="https://man7.org/linux/man-pages/man7/svipc.7.html" target="_blank">svipc(7)</a>。 ' +
        '要查看主机IPC信号量信息，请运行<code>ipcs -us</code>。对于限制，请运行<code>ipcs -ls</code>。'
    },

    'system.ipc shared memory': {
        info: '系统共享内存是一种进程间通信（IPC）机制。 '+
        '它允许进程通过共享内存区域来通信信息。 '+
        '这是可用的最快进程间通信形式，因为当数据在进程之间传递时（没有复制），不会发生内核参与。 '+
        '通常，进程必须同步对共享内存对象的访问，例如使用POSIX信号量。 '+
        '有关详细信息，请参阅<a href="https://man7.org/linux/man-pages/man7/svipc.7.html" target="_blank">svipc(7)</a>。 '+
        '要查看主机IPC共享内存信息，请运行<code>ipcs -um</code>。对于限制，请运行<code>ipcs -lm</code>。'
    },

    'system.ipc message queues': {
        info: '系统消息队列是一种进程间通信（IPC）机制。 '+
        '它允许进程以消息形式交换数据。 '+
        '有关详细信息，请参阅<a href="https://man7.org/linux/man-pages/man7/svipc.7.html" target="_blank">svipc(7)</a>。 ' +
        '要查看主机IPC消息信息，请运行<code>ipcs -uq</code>。对于限制，请运行<code>ipcs -lq</code>。'
    },

    'system.interrupts': {
        info: '<a href="https://en.wikipedia.org/wiki/Interrupt" target="_blank"><b>Interrupts</b></a> 是'+
        '通过外部设备（通常是I/O设备）或程序（运行进程）发送到CPU。 '+
        '它们告诉CPU停止当前的活动，并执行操作系统的相应部分。 '+
        'Interrupt 类型包括 '+
        '<b>hardware</b> (由硬件设备生成，以表明它们需要操作系统的注意), '+
        '<b>software</b> (当程序想要请求操作系统执行系统调用时生成), 及 '+
        '<b>traps</b> (由CPU本身生成，以指示发生了某些错误或情况，需要操作系统的帮助).'
    },

    'system.softirqs': {
        info: '软件中断（或“softirqs”）是内核中最古老的延迟执行机制之一。 '+
        '内核执行的几项任务并不重要： '+
        '如有必要，它们可以被长时间推迟。 '+
        '在启用所有中断的情况下，可以执行可执行的任务 '+
        '（软件在硬件中断后模式化）。 '+
        '将它们从中断处理程序中取出有助于保持内核响应时间小。'
    },

    'cpu.softirqs': {
        info: '每个CPU的软件中断总数。 '+
        '要查看系统的总数，请检查 <a href="#menu_system_submenu_softirqs">softirqs</a> 查看'
    },

    'cpu.interrupts': {
        info: '每个CPU的中断总数。 '+
        '要查看系统的总数，请查看<a href="#menu_system_submenu_interrupts">中断</a>部分。 '+
        '<code>/proc/interrupts</code>的最后一列提供了中断描述或注册该中断处理程序的设备名称。'
    },

    'cpu.throttling': {
        info: ' CPU节流通常用于自动减慢计算机的速度 '+
        '在可能的情况下减少能源消耗并节省电池电量。'
    },

    'cpu.cpuidle': {
        info: '<a href="https://en.wikipedia.org/wiki/Advanced_Configuration_and_Power_Interface#Processor_states" target="_blank">空闲状态（C-states）</a> '+
        '用于在处理器闲置时节省电力。'
    },

    'services.net': {
        title: 'network (eBPF)',
    },

    'services.page_cache': {
        title: 'pache cache (eBPF)',
    },
};

// ----------------------------------------------------------------------------
// chart

// information works on the context of a chart
// Its purpose is to set:
//
// info: the text above the charts
// heads: the representation of the chart at the top the subsection (second level menu)
// mainheads: the representation of the chart at the top of the section (first level menu)
// colors: the dimension colors of the chart (the default colors are appended)
// height: the ratio of the chart height relative to the default
//

var cgroupCPULimitIsSet = 0;
var cgroupMemLimitIsSet = 0;

netdataDashboard.context = {
    'system.cpu': {
        info: function (os) {
            void (os);
            return 'CPU 使用率总表 (全部核心)。 当数值为 100% 时，表示您的 CPU 非常忙碌没有闲置空间。您可以在 <a href="#menu_cpu">CPUs</a> 区段及以及 <a href="#menu_apps">应用程序</a> 区段深入了解每个核心与应用程序的使用情况。'
                + netdataDashboard.sparkline('<br/>请特别关注 <b>iowait</b> ', 'system.cpu', 'iowait', '%', '，如果它一直处于较高的情况，这表示您的磁碟是效能瓶颈，您的系统效能会明显降低。')
                + netdataDashboard.sparkline(
                '<br/>另一个重要的指标是 <b>softirq</b> ',
                'system.cpu',
                'softirq',
                '%',
                '，若这个数值持续在较高的情况，很有可能是您的网路驱动部份有问题。'+
                '可以在 '+
                '<a href="https://www.kernel.org/doc/html/latest/filesystems/proc.html#miscellaneous-kernel-statistics-in-proc-stat" target="_blank">内核文档</a>中找到各个指标。');
        },
        valueRange: "[0, 100]"
    },

    'system.load': {
        info: '目前系统负载，也就是指 CPU 使用情况或正在等待系统资源 (通常是 CPU 与磁碟)。这三个指标分别是 1、5、15 分钟。系统每 5 秒会计算一次。更多的资讯可以参阅 <a href="https://en.wikipedia.org/wiki/Load_(computing)" target="_blank">维基百科</a> 说明。',
        height: 0.7
    },

    'system.cpu_pressure': {
        info: '<a href="https://www.kernel.org/doc/html/latest/accounting/psi.html" target="_blank">压力信息</a> ' +
            '识别和量化资源争用造成的中断。 ' +
            '“一些”行表示CPU上至少<b>一些</b>任务停滞的时间份额。 ' +
            '这些比率（以%为单位）被跟踪为10秒、60秒和300秒windows的近期趋势。'
    },

    'system.memory_some_pressure': {
        info: '<a href="https://www.kernel.org/doc/html/latest/accounting/psi.html" target="_blank">压力信息</a> ' +
            '识别和量化资源争用造成的中断。 ' +
            '“一些”行表示至少<b>一些</b>任务在内存上停滞的时间份额。 ' +
            '“全”行表示<b>所有非空闲</b>任务同时在内存上停滞的时间份额。 ' +
            '在这种状态下，实际的CPU周期将被浪费，在这个状态下花费很长时间的工作负载被认为是鞭打。 ' +
            '这些比率（以%为单位）被跟踪为10秒、60秒和300秒windows的近期趋势。'
    },

    'system.io_some_pressure': {
        info: '<a href="https://www.kernel.org/doc/html/latest/accounting/psi.html" target="_blank">压力信息</a> ' +
            '识别和量化资源争用造成的中断。' +
            '“一些”行表示至少<b>一些</b>任务在I/O上停滞的时间份额。 ' +
            '“全”行表示<b>所有非空闲</b>任务同时在I/O上停滞的时间份额。 ' +
            '在这种状态下，实际的CPU周期将被浪费，在这个状态下花费很长时间的工作负载被认为是鞭打。 ' +
            '这些比率（以%为单位）被跟踪为10秒、60秒和300秒windows的近期趋势。'
    },

    'system.io': {
        info: function (os) {
            var s = '磁碟 I/O 总计, 包含所有的实体磁碟。您可以在 <a href="#menu_disk">磁碟</a> 区段查看每一个磁碟的详细资讯，也可以在 <a href="#menu_apps">应用程序</a> 区段了解每一支应用程序对于磁碟的使用情况。';

            if (os === 'linux')
                return s + ' 实体磁碟指的是 <code>/sys/block</code> 中有列出，但是没有在 <code>/sys/devices/virtual/block</code> 的所有磁碟。';
            else
                return s;
        }
    },

    'system.pgpgio': {
        info: '从记忆体分页到磁碟的 I/O。通常是这个系统所有磁碟的总 I/O。'
    },

    'system.swapio': {
        info: '<p>所有的 Swap I/O.</p>'+
        '<b>输入</b>-系统从磁盘交换到RAM的页面。 '+
        '<b>输出</b> - 系统已从 RAM 交换到磁盘的页面。'
    },

    'system.pgfaults': {
        info: '所有的页面错误。<b>主要页面错误</b>表示系统正在使用其交换。您可以在<a href="#menu_apps">应用程序监控</a>部分找到哪些应用程序使用交换。'
    },

    'system.entropy': {
        colors: '#CC22AA',
        info: '<a href="https://en.wikipedia.org/wiki/Entropy_(computing)" target="_blank">Entropy</a>，主要是用在密码学的乱数集区 (<a href="https://en.wikipedia.org/wiki//dev/random" target="_blank">/dev/random</a>) 如果Entropy的集区为空，需要乱数的程序可能会导致执行变慢 (这取决于每个程序使用的介面)，等待集区补充。在理想情况下，有高度熵需求的系统应该要具备专用的硬体装置 (例如 TPM 装置)。您也可以安装纯软体的方案，例如 <code>haveged</code>，通常这些方案只会使用在伺服器上。'
    },

    'system.clock_sync_state': {
        info:'<p>系统时钟同步状态。 '+
        '强烈建议时钟与可靠的NTP服务器同步。否则， '+
        '这会导致不可预测的问题。 '+
        'NTP守护进程可能需要几分钟（通常最多17分钟）才能选择要同步的服务器。 '+
        '<p><b>状态图</b>：0-不同步，1-同步。</p>'
    },

    'system.clock_sync_offset': {
        info: '典型的NTP客户端定期轮询一个或多个NTP服务器。 '+
        '客户必须计算其 '+
        '<a href="https://en.wikipedia.org/wiki/Network_Time_Protocol#Clock_synchronization_algorithm" target="_blank">时间偏移</a> '+
        '和往返延迟。 '+
        '时间偏移是两个时钟之间绝对时间的差异。'
    },

    'system.forks': {
        colors: '#5555DD',
        info: '建立新程序的数量。'
    },

    'system.intr': {
        colors: '#DD5555',
        info: 'CPU 中断的总数。透过检查 <code>system.interrupts</code>，得知每一个中断的细节资讯。在 <a href="#menu_cpu">CPUs</a> 区段提供每一个 CPU 核心的中断情形。<a href="#menu_cpu_submenu_interrupts">per CPU core</a>.'
    },

    'system.interrupts': {
        info: 'CPU 中断的细节。在 <a href="#menu_cpu">CPUs</a> 区段中，依据每个 CPU 核心分析中断。 <a href="#menu_cpu_submenu_interrupts">per CPU core</a>. '+
        '<code>/proc/interrupts</code>的最后一列提供了中断描述或注册该中断处理程序的设备名称。'
    },

    'system.hardirq_latency': {
        info: '维修硬件中断的总时间。基于BCC工具中的eBPF <a href="https://github.com/iovisor/bcc/blob/master/tools/hardirqs_example.txt" target="_blank">hardirqs</a>。'
    },

    'system.softirqs': {
        info: '<p>系统中的软件中断总数。 '+
        '在<a href="#menu_cpu">CPU</a>部分，对每个CPU内核</a href="#menu_cpu_submenu_softirqs">进行了分析。</p>'+
        '<p><b>HI</b> - 高优先级任务组。 '+
        '<b>TIMER</b> - 与计时器中断相关的任务组。 '+
        '<b>NET_TX</b>，<b>NET_RX</b>-用于网络传输和接收处理。 '+
        '<b>BLOCK</b> - 处理阻止I/O完成事件。 '+
        '<b>IRQ_POLL</b> - IO子系统用于提高性能（块设备的一种类似NAPI的方法）。 '+
        '<b>TASKLET</b> - 处理常规任务。 '+
        '<b>SCHED</b> - 调度程序用于执行负载平衡和其他调度任务。 '+
        '<b>HRTIMER</b> - 用于高分辨率计时器。 '+
        '<b>RCU</b> - 执行读拷贝更新 (RCU) 处理。</p>'

    },

    'system.softirq_latency': {
        info: '维修软件中断的总时间。基于BCC工具中的eBPF <a href="https://github.com/iovisor/bcc/blob/master/tools/softirqs_example.txt" target="_blank">softirqs</a>。'
    },

    'system.processes': {
        info: '<p>系统程序。</p>'+
        '<p><b>Running</b> - 显示正在 CPU 中的程序。'+
        '<b>Blocked</b> - 显示目前被挡下无法进入 CPU 执行的程序，例如：正在等待磁碟完成动作，才能继续。</p>'
    },

    'system.active_processes': {
        info: '所有的系统程序。'
    },

    'system.ctxt': {
        info: '<a href="https://en.wikipedia.org/wiki/Context_switch" target="_blank">Context Switches</a>，指 CPU 从一个程序、工作或是执行绪切换到另一个程序、工作或是执行绪。如果有许多程序或执行绪需要执行，但可以使用的 CPU 核心很少，即表示系统将会进行更多的 context switching 用来平衡它们所使用的 CPU 资源。这个过程需要大量的运算，因此 context switches 越多，整个系统就会越慢。'
    },

    'system.idlejitter': {
        info: 'Idle jitter 是由 netdata 计算而得。当一个执行绪要求睡眠 (Sleep) 时，需要几个微秒的时间。当系统要唤醒它时，会量测它用了多少个微秒的时间。要求睡眠与实际睡眠时间的差异就是 <b>idle jitter</b>。这个数字在即时的环境中非常有用，因为 CPU jitter 将会影响服务的品质 (例如 VoIP media gateways)。'
    },

    'system.net': {
        info: function (os) {
            var s = '所有实体网路介面的总频宽。不包含 <code>lo</code>、VPN、网路桥接、IFB 装置、介面聚合 (Bond).. 等。将合并显示实体网路介面的频宽使用情况。';

            if (os === 'linux')
                return s + ' 实体网路介面是指在 <code>/proc/net/dev</code> 有列出，但不在 <code>/sys/devices/virtual/net</code> 里。';
            else
                return s;
        }
    },

    'system.ip': {
        info: 'IP 总流量。'
    },

    'system.ipv4': {
        info: 'IPv4 总流量。'
    },

    'system.ipv6': {
        info: 'IPv6 总流量。'
    },

    'system.ram': {
        info: '系统随机存取记忆体 (也就是实体记忆体) 使用情况。'
    },

    'system.swap': {
        info: '系统交换空间 (Swap) 记忆体使用情况。Swap 空间会在实体记忆体 (RAM) 已满的情况下使用。当系统记忆体已满但还需要使用更多记忆体情况下，系统记忆体中的比较没有异动的 Page 将会被移动到 Swap 空间 (通常是磁碟、磁碟分割区或是档案)。'
    },

    'system.swapcalls': {
        info: '监控对函数<code>swap_readpage</code>和<code>swap_writepage</code>的调用。当<a href="https://learn.netdata.cloud/guides/troubleshoot/monitor-debug-applications-ebpf" target="_blank">启用</a>时，Netdata还显示<a href="#menu_apps_submenu_swap">应用程序</a>的交换访问权限。'
    },

    'system.ipc_semaphores': {
        info: '分配的系统V IPC信号量。 '+
        '<code>/proc/sys/kernel/sem</code>文件（第二个字段）规定了所有信号量集中信号量的系统范围限制。'
    },

    'system.ipc_semaphore_arrays': {
        info: '使用过的System V IPC信号量阵列（集）的数量。信号量支持信号量集，其中每个信号量都是计数信号量。 '+
        '因此，当应用程序请求信号量时，内核会以集合的方式释放它们。 '+
        '<code>/proc/sys/kernel/sem</code>文件（第4个字段）中指定了信号量集最大数量的系统范围限制。'
    },

    'system.shared_memory_segments': {
        info: '分配的System V IPC内存段数。 '+
        '<code>/proc/sys/kernel/shmmni</code>文件中指定了可以创建的系统范围内共享内存段的最大数量。'
    },

    'system.shared_memory_bytes': {
        info: 'System V IPC内存段目前使用的内存量。 '+
        '可以创建的最大共享内存段大小的运行时限制在<code>/proc/sys/kernel/shmmax</code>文件中指定。'
    },

    'system.shared_memory_calls': {
        info: '监控对函数<code>shmget</code>、<code>shmat</code>、<code>shmdt</code>和<code>shmctl</code>的调用。当与应用程序的集成<a href="https://learn.netdata.cloud/guides/troubleshoot/monitor-debug-applications-ebpf" target="_blank">启用</a>时，Netdata还显示每个应用程序的共享内存系统调用使用情况<a href="#menu_apps_submenu_ipc_shared_memory"></a>。'
    },

    'system.message_queue_messages': {
        info: '系统V IPC消息队列中当前存在的消息数量。'
    },

    'system.message_queue_bytes': {
        info: '系统V IPC消息队列中消息当前使用的内存量。'
    },

    'system.uptime': {
        info: '系统已运行的时间量，包括暂停的时间。'
    },

    'system.process_thread': {
        title : 'Task creation',
        info: '<a href="https://www.ece.uic.edu/~yshi1/linux/lkse/node4.html#SECTION00421000000000000000" target="_blank">do_fork</a>，或者<code>kernel_clone</code>（如果您运行的内核更新于5.16）来创建新任务的次数，这是用于定义内核内进程和任务的常用名称。Netdata标识监控跟踪点<code>sched_process_fork</code>的线程。此图表由eBPF插件提供。'
    },

    'system.exit': {
        title : 'Exit monitoring',
        info: '呼吁负责关闭的功能（<a href="https://www.informit.com/articles/article.aspx?p=370047&seqNum=4" target="_blank">do_exit</a>）和发布（<a href="https://www.informit.com/articles/article.aspx?p=370047&seqNum=4" target="_blank">release_task</a>)任务。此图表由eBPF插件提供。'
    },

    'system.task_error': {
        title : 'Task error',
        info: '创建新进程或线程的错误数量。此图表由eBPF插件提供。'
    },

    'system.process_status': {
        title : 'Task status',
        info: '创建的进程数量和每个周期创建的线程数量（<code>process</code>维度）之间的差异，它还显示了在系统上运行的可能僵尸进程的数量。此图表由eBPF插件提供。'
    },

    // ------------------------------------------------------------------------
    // CPU charts

    'cpu.cpu': {
        commonMin: true,
        commonMax: true,
        valueRange: "[0, 100]"
    },

    'cpu.interrupts': {
        commonMin: true,
        commonMax: true
    },

    'cpu.softirqs': {
        commonMin: true,
        commonMax: true
    },

    'cpu.softnet_stat': {
        commonMin: true,
        commonMax: true
    },

    'cpu.core_throttling': {
        info: '根据CPU的核心温度对CPU的时钟速度所做的调整次数。'
    },

    'cpu.package_throttling': {
        info: '根据CPU的封装（芯片）温度对CPU的时钟速度进行的调整次数。'
    },

    'cpufreq.cpufreq': {
        info: '频率测量CPU每秒执行的周期数。'
    },

    'cpuidle.cpuidle': {
        info: '在C-states中花费的时间百分比'
    },

    // ------------------------------------------------------------------------
    // MEMORY

    'mem.ksm': {
        info: '<p>内存页面合并统计数据。 '+
        '<b>共享</b>与<b>共享</b>的高比率表示良好的共享， '+
        '但<b>未共享</b>与<b>共享</b>的高比率表明浪费了精力。</p>'+
        '<p><b>共享</b> - 使用共享页面。 '+
        '<b>未共享</b> - 内存不再共享（页面是唯一的，但反复检查合并）。 '+
        '<b>共享</b>-当前共享的内存（有多少个网站正在共享页面，即保存了多少）。 '+
        '<b>易变</b> - 易变页面（变化太快，无法放在树上）。</p>'
    },

    'mem.ksm_savings': {
        heads: [
            netdataDashboard.gaugeChart('Saved', '12%', 'savings', '#0099CC')
        ],
        info: '<p>KSM节省的内存量。</p>'+
        '<p><b>节省</b> - 保存内存。 '+
        '<b>提供</b> - 标记为可合并的内存。</p>'
    },

    'mem.ksm_ratios': {
        heads: [
            function (os, id) {
                void (os);
                return '<div data-netdata="' + id + '"'
                    + ' data-gauge-max-value="100"'
                    + ' data-chart-library="gauge"'
                    + ' data-title="Savings"'
                    + ' data-units="percentage %"'
                    + ' data-gauge-adjust="width"'
                    + ' data-width="12%"'
                    + ' data-before="0"'
                    + ' data-after="-CHART_DURATION"'
                    + ' data-points="CHART_DURATION"'
                    + ' role="application"></div>';
            }
        ],
        info: 'The effectiveness of KSM. '+
        '这是当前合并的可合并页面的百分比。'
    },

    'mem.zram_usage': {
        info: 'ZRAM总RAM使用指标。ZRAM使用一些内存来存储有关存储内存页面的元数据，从而引入了与磁盘大小成正比的开销。它排除了相同元素填充的页面，因为没有为它们分配内存。'
    },

    'mem.zram_savings': {
        info: '显示原始和压缩内存数据大小。'
    },

    'mem.zram_ratio': {
        heads: [
            netdataDashboard.gaugeChart('Compression Ratio', '12%', 'ratio', '#0099CC')
        ],
        info: '压缩率，计算为<code>100 * original_size / compressed_size</code>。更多意味着更好的压缩和更多的RAM节省。'
    },

    'mem.zram_efficiency': {
        heads: [
            netdataDashboard.gaugeChart('Efficiency', '12%', 'percent', NETDATA.colors[0])
        ],
        commonMin: true,
        commonMax: true,
        valueRange: "[0, 100]",
        info: '内存使用效率，计算为<code>100 * compressed_size / total_mem_used</code>。'
    },


    'mem.pgfaults': {
        info: '<p> <a href="https://en.wikipedia.org/wiki/Page_fault" target="_blank">页面错误</a>是一种中断， '+
        '称为陷阱，当运行中的程序访问内存页面时，由计算机硬件引发 '+
        '映射到虚拟地址空间，但实际上没有加载到主内存中。</p>'+
        '</p><b>次要</b>-页面在生成故障时加载到内存中， '+
        '但在内存管理单元中未标记为正在加载内存中。 '+
        '<b>主要</b>-当系统需要从磁盘加载内存页面或交换内存时生成。</p>'
    },

    'mem.committed': {
        colors: NETDATA.colors[3],
        info: 'Committed 记忆体，是指程序分配到的所有记忆体总计。'
    },

    'mem.oom_kill': {
        info: '被杀死的进程数量 '+
        '<a href="https://en.wikipedia.org/wiki/Out_of_memory" target="_blank">内存不足</a>杀手。 '+
        '当系统缺少可用内存时，内核的OOM杀手会被召唤，并且 '+
        '无法在不杀死一个或多个进程的情况下进行。 '+
        '它试图选择其消亡将释放最多记忆的过程，同时 '+
        '给系统用户带来最少的痛苦。 '+
        '此计数器还包括容器中超过内存限制的进程。'
    },

    'mem.numa': {
        info: '<p>NUMA平衡统计数据。</p>'+
        '<p><b>本地</b>-通过此节点上的进程成功分配了页面。 '+
        '<b>外国</b> - 最初用于分配给另一个节点的页面。 '+
        '<b>交错</b>-交错策略页面已成功分配给此节点。 '+
        '<b>其他</b>-通过另一个节点上的进程在这个节点上分配的页面。 '+
        '<b>PteUpdates</b> - 标记为NUMA提示故障的基页。 '+
        '<b>HugePteUpdates</b> - 标记为NUMA提示故障的透明大页面。 '+
        '与<b>pte_updates</b>相结合，可以计算标记的总地址空间。 '+
        '<b>HintFaults</b> - NUMA暗示被困的故障。 '+
        '<b>HintFaultsLocal</b> - 提示本地节点的故障。 '+
        '结合<b>提示故障</b>，可以计算局部故障与远程故障的百分比。 '+
        '很高比例的局部提示故障表明工作量更接近收敛。 '+
        '<b>PagesMigrated</b> - 页面被迁移，因为它们放错了地方。 '+
        '由于迁移是一种复制操作，它贡献了NUMA平衡产生的开销的最大部分。</p>'
    },

    'mem.available': {
        info: '可用记忆体是由核心估算而来，也就是使用者空间程序可以使用的 RAM 总量，而不会造成交换 (Swap) 发生。'
    },

    'mem.writeback': {
        info: '<b>Dirty</b> 是等待写入磁碟的记忆体量。<b>Writeback</b> 是指有多少记忆体内容被主动写入磁碟。'
    },

    'mem.kernel': {
        info: '<p>内核使用的总内存量。</p>'+
        '<p><b>Slab</b> - 内核用于缓存数据结构供自己使用。 '+
        '<b>KernelStack</b> - 为内核完成的每个任务分配。 '+
        '<b>PageTables</b> - 专用于最低级别的页面表（页面表用于将虚拟地址转换为物理内存地址）。 '+
        '<b>VmallocUsed</b>-用作虚拟地址空间。 '+
        '<b>Percpu</b> - 分配给用于支持每个CPU分配的每个CPU分配器（不包括元数据成本）。 '+
        '当您创建每个CPU变量时，系统上的每个处理器都会获得该变量的副本。</p>'
    },

    'mem.slab': {
        info: '<p><a href="https://en.wikipedia.org/wiki/Slab_allocation" target="_blank">平板内存</a>统计。<p>'+
        '<p><b>可回收</b> - 内核可以重用的内存量。 '+
        '<b>不可回收</b> - 即使内核缺乏内存，也无法重用。</p>'
    },

    'mem.hugepages': {
        info: '专用（或直接）大型页面是为配置为使用大型页面的应用程序保留的内存。巨页<b>使用</b>内存，即使有免费的巨页可用。'
    },

    'mem.transparent_hugepages': {
        info: '透明巨页（THP）用巨页支持虚拟内存，支持页面大小的自动推广和降级。它适用于匿名内存映射和tmpfs/shmem的所有应用程序。'
    },

    'mem.hwcorrupt': {
        info: '存在物理损坏问题的内存量，由<a href="https://en.wikipedia.org/wiki/ECC_memory" target="_blank">ECC</a>识别，并由内核预留，使其不被使用。'
    },

    'mem.ecc_ce': {
        info: '可更正（单位）ECC错误的数量。 '+
        '这些错误不影响系统的正常运行 '+
        '因为他们仍在纠正。 '+
        '周期性可更正错误可能表明其中一个内存模块正在缓慢故障。'
    },

    'mem.ecc_ue': {
        info: '无法更正（多位）ECC错误的数量。 '+
        '无法更正的错误是一个致命的问题，通常会导致操作系统崩溃。'
    },

    'mem.pagetype_global': {
        info: '以一定大小的块为单位的可用内存量。'
    },

    'mem.cachestat_ratio': {
        info: '当处理器需要读取或写入主内存中的位置时，它会检查页面缓存中的相应条目。如果条目在那里，则发生了页面缓存命中，并且读取来自缓存。如果没有条目，则会发生页面缓存丢失，内核会分配一个新的条目并从磁盘中复制数据。Netdata计算内存上缓存的访问文件的百分比。<a href="https://github.com/iovisor/bcc/blob/master/tools/cachestat.py#L126-L138" target="_blank">计算</a>的比率是计算访问的缓存页面（不计算脏页面和因读取丢失而添加的页面）除以没有脏页面的总访问量。'
    },

    'mem.cachestat_dirties': {
        info: '<a href="https://en.wikipedia.org/wiki/Page_cache#Memory_conservation" target="_blank">肮脏（修改）页面</a>缓存的数量。引入后修改的页面缓存中的页面称为脏页面。由于页面缓存中的非脏页面在<a href="https://en.wikipedia.org/wiki/Secondary_storage" target="_blank">辅助存储</a>（例如硬盘驱动器或固态驱动器）中具有相同的副本，因此丢弃和重用其空间比分页应用程序内存快得多，通常比将脏页面冲入辅助存储并重复使用其空间更可取。'
    },

    'mem.cachestat_hits': {
        info: '当处理器需要读取或写入主内存中的位置时，它会检查页面缓存中的相应条目。如果条目在那里，则发生了页面缓存命中，并且读取来自缓存。点击量显示未修改的访问页面（我们排除脏页面），此计数还不包括最近插入供阅读的页面。'
    },

    'mem.cachestat_misses': {
        info: '当处理器需要读取或写入主内存中的位置时，它会检查页面缓存中的相应条目。如果没有条目，则发生页面缓存丢失，缓存分配新条目并复制主内存的数据。缺少与编写无关的内存的页面插入计数。'
    },

    'mem.sync': {
        info: '系统调用<a href="https://man7.org/linux/man-pages/man2/sync.2.html" target="_blank">sync()和syncfs()</a>，这将文件系统缓冲区刷新到存储设备。这些通话可能会造成性能扰动。<code>sync()</code>调用基于BCC工具中的eBPF <a href="https://github.com/iovisor/bcc/blob/master/tools/syncsnoop.py" target="_blank">syncsnoop</a>。'
    },

    'mem.file_sync': {
        info: '系统调用<a href="https://man7.org/linux/man-pages/man2/fsync.2.html" target="_blank">fsync()和fdatasync()</a>传输磁盘设备上文件的所有修改页面缓存。这些通话会阻止，直到设备报告转接已完成。'
    },

    'mem.memory_map': {
        info: '系统调用<a href="https://man7.org/linux/man-pages/man2/msync.2.html" target="_blank">msync()</a>，该更改刷新了对映射文件的核心副本所做的更改。'
    },

    'mem.file_segment': {
        info: '<a href="https://man7.org/linux/man-pages/man2/sync_file_range.2.html" target="_blank">sync_file_range()</a>的系统调用允许在将文件描述符fd引用的打开文件与磁盘同步时进行精细控制。这种系统调用极其危险，不应用于便携式程序。'
    },

    'filesystem.dc_hit_ratio': {
        info: '目录缓存中存在的文件访问百分比。100%表示访问的每个文件都存在于目录缓存中。如果目录缓存中不存在文件1）它们不存在于文件系统中，2）以前没有访问过文件。阅读更多关于<a href="https://www.kernel.org/doc/htmldocs/filesystems/the_directory_cache.html" target="_blank">目录缓存</a>的信息。当与应用程序的集成<a href="https://learn.netdata.cloud/guides/troubleshoot/monitor-debug-applications-ebpf" target="_blank">启用</a>时，Netdata还根据<a href="#menu_apps_submenu_directory_cache__eBPF_">应用程序</a>显示目录缓存。'
    },

    'filesystem.dc_reference': {
        info: '文件访问计数器。<code>引用</code>是当有文件访问且文件不存在于目录缓存中时。<code>Miss</code>是当有文件访问且文件系统中找不到文件时。<code>慢</code>是指有文件访问，文件存在于文件系统中，但不存在于目录缓存中。阅读更多关于<a href="https://www.kernel.org/doc/htmldocs/filesystems/the_directory_cache.html" target="_blank">目录缓存</a>的信息。'
    },

    'md.health': {
        info: '每个MD阵列的故障设备数量。 '+
        'Netdata从md状态行的<b>[n/m]</b>字段检索此数据。 '+
        '这意味着理想情况下，数组将有<b>n</b>设备，但目前，<b>m</b>设备正在使用中。 '+
        '<code>失败磁盘</code>是<b>n-m</b>。'
    },
    'md.disks': {
        info: '处于使用和处于停机状态的设备数量。 '+
        'Netdata从md状态行的<b>[n/m]</b>字段检索此数据。 '+
        '这意味着理想情况下，数组将有<b>n</b>设备，但目前，<b>m</b>设备正在使用中。 '+
        '<code>inuse</code>是<b>m</b>，<code>down</code>是<b>n-m</b>。'
    },
    'md.status': {
        info: '完成正在进行的业务的进展。'
    },
    'md.expected_time_until_operation_finish': {
        info: '完成正在进行的操作的预计时间。 '+
        '时间只是一个近似值，因为操作速度将根据其他I/O要求而变化。'
    },
    'md.operation_speed': {
        info: '持续运营的速度。 '+
        '<code>/proc/sys/dev/raid/{speed_limit_min,speed_limit_max}</code>文件中指定了系统范围的重建速度限制。 '+
        '这些选项有利于调整重建过程，并可能增加整体系统负载、cpu和内存使用率。'
    },
    'md.mismatch_cnt': {
        info: '在执行<b>检查</b>和<b>修复</b>时，以及可能在执行<b>重新同步</b>时，md将计算发现的错误数量。 '+
        '不匹配计数记录在<code>sysfs</code>文件<code>md/mismatch_cnt</code>中。 '+
        '此值是重写或（对于<b>check</b>）将重写的扇区数量。 '+
        '它可能大于页面扇区数量的因子的实际错误数量。 '+
        '在RAID1或RAID10上无法非常可靠地解释不匹配，特别是在设备用于交换时。 '+
        '在真正干净的RAID5或RAID6阵列上，任何不匹配都应表明在某些级别上存在硬件问题- '+
        '软件问题绝不应导致此类不匹配。 '+
        '有关详细信息，请参阅<a href="https://man7.org/linux/man-pages/man4/md.4.html" target="_blank">md(4)</a>。'
    },
    'md.flush': {
        info: '每个MD阵列的刷新计数。基于BCC工具中的eBPF <a href="https://github.com/iovisor/bcc/blob/master/tools/mdflush_example.txt" target="_blank">mdflush</a>。'
    },

    // ------------------------------------------------------------------------
    // IP

    'ip.inerrors': {
        info: '<p>接收IP数据包时遇到的错误数量。</p>' +
            '</p><b>NoRoutes</b> - 由于没有发送路线而删除的数据包。 ' +
            '<b>Truncated</b> - 由于数据报帧没有携带足够的数据而被丢弃的数据包。 ' +
            '<b>校验和</b>-因校验和错误而删除的数据包。</p>'
    },

    'ip.mcast': {
        info: '系统中的总多播流量。'
    },

    'ip.mcastpkts': {
        info: '系统中传输的多播数据包总数。'
    },

    'ip.bcast': {
        info: '系统中的总广播流量。'
    },

    'ip.bcastpkts': {
        info: '系统中传输的广播数据包总数。'
    },

    'ip.ecnpkts': {
        info: '<p>系统中设置了ECN位的接收IP数据包总数。</p>'+
        '<p><b>CEP</b> - 遇到拥堵。 '+
        '<b>NoECTP</b> - 不支持ECN的运输。 '+
        '<b>ECTP0</b>和<b>ECTP1</b>-支持ECN的传输。</p>'
    },

    'ip.tcpreorders': {
        info: '<p>TCP通过按正确的顺序排序数据包或防止数据包失序 '+
        '通过请求重新传输出序的数据包。</p>'+
        '<p><b>时间戳</b> - 使用时间戳选项检测到重新排序。 '+
        '<b>SACK</b> - 使用选择性确认算法检测到重新排序。 '+
        '<b>FACK</b> - 使用正向确认算法检测到重新排序。 '+
        '<b>Reno</b> - 使用快速重新传输算法检测到重新排序。</p>'
    },

    'ip.tcpofo': {
        info: '<p>TCP维护一个无序队列，以在TCP通信中保留无序数据包。</p>'+
        '<p><b>InQueue</b> - TCP层收到一个无序的数据包，并有足够的内存排队。 '+
        '<b>Droppped</b> - TCP层收到一个无序的数据包，但没有足够的内存，因此将其删除。 '+
        '<b>合并</b> - 收到的无序数据包与上一个数据包具有覆盖。 '+
        '覆盖部分将被删除。所有这些数据包也将计入<b>InQueue</b>。 '+
        '<b>修剪</b> - 由于套接字缓冲区溢出，数据包从无序队列中删除。</p>'
    },

    'ip.tcpsyncookies': {
        info: '<p><a href="https://en.wikipedia.org/wiki/SYN_cookies" target="_blank">SYN cookies</a> '+
        '用于缓解SYN洪水。</p>'+
        '<p><b>收到</b>-发送SYN Cookie后，它回到我们身边并通过了支票。'+
        '<b>发送</b> - 应用程序无法足够快地接受连接，因此内核无法存储 '+
        '此连接队列中的条目。它没有删除它，而是向客户端发送了一个SYN cookie。 '+
        '<b>失败</b>-从SYN Cookie解码的MSS无效。当这个计数器递增时， '+
        '接收的数据包不会被视为SYN Cookie。</p>'
    },

    'ip.tcpmemorypressures': {
        info: '套接字因非致命内存分配失败而施加内存压力的次数 '+
        '（内核试图通过减少发送缓冲区等来解决这个问题）。'
    },

    'ip.tcpconnaborts': {
        info: '<p>TCP连接中止。</p>'+
        '<p><b>BadData</b> - 当连接在FIN_WAIT1上且内核收到数据包时发生 '+
        '此连接的序列号超过最后一个序列号- '+
        '内核使用RST响应（关闭连接）。 '+
        '<b>UserClosed</b> - 当内核在已关闭的连接上接收数据并 '+
        '用RST回复。 '+
        '<b>NoMemory</b> - 当Orphan插太多（未连接到fd）和 '+
        '内核必须删除连接——有时它会发送RST，有时不会。 '+
        '<b>超时</b> - 当连接超时发生。 '+
        '<b>Linger</b> - 当内核杀死已被应用程序关闭的套接字并 '+
        '徘徊了足够长的时间。 '+
        '<b>失败</b> - 当内核尝试发送 RST 但因没有可用内存而失败时发生。</p>'
    },

    'ip.tcp_functions': {
        title : 'TCP calls',
        info: '对函数<code>tcp_sendmsg</code>、<code>tcp_cleanup_rbuf</code>和<code>tcp_close</code>的调用成功或失败。'
    },

    'ip.total_tcp_bandwidth': {
        title : 'TCP bandwidth',
        info: '由函数<code>tcp_sendmsg</code>和<code>tcp_cleanup_rbuf</code>发送和接收的字节。我们使用<code>tcp_cleanup_rbuf</code>而不是<code>tcp_recvmsg</code>，因为最后一个错过了<code>tcp_read_sock()</code>流量，我们还需要有更多的探针来获得套接字和包大小。'
    },

    'ip.tcp_error': {
        title : 'TCP errors',
        info: '对函数<code>tcp_sendmsg</code>、<code>tcp_cleanup_rbuf</code>和<code>tcp_close</code>的调用失败。'
    },

    'ip.tcp_retransmit': {
        title : 'TCP retransmit',
        info: '通过函数<code>tcp_retransmit_skb</code>重新传输的数据包数量。'
    },

    'ip.udp_functions': {
        title : 'UDP calls',
        info: '对函数<code>udp_sendmsg</code>和<code>udp_recvmsg</code>的调用成功或失败。'
    },

    'ip.total_udp_bandwidth': {
        title : 'UDP bandwidth',
        info: '由函数<code>udp_sendmsg</code>和<code>udp_recvmsg</code>发送和接收的字节。'
    },

    'ip.udp_error': {
        title : 'UDP errors',
        info: '对函数<code>udp_sendmsg</code>和<code>udp_recvmsg</code>的调用失败。'
    },


    'ip.tcp_syn_queue': {
        info: '<p>内核的SYN队列跟踪TCP握手，直到连接完全建立。 ' +
            '当太多传入的TCP连接请求处于半开放状态和服务器时，它会溢出 ' +
            '未配置回退到SYN Cookie。溢出通常由SYN洪水DoS攻击引起。</p>' +
            '<p><b>Drops</b> - 由于SYN队列已满且SYN cookie被禁用，连接数量下降。 ' +
            '<b>Cookies</b> - 由于SYN队列已满而发送的SYN Cookie数量。</p>'
    },

    'ip.tcp_accept_queue': {
        info: '<p>内核的接受队列持有完全建立的TCP连接，等待处理 ' +
            '通过收听应用程序。</p>'+
            '<b>溢出</b> - 因 '+
            '监听应用程序的接收队列已满。 '+
            '<b>Drops</b> - 无法处理的传入连接数量，包括SYN洪水， '+
            '溢出、内存不足、安全问题、没有前往目的地的路线、接收相关的ICMP消息、 '+
            '套接字是广播或多播。</p>'
    },


    // ------------------------------------------------------------------------
    // IPv4

    'ipv4.packets': {
        info: '<p>此主机的IPv4数据包统计。</p>'+
        '<p><b>已收到</b> - IP 层接收的数据包。 '+
        '即使稍后删除数据包，这个计数器也会增加。 '+
        '<b>发送</b>-通过IP层发送的数据包，适用于单播和多播数据包。 '+
        '此计数器不包括<b>转发</b>中计算的任何数据包。 '+
        '<b>转发</b> - 此主机不是其最终IP目的地的输入数据包， '+
        '结果，有人试图找到一条路线将他们转发到最终目的地。 '+
        '在不充当IP网关的主机中，此计数器将仅包括那些 '+
        '<a href="https://en.wikipedia.org/wiki/Source_routing" target="_blank">Source-Routed</a> '+
        '源路由选项处理成功。 '+
        '<b>已交付</b> - 交付到上层协议的数据包，例如TCP、UDP、ICMP等。</p>'
    },

    'ipv4.fragsout': {
        info: '<p><a href="https://en.wikipedia.org/wiki/IPv4#Fragmentation" target="_blank">IPv4碎片</a> '+
        '此系统的统计数据。</p>'+
        '<p><b>好的</b> - 已成功碎片化的数据包。 '+
        '<b>失败</b> - 由于需要碎片化而被丢弃的数据包 '+
        '但不能，例如，由于<i>Don\'t Fragment</i> (DF)标志已设置。 '+
        '<b>创建</b>-因碎片生成的碎片。</p>'
    },

    'ipv4.fragsin': {
        info: '<p><a href="https://en.wikipedia.org/wiki/IPv4#Reassembly" target="_blank">IPv4重新组装</a> '+
        '此系统的统计数据。</p>'+
        '<p><b>好的</b> - 已成功重新组装的数据包。 '+
        '<b>失败</b> - IP 重新组装算法检测到故障。 '+
        '这不一定是被丢弃的IP片段的计数，因为一些算法 '+
        '通过在收到碎片时进行组合，可能会丢失碎片数量。 '+
        '<b>所有</b>-收到需要重新组装的IP片段。</p>'
    },

    'ipv4.errors': {
        info: '<p>丢弃的IPv4数据包的数量。</p>'+
        '<p><b>InDiscards</b>，<b>OutDiscards</b>-选择的入站和出站数据包 '+
        '即使没有出错，也要被丢弃 '+
        '检测到以防止它们交付到更高级别的协议。 '+
        '<b>InHdrErrors</b> - 由于IP头错误而被丢弃的输入数据包，包括 '+
        '校验和不好，版本号不匹配，其他格式错误，超过生存时间， '+
        '在处理他们的IP选项等时发现的错误。 '+
        '<b>OutNoRoutes</b> - 由于找不到路线而被丢弃的数据包 '+
        '将它们传输到目的地。这包括主机无法路由的任何数据包 '+
        '因为它所有的默认网关都关闭了。 '+
        '<b>InAddrErrors</b> - 由于IP地址无效或 '+
        '目标IP地址不是本地地址，并且没有启用IP转发。 '+
        '<b>InUnknownProtos</b> - 由于未知或不支持的协议而被丢弃的输入数据包。</p>'
    },

    'ipv4.icmp': {
        info: '<p>传输的IPv4 ICMP消息的数量。</p>'+
        '<p><b>收到</b>，<b>发送</b>-主机收到并试图发送的ICMP消息。 '+
        '这两个计数器都包含错误。</p>'
    },

    'ipv4.icmp_errors': {
        info: '<p>IPv4 ICMP错误的数量。</p>'+
        '<p><b>InErrors</b> - 收到ICMP消息，但确定存在ICMP特定错误， '+
        '例如，ICMP校验和不好，长度不好等。 '+
        '<b>OutErrors</b> - 此主机由于 '+
        '在ICMP中发现的问题，如缺乏缓冲区。 '+
        '此计数器不包括在ICMP层外发现的错误 '+
        '例如IP无法路由生成的数据报。 '+
        '<b>InCsumErrors</b>-收到校验和不良的ICMP消息。</p>'
    },

    'ipv4.icmpmsg': {
        info: '转让数量 '+
        '<a href="https://www.iana.org/assignments/icmp-parameters/icmp-parameters.xhtml" target="_blank">IPv4 ICMP控制消息</a>。'
    },

    'ipv4.udppackets': {
        info: '传输的UDP数据包的数量。'
    },

    'ipv4.udperrors': {
        info: '<p>在传输UDP数据包时遇到的错误数量。</p>'+
        '<b>RcvbufErrors</b> - 接收缓冲区已满。 '+
        '<b>SndbufErrors</b> - 发送缓冲区已满，没有可用的内核内存，或 '+
        'IP层在尝试发送数据包时报告了错误，并且没有设置错误队列。 '+
        '<b>InErrors</b> - 这是所有错误的聚合计数器，不包括<b>NoPorts</b>。 '+
        '<b>NoPorts</b> - 没有应用程序在目标端口监听。 '+
        '<b>InCsumErrors</b> - 检测到UDP校验和失败。 '+
        '<b>忽略多</b> - 忽略多播数据包。'
    },

    'ipv4.udplite': {
        info: '传输的UDP-Lite数据包的数量。'
    },

    'ipv4.udplite_errors': {
        info: '<p>传输UDP-Lite数据包时遇到的错误数量。</p>'+
        '<b>RcvbufErrors</b> - 接收缓冲区已满。 '+
        '<b>SndbufErrors</b> - 发送缓冲区已满，没有可用的内核内存，或 '+
        'IP层在尝试发送数据包时报告了错误，并且没有设置错误队列。 '+
        '<b>InErrors</b> - 这是所有错误的聚合计数器，不包括<b>NoPorts</b>。 '+
        '<b>NoPorts</b> - 没有应用程序在目标端口监听。 '+
        '<b>InCsumErrors</b> - 检测到UDP校验和失败。 '+
        '<b>忽略多</b> - 忽略多播数据包。'
    },

    'ipv4.tcppackets': {
        info: '<p>TCP层传输的数据包数量。</p>'+
        '</p><b>已收到</b>-已收到的数据包，包括错误接收的数据包， '+
        '例如校验和错误、无效的TCP标头等。 '+
        '<b>发送</b>-发送数据包，不包括重新传输的数据包。 '+
        '但它包括SYN、ACK和RST数据包。</p>'
    },

    'ipv4.tcpsock': {
        info: '当前状态已建立或关闭的TCP连接数量。 '+
        '这是测量时已建立连接的快照 '+
        '（即在同一迭代中建立连接和断开连接不会影响此指标）。'
    },

    'ipv4.tcpopens': {
        info: '<p>TCP连接统计。</p>'+
        '<p><b>活跃</b> - 此主机尝试的传出TCP连接数量。 '+
         '<b>被动</b> - 此主机接受的传入TCP连接数量。</p>'
    },

    'ipv4.tcperrors': {
        info: '<p>TCP错误。</p>'+
        '<p><b>InErrs</b> - 错误地收到 TCP 时段 '+
        '（包括标题太小、校验和错误、序列错误、错误数据包——适用于IPv4和IPv6）。 '+
        '<b>InCsumErrors</b> - 收到校验和错误的TCP段（适用于IPv4和IPv6）。 '+
        '<b>RetransSegs</b> - TCP段重新传输。</p>'
    },

    'ipv4.tcphandshake': {
        info: '<p>TCP握手统计。</p>'+
        '<p><b>EstabResets</b> - 已建立的连接重置 '+
        '（即从 ESTABLISHED 或 CLOSE_WAIT 直接过渡到 CLOSED 的连接）。 '+
        '<b>OutRsts</b> - 发送TCP段，并设置RST标志（适用于IPv4和IPv6）。 '+
        '<b>AttemptFails</b> - TCP连接从任一方向直接过渡的次数 '+
        'SYN_SENT或SYN_RECV到CLOED，加上TCP连接直接过渡的次数 '+
        '从SYN_RECV到监听。 '+
        '<b>SynRetrans</b> - 显示新的出站 TCP 连接的重试， '+
        '这可能表明远程主机上的一般连接问题或积压。</p>'
    },

    'ipv4.sockstat_sockets': {
        info: '所有使用的套接字总数 '+
        '<a href="https://man7.org/linux/man-pages/man7/address_families.7.html" target="_blank">地址家庭</a>'+
        '在这个系统中。'
    },

    'ipv4.sockstat_tcp_sockets': {
        info: '<p>系统中某些TCP套接字的数量 '+
        '<a href="https://en.wikipedia.org/wiki/Transmission_Control_Protocol#Protocol_operation" target="_blank">states</a>。</p>'+
        '<p><b>Alloc</b> - 处于任何 TCP 状态。 '+
        '<b>Orphan</b> - 在任何用户进程中不再连接到套接字描述符， '+
        '但为了完成传输协议，内核仍然需要保持状态。 '+
        '<b>InUse</b> - 处于任何 TCP 状态，TIME-WAIT 和 CLOSED 除外。 '+
        '<b>TimeWait</b> - 处于TIME-WAIT状态。</p>'
    },

    'ipv4.sockstat_tcp_mem': {
        info: '分配的TCP套接字使用的内存量。'
    },

    'ipv4.sockstat_udp_sockets': {
        info: '使用UDP套接字的数量。'
    },

    'ipv4.sockstat_udp_mem': {
        info: '分配的UDP套接字使用的内存量。'
    },

    'ipv4.sockstat_udplite_sockets': {
        info: '使用UDP-Lite套接字的数量。'
    },

    'ipv4.sockstat_raw_sockets': {
        info: '使用<a href="https://en.wikipedia.org/wiki/Network_socket#Types" target="_blank">原始套接字的数量</a>。'
    },

    'ipv4.sockstat_frag_sockets': {
        info: '散列表中用于数据包重新组装的条目数量。'
    },

    'ipv4.sockstat_frag_mem': {
        info: '用于数据包重新组装的内存量。'
    },

    // ------------------------------------------------------------------------
    // IPv6

    'ipv6.packets': {
        info: '<p>此主机的IPv6数据包统计信息。</p>'+
        '<p><b>已收到</b> - IP 层接收的数据包。 '+
        '即使稍后删除数据包，这个计数器也会增加。 '+
        '<b>发送</b>-通过IP层发送的数据包，适用于单播和多播数据包。 '+
        '此计数器不包括<b>转发</b>中计算的任何数据包。 '+
        '<b>转发</b> - 此主机不是其最终IP目的地的输入数据包， '+
        '结果，有人试图找到一条路线将他们转发到最终目的地。 '+
        '在不充当IP网关的主机中，此计数器将仅包括那些 '+
        '<a href="https://en.wikipedia.org/wiki/Source_routing" target="_blank">Source-Routed</a> '+
        '源路由选项处理成功。 '+
        '<b>交付</b> - 交付到上层协议的数据包，例如TCP、UDP、ICMP等。</p>'
    },

    'ipv6.fragsout': {
        info: '<p><a href="https://en.wikipedia.org/wiki/IP_fragmentation" target="_blank">IPv6碎片</a>'+
        '此系统的统计数据。</p>'+
        '<p><b>好的</b> - 已成功碎片化的数据包。 '+
        '<b>失败</b> - 由于需要碎片化而被丢弃的数据包 '+
        '但不能，例如，由于<i>Don\'t Fragment</i> (DF)标志已设置。 '+
        '<b>所有</b>-碎片生成的碎片。</p>'
    },

    'ipv6.fragsin': {
        info: '<p><a href="https://en.wikipedia.org/wiki/IP_fragmentation" target="_blank">IPv6重新组装</a> '+
        '此系统的统计数据。</p>'+
        '<p><b>好的</b> - 已成功重新组装的数据包。 '+
        '<b>失败</b> - IP 重新组装算法检测到故障。 '+
        '这不一定是被丢弃的IP片段的计数，因为一些算法 '+
        '通过在收到碎片时进行组合，可能会丢失碎片数量。 '+
        '<b>超时</b> - 检测到重新组装超时。 '+
        '<b>所有</b>-收到需要重新组装的IP片段。</p>'
    },

    'ipv6.errors': {
        info: '<p>丢弃的IPv6数据包的数量。</p>'+
        '<p><b>InDiscards</b>，<b>OutDiscards</b> - 即使 '+
        '没有检测到错误来阻止它们交付到更高级别的协议。 '+
        '<b>InHdrErrors</b> - IP头中的错误，包括糟糕的校验和、版本号不匹配、 '+
        '其他格式错误、超出使用时间等。 '+
        '<b>InAddrErrors</b> - 无效的IP地址或目标IP地址不是本地地址，并且 '+
        '未启用IP转发。 '+
        '<b>InUnknownProtos</b> - 未知或不支持的协议。 '+
        '<b>InTooBigErrors</b> - 大小超过链接MTU。 '+
        '<b>InTruncatedPkts</b> - 数据包框架没有携带足够的数据。 '+
        '<b>InNoRoutes</b> - 转发时找不到任何路线。 '+
        '<b>OutNoRoutes</b> - 找不到此主机生成的数据包的路由。</p>'
    },

    'ipv6.udppackets': {
        info: '传输的UDP数据包的数量。'
    },

    'ipv6.udperrors': {
        info: '<p>在传输UDP数据包时遇到的错误数量。</p>'+
        '<b>RcvbufErrors</b> - 接收缓冲区已满。 '+
        '<b>SndbufErrors</b> - 发送缓冲区已满，没有可用的内核内存，或 '+
        'IP层在尝试发送数据包时报告了错误，并且没有设置错误队列。 '+
        '<b>InErrors</b> - 这是所有错误的聚合计数器，不包括<b>NoPorts</b>。 '+
        '<b>NoPorts</b> - 没有应用程序在目标端口监听。 '+
        '<b>InCsumErrors</b> - 检测到UDP校验和失败。 '+
        '<b>忽略多</b> - 忽略多播数据包。'
    },

    'ipv6.udplitepackets': {
        info: '传输的UDP-Lite数据包的数量。'
    },

    'ipv6.udpliteerrors': {
        info: '<p>传输UDP-Lite数据包时遇到的错误数量。</p>'+
        '<p><b>RcvbufErrors</b> - 接收缓冲区已满。 '+
        '<b>SndbufErrors</b> - 发送缓冲区已满，没有可用的内核内存，或 '+
        'IP层在尝试发送数据包时报告了错误，并且没有设置错误队列。 '+
        '<b>InErrors</b> - 这是所有错误的聚合计数器，不包括<b>NoPorts</b>。 '+
        '<b>NoPorts</b> - 没有应用程序在目标端口监听。 '+
        '<b>InCsumErrors</b> - 检测到UDP校验和失败。</p>'
    },

    'ipv6.mcast': {
        info: 'IPv6组播总流量。'
    },

    'ipv6.bcast': {
        info: 'IPv6广播总流量。'
    },

    'ipv6.mcastpkts': {
        info: '传输的IPv6组播数据包总数。'
    },

    'ipv6.icmp': {
        info: '<p>传输的ICMPv6消息数量。</p>'+
        '<p><b>收到</b>，<b>发送</b>-主机收到并试图发送的ICMP消息。 '+
        '这两个计数器都包含错误。</p>'
    },

    'ipv6.icmpredir': {
        info: '传输的ICMPv6重定向消息的数量。'+
        '这些信息通知主机更新其路由信息（在替代路由上发送数据包）。'
    },

    'ipv6.icmpechos': {
        info: 'ICMPv6回声消息的数量。'
    },

    'ipv6.icmperrors': {
        info: '<p>ICMPv6错误的数量和 '+
        '<a href="https://www.rfc-editor.org/rfc/rfc4443.html#section-3" target="_blank">错误消息</a>。</p>'+
        '<p><b>InErrors</b>，<b>OutErrors</b> - 糟糕的ICMP消息（错误的ICMP校验和，糟糕的长度等）。 '+
        '<b>InCsumErrors</b> - 校验和错误。</p>'
    },

    'ipv6.groupmemb': {
        info: '<p>传输的ICMPv6组成员消息的数量。</p>'+
        '<p>多播路由器发送组成员查询消息，以了解哪些组在其每个组上都有成员 '+
        '连接物理网络。主机计算机通过为每个 '+
        '主机加入的多播组。主机计算机也可以在以下情况下发送组成员报告 '+
        '它加入了一个新的多播组。 '+
        '当主机离开组播组时，会发送组成员减少消息。</p>'
    },

    'ipv6.icmprouter': {
        info: '<p>转让ICMPv6的数量 '+
        '<a href="https://en.wikipedia.org/wiki/Neighbor_Discovery_Protocol" target="_blank">路由器发现</a>消息。</p>'+
        '<p>路由器<b>招标</b>消息从计算机主机发送到局域网上的任何路由器 '+
        '要求他们在网络上做广告。 '+
        '路由器<b>广告</b>消息由局域网上的路由器发送，以宣布其IP地址 '+
        '可供路由。</p>'
    },

    'ipv6.icmpneighbor': {
        info: '<p>转让ICMPv6的数量 '+
        '<a href="https://en.wikipedia.org/wiki/Neighbor_Discovery_Protocol" target="_blank">邻居发现</a>消息。</p>'+
        '<p>邻居<b>请求</b>被节点用于确定链接层地址 '+
        '邻居，或验证邻居是否仍然可以通过缓存的链接层地址访问。 '+
        '邻居<b>广告</b>被节点用于响应邻居邀约消息。</p>'
    },

    'ipv6.icmpmldv2': {
        info: '转让ICMPv6的数量'+
        '<a href="https://en.wikipedia.org/wiki/Multicast_Listener_Discovery" target="_blank">多播监听器发现</a>（MLD）消息。'
    },

    'ipv6.icmptypes': {
        info: '传输的ICMPv6消息数量 '+
        '<a href="https://en.wikipedia.org/wiki/Internet_Control_Message_Protocol_for_IPv6#Types" target="_blank">某些类型</a>。'
    },

    'ipv6.ect': {
        info: '<p>系统中设置了ECN位的接收IPv6数据包总数。</p>'+
        '<p><b>CEP</b> - 遇到拥堵。 '+
        '<b>NoECTP</b> - 不支持ECN的运输。 '+
        '<b>ECTP0</b>和<b>ECTP1</b>-支持ECN的传输。</p>'
    },

    'ipv6.sockstat6_tcp_sockets': {
        info: '任何TCP套接字的数量 '+
        '<a href="https://en.wikipedia.org/wiki/Transmission_Control_Protocol#Protocol_operation" target="_blank">state</a>， '+
        '不包括时间等待和关闭。'
    },

    'ipv6.sockstat6_udp_sockets': {
        info: '使用UDP套接字的数量。'
    },

    'ipv6.sockstat6_udplite_sockets': {
        info: '使用UDP-Lite套接字的数量。'
    },

    'ipv6.sockstat6_raw_sockets': {
        info: '使用<a href="https://en.wikipedia.org/wiki/Network_socket#Types" target="_blank">原始套接字的数量</a>。'
    },

    'ipv6.sockstat6_frag_sockets': {
        info: '散列表中用于数据包重新组装的条目数量。'
    },


    // ------------------------------------------------------------------------
    // SCTP

    'sctp.established': {
        info: '当前状态为的关联数量 '+
        '已建立、已关闭接收或即将关闭。'
    },

    'sctp.transitions': {
        info: '<p>关联在州之间直接过渡的次数。</p>'+
        '<p><b>活跃</b> - 从COOKIE-ECHOED到已建立。上层发起了关联尝试。 '+
        '<b>被动</b> - 从关闭到已建立。远程端点发起了关联尝试。 '+
        '<b>中止</b>-使用原始ABORT从任何状态到关闭。不光彩地终止协会。 '+
        '<b>Shutdown</b> - 从SHUTDOWN-SENT或SHUTDOWN-ACK-SENT到CLOSHED。优雅地终止协会。</p>'
    },

    'sctp.packets': {
        info: '<p>传输的SCTP数据包数量。</p>'+
        '<p><b>已收到</b> - 包含重复的数据包。 '+
        '<b>发送</b>-包括重新传输的数据块。</p>'
    },

    'sctp.packet_errors': {
        info: '<p>接收SCTP数据包时遇到的错误数量。</p>'+
        '<p><b>无效</b> - 接收方无法识别适当关联的数据包。 '+
        '<b>校验和</b> - 校验和无效的数据包。</p>'
    },

    'sctp.fragmentation': {
        info: '<p>碎片化和重新组装的SCTP消息的数量。</p>'+
        '<p><b>重新组装</b> - 重新组装用户消息，在转换为数据块后。 '+
        '<b>碎片化</b> - 由于MTU而不得不碎片化的用户消息。</p>'
    },

    'sctp.chunks': {
        info: '传输控件、有序和无顺序数据块的数量。 '+
        '不包括重播和重复。'
    },

    // ------------------------------------------------------------------------
    // Netfilter Connection Tracker

    'netfilter.conntrack_sockets': {
        info: 'Conntrack表中的条目数。'
    },

    'netfilter.conntrack_new': {
        info: '<p>数据包跟踪统计信息。<b>新</b>（自v4.9以来）和<b>忽略</b>（自v5.10以来）在最新内核中被硬编码为零。</p>'+
        '<p><b>新</b> - 添加以前意想不到的条目。 '+
        '<b>忽略</b>-已连接到conntrack条目的数据包。 '+
        '<b>无效</b> - 看到无法跟踪的数据包。</p>'
    },

    'netfilter.conntrack_changes': {
        info: '<p>conntrack表格中的更改数量。</p>'+
        '<p><b>插入</b>，<b>删除</b>-跟踪插入或删除的条目。 '+
        '<b>删除列表</b> - 跟踪被列入垂死列表的条目。</p>'
    },

    'netfilter.conntrack_expect': {
        info: '<p>“预期”表中的事件数量。 '+
        '连接跟踪预期是用于“预期”与现有连接相关连接的机制。 '+
        '期望是预计在一段时间内发生的连接。</p>'+
        '<p><b>创建</b>，<b>删除</b>-跟踪插入或删除的条目。 '+
        '<b>新</b> - 在对它们的预期已经存在后添加了conntrack条目。</p>'
    },

    'netfilter.conntrack_search': {
        info: '<p>Conntrack表查找统计信息。</p>'+
        '<p><b>Searched</b> - 进行conntrack 表格查找。 '+
        '<b>重新启动</b>-由于散列调整大小而不得不重新启动的conntrack表查找。 '+
        '<b>找到</b>-成功跟踪表格查找。</p>'
    },

    'netfilter.conntrack_errors': {
        info: '<p>Conntrack错误。</p>'+
        '<p><b>IcmpError</b> - 由于错误情况无法跟踪的数据包。 '+
        '<b>插入失败</b> - 尝试插入列表但失败的条目 '+
        '（如果同一条目已经存在，则可能）。 '+
        '<b>Drop</b> - 由于conntrack失败而删除的数据包。 '+
        '要么新的conntrack条目分配失败，要么协议帮助程序删除数据包。 '+
        '<b>EarlyDrop</b> - 如果达到最大表大小，请删除conntrack条目，为新条目腾出空间。</p>'
    },

    'netfilter.synproxy_syn_received': {
        info: '从客户端收到的初始TCP SYN数据包的数量。'
    },

    'netfilter.synproxy_conn_reopened': {
        info: '直接从TIME-WAIT状态由新的TCP SYN数据包重新打开连接的数量。'
    },

    'netfilter.synproxy_cookies': {
        info: '<p>SYNPROXY Cookie统计。</p>'+
        '<p><b>有效</b>，<b>无效</b>-从客户端收到的TCP ACK数据包中的cookie验证结果。 '+
        '<b>重新传输</b> - TCP SYN数据包重新传输到服务器。 '+
        '当客户端重复TCP ACK且与服务器的连接尚未建立时，就会发生这种情况。</p>'
    },

    // ------------------------------------------------------------------------
    // APPS (Applications, Groups, Users)

    // APPS cpu
    'apps.cpu': {
        info: 'CPU总利用率（所有内核）。它包括用户、系统和客人时间。'
    },
    'groups.cpu': {
        info: 'CPU总利用率（所有内核）。它包括用户、系统和客人时间。'
    },
    'users.cpu': {
        info: 'CPU总利用率（所有内核）。它包括用户、系统和客人时间。'
    },

    'apps.cpu_user': {
        info: 'CPU 忙于执行代码所需的时间 '+
        '<a href="https://en.wikipedia.org/wiki/CPU_modes#Mode_types" target="_blank">用户模式</a>（所有核心）。'
    },
    'groups.cpu_user': {
        info: 'CPU 忙于执行代码所需的时间 '+
        '<a href="https://en.wikipedia.org/wiki/CPU_modes#Mode_types" target="_blank">用户模式</a>（所有核心）。'
    },
    'users.cpu_user': {
        info: 'TCPU忙于执行代码的大量时间 '+
        '<a href="https://en.wikipedia.org/wiki/CPU_modes#Mode_types" target="_blank">用户模式</a>（所有核心）。'
    },

    'apps.cpu_system': {
        info: 'CPU 忙于执行代码所需的时间 '+
        '<a href="https://en.wikipedia.org/wiki/CPU_modes#Mode_types" target="_blank">内核模式</a>（所有内核）。'
    },
    'groups.cpu_system': {
        info: 'CPU 忙于执行代码所需的时间 '+
        '<a href="https://en.wikipedia.org/wiki/CPU_modes#Mode_types" target="_blank">内核模式</a>（所有内核）。'
    },
    'users.cpu_system': {
        info: 'CPU 忙于执行代码所需的时间 '+
        '<a href="https://en.wikipedia.org/wiki/CPU_modes#Mode_types" target="_blank">内核模式</a>（所有内核）。'
    },

    'apps.cpu_guest': {
        info: '为来宾操作系统（所有内核）运行虚拟CPU所花费的时间。'
    },
    'groups.cpu_guest': {
        info: '为来宾操作系统（所有内核）运行虚拟CPU所花费的时间。'
    },
    'users.cpu_guest': {
        info: '为来宾操作系统（所有内核）运行虚拟CPU所花费的时间。'
    },

    // APPS disk
    'apps.preads': {
        info: '从存储层读取的数据量。 '+
        '需要实际的物理磁盘I/O。'
    },
    'groups.preads': {
        info: '从存储层读取的数据量。 '+
        '需要实际的物理磁盘I/O。'
    },
    'users.preads': {
        info: '从存储层读取的数据量。 '+
        '需要实际的物理磁盘I/O。'
    },

    'apps.pwrites': {
        info: '已写入存储层的数据量。 '+
        '需要实际的物理磁盘I/O。'
    },
    'groups.pwrites': {
        info: '已写入存储层的数据量。 '+
        '需要实际的物理磁盘I/O。'
    },
    'users.pwrites': {
        info: '已写入存储层的数据量。 '+
        '需要实际的物理磁盘I/O。'
    },

    'apps.lreads': {
        info: '从存储层读取的数据量。 '+
        '它包括I/O终端等内容，不受是否或 '+
        '不是实际的物理磁盘I/O是必需的 '+
        '（读数可能已从pagecache中满意）。'
    },
    'groups.lreads': {
        info: '从存储层读取的数据量。 '+
        '它包括I/O终端等内容，不受是否或 '+
        '不是实际的物理磁盘I/O是必需的 '+
        '（读数可能已从pagecache中满意）。'
    },
    'users.lreads': {
        info: '从存储层读取的数据量。 '+
        '它包括I/O终端等内容，不受是否或 '+
        '不是实际的物理磁盘I/O是必需的 '+
        '（读数可能已从pagecache中满意）。'
    },

    'apps.lwrites': {
        info: '已写入或应写入存储层的数据量。 '+
        '它包括I/O终端等内容，不受是否或 '+
        '不是需要实际的物理磁盘I/O。'
    },
    'groups.lwrites': {
        info: '已写入或应写入存储层的数据量。 '+
        '它包括I/O终端等内容，不受是否或 '+
        '不是需要实际的物理磁盘I/O。'
    },
    'users.lwrites': {
        info: '已写入或应写入存储层的数据量。 '+
        '它包括I/O终端等内容，不受是否或 '+
        '不是需要实际的物理磁盘I/O。'
    },

    'apps.files': {
        info: '打开的文件和目录的数量。'
    },
    'groups.files': {
        info: '打开的文件和目录的数量。'
    },
    'users.files': {
        info: '打开的文件和目录的数量。'
    },

    // APPS mem
    'apps.mem': {
        info: '应用程序使用的真实内存（RAM）。这不包括共享内存。'
    },
    'groups.mem': {
        info: '每个用户组使用的真实内存（RAM）。这不包括共享内存。'
    },
    'users.mem': {
        info: '每个用户组使用的真实内存（RAM）。这不包括共享内存。'
    },

    'apps.vmem': {
        info: '由应用程序分配的虚拟内存。 '+
        '有关更多信息，请查看<a href="https://github.com/netdata/netdata/tree/master/daemon#virtual-memory" target="_blank">本文</a>。'
    },
    'groups.vmem': {
        info: '自Netdata重新启动以来，每个用户组分配的虚拟内存。有关更多信息，请查看<a href="https://github.com/netdata/netdata/tree/master/daemon#virtual-memory" target="_blank">本文</a>。'
    },
    'users.vmem': {
        info: '自Netdata重新启动以来，每个用户组分配的虚拟内存。有关更多信息，请查看<a href="https://github.com/netdata/netdata/tree/master/daemon#virtual-memory" target="_blank">本文</a>。'
    },

    'apps.minor_faults': {
        info: '<a href="https://en.wikipedia.org/wiki/Page_fault#Minor" target="_blank">小故障</a>的数量 '+
        '不需要从磁盘加载内存页面。 '+
        '当一个进程需要内存中的数据并分配给另一个进程时，会出现轻微的页面故障。 '+
        '他们在多个进程之间共享内存页面—— '+
        '无需将其他数据从磁盘读取到内存。'
    },
    'groups.minor_faults': {
        info: '<a href="https://en.wikipedia.org/wiki/Page_fault#Minor" target="_blank">小故障</a>的数量 '+
        '不需要从磁盘加载内存页面。 '+
        '当一个进程需要内存中的数据并分配给另一个进程时，会出现轻微的页面故障。 '+
        '他们在多个进程之间共享内存页面—— '+
        '无需将其他数据从磁盘读取到内存。'
    },
    'users.minor_faults': {
        info: '<a href="https://en.wikipedia.org/wiki/Page_fault#Minor" target="_blank">小故障</a>的数量 '+
        '不需要从磁盘加载内存页面。 '+
        '当一个进程需要内存中的数据并分配给另一个进程时，会出现轻微的页面故障。 '+
        '他们在多个进程之间共享内存页面——'+
        '无需将其他数据从磁盘读取到内存。'
    },

    // APPS processes
    'apps.threads': {
        info: '<a href="https://en.wikipedia.org/wiki/Thread_(computing)" target="_blank">线程</a>的数量。'
    },
    'groups.threads': {
        info: '<a href="https://en.wikipedia.org/wiki/Thread_(computing)" target="_blank">线程</a>的数量。'
    },
    'users.threads': {
        info: '<a href="https://en.wikipedia.org/wiki/Thread_(computing)" target="_blank">线程</a>的数量。'
    },

    'apps.processes': {
        info: '<a href="https://en.wikipedia.org/wiki/Process_(computing)" target="_blank">进程</a>的数量。'
    },
    'groups.processes': {
        info: '<a href="https://en.wikipedia.org/wiki/Process_(computing)" target="_blank">进程</a>的数量。'
    },
    'users.processes': {
        info: '<a href="https://en.wikipedia.org/wiki/Process_(computing)" target="_blank">进程</a>的数量。'
    },

    'apps.uptime': {
        info: '组中至少一个进程运行的时间段。'
    },
    'groups.uptime': {
        info: '组中至少一个进程运行的时间段。'
    },
    'users.uptime': {
        info: '组中至少一个进程运行的时间段。'
    },

    'apps.uptime_min': {
        info: '组中进程中最短的正常运行时间。'
    },
    'groups.uptime_min': {
        info: '组中进程中最短的正常运行时间。'
    },
    'users.uptime_min': {
        info: '组中进程中最短的正常运行时间。'
    },

    'apps.uptime_avg': {
        info: '组中进程的平均正常运行时间。'
    },
    'groups.uptime_avg': {
        info: '组中进程的平均正常运行时间。'
    },
    'users.uptime_avg': {
        info: '组中进程的平均正常运行时间。'
    },

    'apps.uptime_max': {
        info: '组中进程中最长的正常运行时间。'
    },
    'groups.uptime_max': {
        info: '组中进程中最长的正常运行时间。'
    },
    'users.uptime_max': {
        info: '组中进程中最长的正常运行时间。'
    },

    'apps.pipes': {
        info: '开放数量 '+
        '<a href="https://en.wikipedia.org/wiki/Anonymous_pipe#Unix" target="_blank">管道</a>。 '+
        '管道是一种单向数据通道，可用于进程间通信。'
    },
    'groups.pipes': {
        info: '开放数量 '+
        '<a href="https://en.wikipedia.org/wiki/Anonymous_pipe#Unix" target="_blank">管道</a>。 '+
        '管道是一种单向数据通道，可用于进程间通信。'
    },
    'users.pipes': {
        info: '开放数量 '+
        '<a href="https://en.wikipedia.org/wiki/Anonymous_pipe#Unix" target="_blank">管道</a>。 '+
        '管道是一种单向数据通道，可用于进程间通信。'
    },

    // APPS swap
    'apps.swap': {
        info: '匿名私人页面交换虚拟内存的数量。 '+
        '这不包括共享交换内存。'
    },
    'groups.swap': {
        info: '匿名私人页面交换虚拟内存的数量。 '+
        '这不包括共享交换内存。'
    },
    'users.swap': {
        info: '匿名私人页面交换虚拟内存的数量。 '+
        '这不包括共享交换内存。'
    },

    'apps.major_faults': {
        info: '<a href="https://en.wikipedia.org/wiki/Page_fault#Major" target="_blank">重大故障</a>的数量 '+
        '需要从磁盘加载内存页面。 '+
        '由于RAM中缺少所需的页面，会出现重大页面故障。 '+
        '当流程开始或需要读取其他数据时，它们是正常的 '+
        '在这些情况下，不表示问题状况。 '+
        '然而，一个主要的页面错误也可能是阅读已写出的内存页面的结果 '+
        '交换文件，这可能表明内存短缺。'
    },
    'groups.major_faults': {
        info: '<a href="https://en.wikipedia.org/wiki/Page_fault#Major" target="_blank">重大故障</a>的数量 '+
        '需要从磁盘加载内存页面。 '+
        '由于RAM中缺少所需的页面，会出现重大页面故障。 '+
        '当流程开始或需要读取其他数据时，它们是正常的 '+
        '在这些情况下，不表示问题状况。 '+
        '然而，一个主要的页面错误也可能是阅读已写出的内存页面的结果 '+
        '交换文件，这可能表明内存短缺。'
    },
    'users.major_faults': {
        info: '<a href="https://en.wikipedia.org/wiki/Page_fault#Major" target="_blank">重大故障</a>的数量 '+
        '需要从磁盘加载内存页面。 '+
        '由于RAM中缺少所需的页面，会出现重大页面故障。 '+
        '当流程开始或需要读取其他数据时，它们是正常的 '+
        '在这些情况下，不表示问题状况。 '+
        '然而，一个主要的页面错误也可能是阅读已写出的内存页面的结果 '+
        '交换文件，这可能表明内存短缺。'
    },

    // APPS net
    'apps.sockets': {
        info: '打开sockets的数量。 '+
        'sockets是一种在服务器上运行的程序之间实现进程间通信的方式， '+
        '或在不同服务器上运行的程序之间。这包括网络和UNIX sockets。'
    },
    'groups.sockets': {
        info: '打开sockets的数量。 '+
        'sockets是一种在服务器上运行的程序之间实现进程间通信的方式， '+
        '或在不同服务器上运行的程序之间。这包括网络和UNIX sockets。'
    },
    'users.sockets': {
        info: '打开sockets的数量 '+
        'sockets是一种在服务器上运行的程序之间实现进程间通信的方式， '+
        '或在不同服务器上运行的程序之间。这包括网络和UNIX sockets。'
    },

   // Apps eBPF stuff

    'apps.file_open': {
        info: '对内部函数<code>do_sys_open</code>的调用（对于比<code>5.5.19</code>更新的内核，我们在<code>do_sys_openat2</code>中添加一个kprobe。），这是从' +
            ' <a href="https://www.man7.org/linux/man-pages/man2/open.2.html" target="_blank">open(2)</a> ' +
            ' and <a href="https://www.man7.org/linux/man-pages/man2/openat.2.html" target="_blank">openat(2)</a>. '
    },

    'apps.file_open_error': {
        info: '对内部函数<code>do_sys_open</code>的调用失败（对于比<code>5.5.19</code>更新的内核，我们向<code>do_sys_openat2</code>添加了一个kprobe。）。'
    },

    'apps.file_closed': {
        info: '根据内核版本调用内部函数<a href="https://elixir.bootlin.com/linux/v5.10/source/fs/file.c#L665" target="_blank">__close_fd</a>或<a href="https://elixir.bootlin.com/linux/v5.11/source/fs/file.c#L617" target="_blank">close_fd</a>，该版本调用' +
            ' <a href="https://www.man7.org/linux/man-pages/man2/close.2.html" target="_blank">close(2)</a>. '
    },

    'apps.file_close_error': {
        info: '根据内核版本，对内部函数<a href="https://elixir.bootlin.com/linux/v5.10/source/fs/file.c#L665" target="_blank">__close_fd</a>或<a href="https://elixir.bootlin.com/linux/v5.11/source/fs/file.c#L617" target="_blank">close_fd</a>的调用失败。'
    },

    'apps.file_deleted': {
        info: '调用函数<a href="https://www.kernel.org/doc/htmldocs/filesystems/API-vfs-unlink.html" target="_blank">vfs_unlink</a>。此图表没有显示从文件系统中删除文件的所有事件，因为文件系统可以创建自己的功能来删除文件。'
    },

    'apps.vfs_write_call': {
        info: '成功调用了函数<a href="https://topic.alibabacloud.com/a/kernel-state-file-operation-__-work-information-kernel_8_8_20287135.html" target="_blank">vfs_write</a>。如果此图表使用其他功能将数据存储在磁盘上，则可能不会显示所有文件系统事件。'
    },

    'apps.vfs_write_error': {
        info: '对函数<a href="https://topic.alibabacloud.com/a/kernel-state-file-operation-__-work-information-kernel_8_8_20287135.html" target="_blank">vfs_write</a>的调用失败。如果此图表使用其他功能将数据存储在磁盘上，则可能不会显示所有文件系统事件。'
    },

    'apps.vfs_read_call': {
        info: '成功调用函数<a href="https://topic.alibabacloud.com/a/kernel-state-file-operation-__-work-information-kernel_8_8_20287135.html" target="_blank">vfs_read</a>。如果此图表使用其他功能将数据存储在磁盘上，则可能不会显示所有文件系统事件。'
    },

    'apps.vfs_read_error': {
        info: '对函数<a href="https://topic.alibabacloud.com/a/kernel-state-file-operation-__-work-information-kernel_8_8_20287135.html" target="_blank">vfs_read</a>的调用失败。如果此图表使用其他功能将数据存储在磁盘上，则可能不会显示所有文件系统事件。'
    },

    'apps.vfs_write_bytes': {
        info: '使用函数<a href="https://topic.alibabacloud.com/a/kernel-state-file-operation-__-work-information-kernel_8_8_20287135.html" target="_blank">vfs_write</a>成功编写的字节总数。'
    },

    'apps.vfs_read_bytes': {
        info: '使用函数<a href="https://topic.alibabacloud.com/a/kernel-state-file-operation-__-work-information-kernel_8_8_20287135.html" target="_blank">vfs_read</a>成功读取的总字节总数。'
    },

    'apps.process_create': {
        info: '调用<a href="https://programming.vip/docs/the-execution-procedure-of-do_fork-function-in-linux.html" target="_blank">do_fork</a>，或者<code>kernel_clone</code>（如果您运行的内核更新于5.16），以创建一个新任务，这是用于定义内核内进程和任务的常用名称。此图表由eBPF插件提供。'
    },

    'apps.thread_create': {
        info: '调用<a href="https://programming.vip/docs/the-execution-procedure-of-do_fork-function-in-linux.html" target="_blank">do_fork</a>，或者<code>kernel_clone</code>（如果您运行的内核更新于5.16），以创建一个新任务，这是用于定义内核内进程和任务的常用名称。Netdata标识监控跟踪点<code>sched_process_fork</code>的线程。此图表由eBPF插件提供。'
    },

    'apps.task_exit': {
        info: '对负责关闭的函数的调用（<a href="https://www.informit.com/articles/article.aspx?p=370047&seqNum=4" target="_blank">do_exit</a>)任务。此图表由eBPF插件提供。'
    },

    'apps.task_close': {
        info: '对负责发布功能的调用（<a href="https://www.informit.com/articles/article.aspx?p=370047&seqNum=4" target="_blank">release_task</a>)任务。此图表由eBPF插件提供。'
    },

    'apps.task_error': {
        info: '创建新进程或线程的错误数量。此图表由eBPF插件提供。'
    },

    'apps.total_bandwidth_sent': {
        info: '由函数<code>tcp_sendmsg</code>和<code>udp_sendmsg</code>发送的字节。'
    },

    'apps.total_bandwidth_recv': {
        info: '函数<code>tcp_cleanup_rbuf</code>和<code>udp_recvmsg</code>收到的字节。我们使用<code>tcp_cleanup_rbuf</code>而不是<code>tcp_recvmsg</code>，因为这最后错过了<code>tcp_read_sock()</code>流量，我们还需要有更多的探针来获取套接字和包大小。'
    },

    'apps.bandwidth_tcp_send': {
        info: '函数<code>tcp_sendmsg</code>用于收集从TCP连接发送的字节数。'
    },

    'apps.bandwidth_tcp_recv': {
        info: '<code>tcp_cleanup_rbuf</code>函数用于收集从TCP连接接收的字节数。'
    },

    'apps.bandwidth_tcp_retransmit': {
        info: '当主机没有收到发送的数据包的预期返回时，将调用函数<code>tcp_retransmit_skb</code>。'
    },

    'apps.bandwidth_udp_send': {
        info: '<code>udp_sendmsg</code>函数用于收集从UDP连接发送的字节数。'
    },

    'apps.bandwidth_udp_recv': {
        info: '函数<code>udp_recvmsg</code>用于收集从UDP连接接收的字节数。'
    },

    'apps.dc_hit_ratio': {
        info: '目录缓存中存在的文件访问百分比。100%表示访问的每个文件都存在于目录缓存中。如果目录缓存中不存在文件1）它们不存在于文件系统中，2）以前没有访问过文件。阅读更多关于<a href="https://www.kernel.org/doc/htmldocs/filesystems/the_directory_cache.html" target="_blank">目录缓存</a>的信息。Netdata还在<a href="#menu_filesystem_submenu_directory_cache__eBPF_">文件系统子菜单</a>中对这些图表进行了摘要。'
    },

    'apps.dc_reference': {
        info: '文件访问计数器。<code>引用</code>是文件访问时，请参阅<code>filesystem.dc_reference</code>图表以了解更多上下文。阅读更多关于<a href="https://www.kernel.org/doc/htmldocs/filesystems/the_directory_cache.html" target="_blank">目录缓存</a>的信息。'
    },

    'apps.dc_not_cache': {
        info: '文件访问计数器。<code>慢</code>是指有文件访问且目录缓存中不存在文件时，请参阅<code>filesystem.dc_reference</code>图表以了解更多上下文。阅读更多关于<a href="https://www.kernel.org/doc/htmldocs/filesystems/the_directory_cache.html" target="_blank">目录缓存</a>的信息。'
    },

    'apps.dc_not_found': {
        info: '文件访问计数器。<code>Miss</code>是当有文件访问且文件系统中找不到文件时，请参阅<code>filesystem.dc_reference</code>图表以获取更多上下文。阅读更多关于<a href="https://www.kernel.org/doc/htmldocs/filesystems/the_directory_cache.html" target="_blank">目录缓存</a>的信息。'
    },

    // ------------------------------------------------------------------------
    // NETWORK QoS

    'tc.qos': {
        heads: [
            function (os, id) {
                void (os);

                if (id.match(/.*-ifb$/))
                    return netdataDashboard.gaugeChart('Inbound', '12%', '', '#5555AA');
                else
                    return netdataDashboard.gaugeChart('Outbound', '12%', '', '#AA9900');
            }
        ]
    },

    // ------------------------------------------------------------------------
    // NETWORK INTERFACES

    'net.net': {
        mainheads: [
            function (os, id) {
                void (os);
                if (id.match(/^cgroup_.*/)) {
                    var iface;
                    try {
                        iface = ' ' + id.substring(id.lastIndexOf('.net_') + 5, id.length);
                    } catch (e) {
                        iface = '';
                    }
                    return netdataDashboard.gaugeChart('Received' + iface, '12%', 'received');
                } else
                    return '';
            },
            function (os, id) {
                void (os);
                if (id.match(/^cgroup_.*/)) {
                    var iface;
                    try {
                        iface = ' ' + id.substring(id.lastIndexOf('.net_') + 5, id.length);
                    } catch (e) {
                        iface = '';
                    }
                    return netdataDashboard.gaugeChart('Sent' + iface, '12%', 'sent');
                } else
                    return '';
            }
        ],
        heads: [
            function (os, id) {
                void (os);
                if (!id.match(/^cgroup_.*/))
                    return netdataDashboard.gaugeChart('Received', '12%', 'received');
                else
                    return '';
            },
            function (os, id) {
                void (os);
                if (!id.match(/^cgroup_.*/))
                    return netdataDashboard.gaugeChart('Sent', '12%', 'sent');
                else
                    return '';
            }
        ],
        info: '网络接口传输的流量。'
    },
    'net.packets': {
        info: '网络接口传输的数据包数量。 '+
        '收到的<a href="https://en.wikipedia.org/wiki/Multicast" target="_blank">multicast</a>计数器是 '+
        '通常在设备级别计算（与<b>接收</b>不同），因此可能包括未到达主机的数据包。'
    },
    'net.errors': {
        info: '<p>网络接口遇到的错误数量。</p>'+
        '<p><b>入站</b> - 此界面上收到的不良数据包。 '+
        '它包括因长度无效、CRC、帧对齐和其他错误而掉落的数据包。 '+
        '<b>出站</b> - 传输问题。 '+
        '它包括因运营商丢失而导致的帧传输错误、FIFO超支/下流、心跳、 '+
        '延迟碰撞和其他问题。</p>'
    },
    'net.fifo': {
        info: '<p>The number of FIFO errors encountered by the network interface.</p>'+
        '<p><b>Inbound</b> - packets dropped because they did not fit into buffers provided by the host, '+
        'e.g. packets larger than MTU or next buffer in the ring was not available for a scatter transfer. '+
        '<b>Outbound</b> - frame transmission errors due to device FIFO underrun/underflow. '+
        'This condition occurs when the device begins transmission of a frame '+
        'but is unable to deliver the entire frame to the transmitter in time for transmission.</p>'
    },
    'net.drops': {
        info: '<p>The number of packets that have been dropped at the network interface level.</p>'+
        '<p><b>Inbound</b> - packets received but not processed, e.g. due to '+
        '<a href="#menu_system_submenu_softnet_stat">softnet backlog</a> overflow, bad/unintended VLAN tags, '+
        'unknown or unregistered protocols, IPv6 frames when the server is not configured for IPv6. '+
        '<b>Outbound</b> - packets dropped on their way to transmission, e.g. due to lack of resources.</p>'
    },
    'net.compressed': {
        info: 'The number of correctly transferred compressed packets by the network interface. '+
        'These counters are only meaningful for interfaces which support packet compression (e.g. CSLIP, PPP).'
    },
    'net.events': {
        info: '<p>The number of errors encountered by the network interface.</p>'+
        '<p><b>Frames</b> - aggregated counter for dropped packets due to '+
        'invalid length, FIFO overflow, CRC, and frame alignment errors. '+
        '<b>Collisions</b> - '+
        '<a href="https://en.wikipedia.org/wiki/Collision_(telecommunications)" target="blank">collisions</a> during packet transmissions. '+
        '<b>Carrier</b> - aggregated counter for frame transmission errors due to '+
        'excessive collisions, loss of carrier, device FIFO underrun/underflow, Heartbeat/SQE Test errors, and  late collisions.</p>'
    },
    'net.duplex': {
        info: '<p>The interface\'s latest or current '+
        '<a href="https://en.wikipedia.org/wiki/Duplex_(telecommunications)" target="_blank">duplex</a> that the network adapter '+
        '<a href="https://en.wikipedia.org/wiki/Autonegotiation" target="_blank">negotiated</a> with the device it is connected to.</p>'+
        '<p><b>Unknown</b> - the duplex mode can not be determined. '+
        '<b>Half duplex</b> - the communication is one direction at a time. '+
        '<b>Full duplex</b> - the interface is able to send and receive data simultaneously.</p>'+
        '<p><b>State map</b>: 0 - unknown, 1 - half, 2 - full.</p>'
    },
    'net.operstate': {
        info: '<p>The current '+
        '<a href="https://datatracker.ietf.org/doc/html/rfc2863" target="_blank">operational state</a> of the interface.</p>'+
        '<p><b>Unknown</b> - the state can not be determined. '+
        '<b>NotPresent</b> - the interface has missing (typically, hardware) components. '+
        '<b>Down</b> - the interface is unable to transfer data on L1, e.g. ethernet is not plugged or interface is administratively down. '+
        '<b>LowerLayerDown</b> - the interface is down due to state of lower-layer interface(s). '+
        '<b>Testing</b> - the interface is in testing mode, e.g. cable test. It can’t be used for normal traffic until tests complete. '+
        '<b>Dormant</b> - the interface is L1 up, but waiting for an external event, e.g. for a protocol to establish. '+
        '<b>Up</b> - the interface is ready to pass packets and can be used.</p>'+
        '<p><b>State map</b>: 0 - unknown, 1 - notpresent, 2 - down, 3 - lowerlayerdown, 4 - testing, 5 - dormant, 6 - up.</p>'
    },
    'net.carrier': {
        info: '<p>The current physical link state of the interface.</p>'+
        '<p><b>State map</b>: 0 - down, 1 - up.</p>'
    },
    'net.speed': {
        info: 'The interface\'s latest or current speed that the network adapter '+
        '<a href="https://en.wikipedia.org/wiki/Autonegotiation" target="_blank">negotiated</a> with the device it is connected to. '+
        'This does not give the max supported speed of the NIC.'
    },
    'net.mtu': {
        info: 'The interface\'s currently configured '+
        '<a href="https://en.wikipedia.org/wiki/Maximum_transmission_unit" target="_blank">Maximum transmission unit</a> (MTU) value. '+
        'MTU is the size of the largest protocol data unit that can be communicated in a single network layer transaction.'
    },

    // ------------------------------------------------------------------------
    // WIRELESS NETWORK INTERFACES

    'wireless.link_quality': {
        info: 'Overall quality of the link. '+
        'May be based on the level of contention or interference, the bit or frame error rate, '+
        'how good the received signal is, some timing synchronisation, or other hardware metric.'
    },

    'wireless.signal_level': {
        info: 'Received signal strength '+
        '(<a href="https://en.wikipedia.org/wiki/Received_signal_strength_indication" target="_blank">RSSI</a>).'
    },

    'wireless.noise_level': {
        info: 'Background noise level (when no packet is transmitted).'
    },

    'wireless.discarded_packets': {
        info: '<p>The number of discarded packets.</p>'+
        '</p><b>NWID</b> - received packets with a different NWID or ESSID. '+
        'Used to detect configuration problems or adjacent network existence (on the same frequency). '+
        '<b>Crypt</b> - received packets that the hardware was unable to code/encode. '+
        'This can be used to detect invalid encryption settings. '+
        '<b>Frag</b> - received packets for which the hardware was not able to properly re-assemble '+
        'the link layer fragments (most likely one was missing). '+
        '<b>Retry</b> - packets that the hardware failed to deliver. '+
        'Most MAC protocols will retry the packet a number of times before giving up. '+
        '<b>Misc</b> - other packets lost in relation with specific wireless operations.</p>'
    },

    'wireless.missed_beacons': {
        info: 'The number of periodic '+
        '<a href="https://en.wikipedia.org/wiki/Beacon_frame" target="_blank">beacons</a> '+
        'from the Cell or the Access Point have been missed. '+
        'Beacons are sent at regular intervals to maintain the cell coordination, '+
        'failure to receive them usually indicates that the card is out of range.'
    },

    // ------------------------------------------------------------------------
    // INFINIBAND

    'ib.bytes': {
        info: 'The amount of traffic transferred by the port.'
    },

    'ib.packets': {
        info: 'The number of packets transferred by the port.'
    },

    'ib.errors': {
        info: 'The number of errors encountered by the port.'
    },

    'ib.hwerrors': {
        info: 'The number of hardware errors encountered by the port.'
    },

    'ib.hwpackets': {
        info: 'The number of hardware packets transferred by the port.'
    },

    // ------------------------------------------------------------------------
    // NETFILTER

    'netfilter.sockets': {
        colors: '#88AA00',
        heads: [
            netdataDashboard.gaugeChart('Active Connections', '12%', '', '#88AA00')
        ]
    },

    'netfilter.new': {
        heads: [
            netdataDashboard.gaugeChart('New Connections', '12%', 'new', '#5555AA')
        ]
    },

    // ------------------------------------------------------------------------
    // IPVS
    'ipvs.sockets': {
        info: 'Total created connections for all services and their servers. '+
        'To see the IPVS connection table, run <code>ipvsadm -Lnc</code>.'
    },
    'ipvs.packets': {
        info: 'Total transferred packets for all services and their servers.'
    },
    'ipvs.net': {
        info: 'Total network traffic for all services and their servers.'
    },

    // ------------------------------------------------------------------------
    // DISKS

    'disk.util': {
        colors: '#FF5588',
        heads: [
            netdataDashboard.gaugeChart('使用率', '12%', '', '#FF5588')
        ],
        info: 'Disk Utilization measures the amount of time the disk was busy with something. This is not related to its performance. 100% means that the system always had an outstanding operation on the disk. Keep in mind that depending on the underlying technology of the disk, 100% here may or may not be an indication of congestion.'
    },

    'disk.busy': {
        colors: '#FF5588',
        info: 'Disk Busy Time measures the amount of time the disk was busy with something.'
    },
    
    'disk.backlog': {
        colors: '#0099CC',
        info: 'Backlog is an indication of the duration of pending disk operations. On every I/O event the system is multiplying the time spent doing I/O since the last update of this field with the number of pending operations. While not accurate, this metric can provide an indication of the expected completion time of the operations in progress.'
    },

    'disk.io': {
        heads: [
            netdataDashboard.gaugeChart('读取', '12%', 'reads'),
            netdataDashboard.gaugeChart('写入', '12%', 'writes')
        ],
        info: '磁碟传输资料的总计。'
    },

    'disk_ext.io': {
        info: 'The amount of discarded data that are no longer in use by a mounted file system.'
    },

    'disk.ops': {
        info: '已完成的磁碟 I/O operations。提醒：实际上的 operations 数量可能更高，因为系统能够将它们互相合并 (详见 operations 图表)。'
    },

    'disk_ext.ops': {
        info: '<p>The number (after merges) of completed discard/flush requests.</p>'+
        '<p><b>Discard</b> commands inform disks which blocks of data are no longer considered to be in use and therefore can be erased internally. '+
        'They are useful for solid-state drivers (SSDs) and thinly-provisioned storage. '+
        'Discarding/trimming enables the SSD to handle garbage collection more efficiently, '+
        'which would otherwise slow future write operations to the involved blocks down.</p>'+
        '<p><b>Flush</b> operations transfer all modified in-core data (i.e., modified buffer cache pages) to the disk device '+
        'so that all changed information can be retrieved even if the system crashes or is rebooted. '+
        'Flush requests are executed by disks. Flush requests are not tracked for partitions. '+
        'Before being merged, flush operations are counted as writes.</p>'
    },

    'disk.qops': {
        info: 'I/O operations currently in progress. This metric is a snapshot - it is not an average over the last interval.'
    },

    'disk.iotime': {
        height: 0.5,
        info: 'The sum of the duration of all completed I/O operations. This number can exceed the interval if the disk is able to execute I/O operations in parallel.'
    },
    'disk_ext.iotime': {
        height: 0.5,
        info: 'The sum of the duration of all completed discard/flush operations. This number can exceed the interval if the disk is able to execute discard/flush operations in parallel.'
    },
    'disk.mops': {
        height: 0.5,
        info: 'The number of merged disk operations. The system is able to merge adjacent I/O operations, for example two 4KB reads can become one 8KB read before given to disk.'
    },
    'disk_ext.mops': {
        height: 0.5,
        info: 'The number of merged discard disk operations. Discard operations which are adjacent to each other may be merged for efficiency.'
    },
    'disk.svctm': {
        height: 0.5,
        info: 'The average service time for completed I/O operations. This metric is calculated using the total busy time of the disk and the number of completed operations. If the disk is able to execute multiple parallel operations the reporting average service time will be misleading.'
    },
    'disk.latency_io': {
        height: 0.5,
        info: 'Disk I/O latency is the time it takes for an I/O request to be completed. Latency is the single most important metric to focus on when it comes to storage performance, under most circumstances. For hard drives, an average latency somewhere between 10 to 20 ms can be considered acceptable. For SSD (Solid State Drives), depending on the workload it should never reach higher than 1-3 ms. In most cases, workloads will experience less than 1ms latency numbers. The dimensions refer to time intervals. This chart is based on the <a href="https://github.com/cloudflare/ebpf_exporter/blob/master/examples/bio-tracepoints.yaml" target="_blank">bio_tracepoints</a> tool of the ebpf_exporter.'
    },
    'disk.avgsz': {
        height: 0.5,
        info: 'I/O operation 平均大小。'
    },
    'disk_ext.avgsz': {
        height: 0.5,
        info: 'The average discard operation size.'
    },
    'disk.await': {
        height: 0.5,
        info: '对要提供服务的设备发出 I/O 请求平均时间。这包含了请求在伫列中所花费的时间以及实际提供服务的时间。'
    },
    'disk_ext.await': {
        height: 0.5,
        info: 'The average time for discard/flush requests issued to the device to be served. This includes the time spent by the requests in queue and the time spent servicing them.'
    },

    'disk.space': {
        info: '磁碟空间使用率。系统会自动为 root 使用者做保留，以防止 root 使用者使用过多。'
    },
    'disk.inodes': {
        info: 'Inodes (or index nodes) are filesystem objects (e.g. files and directories). On many types of file system implementations, the maximum number of inodes is fixed at filesystem creation, limiting the maximum number of files the filesystem can hold. It is possible for a device to run out of inodes. When this happens, new files cannot be created on the device, even though there may be free space available.'
    },

    'disk.bcache_hit_ratio': {
        info: '<p><b>Bcache (block cache)</b> is a cache in the block layer of Linux kernel, '+
        'which is used for accessing secondary storage devices. '+
        'It allows one or more fast storage devices, such as flash-based solid-state drives (SSDs), '+
        'to act as a cache for one or more slower storage devices, such as hard disk drives (HDDs).</p>'+
        '<p>Percentage of data requests that were fulfilled right from the block cache. '+
        'Hits and misses are counted per individual IO as bcache sees them. '+
        'A partial hit is counted as a miss.</p>'
    },
    'disk.bcache_rates': {
        info: 'Throttling rates. '+
        'To avoid congestions bcache tracks latency to the cache device, and gradually throttles traffic if the latency exceeds a threshold. ' +
        'If the writeback percentage is nonzero, bcache tries to keep around this percentage of the cache dirty by '+
        'throttling background writeback and using a PD controller to smoothly adjust the rate.'
    },
    'disk.bcache_size': {
        info: 'The amount of dirty data for this backing device in the cache.'
    },
    'disk.bcache_usage': {
        info: 'The percentage of cache device which does not contain dirty data, and could potentially be used for writeback.'
    },
    'disk.bcache_cache_read_races': {
        info: '<b>Read races</b> happen when a bucket was reused and invalidated while data was being read from the cache. '+
        'When this occurs the data is reread from the backing device. '+
        '<b>IO errors</b> are decayed by the half life. '+
        'If the decaying count reaches the limit, dirty data is written out and the cache is disabled.'
    },
    'disk.bcache': {
        info: 'Hits and misses are counted per individual IO as bcache sees them; a partial hit is counted as a miss. '+
        'Collisions happen when data was going to be inserted into the cache from a cache miss, '+
        'but raced with a write and data was already present. '+
        'Cache miss reads are rounded up to the readahead size, but without overlapping existing cache entries.'
    },
    'disk.bcache_bypass': {
        info: 'Hits and misses for IO that is intended to skip the cache.'
    },
    'disk.bcache_cache_alloc': {
        info: '<p>Working set size.</p>'+
        '<p><b>Unused</b> is the percentage of the cache that does not contain any data. '+
        '<b>Dirty</b> is the data that is modified in the cache but not yet written to the permanent storage. '+
        '<b>Clean</b> data matches the data stored on the permanent storage. '+
        '<b>Metadata</b> is bcache\'s metadata overhead.</p>'
    },

    // ------------------------------------------------------------------------
    // NFS client

    'nfs.net': {
        info: 'The number of received UDP and TCP packets.'
    },

    'nfs.rpc': {
        info: '<p>Remote Procedure Call (RPC) statistics.</p>'+
        '</p><b>Calls</b> - all RPC calls. '+
        '<b>Retransmits</b> - retransmitted calls. '+
        '<b>AuthRefresh</b> - authentication refresh calls (validating credentials with the server).</p>'
    },

    'nfs.proc2': {
        info: 'NFSv2 RPC calls. The individual metrics are described in '+
        '<a href="https://datatracker.ietf.org/doc/html/rfc1094#section-2.2" target="_blank">RFC1094</a>.'
    },

    'nfs.proc3': {
        info: 'NFSv3 RPC calls. The individual metrics are described in '+
        '<a href="https://datatracker.ietf.org/doc/html/rfc1813#section-3" target="_blank">RFC1813</a>.'
    },

    'nfs.proc4': {
        info: 'NFSv4 RPC calls. The individual metrics are described in '+
        '<a href="https://datatracker.ietf.org/doc/html/rfc8881#section-18" target="_blank">RFC8881</a>.'
    },

    // ------------------------------------------------------------------------
    // NFS server

    'nfsd.readcache': {
        info: '<p>Reply cache statistics. '+
        'The reply cache keeps track of responses to recently performed non-idempotent transactions, and '+
        'in case of a replay, the cached response is sent instead of attempting to perform the operation again.</p>'+
        '<b>Hits</b> - client did not receive a reply and re-transmitted its request. This event is undesirable. '+
        '<b>Misses</b> - an operation that requires caching (idempotent). '+
        '<b>Nocache</b> - an operation that does not require caching (non-idempotent).'
    },

    'nfsd.filehandles': {
        info: '<p>File handle statistics. '+
        'File handles are small pieces of memory that keep track of what file is opened.</p>'+
        '<p><b>Stale</b> - happen when a file handle references a location that has been recycled. '+
        'This also occurs when the server loses connection and '+
        'applications are still using files that are no longer accessible.'
    },

    'nfsd.io': {
        info: 'The amount of data transferred to and from disk.'
    },

    'nfsd.threads': {
        info: 'The number of threads used by the NFS daemon.'
    },

    'nfsd.readahead': {
        info: '<p>Read-ahead cache statistics. '+
        'NFS read-ahead predictively requests blocks from a file in advance of I/O requests by the application. '+
        'It is designed to improve client sequential read throughput.</p>'+
        '<p><b>10%</b>-<b>100%</b> - histogram of depth the block was found. '+
        'This means how far the cached block is from the original block that was first requested. '+
        '<b>Misses</b> - not found in the read-ahead cache.</p>'
    },

    'nfsd.net': {
        info: 'The number of received UDP and TCP packets.'
    },

    'nfsd.rpc': {
        info: '<p>Remote Procedure Call (RPC) statistics.</p>'+
        '</p><b>Calls</b> - all RPC calls. '+
        '<b>BadAuth</b> - bad authentication. '+
        'It does not count if you try to mount from a machine that it\'s not in your exports file. '+
        '<b>BadFormat</b> - other errors.</p>'
    },

    'nfsd.proc2': {
        info: 'NFSv2 RPC calls. The individual metrics are described in '+
        '<a href="https://datatracker.ietf.org/doc/html/rfc1094#section-2.2" target="_blank">RFC1094</a>.'
    },

    'nfsd.proc3': {
        info: 'NFSv3 RPC calls. The individual metrics are described in '+
        '<a href="https://datatracker.ietf.org/doc/html/rfc1813#section-3" target="_blank">RFC1813</a>.'
    },

    'nfsd.proc4': {
        info: 'NFSv4 RPC calls. The individual metrics are described in '+
        '<a href="https://datatracker.ietf.org/doc/html/rfc8881#section-18" target="_blank">RFC8881</a>.'
    },

    'nfsd.proc4ops': {
        info: 'NFSv4 RPC operations. The individual metrics are described in '+
        '<a href="https://datatracker.ietf.org/doc/html/rfc8881#section-18" target="_blank">RFC8881</a>.'
    },

    // ------------------------------------------------------------------------
    // ZFS

    'zfs.arc_size': {
        info: '<p>The size of the ARC.</p>'+
        '<p><b>Arcsz</b> - actual size. '+
        '<b>Target</b> - target size that the ARC is attempting to maintain (adaptive). '+
        '<b>Min</b> - minimum size limit. When the ARC is asked to shrink, it will stop shrinking at this value. '+
        '<b>Min</b> - maximum size limit.</p>'
    },

    'zfs.l2_size': {
        info: '<p>The size of the L2ARC.</p>'+
        '<p><b>Actual</b> - size of compressed data. '+
        '<b>Size</b> - size of uncompressed data.</p>'
    },

    'zfs.reads': {
        info: '<p>The number of read requests.</p>'+
        '<p><b>ARC</b> - all prefetch and demand requests. '+
        '<b>Demand</b> - triggered by an application request. '+
        '<b>Prefetch</b> - triggered by the prefetch mechanism, not directly from an application request. '+
        '<b>Metadata</b> - metadata read requests. '+
        '<b>L2</b> - L2ARC read requests.</p>'
    },

    'zfs.bytes': {
        info: 'The amount of data transferred to and from the L2ARC cache devices.'
    },

    'zfs.hits': {
        info: '<p>Hit rate of the ARC read requests.</p>'+
        '<p><b>Hits</b> - a data block was in the ARC DRAM cache and returned. '+
        '<b>Misses</b> - a data block was not in the ARC DRAM cache. '+
        'It will be read from the L2ARC cache devices (if available and the data is cached on them) or the pool disks.</p>'
    },

    'zfs.dhits': {
        info: '<p>Hit rate of the ARC data and metadata demand read requests. '+
        'Demand requests are triggered by an application request.</p>'+
        '<p><b>Hits</b> - a data block was in the ARC DRAM cache and returned. '+
        '<b>Misses</b> - a data block was not in the ARC DRAM cache. '+
        'It will be read from the L2ARC cache devices (if available and the data is cached on them) or the pool disks.</p>'
    },

    'zfs.phits': {
        info: '<p>Hit rate of the ARC data and metadata prefetch read requests. '+
        'Prefetch requests are triggered by the prefetch mechanism, not directly from an application request.</p>'+
        '<p><b>Hits</b> - a data block was in the ARC DRAM cache and returned. '+
        '<b>Misses</b> - a data block was not in the ARC DRAM cache. '+
        'It will be read from the L2ARC cache devices (if available and the data is cached on them) or the pool disks.</p>'
    },

    'zfs.mhits': {
        info: '<p>Hit rate of the ARC metadata read requests.</p>'+
        '<p><b>Hits</b> - a data block was in the ARC DRAM cache and returned. '+
        '<b>Misses</b> - a data block was not in the ARC DRAM cache. '+
        'It will be read from the L2ARC cache devices (if available and the data is cached on them) or the pool disks.</p>'
    },

    'zfs.l2hits': {
        info: '<p>Hit rate of the L2ARC lookups.</p>'+
        '</p><b>Hits</b> - a data block was in the L2ARC cache and returned. '+
        '<b>Misses</b> - a data block was not in the L2ARC cache. '+
        'It will be read from the pool disks.</p>'
    },

    'zfs.demand_data_hits': {
        info: '<p>Hit rate of the ARC data demand read requests. '+
        'Demand requests are triggered by an application request.</p>'+
        '<b>Hits</b> - a data block was in the ARC DRAM cache and returned. '+
        '<b>Misses</b> - a data block was not in the ARC DRAM cache. '+
        'It will be read from the L2ARC cache devices (if available and the data is cached on them) or the pool disks.</p>'
    },

    'zfs.prefetch_data_hits': {
        info: '<p>Hit rate of the ARC data prefetch read requests. '+
        'Prefetch requests are triggered by the prefetch mechanism, not directly from an application request.</p>'+
        '<p><b>Hits</b> - a data block was in the ARC DRAM cache and returned. '+
        '<b>Misses</b> - a data block was not in the ARC DRAM cache. '+
        'It will be read from the L2ARC cache devices (if available and the data is cached on them) or the pool disks.</p>'
    },

    'zfs.list_hits': {
        info: 'MRU (most recently used) and MFU (most frequently used) cache list hits. '+
        'MRU and MFU lists contain metadata for requested blocks which are cached. '+
        'Ghost lists contain metadata of the evicted pages on disk.'
    },

    'zfs.arc_size_breakdown': {
        info: 'The size of MRU (most recently used) and MFU (most frequently used) cache.'
    },

    'zfs.memory_ops': {
        info: '<p>Memory operation statistics.</p>'+
        '<p><b>Direct</b> - synchronous memory reclaim. Data is evicted from the ARC and free slabs reaped. '+
        '<b>Throttled</b> - number of times that ZFS had to limit the ARC growth. '+
        'A constant increasing of the this value can indicate excessive pressure to evict data from the ARC. '+
        '<b>Indirect</b> - asynchronous memory reclaim. It reaps free slabs from the ARC cache.</p>'
    },

    'zfs.important_ops': {
        info: '<p>Eviction and insertion operation statistics.</p>'+
        '<p><b>EvictSkip</b> - skipped data eviction operations. '+
        '<b>Deleted</b> - old data is evicted (deleted) from the cache. '+
        '<b>MutexMiss</b> - an attempt to get hash or data block mutex when it is locked during eviction. '+
        '<b>HashCollisions</b> - occurs when two distinct data block numbers have the same hash value.</p>'
    },

    'zfs.actual_hits': {
        info: '<p>MRU and MFU cache hit rate.</p>'+
        '<p><b>Hits</b> - a data block was in the ARC DRAM cache and returned. '+
        '<b>Misses</b> - a data block was not in the ARC DRAM cache. '+
        'It will be read from the L2ARC cache devices (if available and the data is cached on them) or the pool disks.</p>'
    },

    'zfs.hash_elements': {
        info: '<p>Data Virtual Address (DVA) hash table element statistics.</p>'+
        '<p><b>Current</b> - current number of elements. '+
        '<b>Max</b> - maximum number of elements seen.</p>'
    },

    'zfs.hash_chains': {
        info: '<p>Data Virtual Address (DVA) hash table chain statistics. '+
        'A chain is formed when two or more distinct data block numbers have the same hash value.</p>'+
        '<p><b>Current</b> - current number of chains. '+
        '<b>Max</b> - longest length seen for a chain. '+
        'If the value is high, performance may degrade as the hash locks are held longer while the chains are walked.</p>'
    },

    // ------------------------------------------------------------------------
    // ZFS pools
    'zfspool.state': {
        info: 'ZFS pool state. '+
        'The overall health of a pool, as reported by <code>zpool status</code>, '+
        'is determined by the aggregate state of all devices within the pool. ' +
        'For states description, '+
        'see <a href="https://openzfs.github.io/openzfs-docs/man/7/zpoolconcepts.7.html#Device_Failure_and_Recovery" target="_blank"> ZFS documentation</a>.'
    },

    // ------------------------------------------------------------------------
    // MYSQL

    'mysql.net': {
        info: 'The amount of data sent to mysql clients (<strong>out</strong>) and received from mysql clients (<strong>in</strong>).'
    },

    'mysql.queries': {
        info: 'The number of statements executed by the server.<ul>' +
            '<li><strong>queries</strong> counts the statements executed within stored SQL programs.</li>' +
            '<li><strong>questions</strong> counts the statements sent to the mysql server by mysql clients.</li>' +
            '<li><strong>slow queries</strong> counts the number of statements that took more than <a href="http://dev.mysql.com/doc/refman/5.7/en/server-system-variables.html#sysvar_long_query_time" target="_blank">long_query_time</a> seconds to be executed.' +
            ' For more information about slow queries check the mysql <a href="http://dev.mysql.com/doc/refman/5.7/en/slow-query-log.html" target="_blank">slow query log</a>.</li>' +
            '</ul>'
    },

    'mysql.handlers': {
        info: 'Usage of the internal handlers of mysql. This chart provides very good insights of what the mysql server is actually doing.' +
            ' (if the chart is not showing all these dimensions it is because they are zero - set <strong>Which dimensions to show?</strong> to <strong>All</strong> from the dashboard settings, to render even the zero values)<ul>' +
            '<li><strong>commit</strong>, the number of internal <a href="http://dev.mysql.com/doc/refman/5.7/en/commit.html" target="_blank">COMMIT</a> statements.</li>' +
            '<li><strong>delete</strong>, the number of times that rows have been deleted from tables.</li>' +
            '<li><strong>prepare</strong>, a counter for the prepare phase of two-phase commit operations.</li>' +
            '<li><strong>read first</strong>, the number of times the first entry in an index was read. A high value suggests that the server is doing a lot of full index scans; e.g. <strong>SELECT col1 FROM foo</strong>, with col1 indexed.</li>' +
            '<li><strong>read key</strong>, the number of requests to read a row based on a key. If this value is high, it is a good indication that your tables are properly indexed for your queries.</li>' +
            '<li><strong>read next</strong>, the number of requests to read the next row in key order. This value is incremented if you are querying an index column with a range constraint or if you are doing an index scan.</li>' +
            '<li><strong>read prev</strong>, the number of requests to read the previous row in key order. This read method is mainly used to optimize <strong>ORDER BY ... DESC</strong>.</li>' +
            '<li><strong>read rnd</strong>, the number of requests to read a row based on a fixed position. A high value indicates you are doing a lot of queries that require sorting of the result. You probably have a lot of queries that require MySQL to scan entire tables or you have joins that do not use keys properly.</li>' +
            '<li><strong>read rnd next</strong>, the number of requests to read the next row in the data file. This value is high if you are doing a lot of table scans. Generally this suggests that your tables are not properly indexed or that your queries are not written to take advantage of the indexes you have.</li>' +
            '<li><strong>rollback</strong>, the number of requests for a storage engine to perform a rollback operation.</li>' +
            '<li><strong>savepoint</strong>, the number of requests for a storage engine to place a savepoint.</li>' +
            '<li><strong>savepoint rollback</strong>, the number of requests for a storage engine to roll back to a savepoint.</li>' +
            '<li><strong>update</strong>, the number of requests to update a row in a table.</li>' +
            '<li><strong>write</strong>, the number of requests to insert a row in a table.</li>' +
            '</ul>'
    },

    'mysql.table_locks': {
        info: 'MySQL table locks counters: <ul>' +
            '<li><strong>immediate</strong>, the number of times that a request for a table lock could be granted immediately.</li>' +
            '<li><strong>waited</strong>, the number of times that a request for a table lock could not be granted immediately and a wait was needed. If this is high and you have performance problems, you should first optimize your queries, and then either split your table or tables or use replication.</li>' +
            '</ul>'
    },

    'mysql.innodb_deadlocks': {
        info: 'A deadlock happens when two or more transactions mutually hold and request for locks, creating a cycle of dependencies. For more information about <a href="https://dev.mysql.com/doc/refman/5.7/en/innodb-deadlocks-handling.html" target="_blank">how to minimize and handle deadlocks</a>.'
    },

    'mysql.galera_cluster_status': {
        info:
            '<code>-1</code>: unknown, ' +
            '<code>0</code>: primary (primary group configuration, quorum present), ' +
            '<code>1</code>: non-primary (non-primary group configuration, quorum lost), ' +
            '<code>2</code>: disconnected(not connected to group, retrying).'
    },

    'mysql.galera_cluster_state': {
        info:
            '<code>0</code>: Undefined, ' +
            '<code>1</code>: Joining, ' +
            '<code>2</code>: Donor/Desynced, ' +
            '<code>3</code>: Joined, ' +
            '<code>4</code>: Synced, ' +
            '<code>5</code>: Inconsistent.'
    },

    'mysql.galera_cluster_weight': {
        info: 'The value is counted as a sum of <code>pc.weight</code> of the nodes in the current Primary Component.'
    },

    'mysql.galera_connected': {
        info: '<code>0</code> means that the node has not yet connected to any of the cluster components. ' +
            'This may be due to misconfiguration.'
    },

    'mysql.open_transactions': {
        info: 'The number of locally running transactions which have been registered inside the wsrep provider. ' +
            'This means transactions which have made operations which have caused write set population to happen. ' +
            'Transactions which are read only are not counted.'
    },


    // ------------------------------------------------------------------------
    // POSTGRESQL


    'postgres.db_stat_blks': {
        info: 'Blocks reads from disk or cache.<ul>' +
            '<li><strong>blks_read:</strong> number of disk blocks read in this database.</li>' +
            '<li><strong>blks_hit:</strong> number of times disk blocks were found already in the buffer cache, so that a read was not necessary (this only includes hits in the PostgreSQL buffer cache, not the operating system&#39;s file system cache)</li>' +
            '</ul>'
    },
    'postgres.db_stat_tuple_write': {
        info: '<ul><li>Number of rows inserted/updated/deleted.</li>' +
            '<li><strong>conflicts:</strong> number of queries canceled due to conflicts with recovery in this database. (Conflicts occur only on standby servers; see <a href="https://www.postgresql.org/docs/10/static/monitoring-stats.html#PG-STAT-DATABASE-CONFLICTS-VIEW" target="_blank">pg_stat_database_conflicts</a> for details.)</li>' +
            '</ul>'
    },
    'postgres.db_stat_temp_bytes': {
        info: 'Temporary files can be created on disk for sorts, hashes, and temporary query results.'
    },
    'postgres.db_stat_temp_files': {
        info: '<ul>' +
            '<li><strong>files:</strong> number of temporary files created by queries. All temporary files are counted, regardless of why the temporary file was created (e.g., sorting or hashing).</li>' +
            '</ul>'
    },
    'postgres.archive_wal': {
        info: 'WAL archiving.<ul>' +
            '<li><strong>total:</strong> total files.</li>' +
            '<li><strong>ready:</strong> WAL waiting to be archived.</li>' +
            '<li><strong>done:</strong> WAL successfully archived. ' +
            'Ready WAL can indicate archive_command is in error, see <a href="https://www.postgresql.org/docs/current/static/continuous-archiving.html" target="_blank">Continuous Archiving and Point-in-Time Recovery</a>.</li>' +
            '</ul>'
    },
    'postgres.checkpointer': {
        info: 'Number of checkpoints.<ul>' +
            '<li><strong>scheduled:</strong> when checkpoint_timeout is reached.</li>' +
            '<li><strong>requested:</strong> when max_wal_size is reached.</li>' +
            '</ul>' +
            'For more information see <a href="https://www.postgresql.org/docs/current/static/wal-configuration.html" target="_blank">WAL Configuration</a>.'
    },
    'postgres.autovacuum': {
        info: 'PostgreSQL databases require periodic maintenance known as vacuuming. For many installations, it is sufficient to let vacuuming be performed by the autovacuum daemon. ' +
            'For more information see <a href="https://www.postgresql.org/docs/current/static/routine-vacuuming.html#AUTOVACUUM" target="_blank">The Autovacuum Daemon</a>.'
    },
    'postgres.standby_delta': {
        info: 'Streaming replication delta.<ul>' +
            '<li><strong>sent_delta:</strong> replication delta sent to standby.</li>' +
            '<li><strong>write_delta:</strong> replication delta written to disk by this standby.</li>' +
            '<li><strong>flush_delta:</strong> replication delta flushed to disk by this standby server.</li>' +
            '<li><strong>replay_delta:</strong> replication delta replayed into the database on this standby server.</li>' +
            '</ul>' +
            'For more information see <a href="https://www.postgresql.org/docs/current/static/warm-standby.html#SYNCHRONOUS-REPLICATION" target="_blank">Synchronous Replication</a>.'
    },
    'postgres.replication_slot': {
        info: 'Replication slot files.<ul>' +
            '<li><strong>wal_keeped:</strong> WAL files retained by each replication slots.</li>' +
            '<li><strong>pg_replslot_files:</strong> files present in pg_replslot.</li>' +
            '</ul>' +
            'For more information see <a href="https://www.postgresql.org/docs/current/static/warm-standby.html#STREAMING-REPLICATION-SLOTS" target="_blank">Replication Slots</a>.'
    },
    'postgres.backend_usage': {
        info: 'Connections usage against maximum connections allowed, as defined in the <i>max_connections</i> setting.<ul>' +
            '<li><strong>available:</strong> maximum new connections allowed.</li>' +
            '<li><strong>used:</strong> connections currently in use.</li>' +
            '</ul>' +
            'Assuming non-superuser accounts are being used to connect to Postgres (so <i>superuser_reserved_connections</i> are subtracted from <i>max_connections</i>).<br/>' +
            'For more information see <a href="https://www.postgresql.org/docs/current/runtime-config-connection.html" target="_blank">Connections and Authentication</a>.'
    },
    'postgres.forced_autovacuum': {
        info: 'Percent towards forced autovacuum for one or more tables.<ul>' +
            '<li><strong>percent_towards_forced_autovacuum:</strong> a forced autovacuum will run once this value reaches 100.</li>' +
            '</ul>' +
            'For more information see <a href="https://www.postgresql.org/docs/current/routine-vacuuming.html" target="_blank">Preventing Transaction ID Wraparound Failures</a>.'
    },
    'postgres.tx_wraparound_oldest_current_xid': {
        info: 'The oldest current transaction id (xid).<ul>' +
            '<li><strong>oldest_current_xid:</strong> oldest current transaction id.</li>' +
            '</ul>' +
            'If for some reason autovacuum fails to clear old XIDs from a table, the system will begin to emit warning messages when the database\'s oldest XIDs reach eleven million transactions from the wraparound point.<br/>' +
            'For more information see <a href="https://www.postgresql.org/docs/current/routine-vacuuming.html" target="_blank">Preventing Transaction ID Wraparound Failures</a>.'
    },
    'postgres.percent_towards_wraparound': {
        info: 'Percent towards transaction wraparound.<ul>' +
            '<li><strong>percent_towards_wraparound:</strong> transaction wraparound may occur when this value reaches 100.</li>' +
            '</ul>' +
            'For more information see <a href="https://www.postgresql.org/docs/current/routine-vacuuming.html" target="_blank">Preventing Transaction ID Wraparound Failures</a>.'
    },


    // ------------------------------------------------------------------------
    // APACHE

    'apache.connections': {
        colors: NETDATA.colors[4],
        mainheads: [
            netdataDashboard.gaugeChart('Connections', '12%', '', NETDATA.colors[4])
        ]
    },

    'apache.requests': {
        colors: NETDATA.colors[0],
        mainheads: [
            netdataDashboard.gaugeChart('Requests', '12%', '', NETDATA.colors[0])
        ]
    },

    'apache.net': {
        colors: NETDATA.colors[3],
        mainheads: [
            netdataDashboard.gaugeChart('Bandwidth', '12%', '', NETDATA.colors[3])
        ]
    },

    'apache.workers': {
        mainheads: [
            function (os, id) {
                void (os);
                return '<div data-netdata="' + id + '"'
                    + ' data-dimensions="busy"'
                    + ' data-append-options="percentage"'
                    + ' data-gauge-max-value="100"'
                    + ' data-chart-library="gauge"'
                    + ' data-title="Workers Utilization"'
                    + ' data-units="percentage %"'
                    + ' data-gauge-adjust="width"'
                    + ' data-width="12%"'
                    + ' data-before="0"'
                    + ' data-after="-CHART_DURATION"'
                    + ' data-points="CHART_DURATION"'
                    + ' role="application"></div>';
            }
        ]
    },

    'apache.bytesperreq': {
        colors: NETDATA.colors[3],
        height: 0.5
    },

    'apache.reqpersec': {
        colors: NETDATA.colors[4],
        height: 0.5
    },

    'apache.bytespersec': {
        colors: NETDATA.colors[6],
        height: 0.5
    },


    // ------------------------------------------------------------------------
    // LIGHTTPD

    'lighttpd.connections': {
        colors: NETDATA.colors[4],
        mainheads: [
            netdataDashboard.gaugeChart('Connections', '12%', '', NETDATA.colors[4])
        ]
    },

    'lighttpd.requests': {
        colors: NETDATA.colors[0],
        mainheads: [
            netdataDashboard.gaugeChart('Requests', '12%', '', NETDATA.colors[0])
        ]
    },

    'lighttpd.net': {
        colors: NETDATA.colors[3],
        mainheads: [
            netdataDashboard.gaugeChart('Bandwidth', '12%', '', NETDATA.colors[3])
        ]
    },

    'lighttpd.workers': {
        mainheads: [
            function (os, id) {
                void (os);
                return '<div data-netdata="' + id + '"'
                    + ' data-dimensions="busy"'
                    + ' data-append-options="percentage"'
                    + ' data-gauge-max-value="100"'
                    + ' data-chart-library="gauge"'
                    + ' data-title="Servers Utilization"'
                    + ' data-units="percentage %"'
                    + ' data-gauge-adjust="width"'
                    + ' data-width="12%"'
                    + ' data-before="0"'
                    + ' data-after="-CHART_DURATION"'
                    + ' data-points="CHART_DURATION"'
                    + ' role="application"></div>';
            }
        ]
    },

    'lighttpd.bytesperreq': {
        colors: NETDATA.colors[3],
        height: 0.5
    },

    'lighttpd.reqpersec': {
        colors: NETDATA.colors[4],
        height: 0.5
    },

    'lighttpd.bytespersec': {
        colors: NETDATA.colors[6],
        height: 0.5
    },

    // ------------------------------------------------------------------------
    // NGINX

    'nginx.connections': {
        colors: NETDATA.colors[4],
        mainheads: [
            netdataDashboard.gaugeChart('Connections', '12%', '', NETDATA.colors[4])
        ]
    },

    'nginx.requests': {
        colors: NETDATA.colors[0],
        mainheads: [
            netdataDashboard.gaugeChart('Requests', '12%', '', NETDATA.colors[0])
        ]
    },

    // ------------------------------------------------------------------------
    // HTTP check

    'httpcheck.responsetime': {
        info: 'The <code>response time</code> describes the time passed between request and response. ' +
            'Currently, the accuracy of the response time is low and should be used as reference only.'
    },

    'httpcheck.responselength': {
        info: 'The <code>response length</code> counts the number of characters in the response body. For static pages, this should be mostly constant.'
    },

    'httpcheck.status': {
        valueRange: "[0, 1]",
        info: 'This chart verifies the response of the webserver. Each status dimension will have a value of <code>1</code> if triggered. ' +
            'Dimension <code>success</code> is <code>1</code> only if all constraints are satisfied. ' +
            'This chart is most useful for alarms or third-party apps.'
    },

    // ------------------------------------------------------------------------
    // NETDATA

    'netdata.response_time': {
        info: 'The netdata API response time measures the time netdata needed to serve requests. This time includes everything, from the reception of the first byte of a request, to the dispatch of the last byte of its reply, therefore it includes all network latencies involved (i.e. a client over a slow network will influence these metrics).'
    },

    'netdata.ebpf_threads': {
        info: 'Show total number of threads and number of active threads. For more details about the threads, see the <a href="https://learn.netdata.cloud/docs/agent/collectors/ebpf.plugin#ebpf-programs">official documentation</a>.'
    },

    'netdata.ebpf_load_methods': {
        info: 'Show number of threads loaded using legacy code (independent binary) or <code>CO-RE (Compile Once Run Everywhere)</code>.'
    },

    // ------------------------------------------------------------------------
    // RETROSHARE

    'retroshare.bandwidth': {
        info: 'RetroShare inbound and outbound traffic.',
        mainheads: [
            netdataDashboard.gaugeChart('Received', '12%', 'bandwidth_down_kb'),
            netdataDashboard.gaugeChart('Sent', '12%', 'bandwidth_up_kb')
        ]
    },

    'retroshare.peers': {
        info: 'Number of (connected) RetroShare friends.',
        mainheads: [
            function (os, id) {
                void (os);
                return '<div data-netdata="' + id + '"'
                    + ' data-dimensions="peers_connected"'
                    + ' data-append-options="friends"'
                    + ' data-chart-library="easypiechart"'
                    + ' data-title="connected friends"'
                    + ' data-units=""'
                    + ' data-width="8%"'
                    + ' data-before="0"'
                    + ' data-after="-CHART_DURATION"'
                    + ' data-points="CHART_DURATION"'
                    + ' role="application"></div>';
            }
        ]
    },

    'retroshare.dht': {
        info: 'Statistics about RetroShare\'s DHT. These values are estimated!'
    },

    // ------------------------------------------------------------------------
    // fping

    'fping.quality': {
        colors: NETDATA.colors[10],
        height: 0.5
    },

    'fping.packets': {
        height: 0.5
    },


    // ------------------------------------------------------------------------
    // containers

    'cgroup.cpu_limit': {
        valueRange: "[0, null]",
        mainheads: [
            function (os, id) {
                void (os);
                cgroupCPULimitIsSet = 1;
                return '<div data-netdata="' + id + '"'
                    + ' data-dimensions="used"'
                    + ' data-gauge-max-value="100"'
                    + ' data-chart-library="gauge"'
                    + ' data-title="CPU"'
                    + ' data-units="%"'
                    + ' data-gauge-adjust="width"'
                    + ' data-width="12%"'
                    + ' data-before="0"'
                    + ' data-after="-CHART_DURATION"'
                    + ' data-points="CHART_DURATION"'
                    + ' data-colors="' + NETDATA.colors[4] + '"'
                    + ' role="application"></div>';
            }
        ],
        info: 'Total CPU utilization within the configured or system-wide (if not set) limits. '+
        'When the CPU utilization of a cgroup exceeds the limit for the configured period, '+
        'the tasks belonging to its hierarchy will be throttled and are not allowed to run again until the next period.'
    },

    'cgroup.cpu': {
        mainheads: [
            function (os, id) {
                void (os);
                if (cgroupCPULimitIsSet === 0) {
                    return '<div data-netdata="' + id + '"'
                        + ' data-chart-library="gauge"'
                        + ' data-title="CPU"'
                        + ' data-units="%"'
                        + ' data-gauge-adjust="width"'
                        + ' data-width="12%"'
                        + ' data-before="0"'
                        + ' data-after="-CHART_DURATION"'
                        + ' data-points="CHART_DURATION"'
                        + ' data-colors="' + NETDATA.colors[4] + '"'
                        + ' role="application"></div>';
                } else
                    return '';
            }
        ],
        info: 'Total CPU utilization within the system-wide CPU resources (all cores). '+
        'The amount of time spent by tasks of the cgroup in '+
        '<a href="https://en.wikipedia.org/wiki/CPU_modes#Mode_types" target="_blank">user and kernel</a> modes.'
    },

    'cgroup.cpu_per_core': {
        info: 'Total CPU utilization per core within the system-wide CPU resources.'
    },

    'cgroup.cpu_pressure': {
        info: 'CPU <a href="https://www.kernel.org/doc/html/latest/accounting/psi.html" target="_blank">Pressure Stall Information</a>. '+
        '<b>Some</b> indicates the share of time in which at least some tasks are stalled on CPU. '+
        'The ratios (in %) are tracked as recent trends over 10-, 60-, and 300-second windows.'
    },

    'cgroup.mem_utilization': {
        info: 'RAM utilization within the configured or system-wide (if not set) limits. '+
        'When the RAM utilization of a cgroup exceeds the limit, '+
        'OOM killer will start killing the tasks belonging to the cgroup.'
    },

    'cgroup.mem_usage_limit': {
        mainheads: [
            function (os, id) {
                void (os);
                cgroupMemLimitIsSet = 1;
                return '<div data-netdata="' + id + '"'
                    + ' data-dimensions="used"'
                    + ' data-append-options="percentage"'
                    + ' data-gauge-max-value="100"'
                    + ' data-chart-library="gauge"'
                    + ' data-title="Memory"'
                    + ' data-units="%"'
                    + ' data-gauge-adjust="width"'
                    + ' data-width="12%"'
                    + ' data-before="0"'
                    + ' data-after="-CHART_DURATION"'
                    + ' data-points="CHART_DURATION"'
                    + ' data-colors="' + NETDATA.colors[1] + '"'
                    + ' role="application"></div>';
            }
        ],
        info: 'RAM usage within the configured or system-wide (if not set) limits. '+
        'When the RAM usage of a cgroup exceeds the limit, '+
        'OOM killer will start killing the tasks belonging to the cgroup.'
    },

    'cgroup.mem_usage': {
        mainheads: [
            function (os, id) {
                void (os);
                if (cgroupMemLimitIsSet === 0) {
                    return '<div data-netdata="' + id + '"'
                        + ' data-chart-library="gauge"'
                        + ' data-title="Memory"'
                        + ' data-units="MB"'
                        + ' data-gauge-adjust="width"'
                        + ' data-width="12%"'
                        + ' data-before="0"'
                        + ' data-after="-CHART_DURATION"'
                        + ' data-points="CHART_DURATION"'
                        + ' data-colors="' + NETDATA.colors[1] + '"'
                        + ' role="application"></div>';
                } else
                    return '';
            }
        ],
        info: 'The amount of used RAM and swap memory.'
    },

    'cgroup.mem': {
        info: 'Memory usage statistics. '+
        'The individual metrics are described in the memory.stat section for '+
        '<a href="https://www.kernel.org/doc/html/latest/admin-guide/cgroup-v1/memory.html#per-memory-cgroup-local-status" target="_blank">cgroup-v1 </a>'+
        'and '+
        '<a href="https://www.kernel.org/doc/html/latest/admin-guide/cgroup-v2.html#memory-interface-files" target="_blank">cgroup-v2</a>.'
    },

    'cgroup.mem_failcnt': {
        info: 'The number of memory usage hits limits.'
    },

    'cgroup.writeback': {
        info: '<b>Dirty</b> is the amount of memory waiting to be written to disk. <b>Writeback</b> is how much memory is actively being written to disk.'
    },

    'cgroup.mem_activity': {
        info: '<p>Memory accounting statistics.</p>'+
        '<p><b>In</b> - a page is accounted as either mapped anon page (RSS) or cache page (Page Cache) to the cgroup. '+
        '<b>Out</b> - a page is unaccounted from the cgroup.</p>'
    },

    'cgroup.pgfaults': {
        info: '<p>Memory <a href="https://en.wikipedia.org/wiki/Page_fault" target="_blank">page fault</a> statistics.</p>'+
        '<p><b>Pgfault</b> - all page faults. '+
        '<b>Swap</b> - major page faults.</p>'
    },

    'cgroup.memory_pressure': {
        info: 'Memory <a href="https://www.kernel.org/doc/html/latest/accounting/psi.html" target="_blank">Pressure Stall Information</a>. '+
        '<b>Some</b> indicates the share of time in which at least some tasks are stalled on memory. '+
        'The ratios (in %) are tracked as recent trends over 10-, 60-, and 300-second windows.'
    },

    'cgroup.memory_full_pressure': {
        info: 'Memory <a href="https://www.kernel.org/doc/html/latest/accounting/psi.html" target="_blank">Pressure Stall Information</a>. '+
        '<b>Full</b> indicates the share of time in which all non-idle tasks are stalled on memory simultaneously. '+
        'In this state actual CPU cycles are going to waste, '+
        'and a workload that spends extended time in this state is considered to be thrashing. '+
        'The ratios (in %) are tracked as recent trends over 10-, 60-, and 300-second windows.'
    },

    'cgroup.io': {
        info: 'The amount of data transferred to and from specific devices as seen by the CFQ scheduler. '+
        'It is not updated when the CFQ scheduler is operating on a request queue.'
    },

    'cgroup.serviced_ops': {
        info: 'The number of I/O operations performed on specific devices as seen by the CFQ scheduler.'
    },

    'cgroup.queued_ops': {
        info: 'The number of requests queued for I/O operations.'
    },

    'cgroup.merged_ops': {
        info: 'The number of BIOS requests merged into requests for I/O operations.'
    },

    'cgroup.throttle_io': {
        mainheads: [
            function (os, id) {
                void (os);
                return '<div data-netdata="' + id + '"'
                    + ' data-dimensions="read"'
                    + ' data-chart-library="gauge"'
                    + ' data-title="Read Disk I/O"'
                    + ' data-units="KB/s"'
                    + ' data-gauge-adjust="width"'
                    + ' data-width="12%"'
                    + ' data-before="0"'
                    + ' data-after="-CHART_DURATION"'
                    + ' data-points="CHART_DURATION"'
                    + ' data-colors="' + NETDATA.colors[2] + '"'
                    + ' role="application"></div>';
            },
            function (os, id) {
                void (os);
                return '<div data-netdata="' + id + '"'
                    + ' data-dimensions="write"'
                    + ' data-chart-library="gauge"'
                    + ' data-title="Write Disk I/O"'
                    + ' data-units="KB/s"'
                    + ' data-gauge-adjust="width"'
                    + ' data-width="12%"'
                    + ' data-before="0"'
                    + ' data-after="-CHART_DURATION"'
                    + ' data-points="CHART_DURATION"'
                    + ' data-colors="' + NETDATA.colors[3] + '"'
                    + ' role="application"></div>';
            }
        ],
        info: 'The amount of data transferred to and from specific devices as seen by the throttling policy.'
    },

    'cgroup.throttle_serviced_ops': {
        info: 'The number of I/O operations performed on specific devices as seen by the throttling policy.'
    },

    'cgroup.io_pressure': {
        info: 'I/O <a href="https://www.kernel.org/doc/html/latest/accounting/psi.html" target="_blank">Pressure Stall Information</a>. '+
        '<b>Some</b> indicates the share of time in which at least some tasks are stalled on I/O. '+
        'The ratios (in %) are tracked as recent trends over 10-, 60-, and 300-second windows.'
    },

    'cgroup.io_full_pressure': {
        info: 'I/O <a href="https://www.kernel.org/doc/html/latest/accounting/psi.html" target="_blank">Pressure Stall Information</a>. '+
        '<b>Full</b> indicates the share of time in which all non-idle tasks are stalled on I/O simultaneously. '+
        'In this state actual CPU cycles are going to waste, '+
        'and a workload that spends extended time in this state is considered to be thrashing. '+
        'The ratios (in %) are tracked as recent trends over 10-, 60-, and 300-second windows.'
    },

    'cgroup.swap_read': {
        info: 'The function <code>swap_readpage</code> is called when the kernel reads a page from swap memory. This chart is provided by eBPF plugin.'
    },

    'cgroup.swap_write': {
        info: 'The function <code>swap_writepage</code> is called when the kernel writes a page to swap memory. This chart is provided by eBPF plugin.'
    },

    'cgroup.fd_open': {
        info: 'Calls to the internal function <code>do_sys_open</code> (for kernels newer than <code>5.5.19</code> we add a kprobe to <code>do_sys_openat2</code>. ), which is the common function called from' +
            ' <a href="https://www.man7.org/linux/man-pages/man2/open.2.html" target="_blank">open(2)</a> ' +
            ' and <a href="https://www.man7.org/linux/man-pages/man2/openat.2.html" target="_blank">openat(2)</a>. '
    },

    'cgroup.fd_open_error': {
        info: 'Failed calls to the internal function <code>do_sys_open</code> (for kernels newer than <code>5.5.19</code> we add a kprobe to <code>do_sys_openat2</code>. ).'
    },

    'cgroup.fd_close': {
        info: 'Calls to the internal function <a href="https://elixir.bootlin.com/linux/v5.10/source/fs/file.c#L665" target="_blank">__close_fd</a> or <a href="https://elixir.bootlin.com/linux/v5.11/source/fs/file.c#L617" target="_blank">close_fd</a> according to your kernel version, which is called from' +
            ' <a href="https://www.man7.org/linux/man-pages/man2/close.2.html" target="_blank">close(2)</a>. '
    },

    'cgroup.fd_close_error': {
        info: 'Failed calls to the internal function <a href="https://elixir.bootlin.com/linux/v5.10/source/fs/file.c#L665" target="_blank">__close_fd</a> or <a href="https://elixir.bootlin.com/linux/v5.11/source/fs/file.c#L617" target="_blank">close_fd</a> according to your kernel version.'
    },

    'cgroup.vfs_unlink': {
        info: 'Calls to the function <a href="https://www.kernel.org/doc/htmldocs/filesystems/API-vfs-unlink.html" target="_blank">vfs_unlink</a>. This chart does not show all events that remove files from the filesystem, because filesystems can create their own functions to remove files.'
    },

    'cgroup.vfs_write': {
        info: 'Successful calls to the function <a href="https://topic.alibabacloud.com/a/kernel-state-file-operation-__-work-information-kernel_8_8_20287135.html" target="_blank">vfs_write</a>. This chart may not show all filesystem events if it uses other functions to store data on disk.'
    },

    'cgroup.vfs_write_error': {
        info: 'Failed calls to the function <a href="https://topic.alibabacloud.com/a/kernel-state-file-operation-__-work-information-kernel_8_8_20287135.html" target="_blank">vfs_write</a>. This chart may not show all filesystem events if it uses other functions to store data on disk.'
    },

    'cgroup.vfs_read': {
        info: 'Successful calls to the function <a href="https://topic.alibabacloud.com/a/kernel-state-file-operation-__-work-information-kernel_8_8_20287135.html" target="_blank">vfs_read</a>. This chart may not show all filesystem events if it uses other functions to store data on disk.'
    },

    'cgroup.vfs_read_error': {
        info: 'Failed calls to the function <a href="https://topic.alibabacloud.com/a/kernel-state-file-operation-__-work-information-kernel_8_8_20287135.html" target="_blank">vfs_read</a>. This chart may not show all filesystem events if it uses other functions to store data on disk.'
    },

    'cgroup.vfs_write_bytes': {
        info: 'Total of bytes successfully written using the function <a href="https://topic.alibabacloud.com/a/kernel-state-file-operation-__-work-information-kernel_8_8_20287135.html" target="_blank">vfs_write</a>.'
    },

    'cgroup.vfs_read_bytes': {
        info: 'Total of bytes successfully read using the function <a href="https://topic.alibabacloud.com/a/kernel-state-file-operation-__-work-information-kernel_8_8_20287135.html" target="_blank">vfs_read</a>.'
    },

    'cgroup.process_create': {
        info: 'Calls to either <a href="https://programming.vip/docs/the-execution-procedure-of-do_fork-function-in-linux.html" target="_blank">do_fork</a>, or <code>kernel_clone</code> if you are running kernel newer than 5.9.16, to create a new task, which is the common name used to define process and tasks inside the kernel. Netdata identifies the process by counting the number of calls to <a href="https://linux.die.net/man/2/clone" target="_blank">sys_clone</a> that do not have the flag <code>CLONE_THREAD</code> set.'
    },

    'cgroup.thread_create': {
        info: 'Calls to either <a href="https://programming.vip/docs/the-execution-procedure-of-do_fork-function-in-linux.html" target="_blank">do_fork</a>, or <code>kernel_clone</code> if you are running kernel newer than 5.9.16, to create a new task, which is the common name used to define process and tasks inside the kernel. Netdata identifies the threads by counting the number of calls to <a  href="https://linux.die.net/man/2/clone" target="_blank">sys_clone</a> that have the flag <code>CLONE_THREAD</code> set.'
    },

    'cgroup.task_exit': {
        info: 'Calls to the function responsible for closing (<a href="https://www.informit.com/articles/article.aspx?p=370047&seqNum=4" target="_blank">do_exit</a>) tasks.'
    },

    'cgroup.task_close': {
        info: 'Calls to the functions responsible for releasing (<a  href="https://www.informit.com/articles/article.aspx?p=370047&seqNum=4" target="_blank">release_task</a>) tasks.'
    },

    'cgroup.task_error': {
        info: 'Number of errors to create a new process or thread. This chart is provided by eBPF plugin.'
    },


    'cgroup.dc_ratio': {
        info: 'Percentage of file accesses that were present in the directory cache. 100% means that every file that was accessed was present in the directory cache. If files are not present in the directory cache 1) they are not present in the file system, 2) the files were not accessed before. Read more about <a href="https://www.kernel.org/doc/htmldocs/filesystems/the_directory_cache.html" target="_blank">directory cache</a>. Netdata also gives a summary for these charts in <a href="#menu_filesystem_submenu_directory_cache__eBPF_">Filesystem submenu</a>.'
    },

    'cgroup.dc_reference': {
        info: 'Counters of file accesses. <code>Reference</code> is when there is a file access, see the <code>filesystem.dc_reference</code> chart for more context. Read more about <a href="https://www.kernel.org/doc/htmldocs/filesystems/the_directory_cache.html" target="_blank">directory cache</a>.'
    },

    'cgroup.dc_not_cache': {
        info: 'Counters of file accesses. <code>Slow</code> is when there is a file access and the file is not present in the directory cache, see the <code>filesystem.dc_reference</code> chart for more context. Read more about <a href="https://www.kernel.org/doc/htmldocs/filesystems/the_directory_cache.html" target="_blank">directory cache</a>.'
    },

    'cgroup.dc_not_found': {
        info: 'Counters of file accesses. <code>Miss</code> is when there is file access and the file is not found in the filesystem, see the <code>filesystem.dc_reference</code> chart for more context. Read more about <a href="https://www.kernel.org/doc/htmldocs/filesystems/the_directory_cache.html" target="_blank">directory cache</a>.'
    },

    'cgroup.shmget': {
        info: 'Number of times the syscall <code>shmget</code> is called. Netdata also gives a summary for these charts in <a href="#menu_system_submenu_ipc_shared_memory">System overview</a>.'
    },

    'cgroup.shmat': {
        info: 'Number of times the syscall <code>shmat</code> is called.'
    },

    'cgroup.shmdt': {
        info: 'Number of times the syscall <code>shmdt</code> is called.'
    },

    'cgroup.shmctl': {
        info: 'Number of times the syscall <code>shmctl</code> is called.'
    },

    'cgroup.net_bytes_send': {
        info: 'Bytes sent by functions <code>tcp_sendmsg</code>.'
    },

    'cgroup.net_bytes_recv': {
        info: 'Bytes received by functions <code>tcp_cleanup_rbuf</code> . We use <code>tcp_cleanup_rbuf</code> instead <code>tcp_recvmsg</code>, because this last misses <code>tcp_read_sock()</code> traffic and we would also need to have more probes to get the socket and package size.'
    },

    'cgroup.net_tcp_send': {
        info: 'The function <code>tcp_sendmsg</code> is used to collect number of bytes sent from TCP connections.'
    },

    'cgroup.net_tcp_recv': {
        info: 'The function <code>tcp_cleanup_rbuf</code> is used to collect number of bytes received from TCP connections.'
    },

    'cgroup.net_retransmit': {
        info: 'The function <code>tcp_retransmit_skb</code> is called when the host did not receive the expected return from a packet sent.'
    },

    'cgroup.net_udp_send': {
        info: 'The function <code>udp_sendmsg</code> is used to collect number of bytes sent from UDP connections.'
    },

    'cgroup.net_udp_recv': {
        info: 'The function <code>udp_recvmsg</code> is used to collect number of bytes received from UDP connections.'
    },

    'cgroup.cachestat_ratio': {
        info: 'When the processor needs to read or write a location in main memory, it checks for a corresponding entry in the page cache. If the entry is there, a page cache hit has occurred and the read is from the cache. If the entry is not there, a page cache miss has occurred and the kernel allocates a new entry and copies in data from the disk. Netdata calculates the percentage of accessed files that are cached on memory. <a href="https://github.com/iovisor/bcc/blob/master/tools/cachestat.py#L126-L138" target="_blank">The ratio</a> is calculated counting the accessed cached pages (without counting dirty pages and pages added because of read misses) divided by total access without dirty pages.'
    },

    'cgroup.cachestat_dirties': {
        info: 'Number of <a href="https://en.wikipedia.org/wiki/Page_cache#Memory_conservation" target="_blank">dirty(modified) pages</a> cache. Pages in the page cache modified after being brought in are called dirty pages. Since non-dirty pages in the page cache have identical copies in <a href="https://en.wikipedia.org/wiki/Secondary_storage" target="_blank">secondary storage</a> (e.g. hard disk drive or solid-state drive), discarding and reusing their space is much quicker than paging out application memory, and is often preferred over flushing the dirty pages into secondary storage and reusing their space.'
    },

    'cgroup.cachestat_hits': {
        info: 'When the processor needs to read or write a location in main memory, it checks for a corresponding entry in the page cache. If the entry is there, a page cache hit has occurred and the read is from the cache. Hits show pages accessed that were not modified (we are excluding dirty pages), this counting also excludes the recent pages inserted for read.'
    },

    'cgroup.cachestat_misses': {
        info: 'When the processor needs to read or write a location in main memory, it checks for a corresponding entry in the page cache. If the entry is not there, a page cache miss has occurred and the cache allocates a new entry and copies in data for the main memory. Misses count page insertions to the memory not related to writing.'
    },

    // ------------------------------------------------------------------------
    // containers (systemd)

    'services.cpu': {
        info: 'Total CPU utilization within the system-wide CPU resources (all cores). '+
        'The amount of time spent by tasks of the cgroup in '+
        '<a href="https://en.wikipedia.org/wiki/CPU_modes#Mode_types" target="_blank">user and kernel</a> modes.'
    },

    'services.mem_usage': {
        info: 'The amount of used RAM.'
    },

    'services.mem_rss': {
        info: 'The amount of used '+
        '<a href="https://en.wikipedia.org/wiki/Resident_set_size" target="_blank">RSS</a> memory. '+
        'It includes transparent hugepages.'
    },

    'services.mem_mapped': {
        info: 'The size of '+
        '<a href="https://en.wikipedia.org/wiki/Memory-mapped_file" target="_blank">memory-mapped</a> files.'
    },

    'services.mem_cache': {
        info: 'The amount of used '+
        '<a href="https://en.wikipedia.org/wiki/Page_cache" target="_blank">page cache</a> memory.'
    },

    'services.mem_writeback': {
        info: 'The amount of file/anon cache that is '+
        '<a href="https://en.wikipedia.org/wiki/Cache_(computing)#Writing_policies" target="_blank">queued for syncing</a> '+
        'to disk.'
    },

    'services.mem_pgfault': {
        info: 'The number of '+
        '<a href="https://en.wikipedia.org/wiki/Page_fault#Types" target="_blank">page faults</a>. '+
        'It includes both minor and major page faults.'
    },

    'services.mem_pgmajfault': {
        info: 'The number of '+
        '<a href="https://en.wikipedia.org/wiki/Page_fault#Major" target="_blank">major</a> '+
        'page faults.'
    },

    'services.mem_pgpgin': {
        info: 'The amount of memory charged to the cgroup. '+
        'The charging event happens each time a page is accounted as either '+
        'mapped anon page(RSS) or cache page(Page Cache) to the cgroup.'
    },

    'services.mem_pgpgout': {
        info: 'The amount of memory uncharged from the cgroup. '+
        'The uncharging event happens each time a page is unaccounted from the cgroup.'
    },

    'services.mem_failcnt': {
        info: 'The number of memory usage hits limits.'
    },

    'services.swap_usage': {
        info: 'The amount of used '+
        '<a href="https://en.wikipedia.org/wiki/Memory_paging#Unix_and_Unix-like_systems" target="_blank">swap</a> '+
        'memory.'
    },

    'services.io_read': {
        info: 'The amount of data transferred from specific devices as seen by the CFQ scheduler. '+
        'It is not updated when the CFQ scheduler is operating on a request queue.'
    },

    'services.io_write': {
        info: 'The amount of data transferred to specific devices as seen by the CFQ scheduler. '+
        'It is not updated when the CFQ scheduler is operating on a request queue.'
    },

    'services.io_ops_read': {
        info: 'The number of read operations performed on specific devices as seen by the CFQ scheduler.'
    },

    'services.io_ops_write': {
        info: 'The number write operations performed on specific devices as seen by the CFQ scheduler.'
    },

    'services.throttle_io_read': {
        info: 'The amount of data transferred from specific devices as seen by the throttling policy.'
    },

    'services.throttle_io_write': {
        info: 'The amount of data transferred to specific devices as seen by the throttling policy.'
    },

    'services.throttle_io_ops_read': {
        info: 'The number of read operations performed on specific devices as seen by the throttling policy.'
    },

    'services.throttle_io_ops_write': {
        info: 'The number of write operations performed on specific devices as seen by the throttling policy.'
    },

    'services.queued_io_ops_read': {
        info: 'The number of queued read requests.'
    },

    'services.queued_io_ops_write': {
        info: 'The number of queued write requests.'
    },

    'services.merged_io_ops_read': {
        info: 'The number of read requests merged.'
    },

    'services.merged_io_ops_write': {
        info: 'The number of write requests merged.'
    },

    'services.swap_read': {
        info: 'The function <code>swap_readpage</code> is called when the kernel reads a page from swap memory. This chart is provided by eBPF plugin.'
    },

    'services.swap_write': {
        info: 'The function <code>swap_writepage</code> is called when the kernel writes a page to swap memory. This chart is provided by eBPF plugin.'
    },

    'services.fd_open': {
        info: 'Calls to the internal function <code>do_sys_open</code> (for kernels newer than <code>5.5.19</code> we add a kprobe to <code>do_sys_openat2</code>. ), which is the common function called from' +
            ' <a href="https://www.man7.org/linux/man-pages/man2/open.2.html" target="_blank">open(2)</a> ' +
            ' and <a href="https://www.man7.org/linux/man-pages/man2/openat.2.html" target="_blank">openat(2)</a>. '
    },

    'services.fd_open_error': {
        info: 'Failed calls to the internal function <code>do_sys_open</code> (for kernels newer than <code>5.5.19</code> we add a kprobe to <code>do_sys_openat2</code>. ).'
    },

    'services.fd_close': {
        info: 'Calls to the internal function <a href="https://elixir.bootlin.com/linux/v5.10/source/fs/file.c#L665" target="_blank">__close_fd</a> or <a href="https://elixir.bootlin.com/linux/v5.11/source/fs/file.c#L617" target="_blank">close_fd</a> according to your kernel version, which is called from' +
            ' <a href="https://www.man7.org/linux/man-pages/man2/close.2.html" target="_blank">close(2)</a>. '
    },

    'services.fd_close_error': {
        info: 'Failed calls to the internal function <a href="https://elixir.bootlin.com/linux/v5.10/source/fs/file.c#L665" target="_blank">__close_fd</a> or <a href="https://elixir.bootlin.com/linux/v5.11/source/fs/file.c#L617" target="_blank">close_fd</a> according to your kernel version.'
    },

    'services.vfs_unlink': {
        info: 'Calls to the function <a href="https://www.kernel.org/doc/htmldocs/filesystems/API-vfs-unlink.html" target="_blank">vfs_unlink</a>. This chart does not show all events that remove files from the filesystem, because filesystems can create their own functions to remove files.'
    },

    'services.vfs_write': {
        info: 'Successful calls to the function <a href="https://topic.alibabacloud.com/a/kernel-state-file-operation-__-work-information-kernel_8_8_20287135.html" target="_blank">vfs_write</a>. This chart may not show all filesystem events if it uses other functions to store data on disk.'
    },

    'services.vfs_write_error': {
        info: 'Failed calls to the function <a href="https://topic.alibabacloud.com/a/kernel-state-file-operation-__-work-information-kernel_8_8_20287135.html" target="_blank">vfs_write</a>. This chart may not show all filesystem events if it uses other functions to store data on disk.'
    },

    'services.vfs_read': {
        info: 'Successful calls to the function <a href="https://topic.alibabacloud.com/a/kernel-state-file-operation-__-work-information-kernel_8_8_20287135.html" target="_blank">vfs_read</a>. This chart may not show all filesystem events if it uses other functions to store data on disk.'
    },

    'services.vfs_read_error': {
        info: 'Failed calls to the function <a href="https://topic.alibabacloud.com/a/kernel-state-file-operation-__-work-information-kernel_8_8_20287135.html" target="_blank">vfs_read</a>. This chart may not show all filesystem events if it uses other functions to store data on disk.'
    },

    'services.vfs_write_bytes': {
        info: 'Total of bytes successfully written using the function <a href="https://topic.alibabacloud.com/a/kernel-state-file-operation-__-work-information-kernel_8_8_20287135.html" target="_blank">vfs_write</a>.'
    },

    'services.vfs_read_bytes': {
        info: 'Total of bytes successfully read using the function <a href="https://topic.alibabacloud.com/a/kernel-state-file-operation-__-work-information-kernel_8_8_20287135.html" target="_blank">vfs_read</a>.'
    },

    'services.process_create': {
        info: 'Calls to either <a href="https://programming.vip/docs/the-execution-procedure-of-do_fork-function-in-linux.html" target="_blank">do_fork</a>, or <code>kernel_clone</code> if you are running kernel newer than 5.9.16, to create a new task, which is the common name used to define process and tasks inside the kernel. Netdata identifies the process by counting the number of calls to <a href="https://linux.die.net/man/2/clone" target="_blank">sys_clone</a> that do not have the flag <code>CLONE_THREAD</code> set.'
    },

    'services.thread_create': {
        info: 'Calls to either <a href="https://programming.vip/docs/the-execution-procedure-of-do_fork-function-in-linux.html" target="_blank">do_fork</a>, or <code>kernel_clone</code> if you are running kernel newer than 5.9.16, to create a new task, which is the common name used to define process and tasks inside the kernel. Netdata identifies the threads by counting the number of calls to <a  href="https://linux.die.net/man/2/clone" target="_blank">sys_clone</a> that have the flag <code>CLONE_THREAD</code> set.'
    },

    'services.task_exit': {
        info: 'Calls to the functions responsible for closing (<a href="https://www.informit.com/articles/article.aspx?p=370047&seqNum=4" target="_blank">do_exit</a>) tasks.'
    },

    'services.task_close': {
        info: 'Calls to the functions responsible for releasing (<a  href="https://www.informit.com/articles/article.aspx?p=370047&seqNum=4" target="_blank">release_task</a>) tasks.'
    },

    'services.task_error': {
        info: 'Number of errors to create a new process or thread. This chart is provided by eBPF plugin.'
    },

    'services.dc_ratio': {
        info: 'Percentage of file accesses that were present in the directory cache. 100% means that every file that was accessed was present in the directory cache. If files are not present in the directory cache 1) they are not present in the file system, 2) the files were not accessed before. Read more about <a href="https://www.kernel.org/doc/htmldocs/filesystems/the_directory_cache.html" target="_blank">directory cache</a>. Netdata also gives a summary for these charts in <a href="#menu_filesystem_submenu_directory_cache__eBPF_">Filesystem submenu</a>.'
    },

    'services.dc_reference': {
        info: 'Counters of file accesses. <code>Reference</code> is when there is a file access, see the <code>filesystem.dc_reference</code> chart for more context. Read more about <a href="https://www.kernel.org/doc/htmldocs/filesystems/the_directory_cache.html" target="_blank">directory cache</a>.'
    },

    'services.dc_not_cache': {
        info: 'Counters of file accesses. <code>Slow</code> is when there is a file access and the file is not present in the directory cache, see the <code>filesystem.dc_reference</code> chart for more context. Read more about <a href="https://www.kernel.org/doc/htmldocs/filesystems/the_directory_cache.html" target="_blank">directory cache</a>.'
    },

    'services.dc_not_found': {
        info: 'Counters of file accesses. <code>Miss</code> is when there is file access and the file is not found in the filesystem, see the <code>filesystem.dc_reference</code> chart for more context. Read more about <a href="https://www.kernel.org/doc/htmldocs/filesystems/the_directory_cache.html" target="_blank">directory cache</a>.'
    },

    'services.shmget': {
        info: 'Number of times the syscall <code>shmget</code> is called. Netdata also gives a summary for these charts in <a href="#menu_system_submenu_ipc_shared_memory">System overview</a>.'
    },

    'services.shmat': {
        info: 'Number of times the syscall <code>shmat</code> is called.'
    },

    'services.shmdt': {
        info: 'Number of times the syscall <code>shmdt</code> is called.'
    },

    'services.shmctl': {
        info: 'Number of times the syscall <code>shmctl</code> is called.'
    },

    'services.net_bytes_send': {
        info: 'Bytes sent by functions <code>tcp_sendmsg</code>.'
    },

    'services.net_bytes_recv': {
        info: 'Bytes received by functions <code>tcp_cleanup_rbuf</code> . We use <code>tcp_cleanup_rbuf</code> instead <code>tcp_recvmsg</code>, because this last misses <code>tcp_read_sock()</code> traffic and we would also need to have more probes to get the socket and package size.'
    },

    'services.net_tcp_send': {
        info: 'The function <code>tcp_sendmsg</code> is used to collect number of bytes sent from TCP connections.'
    },

    'services.net_tcp_recv': {
        info: 'The function <code>tcp_cleanup_rbuf</code> is used to collect number of bytes received from TCP connections.'
    },

    'services.net_retransmit': {
        info: 'The function <code>tcp_retransmit_skb</code> is called when the host did not receive the expected return from a packet sent.'
    },

    'services.net_udp_send': {
        info: 'The function <code>udp_sendmsg</code> is used to collect number of bytes sent from UDP connections.'
    },

    'services.net_udp_recv': {
        info: 'The function <code>udp_recvmsg</code> is used to collect number of bytes received from UDP connections.'
    },

    'services.cachestat_ratio': {
        info: 'When the processor needs to read or write a location in main memory, it checks for a corresponding entry in the page cache. If the entry is there, a page cache hit has occurred and the read is from the cache. If the entry is not there, a page cache miss has occurred and the kernel allocates a new entry and copies in data from the disk. Netdata calculates the percentage of accessed files that are cached on memory. <a href="https://github.com/iovisor/bcc/blob/master/tools/cachestat.py#L126-L138" target="_blank">The ratio</a> is calculated counting the accessed cached pages (without counting dirty pages and pages added because of read misses) divided by total access without dirty pages.'
    },

    'services.cachestat_dirties': {
        info: 'Number of <a href="https://en.wikipedia.org/wiki/Page_cache#Memory_conservation" target="_blank">dirty(modified) pages</a> cache. Pages in the page cache modified after being brought in are called dirty pages. Since non-dirty pages in the page cache have identical copies in <a href="https://en.wikipedia.org/wiki/Secondary_storage" target="_blank">secondary storage</a> (e.g. hard disk drive or solid-state drive), discarding and reusing their space is much quicker than paging out application memory, and is often preferred over flushing the dirty pages into secondary storage and reusing their space.'
    },

    'services.cachestat_hits': {
        info: 'When the processor needs to read or write a location in main memory, it checks for a corresponding entry in the page cache. If the entry is there, a page cache hit has occurred and the read is from the cache. Hits show pages accessed that were not modified (we are excluding dirty pages), this counting also excludes the recent pages inserted for read.'
    },

    'services.cachestat_misses': {
        info: 'When the processor needs to read or write a location in main memory, it checks for a corresponding entry in the page cache. If the entry is not there, a page cache miss has occurred and the cache allocates a new entry and copies in data for the main memory. Misses count page insertions to the memory not related to writing.'
    },

    // ------------------------------------------------------------------------
    // beanstalkd
    // system charts
    'beanstalk.cpu_usage': {
        info: 'Amount of CPU Time for user and system used by beanstalkd.'
    },

    // This is also a per-tube stat
    'beanstalk.jobs_rate': {
        info: 'The rate of jobs processed by the beanstalkd served.'
    },

    'beanstalk.connections_rate': {
        info: 'The rate of connections opened to beanstalkd.'
    },

    'beanstalk.commands_rate': {
        info: 'The rate of commands received by beanstalkd.'
    },

    'beanstalk.current_tubes': {
        info: 'Total number of current tubes on the server including the default tube (which always exists).'
    },

    'beanstalk.current_jobs': {
        info: 'Current number of jobs in all tubes grouped by status: urgent, ready, reserved, delayed and buried.'
    },

    'beanstalk.current_connections': {
        info: 'Current number of connections group by connection type: written, producers, workers, waiting.'
    },

    'beanstalk.binlog': {
        info: 'The rate of records <code>written</code> to binlog and <code>migrated</code> as part of compaction.'
    },

    'beanstalk.uptime': {
        info: 'Total time beanstalkd server has been up for.'
    },

    // tube charts
    'beanstalk.jobs': {
        info: 'Number of jobs currently in the tube grouped by status: urgent, ready, reserved, delayed and buried.'
    },

    'beanstalk.connections': {
        info: 'The current number of connections to this tube grouped by connection type; using, waiting and watching.'
    },

    'beanstalk.commands': {
        info: 'The rate of <code>delete</code> and <code>pause</code> commands executed by beanstalkd.'
    },

    'beanstalk.pause': {
        info: 'Shows info on how long the tube has been paused for, and how long is left remaining on the pause.'
    },

    // ------------------------------------------------------------------------
    // ceph

    'ceph.general_usage': {
        info: 'The usage and available space in all ceph cluster.'
    },

    'ceph.general_objects': {
        info: 'Total number of objects storage on ceph cluster.'
    },

    'ceph.general_bytes': {
        info: 'Cluster read and write data per second.'
    },

    'ceph.general_operations': {
        info: 'Number of read and write operations per second.'
    },

    'ceph.general_latency': {
        info: 'Total of apply and commit latency in all OSDs. The apply latency is the total time taken to flush an update to disk. The commit latency is the total time taken to commit an operation to the journal.'
    },

    'ceph.pool_usage': {
        info: 'The usage space in each pool.'
    },

    'ceph.pool_objects': {
        info: 'Number of objects presents in each pool.'
    },

    'ceph.pool_read_bytes': {
        info: 'The rate of read data per second in each pool.'
    },

    'ceph.pool_write_bytes': {
        info: 'The rate of write data per second in each pool.'
    },

    'ceph.pool_read_objects': {
        info: 'Number of read objects per second in each pool.'
    },

    'ceph.pool_write_objects': {
        info: 'Number of write objects per second in each pool.'
    },

    'ceph.osd_usage': {
        info: 'The usage space in each OSD.'
    },

    'ceph.osd_size': {
        info: "Each OSD's size"
    },

    'ceph.apply_latency': {
        info: 'Time taken to flush an update in each OSD.'
    },

    'ceph.commit_latency': {
        info: 'Time taken to commit an operation to the journal in each OSD.'
    },

    // ------------------------------------------------------------------------
    // web_log

    'web_log.response_statuses': {
        info: 'Web server responses by type. <code>success</code> includes <b>1xx</b>, <b>2xx</b>, <b>304</b> and <b>401</b>, <code>error</code> includes <b>5xx</b>, <code>redirect</code> includes <b>3xx</b> except <b>304</b>, <code>bad</code> includes <b>4xx</b> except <b>401</b>, <code>other</code> are all the other responses.',
        mainheads: [
            function (os, id) {
                void (os);
                return '<div data-netdata="' + id + '"'
                    + ' data-dimensions="success"'
                    + ' data-chart-library="gauge"'
                    + ' data-title="Successful"'
                    + ' data-units="requests/s"'
                    + ' data-gauge-adjust="width"'
                    + ' data-width="12%"'
                    + ' data-before="0"'
                    + ' data-after="-CHART_DURATION"'
                    + ' data-points="CHART_DURATION"'
                    + ' data-common-max="' + id + '"'
                    + ' data-colors="' + NETDATA.colors[0] + '"'
                    + ' data-decimal-digits="0"'
                    + ' role="application"></div>';
            },

            function (os, id) {
                void (os);
                return '<div data-netdata="' + id + '"'
                    + ' data-dimensions="redirect"'
                    + ' data-chart-library="gauge"'
                    + ' data-title="Redirects"'
                    + ' data-units="requests/s"'
                    + ' data-gauge-adjust="width"'
                    + ' data-width="12%"'
                    + ' data-before="0"'
                    + ' data-after="-CHART_DURATION"'
                    + ' data-points="CHART_DURATION"'
                    + ' data-common-max="' + id + '"'
                    + ' data-colors="' + NETDATA.colors[2] + '"'
                    + ' data-decimal-digits="0"'
                    + ' role="application"></div>';
            },

            function (os, id) {
                void (os);
                return '<div data-netdata="' + id + '"'
                    + ' data-dimensions="bad"'
                    + ' data-chart-library="gauge"'
                    + ' data-title="Bad Requests"'
                    + ' data-units="requests/s"'
                    + ' data-gauge-adjust="width"'
                    + ' data-width="12%"'
                    + ' data-before="0"'
                    + ' data-after="-CHART_DURATION"'
                    + ' data-points="CHART_DURATION"'
                    + ' data-common-max="' + id + '"'
                    + ' data-colors="' + NETDATA.colors[3] + '"'
                    + ' data-decimal-digits="0"'
                    + ' role="application"></div>';
            },

            function (os, id) {
                void (os);
                return '<div data-netdata="' + id + '"'
                    + ' data-dimensions="error"'
                    + ' data-chart-library="gauge"'
                    + ' data-title="Server Errors"'
                    + ' data-units="requests/s"'
                    + ' data-gauge-adjust="width"'
                    + ' data-width="12%"'
                    + ' data-before="0"'
                    + ' data-after="-CHART_DURATION"'
                    + ' data-points="CHART_DURATION"'
                    + ' data-common-max="' + id + '"'
                    + ' data-colors="' + NETDATA.colors[1] + '"'
                    + ' data-decimal-digits="0"'
                    + ' role="application"></div>';
            }
        ]
    },

    'web_log.response_codes': {
        info: 'Web server responses by code family. ' +
            'According to the standards <code>1xx</code> are informational responses, ' +
            '<code>2xx</code> are successful responses, ' +
            '<code>3xx</code> are redirects (although they include <b>304</b> which is used as "<b>not modified</b>"), ' +
            '<code>4xx</code> are bad requests, ' +
            '<code>5xx</code> are internal server errors, ' +
            '<code>other</code> are non-standard responses, ' +
            '<code>unmatched</code> counts the lines in the log file that are not matched by the plugin (<a href="https://github.com/netdata/netdata/issues/new?title=web_log%20reports%20unmatched%20lines&body=web_log%20plugin%20reports%20unmatched%20lines.%0A%0AThis%20is%20my%20log:%0A%0A%60%60%60txt%0A%0Aplease%20paste%20your%20web%20server%20log%20here%0A%0A%60%60%60" target="_blank">let us know</a> if you have any unmatched).'
    },

    'web_log.response_time': {
        mainheads: [
            function (os, id) {
                void (os);
                return '<div data-netdata="' + id + '"'
                    + ' data-dimensions="avg"'
                    + ' data-chart-library="gauge"'
                    + ' data-title="Average Response Time"'
                    + ' data-units="milliseconds"'
                    + ' data-gauge-adjust="width"'
                    + ' data-width="12%"'
                    + ' data-before="0"'
                    + ' data-after="-CHART_DURATION"'
                    + ' data-points="CHART_DURATION"'
                    + ' data-colors="' + NETDATA.colors[4] + '"'
                    + ' data-decimal-digits="2"'
                    + ' role="application"></div>';
            }
        ]
    },

    'web_log.detailed_response_codes': {
        info: 'Number of responses for each response code individually.'
    },

    'web_log.requests_per_ipproto': {
        info: 'Web server requests received per IP protocol version.'
    },

    'web_log.clients': {
        info: 'Unique client IPs accessing the web server, within each data collection iteration. If data collection is <b>per second</b>, this chart shows <b>unique client IPs per second</b>.'
    },

    'web_log.clients_all': {
        info: 'Unique client IPs accessing the web server since the last restart of netdata. This plugin keeps in memory all the unique IPs that have accessed the web server. On very busy web servers (several millions of unique IPs) you may want to disable this chart (check <a href="https://github.com/netdata/netdata/blob/master/collectors/python.d.plugin/web_log/web_log.conf" target="_blank"><code>/etc/netdata/python.d/web_log.conf</code></a>).'
    },

    // ------------------------------------------------------------------------
    // web_log for squid

    'web_log.squid_response_statuses': {
        info: 'Squid responses by type. ' +
            '<code>success</code> includes <b>1xx</b>, <b>2xx</b>, <b>000</b>, <b>304</b>, ' +
            '<code>error</code> includes <b>5xx</b> and <b>6xx</b>, ' +
            '<code>redirect</code> includes <b>3xx</b> except <b>304</b>, ' +
            '<code>bad</code> includes <b>4xx</b>, ' +
            '<code>other</code> are all the other responses.',
        mainheads: [
            function (os, id) {
                void (os);
                return '<div data-netdata="' + id + '"'
                    + ' data-dimensions="success"'
                    + ' data-chart-library="gauge"'
                    + ' data-title="Successful"'
                    + ' data-units="requests/s"'
                    + ' data-gauge-adjust="width"'
                    + ' data-width="12%"'
                    + ' data-before="0"'
                    + ' data-after="-CHART_DURATION"'
                    + ' data-points="CHART_DURATION"'
                    + ' data-common-max="' + id + '"'
                    + ' data-colors="' + NETDATA.colors[0] + '"'
                    + ' data-decimal-digits="0"'
                    + ' role="application"></div>';
            },

            function (os, id) {
                void (os);
                return '<div data-netdata="' + id + '"'
                    + ' data-dimensions="redirect"'
                    + ' data-chart-library="gauge"'
                    + ' data-title="Redirects"'
                    + ' data-units="requests/s"'
                    + ' data-gauge-adjust="width"'
                    + ' data-width="12%"'
                    + ' data-before="0"'
                    + ' data-after="-CHART_DURATION"'
                    + ' data-points="CHART_DURATION"'
                    + ' data-common-max="' + id + '"'
                    + ' data-colors="' + NETDATA.colors[2] + '"'
                    + ' data-decimal-digits="0"'
                    + ' role="application"></div>';
            },

            function (os, id) {
                void (os);
                return '<div data-netdata="' + id + '"'
                    + ' data-dimensions="bad"'
                    + ' data-chart-library="gauge"'
                    + ' data-title="Bad Requests"'
                    + ' data-units="requests/s"'
                    + ' data-gauge-adjust="width"'
                    + ' data-width="12%"'
                    + ' data-before="0"'
                    + ' data-after="-CHART_DURATION"'
                    + ' data-points="CHART_DURATION"'
                    + ' data-common-max="' + id + '"'
                    + ' data-colors="' + NETDATA.colors[3] + '"'
                    + ' data-decimal-digits="0"'
                    + ' role="application"></div>';
            },

            function (os, id) {
                void (os);
                return '<div data-netdata="' + id + '"'
                    + ' data-dimensions="error"'
                    + ' data-chart-library="gauge"'
                    + ' data-title="Server Errors"'
                    + ' data-units="requests/s"'
                    + ' data-gauge-adjust="width"'
                    + ' data-width="12%"'
                    + ' data-before="0"'
                    + ' data-after="-CHART_DURATION"'
                    + ' data-points="CHART_DURATION"'
                    + ' data-common-max="' + id + '"'
                    + ' data-colors="' + NETDATA.colors[1] + '"'
                    + ' data-decimal-digits="0"'
                    + ' role="application"></div>';
            }
        ]
    },

    'web_log.squid_response_codes': {
        info: 'Web server responses by code family. ' +
            'According to HTTP standards <code>1xx</code> are informational responses, ' +
            '<code>2xx</code> are successful responses, ' +
            '<code>3xx</code> are redirects (although they include <b>304</b> which is used as "<b>not modified</b>"), ' +
            '<code>4xx</code> are bad requests, ' +
            '<code>5xx</code> are internal server errors. ' +
            'Squid also defines <code>000</code> mostly for UDP requests, and ' +
            '<code>6xx</code> for broken upstream servers sending wrong headers. ' +
            'Finally, <code>other</code> are non-standard responses, and ' +
            '<code>unmatched</code> counts the lines in the log file that are not matched by the plugin (<a href="https://github.com/netdata/netdata/issues/new?title=web_log%20reports%20unmatched%20lines&body=web_log%20plugin%20reports%20unmatched%20lines.%0A%0AThis%20is%20my%20log:%0A%0A%60%60%60txt%0A%0Aplease%20paste%20your%20web%20server%20log%20here%0A%0A%60%60%60" target="_blank">let us know</a> if you have any unmatched).'
    },

    'web_log.squid_duration': {
        mainheads: [
            function (os, id) {
                void (os);
                return '<div data-netdata="' + id + '"'
                    + ' data-dimensions="avg"'
                    + ' data-chart-library="gauge"'
                    + ' data-title="Average Response Time"'
                    + ' data-units="milliseconds"'
                    + ' data-gauge-adjust="width"'
                    + ' data-width="12%"'
                    + ' data-before="0"'
                    + ' data-after="-CHART_DURATION"'
                    + ' data-points="CHART_DURATION"'
                    + ' data-colors="' + NETDATA.colors[4] + '"'
                    + ' data-decimal-digits="2"'
                    + ' role="application"></div>';
            }
        ]
    },

    'web_log.squid_detailed_response_codes': {
        info: 'Number of responses for each response code individually.'
    },

    'web_log.squid_clients': {
        info: 'Unique client IPs accessing squid, within each data collection iteration. If data collection is <b>per second</b>, this chart shows <b>unique client IPs per second</b>.'
    },

    'web_log.squid_clients_all': {
        info: 'Unique client IPs accessing squid since the last restart of netdata. This plugin keeps in memory all the unique IPs that have accessed the server. On very busy squid servers (several millions of unique IPs) you may want to disable this chart (check <a href="https://github.com/netdata/netdata/blob/master/collectors/python.d.plugin/web_log/web_log.conf" target="_blank"><code>/etc/netdata/python.d/web_log.conf</code></a>).'
    },

    'web_log.squid_transport_methods': {
        info: 'Break down per delivery method: <code>TCP</code> are requests on the HTTP port (usually 3128), ' +
            '<code>UDP</code> are requests on the ICP port (usually 3130), or HTCP port (usually 4128). ' +
            'If ICP logging was disabled using the log_icp_queries option, no ICP replies will be logged. ' +
            '<code>NONE</code> are used to state that squid delivered an unusual response or no response at all. ' +
            'Seen with cachemgr requests and errors, usually when the transaction fails before being classified into one of the above outcomes. ' +
            'Also seen with responses to <code>CONNECT</code> requests.'
    },

    'web_log.squid_code': {
        info: 'These are combined squid result status codes. A break down per component is given in the following charts. ' +
            'Check the <a href="http://wiki.squid-cache.org/SquidFaq/SquidLogs" target="_blank">squid documentation about them</a>.'
    },

    'web_log.squid_handling_opts': {
        info: 'These tags are optional and describe why the particular handling was performed or where the request came from. ' +
            '<code>CLIENT</code> means that the client request placed limits affecting the response. Usually seen with client issued a <b>no-cache</b>, or analogous cache control command along with the request. Thus, the cache has to validate the object.' +
            '<code>IMS</code> states that the client sent a revalidation (conditional) request. ' +
            '<code>ASYNC</code>, is used when the request was generated internally by Squid. Usually this is background fetches for cache information exchanges, background revalidation from stale-while-revalidate cache controls, or ESI sub-objects being loaded. ' +
            '<code>SWAPFAIL</code> is assigned when the object was believed to be in the cache, but could not be accessed. A new copy was requested from the server. ' +
            '<code>REFRESH</code> when a revalidation (conditional) request was sent to the server. ' +
            '<code>SHARED</code> when this request was combined with an existing transaction by collapsed forwarding. NOTE: the existing request is not marked as SHARED. ' +
            '<code>REPLY</code> when particular handling was requested in the HTTP reply from server or peer. Usually seen on DENIED due to http_reply_access ACLs preventing delivery of servers response object to the client.'
    },

    'web_log.squid_object_types': {
        info: 'These tags are optional and describe what type of object was produced. ' +
            '<code>NEGATIVE</code> is only seen on HIT responses, indicating the response was a cached error response. e.g. <b>404 not found</b>. ' +
            '<code>STALE</code> means the object was cached and served stale. This is usually caused by stale-while-revalidate or stale-if-error cache controls. ' +
            '<code>OFFLINE</code> when the requested object was retrieved from the cache during offline_mode. The offline mode never validates any object. ' +
            '<code>INVALID</code> when an invalid request was received. An error response was delivered indicating what the problem was. ' +
            '<code>FAIL</code> is only seen on <code>REFRESH</code> to indicate the revalidation request failed. The response object may be the server provided network error or the stale object which was being revalidated depending on stale-if-error cache control. ' +
            '<code>MODIFIED</code> is only seen on <code>REFRESH</code> responses to indicate revalidation produced a new modified object. ' +
            '<code>UNMODIFIED</code> is only seen on <code>REFRESH</code> responses to indicate revalidation produced a <b>304</b> (Not Modified) status, which was relayed to the client. ' +
            '<code>REDIRECT</code> when squid generated an HTTP redirect response to this request.'
    },

    'web_log.squid_cache_events': {
        info: 'These tags are optional and describe whether the response was loaded from cache, network, or otherwise. ' +
            '<code>HIT</code> when the response object delivered was the local cache object. ' +
            '<code>MEM</code> when the response object came from memory cache, avoiding disk accesses. Only seen on HIT responses. ' +
            '<code>MISS</code> when the response object delivered was the network response object. ' +
            '<code>DENIED</code> when the request was denied by access controls. ' +
            '<code>NOFETCH</code> an ICP specific type, indicating service is alive, but not to be used for this request (sent during "-Y" startup, or during frequent failures, a cache in hit only mode will return either UDP_HIT or UDP_MISS_NOFETCH. Neighbours will thus only fetch hits). ' +
            '<code>TUNNEL</code> when a binary tunnel was established for this transaction.'
    },

    'web_log.squid_transport_errors': {
        info: 'These tags are optional and describe some error conditions which occurred during response delivery (if any). ' +
            '<code>ABORTED</code> when the response was not completed due to the connection being aborted (usually by the client). ' +
            '<code>TIMEOUT</code>, when the response was not completed due to a connection timeout.'
    },

     // ------------------------------------------------------------------------
    // go web_log

    'web_log.type_requests': {
        info: 'Web server responses by type. <code>success</code> includes <b>1xx</b>, <b>2xx</b>, <b>304</b> and <b>401</b>, <code>error</code> includes <b>5xx</b>, <code>redirect</code> includes <b>3xx</b> except <b>304</b>, <code>bad</code> includes <b>4xx</b> except <b>401</b>, <code>other</code> are all the other responses.',
        mainheads: [
            function (os, id) {
                void (os);
                return '<div data-netdata="' + id + '"'
                    + ' data-dimensions="success"'
                    + ' data-chart-library="gauge"'
                    + ' data-title="Successful"'
                    + ' data-units="requests/s"'
                    + ' data-gauge-adjust="width"'
                    + ' data-width="12%"'
                    + ' data-before="0"'
                    + ' data-after="-CHART_DURATION"'
                    + ' data-points="CHART_DURATION"'
                    + ' data-common-max="' + id + '"'
                    + ' data-colors="' + NETDATA.colors[0] + '"'
                    + ' data-decimal-digits="0"'
                    + ' role="application"></div>';
            },

            function (os, id) {
                void (os);
                return '<div data-netdata="' + id + '"'
                    + ' data-dimensions="redirect"'
                    + ' data-chart-library="gauge"'
                    + ' data-title="Redirects"'
                    + ' data-units="requests/s"'
                    + ' data-gauge-adjust="width"'
                    + ' data-width="12%"'
                    + ' data-before="0"'
                    + ' data-after="-CHART_DURATION"'
                    + ' data-points="CHART_DURATION"'
                    + ' data-common-max="' + id + '"'
                    + ' data-colors="' + NETDATA.colors[2] + '"'
                    + ' data-decimal-digits="0"'
                    + ' role="application"></div>';
            },

            function (os, id) {
                void (os);
                return '<div data-netdata="' + id + '"'
                    + ' data-dimensions="bad"'
                    + ' data-chart-library="gauge"'
                    + ' data-title="Bad Requests"'
                    + ' data-units="requests/s"'
                    + ' data-gauge-adjust="width"'
                    + ' data-width="12%"'
                    + ' data-before="0"'
                    + ' data-after="-CHART_DURATION"'
                    + ' data-points="CHART_DURATION"'
                    + ' data-common-max="' + id + '"'
                    + ' data-colors="' + NETDATA.colors[3] + '"'
                    + ' data-decimal-digits="0"'
                    + ' role="application"></div>';
            },

            function (os, id) {
                void (os);
                return '<div data-netdata="' + id + '"'
                    + ' data-dimensions="error"'
                    + ' data-chart-library="gauge"'
                    + ' data-title="Server Errors"'
                    + ' data-units="requests/s"'
                    + ' data-gauge-adjust="width"'
                    + ' data-width="12%"'
                    + ' data-before="0"'
                    + ' data-after="-CHART_DURATION"'
                    + ' data-points="CHART_DURATION"'
                    + ' data-common-max="' + id + '"'
                    + ' data-colors="' + NETDATA.colors[1] + '"'
                    + ' data-decimal-digits="0"'
                    + ' role="application"></div>';
            }
        ]
    },

    'web_log.request_processing_time': {
        mainheads: [
            function (os, id) {
                void (os);
                return '<div data-netdata="' + id + '"'
                    + ' data-dimensions="avg"'
                    + ' data-chart-library="gauge"'
                    + ' data-title="Average Response Time"'
                    + ' data-units="milliseconds"'
                    + ' data-gauge-adjust="width"'
                    + ' data-width="12%"'
                    + ' data-before="0"'
                    + ' data-after="-CHART_DURATION"'
                    + ' data-points="CHART_DURATION"'
                    + ' data-colors="' + NETDATA.colors[4] + '"'
                    + ' data-decimal-digits="2"'
                    + ' role="application"></div>';
            }
        ]
    },
    // ------------------------------------------------------------------------
    // Fronius Solar Power

    'fronius.power': {
        info: 'Positive <code>Grid</code> values mean that power is coming from the grid. Negative values are excess power that is going back into the grid, possibly selling it. ' +
            '<code>Photovoltaics</code> is the power generated from the solar panels. ' +
            '<code>Accumulator</code> is the stored power in the accumulator, if one is present.'
    },

    'fronius.autonomy': {
        commonMin: true,
        commonMax: true,
        valueRange: "[0, 100]",
        info: 'The <code>Autonomy</code> is the percentage of how autonomous the installation is. An autonomy of 100 % means that the installation is producing more energy than it is needed. ' +
            'The <code>Self consumption</code> indicates the ratio between the current power generated and the current load. When it reaches 100 %, the <code>Autonomy</code> declines, since the solar panels can not produce enough energy and need support from the grid.'
    },

    'fronius.energy.today': {
        commonMin: true,
        commonMax: true,
        valueRange: "[0, null]"
    },

    // ------------------------------------------------------------------------
    // Stiebel Eltron Heat pump installation

    'stiebeleltron.system.roomtemp': {
        commonMin: true,
        commonMax: true,
        valueRange: "[0, null]"
    },

    // ------------------------------------------------------------------------
    // Port check

    'portcheck.latency': {
        info: 'The <code>latency</code> describes the time spent connecting to a TCP port. No data is sent or received. ' +
            'Currently, the accuracy of the latency is low and should be used as reference only.'
    },

    'portcheck.status': {
        valueRange: "[0, 1]",
        info: 'The <code>status</code> chart verifies the availability of the service. ' +
            'Each status dimension will have a value of <code>1</code> if triggered. Dimension <code>success</code> is <code>1</code> only if connection could be established. ' +
            'This chart is most useful for alarms and third-party apps.'
    },

    // ------------------------------------------------------------------------

    'chrony.system': {
        info: 'In normal operation, chronyd never steps the system clock, because any jump in the timescale can have adverse consequences for certain application programs. Instead, any error in the system clock is corrected by slightly speeding up or slowing down the system clock until the error has been removed, and then returning to the system clock’s normal speed. A consequence of this is that there will be a period when the system clock (as read by other programs using the <code>gettimeofday()</code> system call, or by the <code>date</code> command in the shell) will be different from chronyd\'s estimate of the current true time (which it reports to NTP clients when it is operating in server mode). The value reported on this line is the difference due to this effect.',
        colors: NETDATA.colors[3]
    },

    'chrony.offsets': {
        info: '<code>last offset</code> is the estimated local offset on the last clock update. <code>RMS offset</code> is a long-term average of the offset value.',
        height: 0.5
    },

    'chrony.stratum': {
        info: 'The <code>stratum</code> indicates how many hops away from a computer with an attached reference clock we are. Such a computer is a stratum-1 computer.',
        decimalDigits: 0,
        height: 0.5
    },

    'chrony.root': {
        info: 'Estimated delays against the root time server this system is synchronized with. <code>delay</code> is the total of the network path delays to the stratum-1 computer from which the computer is ultimately synchronised. <code>dispersion</code> is the total dispersion accumulated through all the computers back to the stratum-1 computer from which the computer is ultimately synchronised. Dispersion is due to system clock resolution, statistical measurement variations etc.'
    },

    'chrony.frequency': {
        info: 'The <code>frequency</code> is the rate by which the system\'s clock would be would be wrong if chronyd was not correcting it. It is expressed in ppm (parts per million). For example, a value of 1ppm would mean that when the system\'s clock thinks it has advanced 1 second, it has actually advanced by 1.000001 seconds relative to true time.',
        colors: NETDATA.colors[0]
    },

    'chrony.residualfreq': {
        info: 'This shows the <code>residual frequency</code> for the currently selected reference source. ' +
            'It reflects any difference between what the measurements from the reference source indicate the ' +
            'frequency should be and the frequency currently being used. The reason this is not always zero is ' +
            'that a smoothing procedure is applied to the frequency. Each time a measurement from the reference ' +
            'source is obtained and a new residual frequency computed, the estimated accuracy of this residual ' +
            'is compared with the estimated accuracy (see <code>skew</code>) of the existing frequency value. ' +
            'A weighted average is computed for the new frequency, with weights depending on these accuracies. ' +
            'If the measurements from the reference source follow a consistent trend, the residual will be ' +
            'driven to zero over time.',
        height: 0.5,
        colors: NETDATA.colors[3]
    },

    'chrony.skew': {
        info: 'The estimated error bound on the frequency.',
        height: 0.5,
        colors: NETDATA.colors[5]
    },

    'couchdb.active_tasks': {
        info: 'Active tasks running on this CouchDB <b>cluster</b>. Four types of tasks currently exist: indexer (view building), replication, database compaction and view compaction.'
    },

    'couchdb.replicator_jobs': {
        info: 'Detailed breakdown of any replication jobs in progress on this node. For more information, see the <a href="http://docs.couchdb.org/en/latest/replication/replicator.html" target="_blank">replicator documentation</a>.'
    },

    'couchdb.open_files': {
        info: 'Count of all files held open by CouchDB. If this value seems pegged at 1024 or 4096, your server process is probably hitting the open file handle limit and <a href="http://docs.couchdb.org/en/latest/maintenance/performance.html#pam-and-ulimit" target="_blank">needs to be increased.</a>'
    },

    'btrfs.disk': {
        info: 'Physical disk usage of BTRFS. The disk space reported here is the raw physical disk space assigned to the BTRFS volume (i.e. <b>before any RAID levels</b>). BTRFS uses a two-stage allocator, first allocating large regions of disk space for one type of block (data, metadata, or system), and then using a regular block allocator inside those regions. <code>unallocated</code> is the physical disk space that is not allocated yet and is available to become data, metadata or system on demand. When <code>unallocated</code> is zero, all available disk space has been allocated to a specific function. Healthy volumes should ideally have at least five percent of their total space <code>unallocated</code>. You can keep your volume healthy by running the <code>btrfs balance</code> command on it regularly (check <code>man btrfs-balance</code> for more info).  Note that some of the space listed as <code>unallocated</code> may not actually be usable if the volume uses devices of different sizes.',
        colors: [NETDATA.colors[12]]
    },

    'btrfs.data': {
        info: 'Logical disk usage for BTRFS data. Data chunks are used to store the actual file data (file contents). The disk space reported here is the usable allocation (i.e. after any striping or replication). Healthy volumes should ideally have no more than a few GB of free space reported here persistently. Running <code>btrfs balance</code> can help here.'
    },

    'btrfs.metadata': {
        info: 'Logical disk usage for BTRFS metadata. Metadata chunks store most of the filesystem internal structures, as well as information like directory structure and file names. The disk space reported here is the usable allocation (i.e. after any striping or replication). Healthy volumes should ideally have no more than a few GB of free space reported here persistently. Running <code>btrfs balance</code> can help here.'
    },

    'btrfs.system': {
        info: 'Logical disk usage for BTRFS system. System chunks store information about the allocation of other chunks. The disk space reported here is the usable allocation (i.e. after any striping or replication). The values reported here should be relatively small compared to Data and Metadata, and will scale with the volume size and overall space usage.'
    },

    // ------------------------------------------------------------------------
    // RabbitMQ

    // info: the text above the charts
    // heads: the representation of the chart at the top the subsection (second level menu)
    // mainheads: the representation of the chart at the top of the section (first level menu)
    // colors: the dimension colors of the chart (the default colors are appended)
    // height: the ratio of the chart height relative to the default

    'rabbitmq.queued_messages': {
        info: 'Overall total of ready and unacknowledged queued messages.  Messages that are delivered immediately are not counted here.'
    },

    'rabbitmq.message_rates': {
        info: 'Overall messaging rates including acknowledgements, deliveries, redeliveries, and publishes.'
    },

    'rabbitmq.global_counts': {
        info: 'Overall totals for channels, consumers, connections, queues and exchanges.'
    },

    'rabbitmq.file_descriptors': {
        info: 'Total number of used filed descriptors. See <code><a href="https://www.rabbitmq.com/production-checklist.html#resource-limits-file-handle-limit" target="_blank">Open File Limits</a></code> for further details.',
        colors: NETDATA.colors[3]
    },

    'rabbitmq.sockets': {
        info: 'Total number of used socket descriptors.  Each used socket also counts as a used file descriptor.  See <code><a href="https://www.rabbitmq.com/production-checklist.html#resource-limits-file-handle-limit" target="_blank">Open File Limits</a></code> for further details.',
        colors: NETDATA.colors[3]
    },

    'rabbitmq.processes': {
        info: 'Total number of processes running within the Erlang VM.  This is not the same as the number of processes running on the host.',
        colors: NETDATA.colors[3]
    },

    'rabbitmq.erlang_run_queue': {
        info: 'Number of Erlang processes the Erlang schedulers have queued to run.',
        colors: NETDATA.colors[3]
    },

    'rabbitmq.memory': {
        info: 'Total amount of memory used by the RabbitMQ.  This is a complex statistic that can be further analyzed in the management UI.  See <code><a href="https://www.rabbitmq.com/production-checklist.html#resource-limits-ram" target="_blank">Memory</a></code> for further details.',
        colors: NETDATA.colors[3]
    },

    'rabbitmq.disk_space': {
        info: 'Total amount of disk space consumed by the message store(s).  See <code><a href="https://www.rabbitmq.com/production-checklist.html#resource-limits-disk-space" target=_"blank">Disk Space Limits</a></code> for further details.',
        colors: NETDATA.colors[3]
    },

    'rabbitmq.queue_messages': {
        info: 'Total amount of messages and their states in this queue.',
        colors: NETDATA.colors[3]
    },

    'rabbitmq.queue_messages_stats': {
        info: 'Overall messaging rates including acknowledgements, deliveries, redeliveries, and publishes.',
        colors: NETDATA.colors[3]
    },

    // ------------------------------------------------------------------------
    // ntpd

    'ntpd.sys_offset': {
        info: 'For hosts without any time critical services an offset of &lt; 100 ms should be acceptable even with high network latencies. For hosts with time critical services an offset of about 0.01 ms or less can be achieved by using peers with low delays and configuring optimal <b>poll exponent</b> values.',
        colors: NETDATA.colors[4]
    },

    'ntpd.sys_jitter': {
        info: 'The jitter statistics are exponentially-weighted RMS averages. The system jitter is defined in the NTPv4 specification; the clock jitter statistic is computed by the clock discipline module.'
    },

    'ntpd.sys_frequency': {
        info: 'The frequency offset is shown in ppm (parts per million) relative to the frequency of the system. The frequency correction needed for the clock can vary significantly between boots and also due to external influences like temperature or radiation.',
        colors: NETDATA.colors[2],
        height: 0.6
    },

    'ntpd.sys_wander': {
        info: 'The wander statistics are exponentially-weighted RMS averages.',
        colors: NETDATA.colors[3],
        height: 0.6
    },

    'ntpd.sys_rootdelay': {
        info: 'The rootdelay is the round-trip delay to the primary reference clock, similar to the delay shown by the <code>ping</code> command. A lower delay should result in a lower clock offset.',
        colors: NETDATA.colors[1]
    },

    'ntpd.sys_stratum': {
        info: 'The distance in "hops" to the primary reference clock',
        colors: NETDATA.colors[5],
        height: 0.3
    },

    'ntpd.sys_tc': {
        info: 'Time constants and poll intervals are expressed as exponents of 2. The default poll exponent of 6 corresponds to a poll interval of 64 s. For typical Internet paths, the optimum poll interval is about 64 s. For fast LANs with modern computers, a poll exponent of 4 (16 s) is appropriate. The <a href="http://doc.ntp.org/current-stable/poll.html" target="_blank">poll process</a> sends NTP packets at intervals determined by the clock discipline algorithm.',
        height: 0.5
    },

    'ntpd.sys_precision': {
        colors: NETDATA.colors[6],
        height: 0.2
    },

    'ntpd.peer_offset': {
        info: 'The offset of the peer clock relative to the system clock in milliseconds. Smaller values here weight peers more heavily for selection after the initial synchronization of the local clock. For a system providing time service to other systems, these should be as low as possible.'
    },

    'ntpd.peer_delay': {
        info: 'The round-trip time (RTT) for communication with the peer, similar to the delay shown by the <code>ping</code> command. Not as critical as either the offset or jitter, but still factored into the selection algorithm (because as a general rule, lower delay means more accurate time). In most cases, it should be below 100ms.'
    },

    'ntpd.peer_dispersion': {
        info: 'This is a measure of the estimated error between the peer and the local system. Lower values here are better.'
    },

    'ntpd.peer_jitter': {
        info: 'This is essentially a remote estimate of the peer\'s <code>system_jitter</code> value. Lower values here weight highly in favor of peer selection, and this is a good indicator of overall quality of a given time server (good servers will have values not exceeding single digit milliseconds here, with high quality stratum one servers regularly having sub-millisecond jitter).'
    },

    'ntpd.peer_xleave': {
        info: 'This variable is used in interleaved mode (used only in NTP symmetric and broadcast modes). See <a href="http://doc.ntp.org/current-stable/xleave.html" target="_blank">NTP Interleaved Modes</a>.'
    },

    'ntpd.peer_rootdelay': {
        info: 'For a stratum 1 server, this is the access latency for the reference clock. For lower stratum servers, it is the sum of the <code>peer_delay</code> and <code>peer_rootdelay</code> for the system they are syncing off of. Similarly to <code>peer_delay</code>, lower values here are technically better, but have limited influence in peer selection.'
    },

    'ntpd.peer_rootdisp': {
        info: 'Is the same as <code>peer_rootdelay</code>, but measures accumulated <code>peer_dispersion</code> instead of accumulated <code>peer_delay</code>.'
    },

    'ntpd.peer_hmode': {
        info: 'The <code>peer_hmode</code> and <code>peer_pmode</code> variables give info about what mode the packets being sent to and received from a given peer are. Mode 1 is symmetric active (both the local system and the remote peer have each other declared as peers in <code>/etc/ntp.conf</code>), Mode 2 is symmetric passive (only one side has the other declared as a peer), Mode 3 is client, Mode 4 is server, and Mode 5 is broadcast (also used for multicast and manycast operation).',
        height: 0.2
    },

    'ntpd.peer_pmode': {
        height: 0.2
    },

    'ntpd.peer_hpoll': {
        info: 'The <code>peer_hpoll</code> and <code>peer_ppoll</code> variables are log2 representations of the polling interval in seconds.',
        height: 0.5
    },

    'ntpd.peer_ppoll': {
        height: 0.5
    },

    'ntpd.peer_precision': {
        height: 0.2
    },

    'spigotmc.tps': {
        info: 'The running 1, 5, and 15 minute average number of server ticks per second.  An idealized server will show 20.0 for all values, but in practice this almost never happens.  Typical servers should show approximately 19.98-20.0 here.  Lower values indicate progressively more server-side lag (and thus that you need better hardware for your server or a lower user limit).  For every 0.05 ticks below 20, redstone clocks will lag behind by approximately 0.25%.  Values below approximately 19.50 may interfere with complex free-running redstone circuits and will noticeably slow down growth.'
    },

    'spigotmc.users': {
        info: 'The number of currently connected users on the monitored Spigot server.'
    },

    'boinc.tasks': {
        info: 'The total number of tasks and the number of active tasks.  Active tasks are those which are either currently being processed, or are partially processed but suspended.'
    },

    'boinc.states': {
        info: 'Counts of tasks in each task state.  The normal sequence of states is <code>New</code>, <code>Downloading</code>, <code>Ready to Run</code>, <code>Uploading</code>, <code>Uploaded</code>.  Tasks which are marked <code>Ready to Run</code> may be actively running, or may be waiting to be scheduled.  <code>Compute Errors</code> are tasks which failed for some reason during execution.  <code>Aborted</code> tasks were manually cancelled, and will not be processed.  <code>Failed Uploads</code> are otherwise finished tasks which failed to upload to the server, and usually indicate networking issues.'
    },

    'boinc.sched': {
        info: 'Counts of active tasks in each scheduling state.  <code>Scheduled</code> tasks are the ones which will run if the system is permitted to process tasks.  <code>Preempted</code> tasks are on standby, and will run if a <code>Scheduled</code> task stops running for some reason.  <code>Uninitialized</code> tasks should never be present, and indicate tha the scheduler has not tried to schedule them yet.'
    },

    'boinc.process': {
        info: 'Counts of active tasks in each process state.  <code>Executing</code> tasks are running right now.  <code>Suspended</code> tasks have an associated process, but are not currently running (either because the system isn\'t processing any tasks right now, or because they have been preempted by higher priority tasks).  <code>Quit</code> tasks are exiting gracefully.  <code>Aborted</code> tasks exceeded some resource limit, and are being shut down.  <code>Copy Pending</code> tasks are waiting on a background file transfer to finish.  <code>Uninitialized</code> tasks do not have an associated process yet.'
    },

    'w1sensor.temp': {
        info: 'Temperature derived from 1-Wire temperature sensors.'
    },

    'logind.sessions': {
        info: 'Shows the number of active sessions of each type tracked by logind.'
    },

    'logind.users': {
        info: 'Shows the number of active users of each type tracked by logind.'
    },

    'logind.seats': {
        info: 'Shows the number of active seats tracked by logind.  Each seat corresponds to a combination of a display device and input device providing a physical presence for the system.'
    },

    // ------------------------------------------------------------------------
    // ProxySQL

    'proxysql.pool_status': {
        info: 'The status of the backend servers. ' +
            '<code>1=ONLINE</code> backend server is fully operational, ' +
            '<code>2=SHUNNED</code> backend sever is temporarily taken out of use because of either too many connection errors in a time that was too short, or replication lag exceeded the allowed threshold, ' +
            '<code>3=OFFLINE_SOFT</code> when a server is put into OFFLINE_SOFT mode, new incoming connections aren\'t accepted anymore, while the existing connections are kept until they became inactive. In other words, connections are kept in use until the current transaction is completed. This allows to gracefully detach a backend, ' +
            '<code>4=OFFLINE_HARD</code> when a server is put into OFFLINE_HARD mode, the existing connections are dropped, while new incoming connections aren\'t accepted either. This is equivalent to deleting the server from a hostgroup, or temporarily taking it out of the hostgroup for maintenance work, ' +
            '<code>-1</code> Unknown status.'
    },

    'proxysql.pool_net': {
        info: 'The amount of data sent to/received from the backend ' +
            '(This does not include metadata (packets\' headers, OK/ERR packets, fields\' description, etc).'
    },

    'proxysql.pool_overall_net': {
        info: 'The amount of data sent to/received from the all backends ' +
            '(This does not include metadata (packets\' headers, OK/ERR packets, fields\' description, etc).'
    },

    'proxysql.questions': {
        info: '<code>questions</code> total number of queries sent from frontends, ' +
            '<code>slow_queries</code> number of queries that ran for longer than the threshold in milliseconds defined in global variable <code>mysql-long_query_time</code>. '
    },

    'proxysql.connections': {
        info: '<code>aborted</code> number of frontend connections aborted due to invalid credential or max_connections reached, ' +
            '<code>connected</code> number of frontend connections currently connected, ' +
            '<code>created</code> number of frontend connections created, ' +
            '<code>non_idle</code> number of frontend connections that are not currently idle. '
    },

    'proxysql.pool_latency': {
        info: 'The currently ping time in microseconds, as reported from Monitor.'
    },

    'proxysql.queries': {
        info: 'The number of queries routed towards this particular backend server.'
    },

    'proxysql.pool_used_connections': {
        info: 'The number of connections are currently used by ProxySQL for sending queries to the backend server.'
    },

    'proxysql.pool_free_connections': {
        info: 'The number of connections are currently free. They are kept open in order to minimize the time cost of sending a query to the backend server.'
    },

    'proxysql.pool_ok_connections': {
        info: 'The number of connections were established successfully.'
    },

    'proxysql.pool_error_connections': {
        info: 'The number of connections weren\'t established successfully.'
    },

    'proxysql.commands_count': {
        info: 'The total number of commands of that type executed'
    },

    'proxysql.commands_duration': {
        info: 'The total time spent executing commands of that type, in ms'
    },

    // ------------------------------------------------------------------------
    // Power Supplies

    'powersupply.capacity': {
        info: 'The current battery charge.'
    },

    'powersupply.charge': {
        info: '<p>The battery charge in Amp-hours.</p>'+
        '<p><b>now</b> - actual charge value. '+
        '<b>full</b>, <b>empty</b> - last remembered value of charge when battery became full/empty. '+
        'It also could mean "value of charge when battery considered full/empty at given conditions (temperature, age)". '+
        'I.e. these attributes represents real thresholds, not design values. ' +
        '<b>full_design</b>, <b>empty_design</b> - design charge values, when battery considered full/empty.</p>'
    },

    'powersupply.energy': {
        info: '<p>The battery charge in Watt-hours.</p>'+
        '<p><b>now</b> - actual charge value. '+
        '<b>full</b>, <b>empty</b> - last remembered value of charge when battery became full/empty. '+
        'It also could mean "value of charge when battery considered full/empty at given conditions (temperature, age)". '+
        'I.e. these attributes represents real thresholds, not design values. ' +
        '<b>full_design</b>, <b>empty_design</b> - design charge values, when battery considered full/empty.</p>'
    },

    'powersupply.voltage': {
        info: '<p>The power supply voltage.</p>'+
        '<p><b>now</b> - current voltage. '+
        '<b>max</b>, <b>min</b> - voltage values that hardware could only guess (measure and retain) the thresholds '+
        'of a given power supply. '+
        '<b>max_design</b>, <b>min_design</b> - design values for maximal and minimal power supply voltages. '+
        'Maximal/minimal means values of voltages when battery considered "full"/"empty" at normal conditions.</p>'
    },

    // ------------------------------------------------------------------------
    // VMware vSphere

    // Host specific
    'vsphere.host_mem_usage_percentage': {
        info: 'Percentage of used machine memory: <code>consumed</code> / <code>machine-memory-size</code>.'
    },

    'vsphere.host_mem_usage': {
        info:
            '<code>granted</code> is amount of machine memory that is mapped for a host, ' +
            'it equals sum of all granted metrics for all powered-on virtual machines, plus machine memory for vSphere services on the host. ' +
            '<code>consumed</code> is amount of machine memory used on the host, it includes memory used by the Service Console, the VMkernel, vSphere services, plus the total consumed metrics for all running virtual machines. ' +
            '<code>consumed</code> = <code>total host memory</code> - <code>free host memory</code>.' +
            '<code>active</code> is sum of all active metrics for all powered-on virtual machines plus vSphere services (such as COS, vpxa) on the host.' +
            '<code>shared</code> is sum of all shared metrics for all powered-on virtual machines, plus amount for vSphere services on the host. ' +
            '<code>sharedcommon</code> is amount of machine memory that is shared by all powered-on virtual machines and vSphere services on the host. ' +
            '<code>shared</code> - <code>sharedcommon</code> = machine memory (host memory) savings (KB). ' +
            'For details see <a href="https://docs.vmware.com/en/VMware-vSphere/6.5/com.vmware.vsphere.resmgmt.doc/GUID-BFDC988B-F53D-4E97-9793-A002445AFAE1.html" target="_blank">Measuring and Differentiating Types of Memory Usage</a> and ' +
            '<a href="https://vdc-repo.vmware.com/vmwb-repository/dcr-public/fe08899f-1eec-4d8d-b3bc-a6664c168c2c/7fdf97a1-4c0d-4be0-9d43-2ceebbc174d9/doc/memory_counters.html" target="_blank">Memory Counters</a> articles.'
    },

    'vsphere.host_mem_swap_rate': {
        info:
            'This statistic refers to VMkernel swapping and not to guest OS swapping. ' +
            '<code>in</code> is sum of <code>swapinRate</code> values for all powered-on virtual machines on the host.' +
            '<code>swapinRate</code> is rate at which VMKernel reads data into machine memory from the swap file. ' +
            '<code>out</code> is sum of <code>swapoutRate</code> values for all powered-on virtual machines on the host.' +
            '<code>swapoutRate</code> is rate at which VMkernel writes to the virtual machine’s swap file from machine memory.'
    },

    // VM specific
    'vsphere.vm_mem_usage_percentage': {
        info: 'Percentage of used virtual machine “physical” memory: <code>active</code> / <code>virtual machine configured size</code>.'
    },

    'vsphere.vm_mem_usage': {
        info:
            '<code>granted</code> is amount of guest “physical” memory that is mapped to machine memory, it includes <code>shared</code> memory amount. ' +
            '<code>consumed</code> is amount of guest “physical” memory consumed by the virtual machine for guest memory, ' +
            '<code>consumed</code> = <code>granted</code> - <code>memory saved due to memory sharing</code>. ' +
            '<code>active</code> is amount of memory that is actively used, as estimated by VMkernel based on recently touched memory pages. ' +
            '<code>shared</code> is amount of guest “physical” memory shared with other virtual machines (through the VMkernel’s transparent page-sharing mechanism, a RAM de-duplication technique). ' +
            'For details see <a href="https://docs.vmware.com/en/VMware-vSphere/6.5/com.vmware.vsphere.resmgmt.doc/GUID-BFDC988B-F53D-4E97-9793-A002445AFAE1.html" target="_blank">Measuring and Differentiating Types of Memory Usage</a> and ' +
            '<a href="https://vdc-repo.vmware.com/vmwb-repository/dcr-public/fe08899f-1eec-4d8d-b3bc-a6664c168c2c/7fdf97a1-4c0d-4be0-9d43-2ceebbc174d9/doc/memory_counters.html" target="_blank">Memory Counters</a> articles.'

    },

    'vsphere.vm_mem_swap_rate': {
        info:
            'This statistic refers to VMkernel swapping and not to guest OS swapping. ' +
            '<code>in</code> is rate at which VMKernel reads data into machine memory from the swap file. ' +
            '<code>out</code> is rate at which VMkernel writes to the virtual machine’s swap file from machine memory.'
    },

    'vsphere.vm_mem_swap': {
        info:
            'This statistic refers to VMkernel swapping and not to guest OS swapping. ' +
            '<code>swapped</code> is amount of guest physical memory swapped out to the virtual machine\'s swap file by the VMkernel. ' +
            'Swapped memory stays on disk until the virtual machine needs it.'
    },

    // Common
    'vsphere.cpu_usage_total': {
        info: 'Summary CPU usage statistics across all CPUs/cores.'
    },

    'vsphere.net_bandwidth_total': {
        info: 'Summary receive/transmit statistics across all network interfaces.'
    },

    'vsphere.net_packets_total': {
        info: 'Summary receive/transmit statistics across all network interfaces.'
    },

    'vsphere.net_errors_total': {
        info: 'Summary receive/transmit statistics across all network interfaces.'
    },

    'vsphere.net_drops_total': {
        info: 'Summary receive/transmit statistics across all network interfaces.'
    },

    'vsphere.disk_usage_total': {
        info: 'Summary read/write statistics across all disks.'
    },

    'vsphere.disk_max_latency': {
        info: '<code>latency</code> is highest latency value across all disks.'
    },

    'vsphere.overall_status': {
        info: '<code>0</code> is unknown, <code>1</code> is OK, <code>2</code> is might have a problem, <code>3</code> is definitely has a problem.'
    },

    // ------------------------------------------------------------------------
    // VCSA
    'vcsa.system_health': {
        info:
            '<code>-1</code>: unknown; ' +
            '<code>0</code>: all components are healthy; ' +
            '<code>1</code>: one or more components might become overloaded soon; ' +
            '<code>2</code>: one or more components in the appliance might be degraded; ' +
            '<code>3</code>: one or more components might be in an unusable status and the appliance might become unresponsive soon; ' +
            '<code>4</code>: no health data is available.'
    },

    'vcsa.components_health': {
        info:
            '<code>-1</code>: unknown; ' +
            '<code>0</code>: healthy; ' +
            '<code>1</code>: healthy, but may have some problems; ' +
            '<code>2</code>: degraded, and may have serious problems; ' +
            '<code>3</code>: unavailable, or will stop functioning soon; ' +
            '<code>4</code>: no health data is available.'
    },

    'vcsa.software_updates_health': {
        info:
            '<code>softwarepackages</code> represents information on available software updates available in the remote vSphere Update Manager repository.<br>' +
            '<code>-1</code>: unknown; ' +
            '<code>0</code>: no updates available; ' +
            '<code>2</code>: non-security updates are available; ' +
            '<code>3</code>: security updates are available; ' +
            '<code>4</code>: an error retrieving information on software updates.'
    },

    // ------------------------------------------------------------------------
    // Zookeeper

    'zookeeper.server_state': {
        info:
            '<code>0</code>: unknown, ' +
            '<code>1</code>: leader, ' +
            '<code>2</code>: follower, ' +
            '<code>3</code>: observer, ' +
            '<code>4</code>: standalone.'
    },

    // ------------------------------------------------------------------------
    // Squidlog

    'squidlog.requests': {
        info: 'Total number of requests (log lines read). It includes <code>unmatched</code>.'
    },

    'squidlog.excluded_requests': {
        info: '<code>unmatched</code> counts the lines in the log file that are not matched by the plugin parser (<a href="https://github.com/netdata/netdata/issues/new?title=squidlog%20reports%20unmatched%20lines&body=squidlog%20plugin%20reports%20unmatched%20lines.%0A%0AThis%20is%20my%20log:%0A%0A%60%60%60txt%0A%0Aplease%20paste%20your%20squid%20server%20log%20here%0A%0A%60%60%60" target="_blank">let us know</a> if you have any unmatched).'
    },

    'squidlog.type_requests': {
        info: 'Requests by response type:<br>' +
            '<ul>' +
            ' <li><code>success</code> includes 1xx, 2xx, 0, 304, 401.</li>' +
            ' <li><code>error</code> includes 5xx and 6xx.</li>' +
            ' <li><code>redirect</code> includes 3xx except 304.</li>' +
            ' <li><code>bad</code> includes 4xx except 401.</li>' +
            ' </ul>'
    },

    'squidlog.http_status_code_class_responses': {
        info: 'The HTTP response status code classes. According to <a href="https://tools.ietf.org/html/rfc7231" target="_blank">rfc7231</a>:<br>' +
            ' <li><code>1xx</code> is informational responses.</li>' +
            ' <li><code>2xx</code> is successful responses.</li>' +
            ' <li><code>3xx</code> is redirects.</li>' +
            ' <li><code>4xx</code> is bad requests.</li>' +
            ' <li><code>5xx</code> is internal server errors.</li>' +
            ' </ul>' +
            'Squid also uses <code>0</code> for a result code being unavailable, and <code>6xx</code> to signal an invalid header, a proxy error.'
    },

    'squidlog.http_status_code_responses': {
        info: 'Number of responses for each http response status code individually.'
    },

    'squidlog.uniq_clients': {
        info: 'Unique clients (requesting instances), within each data collection iteration. If data collection is <b>per second</b>, this chart shows <b>unique clients per second</b>.'
    },

    'squidlog.bandwidth': {
        info: 'The size is the amount of data delivered to the clients. Mind that this does not constitute the net object size, as headers are also counted. ' +
            'Also, failed requests may deliver an error page, the size of which is also logged here.'
    },

    'squidlog.response_time': {
        info: 'The elapsed time considers how many milliseconds the transaction busied the cache. It differs in interpretation between TCP and UDP:' +
            '<ul>' +
            ' <li><code>TCP</code> this is basically the time from having received the request to when Squid finishes sending the last byte of the response.</li>' +
            ' <li><code>UDP</code> this is the time between scheduling a reply and actually sending it.</li>' +
            ' </ul>' +
            'Please note that <b>the entries are logged after the reply finished being sent</b>, not during the lifetime of the transaction.'
    },

    'squidlog.cache_result_code_requests': {
        info: 'The Squid result code is composed of several tags (separated by underscore characters) which describe the response sent to the client. ' +
            'Check the <a href="https://wiki.squid-cache.org/SquidFaq/SquidLogs#Squid_result_codes" target="_blank">squid documentation</a> about them.'
    },

    'squidlog.cache_result_code_transport_tag_requests': {
        info: 'These tags are always present and describe delivery method.<br>' +
            '<ul>' +
            ' <li><code>TCP</code> requests on the HTTP port (usually 3128).</li>' +
            ' <li><code>UDP</code> requests on the ICP port (usually 3130) or HTCP port (usually 4128).</li>' +
            ' <li><code>NONE</code> Squid delivered an unusual response or no response at all. Seen with cachemgr requests and errors, usually when the transaction fails before being classified into one of the above outcomes. Also seen with responses to CONNECT requests.</li>' +
            ' </ul>'
    },

    'squidlog.cache_result_code_handling_tag_requests': {
        info: 'These tags are optional and describe why the particular handling was performed or where the request came from.<br>' +
            '<ul>' +
            ' <li><code>CF</code> at least one request in this transaction was collapsed. See <a href="http://www.squid-cache.org/Doc/config/collapsed_forwarding/" target="_blank">collapsed_forwarding</a>  for more details about request collapsing.</li>' +
            ' <li><code>CLIENT</code> usually seen with client issued a "no-cache", or analogous cache control command along with the request. Thus, the cache has to validate the object.</li>' +
            ' <li><code>IMS</code> the client sent a revalidation (conditional) request.</li>' +
            ' <li><code>ASYNC</code> the request was generated internally by Squid. Usually this is background fetches for cache information exchanges, background revalidation from <i>stale-while-revalidate</i> cache controls, or ESI sub-objects being loaded.</li>' +
            ' <li><code>SWAPFAIL</code> the object was believed to be in the cache, but could not be accessed. A new copy was requested from the server.</li>' +
            ' <li><code>REFRESH</code> a revalidation (conditional) request was sent to the server.</li>' +
            ' <li><code>SHARED</code> this request was combined with an existing transaction by collapsed forwarding.</li>' +
            ' <li><code>REPLY</code> the HTTP reply from server or peer. Usually seen on <code>DENIED</code> due to <a href="http://www.squid-cache.org/Doc/config/http_reply_access/" target="_blank">http_reply_access</a> ACLs preventing delivery of servers response object to the client.</li>' +
            ' </ul>'
    },

    'squidlog.cache_code_object_tag_requests': {
        info: 'These tags are optional and describe what type of object was produced.<br>' +
            '<ul>' +
            ' <li><code>NEGATIVE</code> only seen on HIT responses, indicating the response was a cached error response. e.g. <b>404 not found</b>.</li>' +
            ' <li><code>STALE</code> the object was cached and served stale. This is usually caused by <i>stale-while-revalidate</i> or <i>stale-if-error</i> cache controls.</li>' +
            ' <li><code>OFFLINE</code> the requested object was retrieved from the cache during <a href="http://www.squid-cache.org/Doc/config/offline_mode/" target="_blank">offline_mode</a>. The offline mode never validates any object.</li>' +
            ' <li><code>INVALID</code> an invalid request was received. An error response was delivered indicating what the problem was.</li>' +
            ' <li><code>FAILED</code> only seen on <code>REFRESH</code> to indicate the revalidation request failed. The response object may be the server provided network error or the stale object which was being revalidated depending on stale-if-error cache control.</li>' +
            ' <li><code>MODIFIED</code> only seen on <code>REFRESH</code> responses to indicate revalidation produced a new modified object.</li>' +
            ' <li><code>UNMODIFIED</code> only seen on <code>REFRESH</code> responses to indicate revalidation produced a 304 (Not Modified) status. The client gets either a full 200 (OK), a 304 (Not Modified), or (in theory) another response, depending on the client request and other details.</li>' +
            ' <li><code>REDIRECT</code> Squid generated an HTTP redirect response to this request.</li>' +
            ' </ul>'
    },

    'squidlog.cache_code_load_source_tag_requests': {
        info: 'These tags are optional and describe whether the response was loaded from cache, network, or otherwise.<br>' +
            '<ul>' +
            ' <li><code>HIT</code> the response object delivered was the local cache object.</li>' +
            ' <li><code>MEM</code> the response object came from memory cache, avoiding disk accesses. Only seen on HIT responses.</li>' +
            ' <li><code>MISS</code> the response object delivered was the network response object.</li>' +
            ' <li><code>DENIED</code> the request was denied by access controls.</li>' +
            ' <li><code>NOFETCH</code> an ICP specific type, indicating service is alive, but not to be used for this request.</li>' +
            ' <li><code>TUNNEL</code> a binary tunnel was established for this transaction.</li>' +
            ' </ul>'
    },

    'squidlog.cache_code_error_tag_requests': {
        info: 'These tags are optional and describe some error conditions which occurred during response delivery.<br>' +
            '<ul>' +
            ' <li><code>ABORTED</code> the response was not completed due to the connection being aborted (usually by the client).</li>' +
            ' <li><code>TIMEOUT</code> the response was not completed due to a connection timeout.</li>' +
            ' <li><code>IGNORED</code> while refreshing a previously cached response A, Squid got a response B that was older than A (as determined by the Date header field). Squid ignored response B (and attempted to use A instead).</li>' +
            ' </ul>'
    },

    'squidlog.http_method_requests': {
        info: 'The request method to obtain an object. Please refer to section <a href="https://wiki.squid-cache.org/SquidFaq/SquidLogs#Request_methods" target="_blank">request-methods</a> for available methods and their description.'
    },

    'squidlog.hier_code_requests': {
        info: 'A code that explains how the request was handled, e.g. by forwarding it to a peer, or going straight to the source. ' +
            'Any hierarchy tag may be prefixed with <code>TIMEOUT_</code>, if the timeout occurs waiting for all ICP replies to return from the neighbours. The timeout is either dynamic, if the <a href="http://www.squid-cache.org/Doc/config/icp_query_timeout/" target="_blank">icp_query_timeout</a> was not set, or the time configured there has run up. ' +
            'Refer to <a href="https://wiki.squid-cache.org/SquidFaq/SquidLogs#Hierarchy_Codes" target="_blank">Hierarchy Codes</a> for details on hierarchy codes.'
    },

    'squidlog.server_address_forwarded_requests': {
        info: 'The IP address or hostname where the request (if a miss) was forwarded. For requests sent to origin servers, this is the origin server\'s IP address. ' +
            'For requests sent to a neighbor cache, this is the neighbor\'s hostname. NOTE: older versions of Squid would put the origin server hostname here.'
    },

    'squidlog.mime_type_requests': {
        info: 'The content type of the object as seen in the HTTP reply header. Please note that ICP exchanges usually don\'t have any content type.'
    },

    // ------------------------------------------------------------------------
    // CockroachDB

    'cockroachdb.process_cpu_time_combined_percentage': {
        info: 'Current combined cpu utilization, calculated as <code>(user+system)/num of logical cpus</code>.'
    },

    'cockroachdb.host_disk_bandwidth': {
        info: 'Summary disk bandwidth statistics across all system host disks.'
    },

    'cockroachdb.host_disk_operations': {
        info: 'Summary disk operations statistics across all system host disks.'
    },

    'cockroachdb.host_disk_iops_in_progress': {
        info: 'Summary disk iops in progress statistics across all system host disks.'
    },

    'cockroachdb.host_network_bandwidth': {
        info: 'Summary network bandwidth statistics across all system host network interfaces.'
    },

    'cockroachdb.host_network_packets': {
        info: 'Summary network packets statistics across all system host network interfaces.'
    },

    'cockroachdb.live_nodes': {
        info: 'Will be <code>0</code> if this node is not itself live.'
    },

    'cockroachdb.total_storage_capacity': {
        info: 'Entire disk capacity. It includes non-CR data, CR data, and empty space.'
    },

    'cockroachdb.storage_capacity_usability': {
        info: '<code>usable</code> is sum of empty space and CR data, <code>unusable</code> is space used by non-CR data.'
    },

    'cockroachdb.storage_usable_capacity': {
        info: 'Breakdown of <code>usable</code> space.'
    },

    'cockroachdb.storage_used_capacity_percentage': {
        info: '<code>total</code> is % of <b>total</b> space used, <code>usable</code> is % of <b>usable</b> space used.'
    },

    'cockroachdb.sql_bandwidth': {
        info: 'The total amount of SQL client network traffic.'
    },

    'cockroachdb.sql_errors': {
        info: '<code>statement</code> is statements resulting in a planning or runtime error, ' +
            '<code>transaction</code> is SQL transactions abort errors.'
    },

    'cockroachdb.sql_started_ddl_statements': {
        info: 'The amount of <b>started</b> DDL (Data Definition Language) statements. ' +
            'This type means database schema changes. ' +
            'It includes <code>CREATE</code>, <code>ALTER</code>, <code>DROP</code>, <code>RENAME</code>, <code>TRUNCATE</code> and <code>COMMENT</code> statements.'
    },

    'cockroachdb.sql_executed_ddl_statements': {
        info: 'The amount of <b>executed</b> DDL (Data Definition Language) statements. ' +
            'This type means database schema changes. ' +
            'It includes <code>CREATE</code>, <code>ALTER</code>, <code>DROP</code>, <code>RENAME</code>, <code>TRUNCATE</code> and <code>COMMENT</code> statements.'
    },

    'cockroachdb.sql_started_dml_statements': {
        info: 'The amount of <b>started</b> DML (Data Manipulation Language) statements.'
    },

    'cockroachdb.sql_executed_dml_statements': {
        info: 'The amount of <b>executed</b> DML (Data Manipulation Language) statements.'
    },

    'cockroachdb.sql_started_tcl_statements': {
        info: 'The amount of <b>started</b> TCL (Transaction Control Language) statements.'
    },

    'cockroachdb.sql_executed_tcl_statements': {
        info: 'The amount of <b>executed</b> TCL (Transaction Control Language) statements.'
    },

    'cockroachdb.live_bytes': {
        info: 'The amount of live data used by both applications and the CockroachDB system.'
    },

    'cockroachdb.kv_transactions': {
        info: 'KV transactions breakdown:<br>' +
            '<ul>' +
            ' <li><code>committed</code> committed KV transactions (including 1PC).</li>' +
            ' <li><code>fast-path_committed</code> KV transaction on-phase commit attempts.</li>' +
            ' <li><code>aborted</code> aborted KV transactions.</li>' +
            ' </ul>'
    },

    'cockroachdb.kv_transaction_restarts': {
        info: 'KV transactions restarts breakdown:<br>' +
            '<ul>' +
            ' <li><code>write too old</code> restarts due to a concurrent writer committing first.</li>' +
            ' <li><code>write too old (multiple)</code> restarts due to multiple concurrent writers committing first.</li>' +
            ' <li><code>forwarded timestamp (iso=serializable)</code> restarts due to a forwarded commit timestamp and isolation=SERIALIZABLE".</li>' +
            ' <li><code>possible replay</code> restarts due to possible replays of command batches at the storage layer.</li>' +
            ' <li><code>async consensus failure</code> restarts due to async consensus writes that failed to leave intents.</li>' +
            ' <li><code>read within uncertainty interval</code> restarts due to reading a new value within the uncertainty interval.</li>' +
            ' <li><code>aborted</code> restarts due to an abort by a concurrent transaction (usually due to deadlock).</li>' +
            ' <li><code>push failure</code> restarts due to a transaction push failure.</li>' +
            ' <li><code>unknown</code> restarts due to a unknown reasons.</li>' +
            ' </ul>'
    },

    'cockroachdb.ranges': {
        info: 'CockroachDB stores all user data (tables, indexes, etc.) and almost all system data in a giant sorted map of key-value pairs. ' +
            'This keyspace is divided into "ranges", contiguous chunks of the keyspace, so that every key can always be found in a single range.'
    },

    'cockroachdb.ranges_replication_problem': {
        info: 'Ranges with not optimal number of replicas:<br>' +
            '<ul>' +
            ' <li><code>unavailable</code> ranges with fewer live replicas than needed for quorum.</li>' +
            ' <li><code>under replicated</code> ranges with fewer live replicas than the replication target.</li>' +
            ' <li><code>over replicated</code> ranges with more live replicas than the replication target.</li>' +
            ' </ul>'
    },

    'cockroachdb.replicas': {
        info: 'CockroachDB replicates each range (3 times by default) and stores each replica on a different node.'
    },

    'cockroachdb.replicas_leaders': {
        info: 'For each range, one of the replicas is the <code>leader</code> for write requests, <code>not leaseholders</code> is the number of Raft leaders whose range lease is held by another store.'
    },

    'cockroachdb.replicas_leaseholders': {
        info: 'For each range, one of the replicas holds the "range lease". This replica, referred to as the <code>leaseholder</code>, is the one that receives and coordinates all read and write requests for the range.'
    },

    'cockroachdb.queue_processing_failures': {
        info: 'Failed replicas breakdown by queue:<br>' +
            '<ul>' +
            ' <li><code>gc</code> replicas which failed processing in the GC queue.</li>' +
            ' <li><code>replica gc</code> replicas which failed processing in the replica GC queue.</li>' +
            ' <li><code>replication</code> replicas which failed processing in the replicate queue.</li>' +
            ' <li><code>split</code> replicas which failed processing in the split queue.</li>' +
            ' <li><code>consistency</code> replicas which failed processing in the consistency checker queue.</li>' +
            ' <li><code>raft log</code> replicas which failed processing in the Raft log queue.</li>' +
            ' <li><code>raft snapshot</code> replicas which failed processing in the Raft repair queue.</li>' +
            ' <li><code>time series maintenance</code> replicas which failed processing in the time series maintenance queue.</li>' +
            ' </ul>'
    },

    'cockroachdb.rebalancing_queries': {
        info: 'Number of kv-level requests received per second by the store, averaged over a large time period as used in rebalancing decisions.'
    },

    'cockroachdb.rebalancing_writes': {
        info: 'Number of keys written (i.e. applied by raft) per second to the store, averaged over a large time period as used in rebalancing decisions.'
    },

    'cockroachdb.slow_requests': {
        info: 'Requests that have been stuck for a long time.'
    },

    'cockroachdb.timeseries_samples': {
        info: 'The amount of metric samples written to disk.'
    },

    'cockroachdb.timeseries_write_errors': {
        info: 'The amount of errors encountered while attempting to write metrics to disk.'
    },

    'cockroachdb.timeseries_write_bytes': {
        info: 'Size of metric samples written to disk.'
    },

    // ------------------------------------------------------------------------
    // Perf

    'perf.instructions_per_cycle': {
        info: 'An IPC < 1.0 likely means memory bound, and an IPC > 1.0 likely means instruction bound. For more details about the metric take a look at this <a href="https://www.brendangregg.com/blog/2017-05-09/cpu-utilization-is-wrong.html" target="_blank">blog post</a>.'
    },

    // ------------------------------------------------------------------------
    // Filesystem

    'filesystem.vfs_deleted_objects': {
        title : 'VFS remove',
        info: 'This chart does not show all events that remove files from the file system, because file systems can create their own functions to remove files, it shows calls for the function <code>vfs_unlink</code>. '
    },

    'filesystem.vfs_io': {
        title : 'VFS IO',
        info: 'Successful or failed calls to functions <code>vfs_read</code> and <code>vfs_write</code>. This chart may not show all file system events if it uses other functions to store data on disk.'
    },

    'filesystem.vfs_io_bytes': {
        title : 'VFS bytes written',
        info: 'Total of bytes read or written with success using the functions <code>vfs_read</code> and <code>vfs_write</code>.'
    },

    'filesystem.vfs_io_error': {
        title : 'VFS IO error',
        info: 'Failed calls to functions <code>vfs_read</code> and <code>vfs_write</code>.'
    },

    'filesystem.vfs_fsync': {
        info: 'Successful or failed calls to functions <code>vfs_fsync</code>.'
    },

    'filesystem.vfs_fsync_error': {
        info: 'Failed calls to functions <code>vfs_fsync</code>.'
    },

    'filesystem.vfs_open': {
        info: 'Successful or failed calls to functions <code>vfs_open</code>.'
    },

    'filesystem.vfs_open_error': {
        info: 'Failed calls to functions <code>vfs_open</code>.'
    },

    'filesystem.vfs_create': {
        info: 'Successful or failed calls to functions <code>vfs_create</code>.'
    },

    'filesystem.vfs_create_error': {
        info: 'Failed calls to functions <code>vfs_create</code>.'
    },

    'filesystem.ext4_read_latency': {
        info: 'Netdata is attaching <code>kprobes</code> for the function <code>ext4_file_read_iter</code>.'
    },

    'filesystem.ext4_write_latency': {
        info: 'Netdata is attaching <code>kprobes</code> for the function <code>ext4_file_write_iter</code>.'
    },

    'filesystem.ext4_open_latency': {
        info: 'Netdata is attaching <code>kprobes</code> for the function <code>ext4_file_open</code>.'
    },

    'filesystem.ext4_sync_latency': {
        info: 'Netdata is attaching <code>kprobes</code> for the function <code>ext4_sync_file</code>.'
    },

    'filesystem.xfs_read_latency': {
        info: 'Netdata is attaching <code>kprobes</code> for the function <code>xfs_file_read_iter</code>.'
    },

    'filesystem.xfs_write_latency': {
        info: 'Netdata is attaching <code>kprobes</code> for the function <code>xfs_file_write_iter</code>.'
    },

    'filesystem.xfs_open_latency': {
        info: 'Netdata is attaching <code>kprobes</code> for the function <code>xfs_file_open</code>.'
    },

    'filesystem.xfs_sync_latency': {
        info: 'Netdata is attaching <code>kprobes</code> for the function <code>xfs_file_sync</code>.'
    },

    'filesystem.nfs_read_latency': {
        info: 'Netdata is attaching <code>kprobes</code> for the function <code>nfs_file_read</code>.'
    },

    'filesystem.nfs_write_latency': {
        info: 'Netdata is attaching <code>kprobes</code> for the function <code>nfs_file_write</code>.'
    },

    'filesystem.nfs_open_latency': {
        info: 'Netdata is attaching <code>kprobes</code> for functions <code>nfs_file_open</code> and <code>nfs4_file_open</code>'
    },

    'filesystem.nfs_attribute_latency': {
        info: 'Netdata is attaching <code>kprobes</code> for the function <code>nfs_getattr</code>.'
    },

    'filesystem.zfs_read_latency': {
        info: 'Netdata is attaching <code>kprobes</code> for when the function <code>zpl_iter_read</code>.'
    },

    'filesystem.zfs_write_latency': {
        info: 'Netdata is attaching <code>kprobes</code> for when the function <code>zpl_iter_write</code>.'
    },

    'filesystem.zfs_open_latency': {
        info: 'Netdata is attaching <code>kprobes</code> for when the function <code>zpl_open</code>.'
    },

    'filesystem.zfs_sync_latency': {
        info: 'Netdata is attaching <code>kprobes</code> for when the function <code>zpl_fsync</code>.'
    },

    'filesystem.btrfs_read_latency': {
        info: 'Netdata is attaching <code>kprobes</code> for when the function <code>btrfs_file_read_iter</code> (kernel newer than 5.9.16) or the function <code>generic_file_read_iter</code> (old kernels).'
    },

    'filesystem.btrfs_write_latency': {
        info: 'Netdata is attaching <code>kprobes</code> for when the function <code>btrfs_file_write_iter</code>.'
    },

    'filesystem.btrfs_open_latency': {
        info: 'Netdata is attaching <code>kprobes</code> for when the function <code>btrfs_file_open</code>.'
    },

    'filesystem.btrfs_sync_latency': {
        info: 'Netdata is attaching <code>kprobes</code> for when the function <code>btrfs_sync_file</code>.'
    },

    'mount_points.call': {
        info: 'Monitor calls to syscalls <code>mount(2)</code> and <code>umount(2)</code> that are responsible for attaching or removing filesystems.'
    },

    'mount_points.error': {
        info: 'Monitor errors in calls to syscalls <code>mount(2)</code> and <code>umount(2)</code>.'
    },

    'filesystem.file_descriptor': {
        info: 'Calls for internal functions on Linux kernel. The open dimension is attached to the kernel internal function <code>do_sys_open</code> ( For kernels newer than <code>5.5.19</code> we add a kprobe to <code>do_sys_openat2</code>. ), which is the common function called from'+
            ' <a href="https://www.man7.org/linux/man-pages/man2/open.2.html" target="_blank">open(2)</a> ' +
            ' and <a href="https://www.man7.org/linux/man-pages/man2/openat.2.html" target="_blank">openat(2)</a>. ' +
            ' The close dimension is attached to the function <code>__close_fd</code> or <code>close_fd</code> according to your kernel version, which is called from system call' +
            ' <a href="https://www.man7.org/linux/man-pages/man2/close.2.html" target="_blank">close(2)</a>. '
    },

    'filesystem.file_error': {
        info: 'Failed calls to the kernel internal function <code>do_sys_open</code> ( For kernels newer than <code>5.5.19</code> we add a kprobe to <code>do_sys_openat2</code>. ), which is the common function called from'+
            ' <a href="https://www.man7.org/linux/man-pages/man2/open.2.html" target="_blank">open(2)</a> ' +
            ' and <a href="https://www.man7.org/linux/man-pages/man2/openat.2.html" target="_blank">openat(2)</a>. ' +
            ' The close dimension is attached to the function <code>__close_fd</code> or <code>close_fd</code> according to your kernel version, which is called from system call' +
            ' <a href="https://www.man7.org/linux/man-pages/man2/close.2.html" target="_blank">close(2)</a>. '
    },


    // ------------------------------------------------------------------------
    // eBPF

    'apps.swap_read_call': {
        info: 'The function <code>swap_readpage</code> is called when the kernel reads a page from swap memory. Netdata also gives a summary for these charts in <a href="#menu_system_submenu_swap">System overview</a>.'
    },

    'apps.swap_write_call': {
        info: 'The function <code>swap_writepage</code> is called when the kernel writes a page to swap memory.'
    },

    'apps.shmget_call': {
        info: 'Number of times the syscall <code>shmget</code> is called. Netdata also gives a summary for these charts in <a href="#menu_system_submenu_ipc_shared_memory">System overview</a>.'
    },

    'apps.shmat_call': {
        info: 'Number of times the syscall <code>shmat</code> is called.'
    },

    'apps.shmdt_call': {
        info: 'Number of times the syscall <code>shmdt</code> is called.'
    },

    'apps.shmctl_call': {
        info: 'Number of times the syscall <code>shmctl</code> is called.'
    },

    // ------------------------------------------------------------------------
    // ACLK Internal Stats
    'netdata.aclk_status': {
        valueRange: "[0, 1]",
        info: 'This chart shows if ACLK was online during entirety of the sample duration.'
    },

    'netdata.aclk_query_per_second': {
        info: 'This chart shows how many queries were added for ACLK_query thread to process and how many it was actually able to process.'
    },

    'netdata.aclk_latency_mqtt': {
        info: 'Measures latency between MQTT publish of the message and it\'s PUB_ACK being received'
    },

    // ------------------------------------------------------------------------
    // VerneMQ

    'vernemq.sockets': {
        mainheads: [
            function (os, id) {
                void (os);
                return '<div data-netdata="' + id + '"'
                    + ' data-dimensions="open_sockets"'
                    + ' data-chart-library="gauge"'
                    + ' data-title="Connected Clients"'
                    + ' data-units="clients"'
                    + ' data-gauge-adjust="width"'
                    + ' data-width="16%"'
                    + ' data-before="0"'
                    + ' data-after="-CHART_DURATION"'
                    + ' data-points="CHART_DURATION"'
                    + ' data-colors="' + NETDATA.colors[4] + '"'
                    + ' data-decimal-digits="2"'
                    + ' role="application"></div>';
            }
        ]
    },
    'vernemq.queue_processes': {
        mainheads: [
            function (os, id) {
                void (os);
                return '<div data-netdata="' + id + '"'
                    + ' data-dimensions="queue_processes"'
                    + ' data-chart-library="gauge"'
                    + ' data-title="Queues Processes"'
                    + ' data-units="processes"'
                    + ' data-gauge-adjust="width"'
                    + ' data-width="16%"'
                    + ' data-before="0"'
                    + ' data-after="-CHART_DURATION"'
                    + ' data-points="CHART_DURATION"'
                    + ' data-colors="' + NETDATA.colors[4] + '"'
                    + ' data-decimal-digits="2"'
                    + ' role="application"></div>';
            }
        ]
    },
    'vernemq.queue_messages': {
        mainheads: [
            function (os, id) {
                void (os);
                return '<div data-netdata="' + id + '"'
                    + ' data-dimensions="queue_message_in"'
                    + ' data-chart-library="easypiechart"'
                    + ' data-title="MQTT Receive Rate"'
                    + ' data-units="messages/s"'
                    + ' data-gauge-adjust="width"'
                    + ' data-width="14%"'
                    + ' data-before="0"'
                    + ' data-after="-CHART_DURATION"'
                    + ' data-points="CHART_DURATION"'
                    + ' data-colors="' + NETDATA.colors[0] + '"'
                    + ' data-decimal-digits="2"'
                    + ' role="application"></div>';
            },
            function (os, id) {
                void (os);
                return '<div data-netdata="' + id + '"'
                    + ' data-dimensions="queue_message_out"'
                    + ' data-chart-library="easypiechart"'
                    + ' data-title="MQTT Send Rate"'
                    + ' data-units="messages/s"'
                    + ' data-gauge-adjust="width"'
                    + ' data-width="14%"'
                    + ' data-before="0"'
                    + ' data-after="-CHART_DURATION"'
                    + ' data-points="CHART_DURATION"'
                    + ' data-colors="' + NETDATA.colors[1] + '"'
                    + ' data-decimal-digits="2"'
                    + ' role="application"></div>';
            },
        ]
    },
    'vernemq.average_scheduler_utilization': {
        mainheads: [
            function (os, id) {
                void (os);
                return '<div data-netdata="' + id + '"'
                    + ' data-dimensions="system_utilization"'
                    + ' data-chart-library="gauge"'
                    + ' data-gauge-max-value="100"'
                    + ' data-title="Average Scheduler Utilization"'
                    + ' data-units="percentage"'
                    + ' data-gauge-adjust="width"'
                    + ' data-width="16%"'
                    + ' data-before="0"'
                    + ' data-after="-CHART_DURATION"'
                    + ' data-points="CHART_DURATION"'
                    + ' data-colors="' + NETDATA.colors[3] + '"'
                    + ' data-decimal-digits="2"'
                    + ' role="application"></div>';
            }
        ]
    },

    // ------------------------------------------------------------------------
    // Apache Pulsar
    'pulsar.messages_rate': {
        mainheads: [
            function (os, id) {
                void (os);
                return '<div data-netdata="' + id + '"'
                    + ' data-dimensions="pulsar_rate_in"'
                    + ' data-chart-library="easypiechart"'
                    + ' data-title="Publish"'
                    + ' data-units="messages/s"'
                    + ' data-gauge-adjust="width"'
                    + ' data-width="12%"'
                    + ' data-before="0"'
                    + ' data-after="-CHART_DURATION"'
                    + ' data-points="CHART_DURATION"'
                    + ' data-colors="' + NETDATA.colors[0] + '"'
                    + ' data-decimal-digits="2"'
                    + ' role="application"></div>';
            },
            function (os, id) {
                void (os);
                return '<div data-netdata="' + id + '"'
                    + ' data-dimensions="pulsar_rate_out"'
                    + ' data-chart-library="easypiechart"'
                    + ' data-title="Dispatch"'
                    + ' data-units="messages/s"'
                    + ' data-gauge-adjust="width"'
                    + ' data-width="12%"'
                    + ' data-before="0"'
                    + ' data-after="-CHART_DURATION"'
                    + ' data-points="CHART_DURATION"'
                    + ' data-colors="' + NETDATA.colors[1] + '"'
                    + ' data-decimal-digits="2"'
                    + ' role="application"></div>';
            },
        ]
    },
    'pulsar.subscription_msg_rate_redeliver': {
        mainheads: [
            function (os, id) {
                void (os);
                return '<div data-netdata="' + id + '"'
                    + ' data-dimensions="pulsar_subscription_msg_rate_redeliver"'
                    + ' data-chart-library="gauge"'
                    + ' data-gauge-max-value="100"'
                    + ' data-title="Redelivered"'
                    + ' data-units="messages/s"'
                    + ' data-gauge-adjust="width"'
                    + ' data-width="14%"'
                    + ' data-before="0"'
                    + ' data-after="-CHART_DURATION"'
                    + ' data-points="CHART_DURATION"'
                    + ' data-colors="' + NETDATA.colors[3] + '"'
                    + ' data-decimal-digits="2"'
                    + ' role="application"></div>';
            }
        ]
    },
    'pulsar.subscription_blocked_on_unacked_messages': {
        mainheads: [
            function (os, id) {
                void (os);
                return '<div data-netdata="' + id + '"'
                    + ' data-dimensions="pulsar_subscription_blocked_on_unacked_messages"'
                    + ' data-chart-library="gauge"'
                    + ' data-gauge-max-value="100"'
                    + ' data-title="Blocked On Unacked"'
                    + ' data-units="subscriptions"'
                    + ' data-gauge-adjust="width"'
                    + ' data-width="14%"'
                    + ' data-before="0"'
                    + ' data-after="-CHART_DURATION"'
                    + ' data-points="CHART_DURATION"'
                    + ' data-colors="' + NETDATA.colors[3] + '"'
                    + ' data-decimal-digits="2"'
                    + ' role="application"></div>';
            }
        ]
    },
    'pulsar.msg_backlog': {
        mainheads: [
            function (os, id) {
                void (os);
                return '<div data-netdata="' + id + '"'
                    + ' data-dimensions="pulsar_msg_backlog"'
                    + ' data-chart-library="gauge"'
                    + ' data-gauge-max-value="100"'
                    + ' data-title="Messages Backlog"'
                    + ' data-units="messages"'
                    + ' data-gauge-adjust="width"'
                    + ' data-width="14%"'
                    + ' data-before="0"'
                    + ' data-after="-CHART_DURATION"'
                    + ' data-points="CHART_DURATION"'
                    + ' data-colors="' + NETDATA.colors[2] + '"'
                    + ' data-decimal-digits="2"'
                    + ' role="application"></div>';
            }
        ]
    },

    'pulsar.namespace_messages_rate': {
        heads: [
            function (os, id) {
                void (os);
                return '<div data-netdata="' + id + '"'
                    + ' data-dimensions="publish"'
                    + ' data-chart-library="easypiechart"'
                    + ' data-title="Publish"'
                    + ' data-units="messages/s"'
                    + ' data-gauge-adjust="width"'
                    + ' data-width="12%"'
                    + ' data-before="0"'
                    + ' data-after="-CHART_DURATION"'
                    + ' data-points="CHART_DURATION"'
                    + ' data-colors="' + NETDATA.colors[0] + '"'
                    + ' data-decimal-digits="2"'
                    + ' role="application"></div>';
            },
            function (os, id) {
                void (os);
                return '<div data-netdata="' + id + '"'
                    + ' data-dimensions="dispatch"'
                    + ' data-chart-library="easypiechart"'
                    + ' data-title="Dispatch"'
                    + ' data-units="messages/s"'
                    + ' data-gauge-adjust="width"'
                    + ' data-width="12%"'
                    + ' data-before="0"'
                    + ' data-after="-CHART_DURATION"'
                    + ' data-points="CHART_DURATION"'
                    + ' data-colors="' + NETDATA.colors[1] + '"'
                    + ' data-decimal-digits="2"'
                    + ' role="application"></div>';
            },
        ]
    },
    'pulsar.namespace_subscription_msg_rate_redeliver': {
        heads: [
            function (os, id) {
                void (os);
                return '<div data-netdata="' + id + '"'
                    + ' data-dimensions="redelivered"'
                    + ' data-chart-library="gauge"'
                    + ' data-gauge-max-value="100"'
                    + ' data-title="Redelivered"'
                    + ' data-units="messages/s"'
                    + ' data-gauge-adjust="width"'
                    + ' data-width="14%"'
                    + ' data-before="0"'
                    + ' data-after="-CHART_DURATION"'
                    + ' data-points="CHART_DURATION"'
                    + ' data-colors="' + NETDATA.colors[3] + '"'
                    + ' data-decimal-digits="2"'
                    + ' role="application"></div>';
            }
        ]
    },
    'pulsar.namespace_subscription_blocked_on_unacked_messages': {
        heads: [
            function (os, id) {
                void (os);
                return '<div data-netdata="' + id + '"'
                    + ' data-dimensions="blocked"'
                    + ' data-chart-library="gauge"'
                    + ' data-gauge-max-value="100"'
                    + ' data-title="Blocked On Unacked"'
                    + ' data-units="subscriptions"'
                    + ' data-gauge-adjust="width"'
                    + ' data-width="14%"'
                    + ' data-before="0"'
                    + ' data-after="-CHART_DURATION"'
                    + ' data-points="CHART_DURATION"'
                    + ' data-colors="' + NETDATA.colors[3] + '"'
                    + ' data-decimal-digits="2"'
                    + ' role="application"></div>';
            }
        ]
    },
    'pulsar.namespace_msg_backlog': {
        heads: [
            function (os, id) {
                void (os);
                return '<div data-netdata="' + id + '"'
                    + ' data-dimensions="backlog"'
                    + ' data-chart-library="gauge"'
                    + ' data-gauge-max-value="100"'
                    + ' data-title="Messages Backlog"'
                    + ' data-units="messages"'
                    + ' data-gauge-adjust="width"'
                    + ' data-width="14%"'
                    + ' data-before="0"'
                    + ' data-after="-CHART_DURATION"'
                    + ' data-points="CHART_DURATION"'
                    + ' data-colors="' + NETDATA.colors[2] + '"'
                    + ' data-decimal-digits="2"'
                    + ' role="application"></div>';
            },
        ],
    },

    // ------------------------------------------------------------------------
    // Nvidia-smi

    'nvidia_smi.fan_speed': {
        heads: [
            function (os, id) {
                void (os);
                return '<div data-netdata="' + id + '"'
                    + ' data-dimensions="speed"'
                    + ' data-chart-library="easypiechart"'
                    + ' data-title="Fan Speed"'
                    + ' data-units="percentage"'
                    + ' data-easypiechart-max-value="100"'
                    + ' data-gauge-adjust="width"'
                    + ' data-width="12%"'
                    + ' data-before="0"'
                    + ' data-after="-CHART_DURATION"'
                    + ' data-points="CHART_DURATION"'
                    + ' data-colors="' + NETDATA.colors[4] + '"'
                    + ' data-decimal-digits="2"'
                    + ' role="application"></div>';
            }
        ]
    },
    'nvidia_smi.temperature': {
        heads: [
            function (os, id) {
                void (os);
                return '<div data-netdata="' + id + '"'
                    + ' data-dimensions="temp"'
                    + ' data-chart-library="easypiechart"'
                    + ' data-title="Temperature"'
                    + ' data-units="celsius"'
                    + ' data-gauge-adjust="width"'
                    + ' data-width="12%"'
                    + ' data-before="0"'
                    + ' data-after="-CHART_DURATION"'
                    + ' data-points="CHART_DURATION"'
                    + ' data-colors="' + NETDATA.colors[3] + '"'
                    + ' data-decimal-digits="2"'
                    + ' role="application"></div>';
            }
        ]
    },
    'nvidia_smi.memory_allocated': {
        heads: [
            function (os, id) {
                void (os);
                return '<div data-netdata="' + id + '"'
                    + ' data-dimensions="used"'
                    + ' data-chart-library="easypiechart"'
                    + ' data-title="Used Memory"'
                    + ' data-units="MiB"'
                    + ' data-gauge-adjust="width"'
                    + ' data-width="12%"'
                    + ' data-before="0"'
                    + ' data-after="-CHART_DURATION"'
                    + ' data-points="CHART_DURATION"'
                    + ' data-colors="' + NETDATA.colors[4] + '"'
                    + ' data-decimal-digits="2"'
                    + ' role="application"></div>';
            }
        ]
    },
    'nvidia_smi.power': {
        heads: [
            function (os, id) {
                void (os);
                return '<div data-netdata="' + id + '"'
                    + ' data-dimensions="power"'
                    + ' data-chart-library="easypiechart"'
                    + ' data-title="Power Utilization"'
                    + ' data-units="watts"'
                    + ' data-gauge-adjust="width"'
                    + ' data-width="12%"'
                    + ' data-before="0"'
                    + ' data-after="-CHART_DURATION"'
                    + ' data-points="CHART_DURATION"'
                    + ' data-colors="' + NETDATA.colors[2] + '"'
                    + ' data-decimal-digits="2"'
                    + ' role="application"></div>';
            }
        ]
    },

    // ------------------------------------------------------------------------
    // Supervisor

    'supervisord.process_state_code': {
        info: '<a href="http://supervisord.org/subprocess.html#process-states" target="_blank">Process states map</a>: ' +
        '<code>0</code> - stopped, <code>10</code> - starting, <code>20</code> - running, <code>30</code> - backoff,' +
        '<code>40</code> - stopping, <code>100</code> - exited, <code>200</code> - fatal, <code>1000</code> - unknown.'
    },

    // ------------------------------------------------------------------------
    // Systemd units

    'systemd.service_units_state': {
        info: 'Service units start and control daemons and the processes they consist of. ' +
        'For details, see <a href="https://www.freedesktop.org/software/systemd/man/systemd.service.html#" target="_blank"> systemd.service(5)</a>'
    },

    'systemd.socket_unit_state': {
        info: 'Socket units encapsulate local IPC or network sockets in the system, useful for socket-based activation. ' +
        'For details about socket units, see <a href="https://www.freedesktop.org/software/systemd/man/systemd.socket.html#" target="_blank"> systemd.socket(5)</a>, ' +
        'for details on socket-based activation and other forms of activation, see <a href="https://www.freedesktop.org/software/systemd/man/daemon.html#" target="_blank"> daemon(7)</a>.'
    },

    'systemd.target_unit_state': {
        info: 'Target units are useful to group units, or provide well-known synchronization points during boot-up, ' +
        'see <a href="https://www.freedesktop.org/software/systemd/man/systemd.target.html#" target="_blank"> systemd.target(5)</a>.'
    },

    'systemd.path_unit_state': {
        info: 'Path units may be used to activate other services when file system objects change or are modified. ' +
        'See <a href="https://www.freedesktop.org/software/systemd/man/systemd.path.html#" target="_blank"> systemd.path(5)</a>.'
    },

    'systemd.device_unit_state': {
        info: 'Device units expose kernel devices in systemd and may be used to implement device-based activation. ' +
        'For details, see <a href="https://www.freedesktop.org/software/systemd/man/systemd.device.html#" target="_blank"> systemd.device(5)</a>.'
    },

    'systemd.mount_unit_state': {
        info: 'Mount units control mount points in the file system. ' +
        'For details, see <a href="https://www.freedesktop.org/software/systemd/man/systemd.mount.html#" target="_blank"> systemd.mount(5)</a>.'
    },

    'systemd.automount_unit_state': {
        info: 'Automount units provide automount capabilities, for on-demand mounting of file systems as well as parallelized boot-up. ' +
        'See <a href="https://www.freedesktop.org/software/systemd/man/systemd.automount.html#" target="_blank"> systemd.automount(5)</a>.'
    },

    'systemd.swap_unit_state': {
        info: 'Swap units are very similar to mount units and encapsulate memory swap partitions or files of the operating system. ' +
        'They are described in <a href="https://www.freedesktop.org/software/systemd/man/systemd.swap.html#" target="_blank"> systemd.swap(5)</a>.'
    },

    'systemd.timer_unit_state': {
        info: 'Timer units are useful for triggering activation of other units based on timers. ' +
        'You may find details in <a href="https://www.freedesktop.org/software/systemd/man/systemd.timer.html#" target="_blank"> systemd.timer(5)</a>.'
    },

    'systemd.scope_unit_state': {
        info: '切片单元可用于对管理系统流程的单元进行分组（如服务和范围单元） ' +
        '在用于资源管理的分层树中。 ' +
        '请参阅<a href="https://www.freedesktop.org/software/systemd/man/systemd.scope.html#" target="_blank"> systemd.scope(5)</a>。'
    },

    'systemd.slice_unit_state': {
        info: '范围单位与服务单位相似，但也管理外国流程，而不是启动它们。 ' +
        '请参阅<a href="https://www.freedesktop.org/software/systemd/man/systemd.slice.html#" target="_blank"> systemd.slice(5)</a>。'
    },

    'anomaly_detection.dimensions': {
        info: '被认为异常或正常的维度总数。 '
    },

    'anomaly_detection.anomaly_rate': {
        info: '异常维度的百分比。 '
    },

    'anomaly_detection.detector_window': {
        info: '探测器使用的有源窗口的长度。 '
    },

    'anomaly_detection.detector_events': {
        info: '标志（0或1），用于显示探测器何时触发异常事件。 '
    },

    'anomaly_detection.prediction_stats': {
        info: '与异常检测预测时间相关的诊断指标。 '
    },

    'anomaly_detection.training_stats': {
        info: '与异常检测培训时间相关的诊断指标。 '
    },

    // ------------------------------------------------------------------------
    // Supervisor

    'fail2ban.failed_attempts': {
        info: '<p>尝试失败的次数。</p>'+
        '<p>此图表反映了\'Found\'行的数量。 '+
        '找到意味着服务日志文件中的一行与其过滤器中的失败正则表达式匹配。</p>'
    },

    'fail2ban.bans': {
        info: '<p>禁令数量。</p>'+
        '<p>此图表反映了\'Ban\'和\'Restore Ban\'行的数量。 '+
        '当上次配置的间隔（查找时间）发生失败的尝试次数（最大尝试）时，就会发生禁用操作。</p>'
    },

    'fail2ban.banned_ips': {
        info: '<p>禁用IP地址的数量。</p>'
    },

};
