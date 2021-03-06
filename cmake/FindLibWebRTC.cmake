# FindLibWebRTC.cmake
#
# Once done these will be defined:
#
#  LIBWEBRTC_FOUND
#  LIBWEBRTC_ROOT_DIR
#  LIBWEBRTC_INCLUDE_DIRS
#  LIBWEBRTC_LIBRARIES
#
#  WEBRTC_FOUND
#  WEBRTC_ROOT_DIR
#  WEBRTC_INCLUDE_DIRS
#  WEBRTC_LIBRARIES
#

if(${CMAKE_BUILD_TYPE} STREQUAL "Debug")
	add_definitions(-DDEBUG -D_DEBUG)
else()
	add_definitions(-DNDEBUG)
endif()

if(libwebrtc_DIR)
	set(LIBWEBRTC_CMAKE_DIR ${libwebrtc_DIR})
	list(APPEND CMAKE_MODULE_PATH ${LIBWEBRTC_CMAKE_DIR})
	list(APPEND CMAKE_PREFIX_PATH ${LIBWEBRTC_CMAKE_DIR})
	add_definitions(-DWEBRTC_LIBRARY_IMPL -DNO_TCMALLOC -DABSL_ALLOCATOR_NOTHROW)
	if(APPLE)
		add_definitions(-DWEBRTC_POSIX -DWEBRTC_MAC -DHAVE_PTHREAD)
	elseif(WIN32)
		add_definitions(-DWEBRTC_WIN -DWIN32 -D_WINDOWS -D__STD_C
			-DWIN32_LEAN_AND_MEAN -DNOMINMAX -D_UNICODE -DUNICODE)
	elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
		add_definitions(-DWEBRTC_LINUX -D_GLIBCXX_USE_CXX11_ABI=0)
	endif()
	find_package(libwebrtc CONFIG REQUIRED)
	return()
endif()

find_package(PkgConfig QUIET)
if (PKG_CONFIG_FOUND)
	pkg_check_modules(_WEBRTC QUIET webrtc libwebrtc webrtc_full libwebrtc_full)
endif()

if(CMAKE_SIZEOF_VOID_P EQUAL 8)
	set(_lib_suffix 64)
else()
	set(_lib_suffix 32)
endif()

find_path(WEBRTC_INCLUDE_DIR
	NAMES
		pc/channel.h
		api/peerconnectioninterface.h
		api/peer_connection_interface.h
	HINTS
		ENV WEBRTC_ROOT_DIR${_lib_suffix}
		ENV WEBRTC_ROOT_DIR
		ENV WEBRTC_ROOT
		ENV WEBRTC
		${WEBRTC_ROOT_DIR${_lib_suffix}}
		${WEBRTC_ROOT_DIR}
		${_WEBRTC_INCLUDE_DIRS}
	PATHS
		/sw
		/opt/local
		/opt
		/usr/local
		/usr
	PATH_SUFFIXES
		include${_lib_suffix}
		include
		src
)

find_library(WEBRTC_LIB
	NAMES ${_WEBRTC_LIBRARIES} webrtc libwebrtc webrtc_full libwebrtc_full
	HINTS
		ENV WEBRTC_ROOT_DIR${_lib_suffix}
		ENV WEBRTC_ROOT_DIR
		ENV WEBRTC_ROOT_DIR/src/out
		${WEBRTC_ROOT_DIR${_lib_suffix}}
		${WEBRTC_ROOT_DIR}
		${WEBRTC_ROOT_DIR}/src/out
		${_WEBRTC_LIBRARY_DIRS}
	PATHS
		/sw
		/opt/local
		/opt
		/usr/local
		/usr
	PATH_SUFFIXES
		lib${_lib_suffix} lib
		libs${_lib_suffix} libs
		bin${_lib_suffix} bin
		../lib${_lib_suffix} ../lib
		../libs${_lib_suffix} ../libs
		../bin${_lib_suffix} ../bin
		obj
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(LibWebRTC DEFAULT_MSG WEBRTC_LIB WEBRTC_INCLUDE_DIR)
set(WEBRTC_FOUND ${LIBWEBRTC_FOUND})
mark_as_advanced(WEBRTC_INCLUDE_DIR WEBRTC_LIB LIBWEBRTC_FOUND)

if(LIBWEBRTC_CMAKE_DIR)
	set(libwebrtc_DIR LIBWEBRTC_CMAKE_DIR)
endif()

#------------------------------------------------------------------------
# Platform dependencies & preprocessor definitions
#
if(APPLE)
	# Enable threading
	set(THREADS_PREFER_PTHREAD_FLAG ON)
	find_package(Threads REQUIRED)

	add_definitions(-DENABLE_RTC_EVENT_LOG
		-D_LIBCPP_HAS_NO_ALIGNED_ALLOCATION
		-DCR_XCODE_VERSION=0941 -D__STDC_CONSTANT_MACROS -D__STDC_FORMAT_MACROS -D_FORTIFY_SOURCE=2
		-D_LIBCPP_DISABLE_VISIBILITY_ANNOTATIONS -D_LIBCXXABI_DISABLE_VISIBILITY_ANNOTATIONS
		-D_LIBCPP_ENABLE_NODISCARD -DCR_LIBCXX_REVISION=361348
		-D__ASSERT_MACROS_DEFINE_VERSIONS_WITHOUT_UNDERSCORE=0
		-DNVALGRIND -DDYNAMIC_ANNOTATIONS_ENABLED=0
		-DWEBRTC_ENABLE_PROTOBUF=1 -DWEBRTC_INCLUDE_INTERNAL_AUDIO_DEVICE -DRTC_ENABLE_VP9 -DHAVE_SCTP
		-DWEBRTC_USE_H264 -DWEBRTC_LIBRARY_IMPL -DWEBRTC_NON_STATIC_TRACE_EVENT_HANDLERS=0
		-DWEBRTC_POSIX -DWEBRTC_MAC -DABSL_ALLOCATOR_NOTHROW=1 -DHAVE_SCTP
		-DGOOGLE_PROTOBUF_NO_RTTI -DGOOGLE_PROTOBUF_NO_STATIC_INITIALIZER -DHAVE_PTHREAD
		-DHAVE_WEBRTC_VIDEO
	) # webrtc 78/79 release

	# find_library(APP_KIT AppKit)
	# find_library(APPLICATION_SERVICES ApplicationServices)
	find_library(AUDIO_TOOLBOX AudioToolbox)
	# find_library(AV_FOUNDATION AVFoundation)
	## find_library(COCOA Cocoa)
	find_library(CORE_AUDIO CoreAudio)
	find_library(CORE_FOUNDATION CoreFoundation)
	find_library(CORE_GRAPHICS CoreGraphics)
	# find_library(CORE_MEDIA CoreMedia)
	## find_library(CORE_SERVICES CoreServices)
	## find_library(CORE_VIDEO CoreVideo)
	find_library(FOUNDATION Foundation)
	# find_library(IO_KIT IOKit)
	# find_library(IO_SURFACE IOSurface)
	## find_library(METAL Metal)
	## find_library(METAL_KIT MetalKit)
	## find_library(OPENGL OpenGL)
	## find_library(SECURITY_FRAMEWORK Security)
	## find_library(SYSTEM_CONFIG SystemConfiguration)
	## find_library(VIDEO_TOOLBOX VideoToolbox)

	set(LIBWEBRTC_PLATFORM_DEPS
		# ${APP_KIT}
		# ${APPLICATION_SERVICES}
		${AUDIO_TOOLBOX}
		# ${AV_FOUNDATION}
		## ${COCOA}
		${CORE_AUDIO}
		${CORE_FOUNDATION}
		${CORE_GRAPHICS}
		# ${CORE_MEDIA}
		## ${CORE_SERVICES}
		## ${CORE_VIDEO}
		${FOUNDATION}
		# ${IO_KIT}
		# ${IO_SURFACE}
		## ${METAL}
		## ${METAL_KIT}
		## ${OPENGL}
		## ${SECURITY_FRAMEWORK}
		## ${SYSTEM_CONFIG}
		## ${VIDEO_TOOLBOX}
	)
elseif(UNIX)
	add_definitions(-DWEBRTC_POSIX)

	if (CMAKE_SYSTEM_NAME STREQUAL "Linux")
		add_definitions(-DWEBRTC_LINUX -D_GLIBCXX_USE_CXX11_ABI=0)
		set(LIBWEBRTC_PLATFORM_DEPS
			-lrt
			-lX11
			-lGLU
			# -lGL
		)
	endif()
endif()

if(WIN32 AND MSVC)
	set(CMAKE_C_FLAGS_DEBUG     "${CMAKE_C_FLAGS_DEBUG}     /MTd")
	set(CMAKE_CXX_FLAGS_DEBUG   "${CMAKE_CXX_FLAGS_DEBUG}   /MTd")
	set(CMAKE_C_FLAGS_RELEASE   "${CMAKE_C_FLAGS_RELEASE}   /MT")
	set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /MT")

	if(${CMAKE_BUILD_TYPE} STREQUAL "Debug")
		add_compile_definitions(
			ENABLE_RTC_EVENT_LOG
			USE_AURA=1
			NO_TCMALLOC
			FULL_SAFE_BROWSING
			SAFE_BROWSING_CSD
			SAFE_BROWSING_DB_LOCAL
			CHROMIUM_BUILD
			_HAS_NODISCARD
			_HAS_EXCEPTIONS=0
			__STD_C
			_CRT_RAND_S
			_CRT_SECURE_NO_DEPRECATE
			_SCL_SECURE_NO_DEPRECATE
			_ATL_NO_OPENGL
			_WINDOWS
			CERT_CHAIN_PARA_HAS_EXTRA_FIELDS
			PSAPI_VERSION=2
			WIN32
			_SECURE_ATL
			_USING_V110_SDK71_
			WINAPI_FAMILY=WINAPI_FAMILY_DESKTOP_APP
			WIN32_LEAN_AND_MEAN
			NOMINMAX
			_UNICODE
			UNICODE
			NTDDI_VERSION=NTDDI_WIN10_RS2
			_WIN32_WINNT=0x0A00
			WINVER=0x0A00
			_DEBUG
			DYNAMIC_ANNOTATIONS_ENABLED=1
			WTF_USE_DYNAMIC_ANNOTATIONS=1
			WEBRTC_ENABLE_PROTOBUF=1
			WEBRTC_INCLUDE_INTERNAL_AUDIO_DEVICE
			RTC_ENABLE_VP9
			HAVE_SCTP
			WEBRTC_USE_H264
			WEBRTC_LIBRARY_IMPL
			WEBRTC_NON_STATIC_TRACE_EVENT_HANDLERS=0
			WEBRTC_WIN
			ABSL_ALLOCATOR_NOTHROW=1
			HAVE_SCTP
			GOOGLE_PROTOBUF_NO_RTTI
			GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER
		)
	else()
		add_definitions(-DENABLE_RTC_EVENT_LOG -DUSE_AURA=1 -DNO_TCMALLOC
			-DFULL_SAFE_BROWSING -DSAFE_BROWSING_CSD -DSAFE_BROWSING_DB_LOCAL
			-DCHROMIUM_BUILD -D_HAS_EXCEPTIONS=0 -D__STD_C -D_CRT_RAND_S
			-D_CRT_SECURE_NO_DEPRECATE -D_SCL_SECURE_NO_DEPRECATE -D_ATL_NO_OPENGL
			-D_WINDOWS -DCERT_CHAIN_PARA_HAS_EXTRA_FIELDS -DPSAPI_VERSION=2 -DWIN32
			-D_SECURE_ATL -D_USING_V110_SDK71_ -DWINAPI_FAMILY=WINAPI_FAMILY_DESKTOP_APP
			-DWIN32_LEAN_AND_MEAN -DNOMINMAX -D_UNICODE -DUNICODE -DNTDDI_VERSION=NTDDI_WIN10_RS2
			-D_WIN32_WINNT=0x0A00 -DWINVER=0x0A00 -DNVALGRIND -DDYNAMIC_ANNOTATIONS_ENABLED=0
			-DWEBRTC_ENABLE_PROTOBUF=1 -DWEBRTC_INCLUDE_INTERNAL_AUDIO_DEVICE -DRTC_ENABLE_VP9 -DHAVE_SCTP
			-DWEBRTC_USE_H264 -DWEBRTC_LIBRARY_IMPL -DWEBRTC_NON_STATIC_TRACE_EVENT_HANDLERS=0
			-DWEBRTC_WIN -DABSL_ALLOCATOR_NOTHROW=1 -DHAVE_SCTP -DGOOGLE_PROTOBUF_NO_RTTI
			-DGOOGLE_PROTOBUF_NO_STATIC_INITIALIZER
			-D_HAS_NODISCARD
		) # WebRTC 75 Release
	endif()

	set(LIBWEBRTC_PLATFORM_DEPS
		advapi32.lib
		amstrmid.lib
		crypt32.lib
		d3d11.lib
		dmoguids.lib
		dxgi.lib
		iphlpapi.lib
		msdmo.lib
		secur32.lib
		strmiids.lib
		winmm.lib
		wmcodecdspuuid.lib
		ws2_32.lib
	)
endif()

if(LIBWEBRTC_FOUND)
	set(CMAKE_CXX_STANDARD 17)

	get_filename_component(LIBWEBRTC_ROOT_DIR ${WEBRTC_INCLUDE_DIR} DIRECTORY)
	set(WEBRTC_ROOT_DIR ${LIBWEBRTC_ROOT_DIR})

	set(LIBWEBRTC_INCLUDE_DIRS
		${WEBRTC_INCLUDE_DIR}
		${WEBRTC_INCLUDE_DIR}/third_party
		${WEBRTC_INCLUDE_DIR}/third_party/abseil-cpp
		${WEBRTC_INCLUDE_DIR}/third_party/libyuv/include
		${WEBRTC_INCLUDE_DIR}/third_party/boringssl/src/include
		${WEBRTC_INCLUDE_DIR}/third_party/protobuf/src
	)
	set(WEBRTC_INCLUDE_DIRS ${LIBWEBRTC_INCLUDE_DIRS})

	set(LIBWEBRTC_LIBRARY ${WEBRTC_LIB})
	set(WEBRTC_LIBRARY ${WEBRTC_LIB})

	set(LIBWEBRTC_LIBRARIES
		${WEBRTC_LIB}
		${LIBWEBRTC_PLATFORM_DEPS}
	)
	set(WEBRTC_LIBRARIES ${LIBWEBRTC_LIBRARIES})

	mark_as_advanced(LIBWEBRTC_LIBRARY LIBWEBRTC_LIBRARIES LIBWEBRTC_ROOT_DIR)

	# message(STATUS "WEBRTC_ROOT_DIR: ${WEBRTC_ROOT_DIR}")
	# message(STATUS "WEBRTC_INCLUDE_DIRS:")
	# foreach(_dir ${WEBRTC_INCLUDE_DIRS})
	# 	message(STATUS "-- ${_dir}")
	# endforeach()
	# message(STATUS "WEBRTC_LIBRARY: ${WEBRTC_LIBRARY}")
	# message(STATUS "WEBRTC_LIBRARIES:")
	# foreach(_lib ${WEBRTC_LIBRARIES})
	# 	message(STATUS "-- ${_lib}")
	# endforeach()
endif()
