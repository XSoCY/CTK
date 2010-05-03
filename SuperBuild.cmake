SET(cmake_version_required "2.8")
SET(cmake_version_required_dash "2-8")

CMAKE_MINIMUM_REQUIRED(VERSION ${cmake_version_required})

# 
# CTK_KWSTYLE_EXECUTABLE
# DCMTK_DIR
# QT_QMAKE_EXECUTABLE
# VTK_DIR
# PYTHONQT_INSTALL_DIR
# PYTHON_LIBRARY
# PYTHON_INCLUDE_DIR
#

#-----------------------------------------------------------------------------
# Enable and setup External project global properties
#
INCLUDE(ExternalProject)

SET(ep_base "${CMAKE_BINARY_DIR}/CMakeExternals")
SET_PROPERTY(DIRECTORY PROPERTY EP_BASE ${ep_base})

SET(ep_install_dir ${ep_base}/Install)
SET(ep_build_dir ${ep_base}/Build)
SET(ep_source_dir ${ep_base}/Source)
#SET(ep_parallelism_level)
SET(ep_build_shared_libs ON)
SET(ep_build_testing OFF)

SET(ep_common_args
  -DCMAKE_INSTALL_PREFIX:PATH=${ep_install_dir}
  -DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE}
  -DBUILD_TESTING:BOOL=${ep_build_testing}
  )

# Compute -G arg for configuring external projects with the same CMake generator:
IF(CMAKE_EXTRA_GENERATOR)
  SET(gen "${CMAKE_EXTRA_GENERATOR} - ${CMAKE_GENERATOR}")
ELSE()
  SET(gen "${CMAKE_GENERATOR}")
ENDIF()

# Use this value where semi-colons are needed in ep_add args:
set(sep "^^")

#-----------------------------------------------------------------------------
# Update CMake module path
#
SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/CMake)

#-----------------------------------------------------------------------------
# Collect CTK library target dependencies
#

ctkMacroCollectAllTargetLibraries("${CTK_LIBS_SUBDIRS}" "Libs" ALL_TARGET_LIBRARIES)
ctkMacroCollectAllTargetLibraries("${CTK_PLUGINS_SUBDIRS}" "Plugins" ALL_TARGET_LIBRARIES)
ctkMacroCollectAllTargetLibraries("${CTK_APPLICATIONS_SUBDIRS}" "Applications" ALL_TARGET_LIBRARIES)
#MESSAGE(STATUS ALL_TARGET_LIBRARIES:${ALL_TARGET_LIBRARIES})

#-----------------------------------------------------------------------------
# Initialize NON_CTK_DEPENDENCIES variable
#
# Using the variable ALL_TARGET_LIBRARIES initialized above with the help
# of the macro ctkMacroCollectAllTargetLibraries, let's get the list of all Non-CTK dependencies.
# NON_CTK_DEPENDENCIES is expected by the macro ctkMacroShouldAddExternalProject
ctkMacroGetAllNonCTKTargetLibraries("${ALL_TARGET_LIBRARIES}" NON_CTK_DEPENDENCIES)
#MESSAGE(STATUS NON_CTK_DEPENDENCIES:${NON_CTK_DEPENDENCIES})

#-----------------------------------------------------------------------------
# Qt is expected to be setup by CTK/CMakeLists.txt just before it includes the SuperBuild script
#

#-----------------------------------------------------------------------------
# KWStyle
#
SET(kwstyle_DEPENDS)
IF(CTK_USE_KWSTYLE)
  IF(NOT DEFINED CTK_KWSTYLE_EXECUTABLE)
    SET(proj KWStyle-CVSHEAD)
    SET(kwstyle_DEPENDS ${proj})
    ExternalProject_Add(${proj}
      LIST_SEPARATOR ${sep}
      CVS_REPOSITORY ":pserver:anoncvs:@public.kitware.com:/cvsroot/KWStyle"
      CVS_MODULE "KWStyle"
      CMAKE_GENERATOR ${gen}
      CMAKE_ARGS
        ${ep_common_args}
      )
    SET(CTK_KWSTYLE_EXECUTABLE ${ep_install_dir}/bin/KWStyle)
  ENDIF()
ENDIF()

#-----------------------------------------------------------------------------
# PythonQt
#
SET(PythonQt_DEPENDS)
ctkMacroShouldAddExternalProject(PYTHONQT_LIBRARIES add_project)
IF(${add_project})
  IF(NOT DEFINED PYTHONQT_INSTALL_DIR)
    SET(proj PythonQt)
  #   MESSAGE(STATUS "Adding project:${proj}")
    SET(PythonQt_DEPENDS ${proj})

    # Python is required
    FIND_PACKAGE(PythonLibs)
    IF(NOT PYTHONLIBS_FOUND)
      MESSAGE(FATAL_ERROR "error: Python is required to build ${PROJECT_NAME}")
    ENDIF()

    # Configure patch script
    SET(pythonqt_src_dir ${ep_source_dir}/${proj})
    SET(pythonqt_patch_dir ${CTK_SOURCE_DIR}/Utilities/PythonQt/)
    SET(pythonqt_configured_patch_dir ${CTK_BINARY_DIR}/Utilities/PythonQt/)
    SET(pythonqt_patchscript
      ${CTK_BINARY_DIR}/Utilities/PythonQt/PythonQt-trunk-patch.cmake)
    CONFIGURE_FILE(
      ${CTK_SOURCE_DIR}/Utilities/PythonQt/PythonQt-trunk-patch.cmake.in
      ${pythonqt_patchscript} @ONLY)
      
    ExternalProject_Add(${proj}
      SVN_REPOSITORY "http://pythonqt.svn.sourceforge.net/svnroot/pythonqt/trunk"
      CMAKE_GENERATOR ${gen}
      PATCH_COMMAND ${CMAKE_COMMAND} -P ${pythonqt_patchscript}
      BUILD_COMMAND ""
      CMAKE_ARGS
        ${ep_common_args}
        -DQT_QMAKE_EXECUTABLE:FILEPATH=${QT_QMAKE_EXECUTABLE}
        -DPYTHON_INCLUDE_DIR:PATH=${PYTHON_INCLUDE_DIR}
        -DPYTHON_LIBRARY:FILEPATH=${PYTHON_LIBRARY}
      )
    SET(PYTHONQT_INSTALL_DIR ${ep_install_dir})
  ENDIF()
ENDIF()
    
#-----------------------------------------------------------------------------
# Utilities/DCMTK
#
SET(DCMTK_DEPENDS)
ctkMacroShouldAddExternalProject(DCMTK_LIBRARIES add_project)
IF(${add_project})
  IF(NOT DEFINED DCMTK_DIR)
    SET(proj DCMTK)
#     MESSAGE(STATUS "Adding project:${proj}")
    SET(DCMTK_DEPENDS ${proj})
    ExternalProject_Add(${proj}
        DOWNLOAD_COMMAND ""
        CMAKE_GENERATOR ${gen}
        SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/Utilities/${proj}
        CMAKE_ARGS
          ${ep_common_args}
          -DDCMTK_BUILD_APPS:BOOL=ON # Build also dmctk tools (movescu, storescp, ...)
        )
    SET(DCMTK_DIR ${ep_install_dir})
  ENDIF()
ENDIF()

#-----------------------------------------------------------------------------
# Utilities/ZMQ
#
SET(ZMQ_DEPENDS)
ctkMacroShouldAddExternalProject(ZMQ_LIBRARIES add_project)
IF(${add_project})
  SET(proj ZMQ)
#   MESSAGE(STATUS "Adding project:${proj}")
  SET(ZMQ_DEPENDS ${proj})
  ExternalProject_Add(${proj}
      DOWNLOAD_COMMAND ""
      INSTALL_COMMAND ""
      CMAKE_GENERATOR ${gen}
      SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/Utilities/ZMQ
      CMAKE_ARGS
        ${ep_common_args}
      )
ENDIF()

#-----------------------------------------------------------------------------
# QtMobility
#
SET(QtMobility_DEPENDS)
ctkMacroShouldAddExternalProject(QTMOBILITY_QTSERVICEFW_LIBRARIES add_project)
IF(${add_project})
  SET(proj QtMobility)
#   MESSAGE(STATUS "Adding project:${proj}")
  SET(QtMobility_DEPENDS ${proj})
  
  # Configure patch script
  SET(qtmobility_src_dir ${ep_source_dir}/${proj})
  SET(qtmobility_patch_dir ${CTK_SOURCE_DIR}/Utilities/QtMobility/)
  SET(qtmobility_configured_patch_dir ${CTK_BINARY_DIR}/Utilities/QtMobility/)
  SET(qtmobility_patchscript
    ${CTK_BINARY_DIR}/Utilities/QtMobility/QtMobility-1.0.0-patch.cmake)
  CONFIGURE_FILE(
    ${CTK_SOURCE_DIR}/Utilities/QtMobility/QtMobility-1.0.0-patch.cmake.in
    ${qtmobility_patchscript} @ONLY)

  # Define configure options
  SET(qtmobility_modules "serviceframework")
  SET(qtmobility_build_type "release")
  IF(UNIX)
    IF(CMAKE_BUILD_TYPE STREQUAL "Debug")
      SET(qtmobility_build_type "debug")
    ENDIF()
  ELSEIF(NOT ${CMAKE_CFG_INTDIR} STREQUAL "Release")
    SET(qtmobility_build_type "debug")
  ENDIf()
  
  SET(qtmobility_make_cmd)
  IF(UNIX OR MINGW)
    SET(qtmobility_make_cmd make)
  ELSEIF(WIN32)
    SET(qtmobility_make_cmd nmake)
  ENDIF()

  ExternalProject_Add(${proj}
    URL ${CTK_BINARY_DIR}/Utilities/QtMobility/qt-mobility-servicefw-opensource-src-1.0.0.tar.gz
    PATCH_COMMAND ${CMAKE_COMMAND} -P ${qtmobility_patchscript}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure -${qtmobility_build_type} -libdir ${CMAKE_BINARY_DIR}/CTK-build/bin -no-docs -modules ${qtmobility_modules}
    BUILD_COMMAND ${qtmobility_make_cmd}
    INSTALL_COMMAND ${qtmobility_make_cmd} install
    BUILD_IN_SOURCE 1
    )
ENDIF()

#-----------------------------------------------------------------------------
# Utilities/OpenIGTLink
#
SET (OpenIGTLink_DEPENDS)
ctkMacroShouldAddExternalProject(OpenIGTLink_LIBRARIES add_project)
IF(${add_project})
  IF(NOT DEFINED OpenIGTLink_DIR)
    SET(proj OpenIGTLink)
  #   MESSAGE(STATUS "Adding project:${proj}")
    SET(OpenIGTLink_DEPENDS ${proj})
    ExternalProject_Add(${proj}
        SVN_REPOSITORY "http://svn.na-mic.org/NAMICSandBox/trunk/OpenIGTLink"
        INSTALL_COMMAND ""
        CMAKE_GENERATOR ${gen}
        CMAKE_ARGS
          ${ep_common_args}
        )
    SET(OpenIGTLink_DIR ${ep_build_dir}/${proj})
  ENDIF()
ENDIF()

#-----------------------------------------------------------------------------
# VTK
#
SET (VTK_DEPENDS)
ctkMacroShouldAddExternalProject(VTK_LIBRARIES add_project)
IF(${add_project})
  IF(NOT DEFINED VTK_DIR)
    SET(proj VTK)
#     MESSAGE(STATUS "Adding project:${proj}")
    SET(VTK_DEPENDS ${proj})
    ExternalProject_Add(${proj}
      GIT_REPOSITORY git://vtk.org/VTK.git
      INSTALL_COMMAND ""
      CMAKE_GENERATOR ${gen}
      CMAKE_ARGS
        ${ep_common_args}
        -DVTK_WRAP_TCL:BOOL=OFF
        -DVTK_WRAP_PYTHON:BOOL=OFF
        -DVTK_WRAP_JAVA:BOOL=OFF
        -DBUILD_SHARED_LIBS:BOOL=ON 
        -DDESIRED_QT_VERSION:STRING=4
        -DVTK_USE_GUISUPPORT:BOOL=ON
        -DVTK_USE_QVTK_QTOPENGL:BOOL=ON
        -DVTK_USE_QT:BOOL=ON
        -DQT_QMAKE_EXECUTABLE:FILEPATH=${QT_QMAKE_EXECUTABLE}
      )
    SET(VTK_DIR ${ep_build_dir}/${proj})
  ENDIF()
ENDIF()

#-----------------------------------------------------------------------------
# XIP
#
SET (XIP_DEPENDS)
ctkMacroShouldAddExternalProject(XIP_LIBRARIES add_project)
IF(${add_project})
  SET(proj XIP)
#   MESSAGE(STATUS "Adding project:${proj}")
  SET(XIP_DEPENDS ${proj})
  ExternalProject_Add(${proj}
    SVN_REPOSITORY "https://collab01a.scr.siemens.com/svn/xip/releases/latest"
    SVN_USERNAME "anonymous"
    INSTALL_COMMAND ""
    CMAKE_GENERATOR ${gen}
    CMAKE_ARGS
      ${ep_common_args}
    )
ENDIF()
   
#-----------------------------------------------------------------------------
# CTK Utilities
#
set(proj CTK-Utilities)
ExternalProject_Add(${proj}
  DOWNLOAD_COMMAND ""
  CONFIGURE_COMMAND ""
  BUILD_COMMAND ""
  INSTALL_COMMAND ""
  DEPENDS
    # Mandatory dependencies
    #  - none
    # Optionnal dependencies
    ${QtMobility_DEPENDS}
    ${kwstyle_DEPENDS}
    ${DCMTK_DEPENDS}
    ${PythonQt_DEPENDS}
    ${ZMQ_DEPENDS}
    ${OpenIGTLink_DEPENDS}
    ${VTK_DEPENDS}
    ${XIP_DEPENDS}
)

#-----------------------------------------------------------------------------
# Generate cmake variable name corresponding to Libs, Plugins and Applications
#
SET(ctk_libs_bool_vars)
FOREACH(lib ${CTK_LIBS_SUBDIRS})
  LIST(APPEND ctk_libs_bool_vars CTK_LIB_${lib})
ENDFOREACH()

SET(ctk_plugins_bool_vars)
FOREACH(plugin ${CTK_PLUGINS_SUBDIRS})
  LIST(APPEND ctk_plugins_bool_vars CTK_PLUGIN_${plugin})
ENDFOREACH()

SET(ctk_applications_bool_vars)
FOREACH(app ${CTK_APPLICATIONS_SUBDIRS})
  LIST(APPEND ctk_applications_bool_vars CTK_APP_${app})
ENDFOREACH()

#-----------------------------------------------------------------------------
# Convenient macro allowing to define superbuild arg
#
MACRO(ctk_set_superbuild_boolean_arg ctk_cmake_var)
  SET(superbuild_${ctk_cmake_var} ON)
  IF(DEFINED ${ctk_cmake_var} AND NOT ${ctk_cmake_var})
    SET(superbuild_${ctk_cmake_var} OFF)
  ENDIF()
ENDMACRO()

#-----------------------------------------------------------------------------
# Set superbuild boolean args
#

SET(ctk_cmake_boolean_args
  BUILD_TESTING
  CTK_USE_KWSTYLE
  ${ctk_libs_bool_vars}
  ${ctk_plugins_bool_vars}
  ${ctk_applications_bool_vars}
  )

SET(ctk_superbuild_boolean_args)
FOREACH(ctk_cmake_arg ${ctk_cmake_boolean_args})
  ctk_set_superbuild_boolean_arg(${ctk_cmake_arg})
  LIST(APPEND ctk_superbuild_boolean_args -D${ctk_cmake_arg}:BOOL=${superbuild_${ctk_cmake_arg}})
ENDFOREACH()

# MESSAGE("CMake args:")
# FOREACH(arg ${ctk_superbuild_boolean_args})
#   MESSAGE("  ${arg}")
# ENDFOREACH()

#-----------------------------------------------------------------------------
# CTK Configure
#
SET(proj CTK-Configure)

ExternalProject_Add(${proj}
  DOWNLOAD_COMMAND ""
  CMAKE_GENERATOR ${gen}
  CMAKE_ARGS
    ${ctk_superbuild_boolean_args}
    -DCTK_SUPERBUILD:BOOL=OFF
    -DWITH_COVERAGE:BOOL=${WITH_COVERAGE}
    -DCTEST_USE_LAUNCHERS:BOOL=${CTEST_USE_LAUNCHERS}
    -DCTK_SUPERBUILD_BINARY_DIR:PATH=${CTK_BINARY_DIR}
    -DCMAKE_INSTALL_PREFIX:PATH=${ep_install_dir}
    -DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE}
    -DCTK_CXX_FLAGS:STRING=${CTK_CXX_FLAGS}
    -DCTK_C_FLAGS:STRING=${CTK_C_FLAGS}
    -DQT_QMAKE_EXECUTABLE:FILEPATH=${QT_QMAKE_EXECUTABLE}
    -DCTK_KWSTYLE_EXECUTABLE:FILEPATH=${CTK_KWSTYLE_EXECUTABLE}
    -DDCMTK_DIR:PATH=${DCMTK_DIR} # FindDCMTK expects DCMTK_DIR
    -DVTK_DIR:PATH=${VTK_DIR}     # FindVTK expects VTK_DIR
    -DPYTHON_INCLUDE_DIR:PATH=${PYTHON_INCLUDE_DIR}    # FindPythonQt expects PYTHON_INCLUDE_DIR
    -DPYTHON_LIBRARY:FILEPATH=${PYTHON_LIBRARY}        # FindPythonQt expects PYTHON_LIBRARY
    -DPYTHONQT_INSTALL_DIR:PATH=${PYTHONQT_INSTALL_DIR} # FindPythonQt expects PYTHONQT_INSTALL_DIR
  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}
  BINARY_DIR ${CMAKE_BINARY_DIR}/CTK-build
  BUILD_COMMAND ""
  INSTALL_COMMAND ""
  DEPENDS
    "CTK-Utilities"
  )


#-----------------------------------------------------------------------------
# CTK
#
#MESSAGE(STATUS SUPERBUILD_EXCLUDE_CTKBUILD_TARGET:${SUPERBUILD_EXCLUDE_CTKBUILD_TARGET})
IF(NOT DEFINED SUPERBUILD_EXCLUDE_CTKBUILD_TARGET OR NOT SUPERBUILD_EXCLUDE_CTKBUILD_TARGET)
  SET(proj CTK-build)
  ExternalProject_Add(${proj}
    DOWNLOAD_COMMAND ""
    CMAKE_GENERATOR ${gen}
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}
    BINARY_DIR CTK-build
    INSTALL_COMMAND ""
    DEPENDS
      "CTK-Configure"
    )
ENDIF()

#-----------------------------------------------------------------------------
# Custom target allowing to drive the build of CTK project itself
#
ADD_CUSTOM_TARGET(CTK
  COMMAND ${CMAKE_COMMAND} --build ${CMAKE_CURRENT_BINARY_DIR}/CTK-build
  WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/CTK-build
  )
