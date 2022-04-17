#CFLAGS=-fPIC -DPPPOE_VER='"${PPPD_VER}"'

all:build_dir netkeeper-interception-c netkeeper-interception-s
	@find ./builds/*.so

build_dir:
	@mkdir ./builds

netkeeper-interception-c:
	@$(CC) $(CFLAGS) netkeeper-interception-c.c -shared -o ./builds/$@.so

netkeeper-interception-s:
	@$(CC) $(CFLAGS) netkeeper-interception-s.c -shared -o ./builds/$@.so

clean:
	rm *.so
