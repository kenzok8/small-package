SRCDIR := src
BINDIR := bin
OBJDIR := build

TARGETS := $(BINDIR)/vlmcs $(BINDIR)/vlmcsd

.PHONY: all
all: $(BINDIR) $(TARGETS)

$(BINDIR)/vlmcs: $(OBJDIR)/vlmcs.o $(OBJDIR)/kmsdata-full.o $(OBJDIR)/crypto.o \
                 $(OBJDIR)/kms.o $(OBJDIR)/endian.o $(OBJDIR)/output.o \
                 $(OBJDIR)/shared_globals.o $(OBJDIR)/helpers.o \
                 $(OBJDIR)/network.o $(OBJDIR)/rpc.o \
                 $(OBJDIR)/crypto_internal.o $(OBJDIR)/dns_srv.o
	$(CC) $(LDFLAGS) -o $@ $^

$(BINDIR)/vlmcsd: $(OBJDIR)/vlmcsd.o $(OBJDIR)/kmsdata.o $(OBJDIR)/crypto.o \
                  $(OBJDIR)/kms.o $(OBJDIR)/endian.o $(OBJDIR)/output.o \
                  $(OBJDIR)/shared_globals.o $(OBJDIR)/helpers.o \
                  $(OBJDIR)/network.o $(OBJDIR)/rpc.o \
                  $(OBJDIR)/crypto_internal.o
	$(CC) $(LDFLAGS) -o $@ $^

$(OBJDIR)/%.o: $(SRCDIR)/%.c | $(OBJDIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJDIR):
	@mkdir -p $(OBJDIR)

$(BINDIR):
	@mkdir -p $(BINDIR)

.PHONY: clean
clean:
	@rm -rf $(OBJDIR) $(BINDIR)
