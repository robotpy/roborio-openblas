
VERSION = 0.3.28

BINRELEASE = https://github.com/OpenMathLib/OpenBLAS/releases/download/v$(VERSION)/OpenBLAS-$(VERSION).tar.gz
LIBGZIP = $(abspath $(notdir ${BINRELEASE}))
SRCDIR = OpenBLAS-$(VERSION)

FC=arm-frc2024-linux-gnueabi-gfortran
CC=arm-frc2024-linux-gnueabi-gcc
STRIP=arm-frc2024-linux-gnueabi-strip

MAKE_OPTIONS=FC=$(FC) CC=$(CC) HOSTCC=gcc \
		TARGET=CORTEXA9 ARM_SOFTFP_ABI=1 \
		NUM_CORES=2 USE_OPENMP=0 MAX_STACK_ALLOC=256 \
		PREFIX=/usr/local DESTDIR=../prefix \
		QUIET_MAKE=1

all: package

${LIBGZIP}:
	wget ${BINRELEASE}

${SRCDIR}: ${LIBGZIP}
	tar -xf ${LIBGZIP}
	cd $(SRCDIR) && patch -p1 < ../arm-buffersize.patch

.PHONY: compile
compile: ${SRCDIR}
	rm -rf prefix
	cd ${SRCDIR} && make $(MAKE_OPTIONS)
	cd ${SRCDIR} && make $(MAKE_OPTIONS) install

.PHONY: package
package: compile
	rm -rf data devdata

	# create release package
	mkdir -p data/usr/local/lib
	cp -L prefix/usr/local/lib/libopenblas.so.0 data/usr/local/lib/libopenblas.so.0
	roborio-gen-whl data.py data -o dist --strip $(STRIP)
	
	# create development package
	mkdir -p devdata/usr/local/lib 
	cp -r prefix/usr/local/include devdata/usr/local/include
	cp -r prefix/usr/local/lib/pkgconfig devdata/usr/local/lib/pkgconfig
	cp -r prefix/usr/local/lib/cmake devdata/usr/local/lib/cmake
	cp -L prefix/usr/local/lib/libopenblas.so devdata/usr/local/lib/libopenblas.so
	cp -L prefix/usr/local/lib/libopenblas.a devdata/usr/local/lib/libopenblas.a
	roborio-gen-whl --dev data.py devdata -o dist
