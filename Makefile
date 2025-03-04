IMAGEMAGICK_VERSION=7.1.1-21
LIBPNG_VERSION=1.6.40
LIBJPG_VERSION=9e
OPENJP2_VERSION=2.5.0
LIBTIFF_VERSION= 4.6.0
BZIP2_VERSION=1.0.8
LIBWEBP_VERSION=1.3.2

TARGET_DIR ?= /opt/
PROJECT_ROOT = $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
CACHE_DIR=$(PROJECT_ROOT)build/cache

.ONESHELL:

CONFIGURE = PKG_CONFIG_PATH=$(CACHE_DIR)/lib/pkgconfig \
	./configure \
		CPPFLAGS=-I$(CACHE_DIR)/include \
		LDFLAGS=-L$(CACHE_DIR)/lib \
		--disable-dependency-tracking \
		--disable-shared \
		--enable-static \
		--prefix=$(CACHE_DIR)

## libjpg

LIBJPG_SOURCE=jpegsrc.v$(LIBJPG_VERSION).tar.gz

$(LIBJPG_SOURCE):
	curl -LO http://ijg.org/files/$(LIBJPG_SOURCE)

$(CACHE_DIR)/lib/libjpeg.a: $(LIBJPG_SOURCE)
	tar xf $<
	cd jpeg*
	$(CONFIGURE)	 
	make
	make install


## libpng

LIBPNG_SOURCE=libpng-$(LIBPNG_VERSION).tar.xz

$(LIBPNG_SOURCE):
	curl -LO http://prdownloads.sourceforge.net/libpng/$(LIBPNG_SOURCE)

$(CACHE_DIR)/lib/libpng.a: $(LIBPNG_SOURCE)
	tar xf $<
	cd libpng*
	$(CONFIGURE)	 
	make
	make install

# libbz2

BZIP2_SOURCE=bzip2-$(BZIP2_VERSION).tar.gz

# 2023-11-04 appears the repo moved from 
# http://prdownloads.sourceforge.net/bzip2/bzip2-$(BZIP2_VERSION).tar.gz
# to
# https://sourceware.org/pub/bzip2/bzip2-1.0.8.tar.gz

$(BZIP2_SOURCE):
	curl -LO https://sourceware.org/pub/bzip2/bzip2-$(BZIP2_VERSION).tar.gz

$(CACHE_DIR)/lib/libbz2.a: $(BZIP2_SOURCE)
	tar xf $<
	cd bzip2-*
	make libbz2.a
	make install PREFIX=$(CACHE_DIR)

# libtiff

LIBTIFF_SOURCE=tiff-$(LIBTIFF_VERSION).tar.gz

$(LIBTIFF_SOURCE):
	curl -LO http://download.osgeo.org/libtiff/$(LIBTIFF_SOURCE)

$(CACHE_DIR)/lib/libtiff.a: $(LIBTIFF_SOURCE) $(CACHE_DIR)/lib/libjpeg.a
	tar xf $<
	cd tiff-*
	$(CONFIGURE)	 
	make
	make install

# libwebp

LIBWEBP_SOURCE=libwebp-$(LIBWEBP_VERSION).tar.gz

$(LIBWEBP_SOURCE):
	curl -L https://github.com/webmproject/libwebp/archive/v$(LIBWEBP_VERSION).tar.gz -o $(LIBWEBP_SOURCE)
	
$(CACHE_DIR)/lib/libwebp.a: $(LIBWEBP_SOURCE)
	tar xf $<
	cd libwebp-*
	sh autogen.sh
	$(CONFIGURE)	 
	make
	make install

## libopenjp2

OPENJP2_SOURCE=openjp2-$(OPENJP2_VERSION).tar.gz

$(OPENJP2_SOURCE):
	curl -L https://github.com/uclouvain/openjpeg/archive/v$(OPENJP2_VERSION).tar.gz -o $(OPENJP2_SOURCE)


$(CACHE_DIR)/lib/libopenjp2.a: $(OPENJP2_SOURCE) $(CACHE_DIR)/lib/libpng.a $(CACHE_DIR)/lib/libtiff.a
	tar xf $<
	cd openjpeg-*
	mkdir -p build
	cd build 
	PKG_CONFIG_PATH=$(CACHE_DIR)/lib/pkgconfig cmake .. \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX=$(CACHE_DIR) \
		-DBUILD_SHARED_LIBS:bool=off \
		-DBUILD_CODEC:bool=off
	make clean
	make install

# libfreetype
FREETYPE_SOURCE=freetype-2.10.1.tar.gz

$(FREETYPE_SOURCE):
	curl -L http://download.savannah.gnu.org/releases/freetype/freetype-2.10.1.tar.gz -o $(FREETYPE_SOURCE)

$(CACHE_DIR)/lib/freetype2.a: $(FREETYPE_SOURCE)
	tar xf $<
	cd freetype-*
	sh autogen.sh
	$(CONFIGURE)	 
	make
	make install

# ghostscript
GS_SOURCE=gs10040.tar.gz

$(GS_SOURCE): 
	curl -L https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs10040/ghostpdl-10.04.0.tar.gz -o $(GS_SOURCE)

$(CACHE_DIR)/lib/gslib.a: $(GS_SOURCE)
	tar xf $<
	cd ghostpdl-*
	$(CONFIGURE)	 
	make libgs
	make install

## ImageMagick

IMAGE_MAGICK_SOURCE=ImageMagick-$(IMAGEMAGICK_VERSION).tar.gz

$(IMAGE_MAGICK_SOURCE):
	curl -L https://github.com/ImageMagick/ImageMagick/archive/$(IMAGEMAGICK_VERSION).tar.gz -o $(IMAGE_MAGICK_SOURCE)


LIBS:=$(CACHE_DIR)/lib/libjpeg.a \
	$(CACHE_DIR)/lib/libpng.a \
	$(CACHE_DIR)/lib/libopenjp2.a \
	$(CACHE_DIR)/lib/libtiff.a \
	$(CACHE_DIR)/lib/libbz2.a \
	$(CACHE_DIR)/lib/freetype2.a \
	$(CACHE_DIR)/lib/gslib.a \
	$(CACHE_DIR)/lib/libwebp.a

$(TARGET_DIR)/bin/identify: $(IMAGE_MAGICK_SOURCE) $(LIBS)
	tar xf $<
	cd ImageMa*
	PKG_CONFIG_PATH=$(CACHE_DIR)/lib/pkgconfig \
		./configure \
		CPPFLAGS=-I$(CACHE_DIR)/include \
		LDFLAGS=-L$(CACHE_DIR)/lib \
		--prefix=$(TARGET_DIR) \
		--enable-shared=no \
		--enable-static \
		--enable-delegate-build \
		--disable-dependency-tracking \
		--without-modules \
		--without-perl \
		--without-x \
		--without-magick-plus-plus \
		--enable-hdri=no \
		--disable-docs \
		--with-jpeg=yes \
		--with-png=yes \
		--with-xml=yes \
		--with-freetype=yes \
		--with-ghostscript=yes \
		--with-fontconfig=yes \
		--disable-openmp
	make clean
	make all LDFLAGS="-all-static"
	make install

libs: $(LIBS)

all: $(TARGET_DIR)/bin/identify
