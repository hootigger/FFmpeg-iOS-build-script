#!/bin/sh

# directories
#FF_VERSION="4.1"
FF_VERSION="3.4"
#FF_VERSION="snapshot-git"
if [[ $FFMPEG_VERSION != "" ]]; then
  FF_VERSION=$FFMPEG_VERSION
fi
SOURCE="ffmpeg-$FF_VERSION"
FAT="FFmpeg-iOS"

SCRATCH="scratch"
# must be an absolute path
THIN=`pwd`/"thin"

# absolute path to x264 library
#X264=`pwd`/fat-x264

#FDK_AAC=`pwd`/../fdk-aac-build-script-for-iOS/fdk-aac-ios

# 配置选项
CONFIGURE_FLAGS="--enable-cross-compile --disable-debug --disable-programs \
                 --disable-doc --enable-pic"
#开始裁剪操作
CONFIGURE_FLAGS="$CONFIGURE_FLAGS \
                --disable-ffplay \
                --disable-ffprobe \
                --disable-ffserver"
#								--disable-filters \
#								--disable-parsers --enable-parser=mpegaudio --enable-parser=aac --enable-parser=aac_latm --enable-parser=ac3 --enable-parser=h264 \
#								--disable-muxers  --enable-muxer=mpegts --disable-demuxers --enable-demuxer=mpegts \
#								--disable-bsfs --enable-bsf=aac_adtstoasc \
#								--disable-indevs --disable-outdevs \
#								--disable-protocols --enable-protocol=file \
#								--disable-network"

#启用优化文件大小(牺牲速度)
CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-small"

#禁用所有解码器
CONFIGURE_FLAGS="$CONFIGURE_FLAGS --disable-decoders"

#禁用所有编码器
CONFIGURE_FLAGS="$CONFIGURE_FLAGS --disable-encoders"

#aac mp3解码器
CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-decoder=aac --enable-decoder=mp3"

#aac mp3编码器 WARNING: Option --enable-encoder=mp3 did not match anything,所以移除
CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-encoder=aac"

# pcm_s16le 解码器
CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-decoder=pcm_s16le --enable-encoder=pcm_s16le"

if [ "$X264" ]
then
	CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-gpl --enable-libx264"
fi

if [ "$FDK_AAC" ]
then
	CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-libfdk-aac --enable-nonfree"
fi

# avresample
#CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-avresample"

#ARCHS="arm64 armv7 x86_64 i386"
ARCHS="arm64 x86_64"

COMPILE="y"
LIPO="y"

DEPLOYMENT_TARGET="13.0"

if [ "$*" ]
then
	if [ "$*" = "lipo" ]
	then
		# skip compile
		COMPILE=
	else
		ARCHS="$*"
		if [ $# -eq 1 ]
		then
			# skip lipo
			LIPO=
		fi
	fi
fi

if [ "$COMPILE" ]
then
	if [ ! `which yasm` ]
	then
		echo 'Yasm not found'
		if [ ! `which brew` ]
		then
			echo 'Homebrew not found. Trying to install...'
                        ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" \
				|| exit 1
		fi
		echo 'Trying to install Yasm...'
		brew install yasm || exit 1
	fi
	if [ ! `which gas-preprocessor.pl` ]
	then
		echo 'gas-preprocessor.pl not found. Trying to install...'
		(curl -L https://github.com/libav/gas-preprocessor/raw/master/gas-preprocessor.pl \
			-o /usr/local/bin/gas-preprocessor.pl \
			&& chmod +x /usr/local/bin/gas-preprocessor.pl) \
			|| exit 1
	fi

	if [ ! -r $SOURCE ]
	then
		echo 'FFmpeg source not found. Trying to download...'
		curl -L http://www.ffmpeg.org/releases/$SOURCE.tar.bz2 | tar xj \
			|| exit 1
	fi

	CWD=`pwd`
	for ARCH in $ARCHS
	do
		echo "building $ARCH..."
		mkdir -p "$SCRATCH/$ARCH"
		cd "$SCRATCH/$ARCH"

		CFLAGS="-arch $ARCH"
        # 禁用类型 在编译配置中禁用警告
        CFLAGS="$CFLAGS -Wno-incompatible-function-pointer-types"
		if [ "$ARCH" = "i386" -o "$ARCH" = "x86_64" ]
		then
		    PLATFORM="iPhoneSimulator"
		    CFLAGS="$CFLAGS -mios-simulator-version-min=$DEPLOYMENT_TARGET"
		else
		    PLATFORM="iPhoneOS"
		    CFLAGS="$CFLAGS -mios-version-min=$DEPLOYMENT_TARGET -fembed-bitcode"
		    if [ "$ARCH" = "arm64" ]
		    then
		        EXPORT="GASPP_FIX_XCODE5=1"
		    fi
		fi

		XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
		CC="xcrun -sdk $XCRUN_SDK clang"

		# force "configure" to use "gas-preprocessor.pl" (FFmpeg 3.3)
		if [ "$ARCH" = "arm64" ]
		then
		    AS="gas-preprocessor.pl -arch aarch64 -- $CC"
		else
		    AS="gas-preprocessor.pl -- $CC"
		fi

		CXXFLAGS="$CFLAGS"
		LDFLAGS="$CFLAGS"
		if [ "$X264" ]
		then
			CFLAGS="$CFLAGS -I$X264/include"
			LDFLAGS="$LDFLAGS -L$X264/lib"
		fi
		if [ "$FDK_AAC" ]
		then
			CFLAGS="$CFLAGS -I$FDK_AAC/include"
			LDFLAGS="$LDFLAGS -L$FDK_AAC/lib"
		fi

		TMPDIR=${TMPDIR/%\/} $CWD/$SOURCE/configure \
		    --target-os=darwin \
		    --arch=$ARCH \
		    --cc="$CC" \
		    --as="$AS" \
		    $CONFIGURE_FLAGS \
		    --extra-cflags="$CFLAGS" \
		    --extra-ldflags="$LDFLAGS" \
		    --prefix="$THIN/$ARCH" \
		|| exit 1

		make -j3 install $EXPORT || exit 1
		cd $CWD
	done
fi

if [ "$LIPO" ]
then
	echo "building fat binaries..."
	mkdir -p $FAT/lib
	set - $ARCHS
	CWD=`pwd`
	cd $THIN/$1/lib
	for LIB in *.a
	do
		cd $CWD
		echo lipo -create `find $THIN -name $LIB` -output $FAT/lib/$LIB 1>&2
		lipo -create `find $THIN -name $LIB` -output $FAT/lib/$LIB || exit 1
	done

	cd $CWD
	cp -rf $THIN/$1/include $FAT
fi

echo Done
