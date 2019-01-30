##############################
# RPM
##############################
SET(CPACK_RPM_PACKAGE_PROVIDES "avidemux3-${QT_EXTENSION} = ${AVIDEMUX_VERSION}")
SET(CPACK_RPM_PACKAGE_NAME "avidemux3-${QT_EXTENSION}")
SET(CPACK_RPM_PACKAGE_DESCRIPTION "Simple video editor,main program ${QT_EXTENSION} version ")
SET(CPACK_RPM_PACKAGE_SUMMARY "Qt interface for avidemux")
SET(CPACK_RPM_PACKAGE_REQUIRES "avidemux3-core")
SET(CPACK_PACKAGE_RELOCATABLE "false")
SET(CPACK_RPM_EXCLUDE_FROM_AUTO_FILELIST_ADDITION
    ${CPACK_PACKAGING_INSTALL_PREFIX}${CMAKE_INSTALL_PREFIX}/share/applications
    ${CPACK_PACKAGING_INSTALL_PREFIX}${CMAKE_INSTALL_PREFIX}/share/icons
    ${CPACK_PACKAGING_INSTALL_PREFIX}${CMAKE_INSTALL_PREFIX}/share/icons/hicolor
    ${CPACK_PACKAGING_INSTALL_PREFIX}${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/128x128
    ${CPACK_PACKAGING_INSTALL_PREFIX}${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/128x128/appsS
    ${CPACK_PACKAGING_INSTALL_PREFIX}${CMAKE_INSTALL_PREFIX}/share/metainfo )

include(admCPackRpm)
