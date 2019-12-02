# powturbo  (c) Copyright 2016-2019
# Linux: "export CC=clang" "export CXX=clang". windows mingw: "set CC=gcc" "set CXX=g++" or uncomment the CC,CXX lines
CC ?= gcc
CXX ?= g++

#CC=powerpc64le-linux-gnu-gcc

#------- OS/ARCH -------------------
ifneq (,$(filter Windows%,$(OS)))
  OS := Windows
  CC=gcc
  CXX=g++
  ARCH=x86_64
else
  OS := $(shell uname -s)
  ARCH := $(shell uname -m)

ifneq (,$(findstring aarch64,$(CC)))
  ARCH = aarch64
else ifneq (,$(findstring powerpc64le,$(CC)))
  ARCH = ppc64le
endif
endif

ifeq ($(ARCH),ppc64le)
  CFLAGS=-mcpu=power9 -mtune=power9
  MSSE=-D__SSSE3__
else ifeq ($(ARCH),aarch64)
  CFLAGS+=-march=armv8-a 
ifneq (,$(findstring clang, $(CC)))
  CFLAGS+=-march=armv8-a -falign-loops -fomit-frame-pointer
else
  CFLAGS+=-march=armv8-a 
endif
  MSSE=-march=armv8-a
else ifeq ($(ARCH),$(filter $(ARCH),x86_64 ppc64le))
  CFLAGS=-march=native
  MSSE=-mssse3
endif

ifeq (,$(findstring clang, $(CC)))
DEFS+=-falign-loops
endif
#$(info ARCH="$(ARCH)")

ifeq ($(OS),$(filter $(OS),Linux GNU/kFreeBSD GNU OpenBSD FreeBSD DragonFly NetBSD MSYS_NT Haiku))
LDFLAGS+=-lrt
endif
ifeq ($(STATIC),1)
LDFLAGS+=-static
endif


all: tb64app

ifeq ($(FULLCHECK),1)
DEFS+=-DB64CHECK
endif

turbob64c.o: turbob64c.c
	$(CC) -O3 $(MARCH) $(DEFS) -fstrict-aliasing  $< -c -o $@ 

tb64app.o: tb64app.c
	$(CC) -O3 $(DEFS) $< -c -o $@ 

turbob64d.o: turbob64d.c
	$(CC) -O3 $(MARCH) $(DEFS) -fstrict-aliasing $< -c -o $@ 

turbob64sse.o: turbob64sse.c
	$(CC) -O3 $(MSSE) $(DEFS) -fstrict-aliasing $< -c -o $@ 

turbob64avx.o: turbob64sse.c
	$(CC) -O3 $(DEFS) -march=corei7-avx -mtune=corei7-avx -mno-aes -fstrict-aliasing $< -c -o turbob64avx.o 

turbob64avx2.o: turbob64avx2.c
	$(CC) -O3 -march=haswell -fstrict-aliasing -falign-loops $< -c -o $@ 

LIB=turbob64c.o turbob64d.o turbob64sse.o
ifeq ($(ARCH),x86_64)
LIB+=turbob64avx.o turbob64avx2.o
endif

ifeq ($(BASE64),1)
include xtb64make
endif


tb64app: $(LIB) tb64app.o 
	$(CC) -O3 $(LIB) tb64app.o $(LDFLAGS) -o tb64app

tb64bench: $(LIB) tb64bench.o 
	$(CC) -O3 $(LIB) tb64bench.o $(LDFLAGS) -o tb64bench

tb64test: $(LIB) tb64test.o 
	$(CC) -O3 $(LIB) tb64test.o $(LDFLAGS) -o tb64test
	
	
.c.o:
	$(CC) -O3 $(CFLAGS)  $(MARCH) $< -c -o $@

clean:
	@find . -type f -name "*\.o" -delete -or -name "*\~" -delete -or -name "core" -delete -or -name "turbob64"

cleanw:
	del /S *.o

