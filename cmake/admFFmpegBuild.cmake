MACRO (xadd opt)
	if ("${ARGV1}" STREQUAL "")
		set(FFMPEG_FLAGS "${FFMPEG_FLAGS} ${opt}")
	else ("${ARGV1}" STREQUAL "")
		string(STRIP ${ARGV1} arg)
		set(FFMPEG_FLAGS "${FFMPEG_FLAGS} ${opt}=\"${arg}\"")
	endif ("${ARGV1}" STREQUAL "")
ENDMACRO (xadd)

option(FF_INHERIT_BUILD_ENV "" ON)

set(FFMPEG_VERSION "2.6.1")
set(FFMPEG_ROOT_DIR "${AVIDEMUX_TOP_SOURCE_DIR}/avidemux_core/ffmpeg_package")
set(FFMPEG_PATCH_DIR  "${FFMPEG_ROOT_DIR}/patches/")
set(FFMPEG_SOURCE_ARCHIVE "ffmpeg-${FFMPEG_VERSION}.tar.bz2")
set(FFMPEG_SOURCE_ARCHIVE_DIR "ffmpeg-${FFMPEG_VERSION}")
set(FFMPEG_EXTRACT_DIR "${CMAKE_BINARY_DIR}")
set(FFMPEG_BASE_DIR "${FFMPEG_EXTRACT_DIR}/ffmpeg")
set(FFMPEG_SOURCE_DIR "${FFMPEG_BASE_DIR}/source")
set(FFMPEG_BINARY_DIR "${FFMPEG_BASE_DIR}/build")

set(FFMPEG_DECODERS  aac ac3 eac3 adpcm_ima_amv  amv  bmp  cinepak  cyuv  dca  dvbsub  dvvideo  ffv1  ffvhuff  flv  fraps  h263  h264  
                                         hevc  huffyuv  mjpeg
					 mjpegb  mpeg2video  mpeg4  msmpeg4v2  msmpeg4v3  msvideo1  nellymoser  png  qdm2  rawvideo  snow
					 svq3  theora  tscc  mp2 mp3 mp2_float mp3_float
					 vc1  vp3  vp6  vp6a  vp6f  vp8 vp9 wmapro wmav2  wmv1  wmv2  wmv3 cscd)
set(FFMPEG_ENCODERS  ac3  ac3_float dvvideo  ffv1  ffvhuff  flv  h263  huffyuv  mjpeg  mp2  mpeg1video  mpeg2video  mpeg4  snow aac dca)
set(FFMPEG_MUXERS  flv  matroska  mpeg1vcd  mpeg2dvd  mpeg2svcd  mpegts  mov  mp4  psp)
set(FFMPEG_PARSERS  ac3  h263  h264  hevc  mpeg4video)
set(FFMPEG_PROTOCOLS  file)
xadd("--enable-shared --disable-static --disable-everything --disable-avfilter --enable-hwaccels --enable-postproc --enable-gpl")
xadd("--enable-runtime-cpudetect --disable-network ")
xadd("--enable-swscale --disable-swresample")
xadd("--disable-doc --disable-programs")

FIND_HEADER_AND_LIB(_X265 x265.h)
FIND_HEADER_AND_LIB(_X265_CONFIG x265_config.h)

IF (_X265_FOUND AND _X265_CONFIG_FOUND)
#	xadd("--enable-libx265")
#	message("adding --enable-libx265 to ffmpeg protocols")
ENDIF (_X265_FOUND AND _X265_CONFIG_FOUND)
xadd("--disable-libx265")
xadd("--disable-libx264")
IF(USE_NVENC)
   SET(FFMPEG_ENCODERS ${FFMPEG_ENCODERS} nvenc)
   xadd("--enable-nonfree")
   xadd("--enable-nvenc")
ENDIF(USE_NVENC)

if (NOT CROSS)
	xadd(--prefix ${CMAKE_INSTALL_PREFIX})
endif (NOT CROSS)

# Clean FFmpeg
set_directory_properties(${CMAKE_CURRENT_BINARY_DIR} ADDITIONAL_MAKE_CLEAN_FILES "${FFMPEG_BASE_DIR}")

# Prepare FFmpeg source
include(admFFmpegUtil)
include(admFFmpegPrepareTar)

if (NOT FFMPEG_PREPARED)
	include(admFFmpegPrepareGit)
endif (NOT FFMPEG_PREPARED)

message("")

if (FFMPEG_PERFORM_PATCH)
	find_package(Patch)

        # my patches
	file(GLOB patchFiles "${FFMPEG_PATCH_DIR}/*.patch")

	foreach(patchFile ${patchFiles})
                get_filename_component(short ${patchFile}  NAME)
                MESSAGE(STATUS "-- Mine, Applying patch <${short}> --")
		patch_file("${FFMPEG_SOURCE_DIR}" "${patchFile}")
	endforeach(patchFile)
        # XVBA patch from xbmc_dxva
        IF(XVBA_NOT_ENABLED_FOR_NOW) #<-------------------
	file(GLOB patchFilesXvba "${FFMPEG_PATCH_DIR}/xvba/*.patch")

	foreach(patchFileXvba ${patchFilesXvba})
                get_filename_component(short ${patchFileXvba}  NAME)
                MESSAGE(STATUS "-- DXVA, Applying patch <${short}> --")
		patch_file_p1("${FFMPEG_SOURCE_DIR}" "${patchFileXvba}")
	endforeach(patchFileXvba)
        ENDIF(XVBA_NOT_ENABLED_FOR_NOW) #<-------------------
        
        #
	if (UNIX )
			MESSAGE(STATUS "Patching Linux common.mak")
			patch_file("${FFMPEG_SOURCE_DIR}" "${FFMPEG_PATCH_DIR}/common.mak.diff") 
	endif (UNIX )

	message("")
endif (FFMPEG_PERFORM_PATCH)

if (USE_VDPAU)
	xadd(--enable-vdpau)
	set(FFMPEG_DECODERS ${FFMPEG_DECODERS} h264_vdpau  vc1_vdpau  mpeg1_vdpau  mpeg_vdpau  wmv3_vdpau)
endif (USE_VDPAU)

if (USE_LIBVA)
	xadd(--enable-vaapi)
	set(FFMPEG_DECODERS ${FFMPEG_DECODERS} h264_vaapi)
endif (USE_LIBVA)


#if(USE_XVBA)
	#xadd(--enable-xvba)
#else(USE_XVBA)
	#xadd(--disable-xvba)
#endif(USE_XVBA)


xadd(--enable-bsf aac_adtstoasc)

# Configure FFmpeg, if required
foreach (decoder ${FFMPEG_DECODERS})
	xadd(--enable-decoder ${decoder})
endforeach (decoder)

foreach (encoder ${FFMPEG_ENCODERS})
	xadd(--enable-encoder ${encoder})
endforeach (encoder)

foreach (muxer ${FFMPEG_MUXERS})
	xadd(--enable-muxer ${muxer})
endforeach (muxer)

foreach (parser ${FFMPEG_PARSERS})
	xadd(--enable-parser ${parser})
endforeach (parser)

foreach (protocol ${FFMPEG_PROTOCOLS})
	xadd(--enable-protocol ${protocol})
endforeach (protocol)

if (WIN32)
	if (ADM_CPU_X86_32)
		xadd(--enable-memalign-hack)
	endif (ADM_CPU_X86_32)

	xadd(--enable-w32threads)
else (WIN32)
	xadd(--enable-pthreads)
endif (WIN32)

if (NOT ADM_DEBUG)
	xadd(--disable-debug)
endif (NOT ADM_DEBUG)

#  Cross compiler override (win32 & win64)
if (CROSS)
	if(APPLE)
		xadd(--prefix /opt/mac)
		xadd(--host-cc gcc)
		xadd(--nm ${CMAKE_CROSS_PREFIX}-nm) 
		xadd(--strip ${CMAKE_CROSS_PREFIX}-strip) 

		set(CROSS_OS darwin)
		set(CROSS_ARCH i386)
	else(APPLE)
		xadd(--prefix /mingw)
		xadd(--host-cc gcc)
		xadd(--nm ${CMAKE_CROSS_PREFIX}-nm) 
		#xadd(--sysroot /mingw/include)

		set(CROSS_OS mingw32)	

		if (ADM_CPU_64BIT)
			set(CROSS_ARCH x86_64)
		else (ADM_CPU_64BIT)
			set(CROSS_ARCH i386)
		endif (ADM_CPU_64BIT)
	endif(APPLE)

	message(STATUS "Using cross compilation flag: ${FFMPEG_FLAGS}")
endif (CROSS)

if (FF_INHERIT_BUILD_ENV)
	xadd(--cc "${CMAKE_C_COMPILER}")
	xadd(--ld "${CMAKE_C_COMPILER}")
	xadd(--ar "${CMAKE_AR}")
	# nm should be ok if we do not cross compile

	if (CMAKE_C_FLAGS)
		xadd(--extra-cflags ${CMAKE_C_FLAGS})
	endif (CMAKE_C_FLAGS)

	if (CMAKE_SHARED_LINKER_FLAGS)
		xadd(--extra-ldflags ${CMAKE_SHARED_LINKER_FLAGS})
	endif (CMAKE_SHARED_LINKER_FLAGS)

	if (VERBOSE)
		# for ffmpeg to use the same  compiler as others
		MESSAGE(STATUS "Building ffmpeg with CC=${CMAKE_C_COMPILER}")
		MESSAGE(STATUS "Building ffmpeg with LD=${CMAKE_C_COMPILER}")
		MESSAGE(STATUS "Building ffmpeg with AR=${CMAKE_AR}")
		MESSAGE(STATUS "Building ffmpeg with CMAKE_C_FLAGS=${CMAKE_C_FLAGS}")
		MESSAGE(STATUS "Building ffmpeg with CFLAGS=${FF_FLAGS}")
		MESSAGE(STATUS "Building ffmpeg with CFLAGS2=${FFMPEG_FLAGS}")
		message("")
	endif (VERBOSE)
endif (FF_INHERIT_BUILD_ENV)

if (CROSS_ARCH OR CROSS_OS)
	xadd(--enable-cross-compile)
endif (CROSS_ARCH OR CROSS_OS)

if (CROSS_ARCH)
	set(CROSS_ARCH "${CROSS_ARCH}" CACHE STRING "")
	xadd(--arch ${CROSS_ARCH})
endif (CROSS_ARCH)

if (CROSS_OS)
	set(CROSS_OS "${CROSS_OS}" CACHE STRING "")
	xadd(--target-os ${CROSS_OS})
endif (CROSS_OS)

if (FF_FLAGS)
	set(FF_FLAGS "${FF_FLAGS}" CACHE STRING "")
	xadd(${FF_FLAGS})
endif (FF_FLAGS)

if (NOT "${LAST_FFMPEG_FLAGS}" STREQUAL "${FFMPEG_FLAGS}")
	set(FFMPEG_PERFORM_BUILD 1)
endif (NOT "${LAST_FFMPEG_FLAGS}" STREQUAL "${FFMPEG_FLAGS}")

if (NOT EXISTS "${FFMPEG_BINARY_DIR}/Makefile")
	set(FFMPEG_PERFORM_BUILD 1)
endif (NOT EXISTS "${FFMPEG_BINARY_DIR}/Makefile")

if (FFMPEG_PERFORM_BUILD)
	find_package(Bourne)
	find_package(GnuMake)

	message(STATUS "Configuring FFmpeg")
	set(LAST_FFMPEG_FLAGS "${FFMPEG_FLAGS}" CACHE STRING "" FORCE)

	file(MAKE_DIRECTORY "${FFMPEG_BINARY_DIR}")
	file(REMOVE "${FFMPEG_BINARY_DIR}/ffmpeg${CMAKE_EXECUTABLE_SUFFIX}")
	file(REMOVE "${FFMPEG_BINARY_DIR}/ffmpeg_g${CMAKE_EXECUTABLE_SUFFIX}")

	set(ffmpeg_bash_directory ${BASH_EXECUTABLE})
	convertPathToUnix(ffmpeg_bash_directory ${BASH_EXECUTABLE})
	get_filename_component(ffmpeg_bash_directory ${ffmpeg_bash_directory} PATH)
	configure_file("${AVIDEMUX_TOP_SOURCE_DIR}/cmake/ffmpeg_configure.sh.cmake" "${FFMPEG_BINARY_DIR}/ffmpeg_configure.sh")

	execute_process(COMMAND ${BASH_EXECUTABLE} ffmpeg_configure.sh WORKING_DIRECTORY "${FFMPEG_BINARY_DIR}"
					OUTPUT_VARIABLE FFMPEG_CONFIGURE_OUTPUT RESULT_VARIABLE FFMPEG_CONFIGURE_RESULT)

    if (NOT (FFMPEG_CONFIGURE_RESULT EQUAL 0))
	    MESSAGE(ERROR "configure returned <${FFMPEG_CONFIGURE_RESULT}>")
	    MESSAGE(ERROR "configure output is <${FFMPEG_CONFIGURE_OUTPUT}>")
		MESSAGE(FATAL_ERROR "An error occured ")
    endif (NOT (FFMPEG_CONFIGURE_RESULT EQUAL 0))

	MESSAGE(STATUS "Configuring done, processing")

	if (ADM_CPU_X86)
		file(READ ${FFMPEG_BINARY_DIR}/config.h FF_CONFIG_H)
		string(REGEX MATCH "#define[ ]+HAVE_YASM[ ]+1" FF_YASM "${FF_CONFIG_H}")

		if (NOT FF_YASM)
			message(FATAL_ERROR "Yasm was not found.")
		endif (NOT FF_YASM)
	endif (ADM_CPU_X86)

	execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory "libavutil"
					WORKING_DIRECTORY "${CMAKE_BINARY_DIR}/config")

	execute_process(COMMAND ${CMAKE_COMMAND} -E copy "./libavutil/avconfig.h" "${CMAKE_BINARY_DIR}/config/libavutil"
					WORKING_DIRECTORY "${FFMPEG_BINARY_DIR}")

	   if (UNIX)
		find_package(Patch)
		IF(APPLE)
			MESSAGE(STATUS "Patching config.mak - mac(2)")
			patch_file("${FFMPEG_BINARY_DIR}" "${FFMPEG_PATCH_DIR}/config.mak.mac.diff")
		ELSE(APPLE)
			MESSAGE(STATUS "Patching config.mak - linux (2)")
			patch_file("${FFMPEG_BINARY_DIR}" "${FFMPEG_PATCH_DIR}/config.mak.diff")
		ENDIF(APPLE)
	   endif (UNIX)

	message("")
endif (FFMPEG_PERFORM_BUILD)

# Build FFmpeg
getFfmpegLibNames("${FFMPEG_SOURCE_DIR}")

set(ffmpeg_gnumake_executable ${GNUMAKE_EXECUTABLE})
convertPathToUnix(ffmpeg_gnumake_executable ${BASH_EXECUTABLE})
configure_file("${AVIDEMUX_TOP_SOURCE_DIR}/cmake/ffmpeg_make.sh.cmake" "${FFMPEG_BINARY_DIR}/ffmpeg_make.sh")

add_custom_command(OUTPUT
						"${FFMPEG_BINARY_DIR}/libavcodec/${LIBAVCODEC_LIB}"
						"${FFMPEG_BINARY_DIR}/libavformat/${LIBAVFORMAT_LIB}"
						"${FFMPEG_BINARY_DIR}/libavutil/${LIBAVUTIL_LIB}"
						"${FFMPEG_BINARY_DIR}/libpostproc/${LIBPOSTPROC_LIB}"
						"${FFMPEG_BINARY_DIR}/libswscale/${LIBSWSCALE_LIB}"
				   COMMAND ${BASH_EXECUTABLE} ffmpeg_make.sh WORKING_DIRECTORY "${FFMPEG_BINARY_DIR}")

# Add and INSTALL libraries
registerFFmpeg("${FFMPEG_SOURCE_DIR}" "${FFMPEG_BINARY_DIR}" 0)
include_directories("${FFMPEG_SOURCE_DIR}")
include_directories("${FFMPEG_BINARY_DIR}")

ADM_INSTALL_LIB_FILES("${FFMPEG_BINARY_DIR}/libswscale/${LIBSWSCALE_LIB}")
ADM_INSTALL_LIB_FILES("${FFMPEG_BINARY_DIR}/libpostproc/${LIBPOSTPROC_LIB}")
ADM_INSTALL_LIB_FILES("${FFMPEG_BINARY_DIR}/libavutil/${LIBAVUTIL_LIB}")
ADM_INSTALL_LIB_FILES("${FFMPEG_BINARY_DIR}/libavcodec/${LIBAVCODEC_LIB}")
ADM_INSTALL_LIB_FILES("${FFMPEG_BINARY_DIR}/libavformat/${LIBAVFORMAT_LIB}")

INSTALL(FILES "${FFMPEG_BINARY_DIR}/libavutil/avconfig.h" DESTINATION "${AVIDEMUX_INCLUDE_DIR}/avidemux/2.6/libavutil" COMPONENT dev) 
IF(USE_LIBVA)
        INSTALL(FILES "${FFMPEG_SOURCE_DIR}/libavcodec/vaapi.h" DESTINATION "${AVIDEMUX_INCLUDE_DIR}/avidemux/2.6/libavcodec" COMPONENT dev) 
        INSTALL(FILES "${FFMPEG_SOURCE_DIR}/libavcodec/vaapi_internal.h" DESTINATION "${AVIDEMUX_INCLUDE_DIR}/avidemux/2.6/libavcodec" COMPONENT dev) 
ENDIF(USE_LIBVA)
IF(USE_XVBA)
        INSTALL(FILES "${FFMPEG_SOURCE_DIR}/libavcodec/xvba.h" DESTINATION "${AVIDEMUX_INCLUDE_DIR}/avidemux/2.6/libavcodec" COMPONENT dev) 
        INSTALL(FILES "${FFMPEG_SOURCE_DIR}/libavcodec/xvba_internal.h" DESTINATION "${AVIDEMUX_INCLUDE_DIR}/avidemux/2.6/libavcodec" COMPONENT dev) 
ENDIF(USE_XVBA)
INSTALL(FILES "${FFMPEG_SOURCE_DIR}/libavcodec/avcodec.h" "${FFMPEG_SOURCE_DIR}/libavcodec/vdpau.h"
	"${FFMPEG_SOURCE_DIR}/libavcodec/version.h" 
	"${FFMPEG_SOURCE_DIR}/libavcodec/old_codec_ids.h" 
	DESTINATION "${AVIDEMUX_INCLUDE_DIR}/avidemux/2.6/libavcodec" COMPONENT dev)
INSTALL(FILES "${FFMPEG_SOURCE_DIR}/libavformat/avformat.h" "${FFMPEG_SOURCE_DIR}/libavformat/avio.h"
	"${FFMPEG_SOURCE_DIR}/libavformat/version.h" 
	"${FFMPEG_SOURCE_DIR}/libavformat/flv.h" DESTINATION "${AVIDEMUX_INCLUDE_DIR}/avidemux/2.6/libavformat" COMPONENT dev)
INSTALL(FILES "${FFMPEG_SOURCE_DIR}/libavutil/attributes.h" "${FFMPEG_SOURCE_DIR}/libavutil/avutil.h" 
	"${FFMPEG_SOURCE_DIR}/libavutil/buffer.h"
	"${FFMPEG_SOURCE_DIR}/libavutil/bswap.h" "${FFMPEG_SOURCE_DIR}/libavutil/common.h"
	"${FFMPEG_SOURCE_DIR}/libavutil/cpu.h" "${FFMPEG_SOURCE_DIR}/libavutil/frame.h"
	"${FFMPEG_SOURCE_DIR}/libavutil/log.h" "${FFMPEG_SOURCE_DIR}/libavutil/mathematics.h"
	"${FFMPEG_SOURCE_DIR}/libavutil/mem.h" "${FFMPEG_SOURCE_DIR}/libavutil/pixfmt.h"
	"${FFMPEG_SOURCE_DIR}/libavutil/macros.h" "${FFMPEG_SOURCE_DIR}/libavutil/old_pix_fmts.h"
	"${FFMPEG_SOURCE_DIR}/libavutil/channel_layout.h" 
	"${FFMPEG_SOURCE_DIR}/libavutil/error.h" 
	"${FFMPEG_SOURCE_DIR}/libavutil/dict.h" 
	"${FFMPEG_SOURCE_DIR}/libavutil/version.h" 
	"${FFMPEG_SOURCE_DIR}/libavutil/time.h" 
	"${FFMPEG_SOURCE_DIR}/libavutil/intfloat.h" 
	"${FFMPEG_SOURCE_DIR}/libavutil/samplefmt.h" "${FFMPEG_SOURCE_DIR}/libavutil/audioconvert.h"
	"${FFMPEG_SOURCE_DIR}/libavutil/rational.h" DESTINATION "${AVIDEMUX_INCLUDE_DIR}/avidemux/2.6/libavutil" COMPONENT dev)
INSTALL(FILES "${FFMPEG_SOURCE_DIR}/libpostproc/postprocess.h" DESTINATION "${AVIDEMUX_INCLUDE_DIR}/avidemux/2.6/libpostproc" COMPONENT dev)
INSTALL(FILES "${FFMPEG_SOURCE_DIR}/libpostproc/version.h" DESTINATION "${AVIDEMUX_INCLUDE_DIR}/avidemux/2.6/libpostproc" COMPONENT dev)
INSTALL(FILES "${FFMPEG_SOURCE_DIR}/libswscale/swscale.h" DESTINATION "${AVIDEMUX_INCLUDE_DIR}/avidemux/2.6/libswscale" COMPONENT dev)
INSTALL(FILES "${FFMPEG_SOURCE_DIR}/libswscale/version.h" DESTINATION "${AVIDEMUX_INCLUDE_DIR}/avidemux/2.6/libswscale" COMPONENT dev)

