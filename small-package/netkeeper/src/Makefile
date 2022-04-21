#CFLAGS = -fPIC -DPPPOE_VER='"${PPPD_VER}"'

all:build_dir chongqing_sxplugin chongqing0094_sxplugin hubei_sxplugin zhejiang_xiaoyuan_sxplugin xinjiang_sxplugin qinghai_sxplugin shandongmobile_sxplugin shandongmobile_4_9_sxplugin hebei_sxplugin shanxi_yixun_sxplugin gansu_telecom_sxplugin zhejiang_qiye_sxplugin hainan_sxplugin
	@find ./builds/*.so

build_dir:
	@mkdir ./builds

chongqing0094_sxplugin:
	@$(CC) $(CFLAGS) sxplugin.c -DRADIUS='"xianxinli1radius"'  -DPREFIX1="'\n'" -shared -o ./builds/$@.so

chongqing_sxplugin:
	@$(CC) $(CFLAGS) sxplugin.c -DRADIUS='"cqxinliradius002"'  -DPREFIX1="'\n'" -shared -o ./builds/$@.so

hubei_sxplugin:
	@$(CC) $(CFLAGS) sxplugin.c -DRADIUS='"hubtxinli01"' -DPREFIX1="'\n'" -shared -o ./builds/$@.so

zhejiang_xiaoyuan_sxplugin:
	@$(CC) $(CFLAGS) sxplugin.c -DRADIUS='"singlenet01"' -DPREFIX1="'\n'" -shared -o ./builds/$@.so

xinjiang_sxplugin:
	@$(CC) $(CFLAGS) sxplugin.c -DRADIUS='"xinjiang@0724"' -DPREFIX1="'\n'" -shared -o ./builds/$@.so

qinghai_sxplugin:
	@$(CC) $(CFLAGS) sxplugin.c -DRADIUS='"shd@xiaoyuan0002"'  -DPREFIX1="'\n'" -shared -o ./builds/$@.so

shandongmobile_sxplugin:
	@$(CC) $(CFLAGS) sxplugin.c -DRADIUS='"shandongmobile13"' -DPREFIX1="'\n'" -shared -o ./builds/$@.so

shandongmobile_4_9_sxplugin:
	@$(CC) $(CFLAGS) sxplugin.c -DRADIUS='""' -DPREFIX1="'\n'" -shared -o ./builds/$@.so

hebei_sxplugin:
	@$(CC) $(CFLAGS) sxplugin.c -DRADIUS='"hebeicncxinli002"' -DPREFIX1="'\n'" -shared -o ./builds/$@.so

shanxi_yixun_sxplugin:
	@$(CC) $(CFLAGS) sxplugin.c -DRADIUS='"sh_xi@xiaoyuan01"' -DPREFIX1="'\n'" -shared -o ./builds/$@.so

gansu_telecom_sxplugin:
	@$(CC) $(CFLAGS) sxplugin.c -DRADIUS='"xiaoyuanyixun001"' -DPREFIX1="'\n'" -shared -o ./builds/$@.so

ningxia_telecom_sxplugin:
	@$(CC) $(CFLAGS) sxplugin.c -DRADIUS='"n_x@xiaoyuanwang"' -DPREFIX1="'\n'" -shared -o ./builds/$@.so

zhejiang_qiye_sxplugin:
	@$(CC) $(CFLAGS) sxplugin.c -DRADIUS='"zjxinlisx02"' -DPREFIX1="'\n'" -shared -o ./builds/$@.so

hainan_sxplugin:
	@$(CC) $(CFLAGS) hainan_sxplugin.c -shared -o ./builds/$@.so

chongqing_sxplugin4:
	@$(CC) $(CFLAGS) sxplugin4.c -DRADIUS='"xianxinli1radiusGJxDpkZLtSEFarOM"' -DPREFIX1="'1'" -shared -o ./builds/$@.so

clean:
	rm *.so
