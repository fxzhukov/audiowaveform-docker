FROM alpine:slim as builder
ENV COMMIT 4f85cb9
RUN apk add autoconf automake g++ gcc libtool make nasm ncurses-dev && \
	wget https://downloads.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz && \
	tar -xf lame-3.100.tar.gz && \
	cd lame-3.100 && \
	# fix for parallel builds
	mkdir -p libmp3lame/i386/.libs && \
	# fix for pic build with new nasm
	sed -i -e '/define sp/s/+/ + /g' libmp3lame/i386/nasm.h && \
	aclocal && automake --force --add-missing && \
	./configure \
		--build=$CBUILD \
		--host=$CHOST \
		--prefix=/usr \
		--enable-nasm \
		--disable-mp3x \
		--disable-shared \
		--with-pic && \
	make -j $(nproc) && \
	make install
RUN apk add autoconf automake g++ gcc libtool gettext git make && \
	git clone https://github.com/xiph/opus && \
	cd opus && \
	./autogen.sh && \
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc \
		--localstatedir=/var \
		--enable-custom-modes && \
	make -j $(nproc) && \
	make install
RUN apk add cmake g++ gcc git samurai && \
	git clone https://github.com/xiph/ogg && \
	cd ogg && \
	cmake -B build -G Ninja \
		-DCMAKE_INSTALL_PREFIX=/usr \
		-DCMAKE_INSTALL_LIBDIR=lib \
		-DBUILD_SHARED_LIBS=False \
		-DCMAKE_BUILD_TYPE=Release \
		$CMAKE_CROSSOPTS && \
	cmake --build build -j $(nproc) && \
	cmake --install build
RUN apk add autoconf automake libtool g++ gcc gettext git !libiconv make pkgconfig && \
	git clone https://github.com/xiph/flac && \
	cd flac && \
	./autogen.sh && \
	./configure \
		--prefix=/usr \
		--enable-shared=no \
		--enable-ogg \
		--disable-rpath \
		--with-pic && \
	make -j $(nproc) && \
	make install
RUN apk add alsa-lib-dev cmake git flac-dev libvorbis-dev linux-headers python3 samurai && \
	git clone https://github.com/libsndfile/libsndfile && \
	cd libsndfile && \
	cmake -B build -G Ninja \
		-DBUILD_SHARED_LIBS=OFF \
		-DCMAKE_BUILD_TYPE=MinSizeRel \
		-DCMAKE_INSTALL_PREFIX=/usr \
		-DENABLE_MPEG=ON && \
	cmake --build build -j $(nproc) && \
	cd build && \
	cd .. && \
	cmake --install build
RUN apk add cmake g++ gcc git samurai zlib-dev && \
	git clone https://github.com/tenacityteam/libid3tag && \
	cd libid3tag && \
	cmake -B build -G Ninja \
		-DBUILD_SHARED_LIBS=OFF \
		-DCMAKE_BUILD_TYPE=MinSizeRel \
		-DENABLE_TESTS=YES \
		-DCMAKE_INSTALL_PREFIX=/usr \
		-DCMAKE_INSTALL_LIBDIR=lib && \
	cmake --build build -j $(nproc) && \
	cd build && \
	cd .. && \
	cmake --install build
RUN apk add boost-dev boost-static cmake g++ gcc gd-dev git libgd libmad-dev libpng-dev libpng-static libvorbis-static make zlib-dev zlib-static && \
	git clone -n https://github.com/bbc/audiowaveform.git && \
	cd audiowaveform && \
	git checkout ${COMMIT} && \
	git clone https://github.com/google/googletest && \
	mkdir build && \
	cd build && \
	cmake -DCMAKE_CXX_STANDARD=14 -D ENABLE_TESTS=1 -D BUILD_STATIC=1 .. && \
	make -j $(nproc) && \
	make install && \
	strip /usr/local/bin/audiowaveform
FROM alpine:slim
RUN apk add libstdc++
COPY --from=builder /usr/local/bin/audiowaveform /usr/local/bin/audiowaveform
ENTRYPOINT [ "audiowaveform" ]
CMD [ "--help" ]
