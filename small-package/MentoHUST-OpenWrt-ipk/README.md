# MentoHUST-OpenWrt-ipk

这是一个积累了很长时间的项目。从2014年起，就陆续在折腾这些东西，期间还自己写了一个基于OpenWrt的神州数码客户端[802.1X Evasi0n](https://github.com/KyleRicardo/802.1X-Evasi0n)，服役了大半年的时间，表现良好，内存占用小，工作效率高。后来，学校所有神州数码服务器全部换成了锐捷，导致我的项目失去了光彩，我又翻出了大名鼎鼎的MentoHUST，在反复折腾交叉编译和功能性修补过程中，有了这样一个版本。该版本非常适合于在OpenWrt的SDK环境下编译出MentoHUST的ipk包。


## 特点

- 修复了原MentoHUST在shell下由于libiconv库编译或工作不正常导致的反馈信息乱码问题
- 去除了libiconv库的依赖，加入了轻量级的strnormalize库，GBK to UTF-8转换良好
- 去除configure等冗余文件，仅保留核心src源码文件
- ./src/Makefile中使用通配符`*`指代libpcap版本，通用性更强
- 无需手动配置环境变量，无需使用automake和configure生成所需Makefile
- 重新完全手动编写./和./src/目录下的Makefile，保证编译的有效性
- 无`--disable-notify --disable-encodepass`等配置，保证原汁原味
- 无手动`#define NO_DYLOAD`补丁，使用动态加载库函数，ipk包更小，并且更容易编译


## PreOperation

### 预备知识

> 这里的编译是指交叉编译。所谓交叉编译，简单地说，就是在一个平台上生成另一个平台上的可执行代码。这里需要注意的是所谓 平台，实际上包含两个概念：体系结构（Architecture）、操作系统（Operating System）。同一个体系结构可以运行不同的操作系统；同样，同一个操作系统也可以在不同的体系结构上运行。
> 交叉编译通常是不得已而为之，有时是因为目的平台上不允许或不能够安装我们所需要的编译器，而我们又需要这个编译器的某些特征；有时是因为目的平台上的资源贫乏，无法运行我们所需要编译器；有时又是因为目的平台还没有建立，连操作系统都没有，根本谈不上运行什么编译器。

> OpenWrt系统是基于Linux平台的操作系统，故我们需要用到Linux的操作系统平台进行交叉编译。但由于种种原因，我们的电脑不可能使用Linux操作系统，但又要交叉编译，怎么办呢？这时候就需要用到虚拟机了。

### 需要的工具
- VMWare Workstation虚拟机工具（[官网下载](https://www.vmware.com/go/getworkstation-win)）
- 一个Ubuntu Linux镜像（可以使用最新LTS版本，[20.04LTS下载](https://releases.ubuntu.com/20.04.3/ubuntu-20.04.3-desktop-amd64.iso)）
- OpenWrt SDK（在[官网](https://downloads.openwrt.org/snapshots/targets/)寻找对应你路由器架构的版本，比如斐讯k2p是ramips的mt7621）
- 本项目的源码

注：OpenWrt SDK在[官网](https://downloads.openwrt.org/snapshots/targets/)找到对应架构后，在最下面`Supplementary Files → openwrt-sdk-<Platform>_gcc-<version>_musl.Linux-x86_64.tar.xz`，比如斐讯k2p是[openwrt-sdk-ramips-mt7621_gcc-11.2.0_musl.Linux-x86_64.tar.xz](https://downloads.openwrt.org/snapshots/targets/ramips/mt7621/openwrt-sdk-ramips-mt7621_gcc-11.2.0_musl.Linux-x86_64.tar.xz)。

### 虚拟机的安装（Tips）
关于虚拟机，在这里不多赘述，仅提供一些Tips。如果对虚拟机完全不了解，建议不要继续观看本教程，先找百度谷歌充充电。

- 推荐新手使用**Ubuntu**

> 虚拟机的Linux系统推荐使用Ubuntu，对于我们新手来说，这无疑是最适合于我们的系统，图形化的界面很贴心，基本操作上和Windows相差不大，可以较快的熟悉起来。

- 务必安装VMWare Tools工具

> 使用VMWare Workstation装Ubuntu的时候，千万不要选择简易安装，这样在后面安装VMware Tools会非常麻烦。先建立一个空虚拟机，然后再用镜像引导安装，这样就比较好，系统安装好了之后再安装上VMWare Tools你会发现这个Tools有多么方便。其中最大的好处有二：系统分辨率的自动调整和剪贴板的无缝连接。就是说，不管文字或者文件，你在windows里面使用Ctrl+C复制后，可以直接在Ubuntu里面粘贴，反之亦然。这在后面将给我们提供非常大的方便。所以，VMWare Tools必须安装，切记。
>
> 2021.11.28更新：现在VMWare比较先进了，似乎装好系统后自动加载了VMWare Tools。

- 务必关闭Ubuntu系统屏保和自动睡眠

> 还有一点需要提醒的是，安装好后，在右上角“系统”菜单的“首选项”中选择“屏幕保护程序”，然后去掉左下角的“计算机空闲时激活屏幕保护程序”，然后按“关闭”，这个窗口是没有“应用”或“确定”之类的，直接关闭它就会保存。用惯了WINDOWS的用户注意了。为什么要做这步呢？因为整个编译过程中有些步骤要等一段时间的，老是自动启用屏幕保护程序，然后还要重新输密码才能退出，也是麻烦事。开始的时候我忘了设置这一步，后来有一次把黑屏状态的虚拟机唤醒的时候，显卡瞬间崩溃了，虚拟机直接死机，然后编译了好久的数据丢失了，白白浪费了几个小时。这个教训也希望大家引起重视。

## PreCompile
现在进入正题了，首先要做的是配置好SDK的交叉编译环境。

### 获取OpenWrt SDK

使用`Ctrl+Alt+T`组合快捷键打开终端，然后在左侧的Dock中，右键单击，将其锁定，方便以后打开。如下图：



在下文中，终端里执行的命令，如果是`$`开头，说明是以普通用户执行；如果是`#`开头，说明是以root用户（最高权限）执行。在输入终端时**不用输入**`$`或`#`符号。

我们的虚拟机是全新系统，缺少许多交叉编译所需的必要组件与工具。先执行如下命令将它们一并安装：

```bash
$ sudo apt install -y git curl build-essential libncurses5-dev zlib1g-dev gawk flex quilt libssl-dev xsltproc libxml-parser-perl mercurial bzr ecj cvs unzip
```

如果你用的是Fedora系统，则执行如下命令：

```
$ sudo dnf install -y gcc gcc-c++ perl-FindBin perl-File-Copy perl-File-Compare perl-Thread-Queue
```



下面就是来获取trunk版本的SDK了，执行命令：

```bash
$ cd Downloads/
$ wget https://downloads.openwrt.org/snapshots/targets/ramips/mt7621/openwrt-sdk-ramips-mt7621_gcc-11.2.0_musl.Linux-x86_64.tar.xz
```

下载好SDK后，我们先解压：
```bash
$ tar -Jxf openwrt-sdk-ramips-mt7621_gcc-11.2.0_musl.Linux-x86_64.tar.xz
```
可以利用Ubuntu的自动填充，就是输入`tar -Jxf op`然后按一下Tab键，就会自动填充为上面的命令。记住这一点，以后会经常用到，熟练使用自动填充会节约不少时间。

解压好后，cd到SDK目录下：

```shell
$ cd openwrt-sdk-ramips-mt7621_gcc-11.2.0_musl.Linux-x86_64
```

### 更新feeds
Feeds，也就是软件包列表，是在OpenWrt中共用位置的包的集合。运行以下命令即可更新内置软件包列表并将我们所需的`libpcap`库编译并安装到`staging_dir`中：
```shell
$ ./scripts/feeds update -a
$ ./scripts/feeds install libpcap
```
如果网速不快，可能需要等待一段时间。静待其完成后，我们的libpcap依赖就准备完毕了。


### 添加需要编译的第三方软件包（也就是我们的MentoHUST-OpenWrt-ipk）

首先要在GitHub上clone此repo至package/mentohust目录下。执行命令：

```bash
$ git clone https://github.com/KyleRicardo/MentoHUST-OpenWrt-ipk.git package/mentohust
```

这里说一下我的Makefile。
一个工程中的源文件不计其数，其按类型、功能、模块分别放在若干个目录中，Makefile定义了一系列的规则来指定，哪些文件需要先编译，哪些文件需要后编译，哪些文件需要重新编译，甚至于进行更复杂的功能操作，因为 Makefile就像一个Shell脚本一样，其中也可以执行操作系统的命令。

Makefile的语法规则并不算复杂，但是新手研究起来也很头大，也不能静下心来去花时间学习Makefile的写法。我虽然起初不会写Makefile，但是折腾了这么久之后，对于一个Makefile，已经不算什么了。于是github上包含了我写的Makefile，同学们可以直接编译。下个版本可能会发布自动从网上下载源码并编译的Makefile。

原始的mentohust编码转换是使用的libiconv库，这个库问题特别多，效率低，不方便编译，受802.1X Evasi0n项目的启发，我干脆摒弃了libiconv库，使用了strnormalize这个文件代替了它，一次性解决了编码转换问题。所以现在，Makefile里面再也找不到iconv的依赖了，现在mentohust唯一依赖的库就是libpcap，编译起来也是相当轻松了。

Makefile既然已经包括在源码中，那么我们可以开始配置我们的编译器了。使用命令：
```
$ make menuconfig
```
这个命令会启用图形化的选项，我们在其中进行调节即可。

在Makefile里面我们已经知道，这个软件包是属于Network里的Ruijie，所以我们在主菜单中找到Network，回车进入，然后找到Ruijie这一项

![Ruijie](https://ws3.sinaimg.cn/large/8832d37agy1fxkpcgym9xj215p0q8afx.jpg)

然后到这里

![mentohust](https://ws2.sinaimg.cn/large/8832d37agy1fxkpcox4yvj215p0q8tcv.jpg)

我们会发现系统已经自动帮我们选中了该软件包。如果没有，我们按M键选中，将其编译为一个组件模块(Module)。

用M键选中后，我们用光标键右几次选中Save，保存后，再多次Exit，最终退出这个界面。



## Compile

```bash
$ make package/mentohust/compile -j$((`nproc`+1)) V=s
```

其中，`-jN`是开启多线程编译，`N`代表线程数，这里是获取逻辑CPU数量+1。`V=s`表示开启详细输出，如果有错误我们好进行排查。如果多线程编译出问题，可以试试单线程，出错概率会减小但是时间会增加不少：

```shell
$ make package/mentohust/compile V=s
```

如果顺利，编译完成之后就能在`<OpenWrt SDK>/bin/packages/<YourArchitecture>/base`中找到你的ipk包了。还包含其依赖的libpcap.ipk。如果你的路由器默认没有安装libpcap包，可以一并安装。

## Install

将上面拷贝出来的mentohust及libpcap的ipk，用上面的方法，利用WinSCP上传到路由器的tmp目录。这个操作很简单，这里不再赘述。

使用快捷键`Ctrl+P`打开PuTTY，输入密码(默认是admin)回车后，来到如下界面：

![pandorabox](https://ws3.sinaimg.cn/large/8832d37agy1fxkpeg7eg2j20ir0btjrj.jpg)

然后我们先`cd /tmp/`
然后用`opkg`命令安装我们所需的软件包：

```
opkg install libpcap_1.7.4-1_ramips_24kec.ipk
opkg install mentohust_0.3.1-1_ramips_24kec.ipk
```

这时有可能会出现这种情况：

![arch-mismatch](https://ws4.sinaimg.cn/large/8832d37agy1fxkpfctgj9j20ir0btmxg.jpg)

遇到这种错误，需要修改/etc/opkg.conf文件，对于小米Mini，需要在其尾部追加：

```
arch all 1
arch ralink 200
arch ramips_24kec 100
```

这样就能正确地安装了：

![libpcap](https://wx3.sinaimg.cn/large/8832d37agy1fxkpfyu41kj20ua0jgdgv.jpg)

当然，mentohust也可以了：

![mentohust](https://ws4.sinaimg.cn/large/8832d37agy1fxkpg99g6zj20ir0btmxg.jpg)

在有些比较老的路由器固件中安装，会有类似这样的错误：

> //usr/lib/opkg/info/mentohust: line 4: default_postinst: not found
> Collected errors:
>
> pkg_run_script: package "mentohust" postinst script returned status 127.
> opkg_configure: dnsmasq-full.postinst returned 127.

上述错误原因如下：

因为evasi0n是基于 trunk 代码编译，所以目前编译出的ipk 包默认带有
Package/postinst 脚本

```
#!/bin/sh

[ "${IPKG_NO_SCRIPT}" = "1" ] && exit 0

. ${IPKG_INSTROOT}/lib/functions.sh

default_postinst$0 $@
```
Package/prerm 脚本
```
#!/bin/sh

. ${IPKG_INSTROOT}/lib/functions.sh

default_prerm $0$@
```
而若不是最新编译的固件， /lib/functions.sh 中是没有 default_postinst default_prerm函数的，所以会造成 127错误。

临时解决办法：
在PuTTY中，键入如下命令并回车：

`echo -e "\ndefault_postinst() {\n\treturn0\n}\ndefault_prerm() {\n\treturn 0\n}" >> /lib/functions.sh`

注意，这是一条命令，是用echo命令将这段空函数追加到functions.sh文件尾部。
上述错误解决之后，终于可以愉快地安装mentohust了。

## Usage

安装好后可以立即使用，配置文件在`/etc/mentohust.conf`，可以自行编辑。

关于mentohust的用法，想必不用我多说吧。我都已经帮忙帮到这一步了。这里提一下，mentohust未能智能识别路由器WAN口对应的网卡，请手动在mentohust.conf的末尾DHCP脚本中添加自己WAN口对应的网卡。最终脚本类似`udhcpc -i eth1`。

最后，可以将mentohust添加到开机启动，怎么弄不用我多说了吧。

## 已知问题

- mentohust未能智能识别路由器WAN口对应的网卡，请手动在mentohust.conf的末尾DHCP脚本中添加自己WAN口对应的网卡。最终脚本类似`udhcpc -i eth1`
- 暂未加入init.d目录的mentohust脚本，可能下个版本加入。
- 后续可能加入只有一个Makefile，通过自动从git下载源码进行编译的版本

