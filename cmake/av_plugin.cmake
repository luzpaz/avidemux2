include(admAsNeeded)
MACRO(INIT_AUDIO_DEVICE _lib)
	INCLUDE_DIRECTORIES("${AVIDEMUX_TOP_SOURCE_DIR}/avidemux/ADM_coreAudioDevice/include")
	INCLUDE_DIRECTORIES("${AVIDEMUX_TOP_SOURCE_DIR}/avidemux/ADM_core/include")
	INCLUDE_DIRECTORIES("${AVIDEMUX_TOP_SOURCE_DIR}/avidemux/ADM_coreAudio/include")
	INCLUDE_DIRECTORIES("${AVIDEMUX_TOP_SOURCE_DIR}/avidemux/ADM_coreUtils/include")
ENDMACRO(INIT_AUDIO_DEVICE)

MACRO(INSTALL_AUDIO_DEVICE _lib)
	INSTALL(TARGETS ${_lib} 
                DESTINATION "${AVIDEMUX_LIB_DIR}/${ADM_PLUGIN_DIR}/audioDevices/"
                COMPONENT plugins
                )
ENDMACRO(INSTALL_AUDIO_DEVICE)


MACRO(ADD_AUDIO_DEVICE name)
        ADM_ADD_SHARED_LIBRARY(${name} ${ARGN})
        TARGET_LINK_LIBRARIES( ${name} ADM_coreAudioDevice6 ADM_core6 m)
ENDMACRO(ADD_AUDIO_DEVICE name)

