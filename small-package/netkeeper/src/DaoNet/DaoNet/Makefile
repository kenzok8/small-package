CC = mips-openwrt-linux-gcc 
CFLAGS = -g -Wall -Wimplicit-function-declaration -I $(STAGING_DIR)/include/ 

DaoNet: main.o frame.o netutils.o netkeeper.o
	$(CC) -o $@ $^ $(STAGING_DIR)/lib/libmbedcrypto.a $(CFLAGS)

main.o: main.c frame.h netutils.h netkeeper.h
	$(CC) -o $@ $< $(CFLAGS) -c

frame.o: frame.c frame.h
	$(CC) -o $@ $< $(CFLAGS) -c

netkeeper.o: netkeeper.c netkeeper.h
	$(CC) -o $@ $< $(CFLAGS) -c

netutils.o: netutils.c netutils.h
	$(CC) -o $@ $< $(CFLAGS) -c

clean:
	rm *.o DaoNet
