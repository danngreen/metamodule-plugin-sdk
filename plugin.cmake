set(CMAKE_TOOLCHAIN_FILE ${CMAKE_CURRENT_LIST_DIR}/cmake/arm-none-eabi-gcc.cmake)
project(MetaModulePluginSDK LANGUAGES C CXX ASM)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_BUILD_TYPE "RelWithDebInfo")
include(${CMAKE_CURRENT_LIST_DIR}/cmake/ccache.cmake)

# Whether to compile with static libc and libm
set(METAMODULE_PLUGIN_STATIC_LIBC 0)

# Set the chip architecture
include(${CMAKE_CURRENT_LIST_DIR}/cmake/arch_mp15xa7.cmake)
link_libraries(arch_mp15x_a7)

# Add plugin SDK
add_subdirectory(${CMAKE_CURRENT_LIST_DIR} ${CMAKE_CURRENT_BINARY_DIR}/plugin-sdk)

# Function to create a ready to use plugin from a static library
function(create_plugin)

    ################

    set(oneValueArgs SOURCE_LIB SOURCE_ASSETS DESTINATION PLUGIN_NAME)
    cmake_parse_arguments(PLUGIN_OPTIONS "" "${oneValueArgs}" "" ${ARGN} )

    # TODO: Add more checking and validation for arguments

    set(LIB_NAME ${PLUGIN_OPTIONS_SOURCE_LIB})

    if (DEFINED PLUGIN_OPTIONS_PLUGIN_NAME)
        set(PLUGIN_NAME ${PLUGIN_OPTIONS_PLUGIN_NAME})
    else()
        set(PLUGIN_NAME ${LIB_NAME})
    endif()

    set(PLUGIN_FILE_FULL ${PLUGIN_NAME}-debug.so)
    cmake_path(APPEND PLUGIN_FILE ${PLUGIN_OPTIONS_DESTINATION} ${PLUGIN_NAME}.so)

    file(MAKE_DIRECTORY ${PLUGIN_OPTIONS_DESTINATION})

    if (PLUGIN_OPTIONS_SOURCE_ASSETS)
        file(COPY ${PLUGIN_OPTIONS_SOURCE_ASSETS}/ DESTINATION ${PLUGIN_OPTIONS_DESTINATION})
    endif()

    ###############

	target_link_libraries(${LIB_NAME} PRIVATE metamodule-sdk)

	set(LFLAGS
        -shared
        -Wl,-Map,plugin.map,--cref
        -Wl,--gc-sections
        -nostartfiles 
        -nostdlib
        ${ARCH_MP15x_A7_FLAGS}
    )

    if (METAMODULE_PLUGIN_STATIC_LIBC)
        set(LINK_LIBS_DIR ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/metamodule-plugin-libc/lib)
        find_library(LIBCLIB "pluginc" PATHS ${LINK_LIBS_DIR} REQUIRED)
        find_library(LIBMLIB "pluginm" PATHS ${LINK_LIBS_DIR} REQUIRED)
        set(LINK_STATIC_LIBC
            -lpluginc
            -lpluginm
        )
    endif()

    get_target_property(LIBC_BIN_DIR metamodule-plugin-libc BINARY_DIR)
    find_library(LIBC_BIN_DIR "metamodule-plugin-libc" PATHS ${LIBC_BIN_DIR} REQUIRED)

    get_target_property(LIBCPP_BIN_DIR libstdcpp98 BINARY_DIR)
    find_library(LIBCPP_BIN_DIR "libstdcpp98" PATHS ${LIBCPP_BIN_DIR} REQUIRED)

	# Link objects into a shared library (CMake won't do it for us)
    add_custom_command(
		OUTPUT ${PLUGIN_FILE_FULL}
		DEPENDS ${LIB_NAME} libstdcpp98 libstdcpp11 libstdcpp17 libstdcpp20 metamodule-plugin-libc
		COMMAND ${CMAKE_CXX_COMPILER} ${LFLAGS} -o ${PLUGIN_FILE_FULL}
				$<TARGET_OBJECTS:${LIB_NAME}>  #FIXME: libraries linked to LIB_NAME target will not be included
                -u__dso_handle
                -L${LIBC_BIN_DIR} 
                -L${LIBCPP_BIN_DIR} 
                -Ur
                -llibstdcpp20
                -llibstdcpp17
                -llibstdcpp11
                -llibstdcpp98
                #repeat this because it defines sso and cow shim, which libstdcpp98 needs
                -llibstdcpp11 

                -lmetamodule-plugin-libc
                -lgcc
 -Wl,--trace-symbol,_ZNSt10moneypunctIcLb1EED2Ev
 -Wl,--trace-symbol,_ZNSt10moneypunctIwLb0EED2Ev
 -Wl,--trace-symbol,_ZNSt10moneypunctIcLb0EED0Ev
 -Wl,--trace-symbol,_ZNSt12__basic_fileIcE2fdEv
 -Wl,--trace-symbol,_ZNSt8numpunctIcED2Ev
 -Wl,--trace-symbol,_ZNSt12__basic_fileIcE5closeEv
 -Wl,--trace-symbol,_ZNSt8numpunctIwED0Ev
 -Wl,--trace-symbol,_ZNKSt12__basic_fileIcE7is_openEv
 -Wl,--trace-symbol,_ZNSt12__basic_fileIcE8sys_openEiSt13_Ios_Openmode
 -Wl,--trace-symbol,_ZNSt10moneypunctIwLb0EED0Ev
 -Wl,--trace-symbol,_ZNSt8numpunctIwED2Ev
 -Wl,--trace-symbol,_ZNSt12__basic_fileIcE4fileEv
 -Wl,--trace-symbol,_ZNSt10moneypunctIwLb1EE24_M_initialize_moneypunctEPiPKc
 -Wl,--trace-symbol,_ZNSt12__basic_fileIcE4fileEv
 -Wl,--trace-symbol,_ZNSt10moneypunctIwLb1EE24_M_initialize_moneypunctEPiPKc
 -Wl,--trace-symbol,_ZNSt10moneypunctIwLb0EE24_M_initialize_moneypunctEPiPKc
 -Wl,--trace-symbol,__cxa_bad_cast
 -Wl,--trace-symbol,_ZNSt12__basic_fileIcE8xsputn_2EPKciS2_i
 -Wl,--trace-symbol,_ZNSt8numpunctIcED1Ev
 -Wl,--trace-symbol,_ZNSt10moneypunctIcLb0EED2Ev
 -Wl,--trace-symbol,_ZNSt12__basic_fileIcE4openEPKcSt13_Ios_Openmodei
 -Wl,--trace-symbol,_ZNSt8numpunctIwE22_M_initialize_numpunctEPi
 -Wl,--trace-symbol,_jp2uc_l
 -Wl,--trace-symbol,_ZNKSt7__cxx117collateIwE12_M_transformEPwPKwj
 -Wl,--trace-symbol,_ZNSt10moneypunctIwLb1EED2Ev
 -Wl,--trace-symbol,_ZNSt12__basic_fileIcE8sys_openEP7__sFILESt13_Ios_Openmode
 -Wl,--trace-symbol,_ZNKSt7collateIcE12_M_transformEPcPKcj
 -Wl,--trace-symbol,_ZNSt12__basic_fileIcEC1EPi
 -Wl,--trace-symbol,_ZNKSt7collateIwE12_M_transformEPwPKwj
 -Wl,--trace-symbol,_ZNSt10moneypunctIwLb1EED0Ev
 -Wl,--trace-symbol,_ZNKSt7__cxx118messagesIwE6do_getEiiiRKNS_12basic_stringIwSt11char_traitsIwESaIwEEE
 -Wl,--trace-symbol,_ZNSt10moneypunctIwLb1EED1Ev
 -Wl,--trace-symbol,_ZNKSt7collateIcE10_M_compareEPKcS2_
 -Wl,--trace-symbol,_ZNSt10moneypunctIwLb0EED1Ev
 -Wl,--trace-symbol,_ZNSt10moneypunctIcLb1EE24_M_initialize_moneypunctEPiPKc
-Wl,--trace-symbol,_uc2jp_l
-Wl,--trace-symbol,_ZNKSt8messagesIcE6do_getEiiiRKSs
-Wl,--trace-symbol,_ZSt18uncaught_exceptionv
-Wl,--trace-symbol,_ZNSt10moneypunctIcLb0EE24_M_initialize_moneypunctEPiPKc
-Wl,--trace-symbol,_ZNKSt7__cxx117collateIwE10_M_compareEPKwS3_
-Wl,--trace-symbol,_ZNSt10moneypunctIcLb1EED1Ev
-Wl,--trace-symbol,_ZSt17__verify_groupingPKcjRKNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEE
-Wl,--trace-symbol,_ZNKSt7__cxx117collateIcE12_M_transformEPcPKcj
-Wl,--trace-symbol,_ZNSt8numpunctIwED1Ev
-Wl,--trace-symbol,_ZNSt8numpunctIcE22_M_initialize_numpunctEPi
-Wl,--trace-symbol,_ZNKSt7collateIwE10_M_compareEPKwS2_
-Wl,--trace-symbol,_ZNSt12__basic_fileIcE7seekoffExSt12_Ios_Seekdir
-Wl,--trace-symbol,_ZNSt10moneypunctIcLb0EED1Ev
-Wl,--trace-symbol,_ZNKSt7__cxx118messagesIcE6do_getEiiiRKNS_12basic_stringIcSt11char_traitsIcESaIcEEE
-Wl,--trace-symbol,_ZNKSt7__cxx117collateIcE10_M_compareEPKcS3_
-Wl,--trace-symbol,_ZNKSt8messagesIwE6do_getEiiiRKSbIwSt11char_traitsIwESaIwEE
-Wl,--trace-symbol,_ZNSt10moneypunctIcLb1EED0Ev
-Wl,--trace-symbol,_ZNSt8numpunctIcED0Ev
-Wl,--trace-symbol,_ZNSt12__basic_fileIcE6xsgetnEPci
-Wl,--trace-symbol,_ZNSt12__basic_fileIcE9showmanycEv
-Wl,--trace-symbol,_ZNSt12__basic_fileIcED1Ev
-Wl,--trace-symbol,_ZNSt12__basic_fileIcE6xsputnEPKci
# -Wl,--trace-symbol,_ZNKSt7collateIwE10_M_compareEPKwS2_
# -Wl,--trace-symbol,_ZNSt10moneypunctIwLb1EED0Ev
# -Wl,--trace-symbol,_ZNSt10moneypunctIcLb0EED1Ev
# -Wl,--trace-symbol,_ZNKSt7collateIcE12_M_transformEPcPKcj
# -Wl,--trace-symbol,_ZNKSt7collateIwE12_M_transformEPwPKwj
# -Wl,--trace-symbol,_ZNSt10moneypunctIcLb0EE24_M_initialize_moneypunctEPiPKc
# -Wl,--trace-symbol,_jp2uc_l
# -Wl,--trace-symbol,_ZSt18uncaught_exceptionv
# -Wl,--trace-symbol,_ZNSt10moneypunctIwLb0EE24_M_initialize_moneypunctEPiPKc
# -Wl,--trace-symbol,_ZNSt10moneypunctIcLb0EED0Ev
# -Wl,--trace-symbol,_ZNSt10moneypunctIwLb0EED0Ev
# -Wl,--trace-symbol,_ZNSt8numpunctIwE22_M_initialize_numpunctEPi
# -Wl,--trace-symbol,_ZNSt8numpunctIcE22_M_initialize_numpunctEPi
# -Wl,--trace-symbol,_ZNSt10moneypunctIcLb1EED2Ev
# -Wl,--trace-symbol,_ZNSt13basic_istreamIwSt11char_traitsIwEE6ignoreEi
# -Wl,--trace-symbol,__cxa_bad_cast
# -Wl,--trace-symbol,_ZNSt10moneypunctIwLb0EED1Ev
# -Wl,--trace-symbol,_ZNSt8numpunctIwED1Ev
# -Wl,--trace-symbol,_ZNKSt7collateIcE10_M_compareEPKcS2_
# -Wl,--trace-symbol,_ZNSt8numpunctIcED0Ev
# -Wl,--trace-symbol,_ZNSt8numpunctIcED2Ev
# -Wl,--trace-symbol,_uc2jp_l
# -Wl,--trace-symbol,_ZNKSt8messagesIcE6do_getEiiiRKSs
# -Wl,--trace-symbol,_ZNSt8numpunctIcED1Ev
# -Wl,--trace-symbol,_ZNSt10moneypunctIwLb1EE24_M_initialize_moneypunctEPiPKc
# -Wl,--trace-symbol,_ZNSt10moneypunctIcLb1EED0Ev
# -Wl,--trace-symbol,_ZNSt8numpunctIwED2Ev
# -Wl,--trace-symbol,_ZNSt10moneypunctIcLb1EED1Ev
# -Wl,--trace-symbol,_ZNSt10moneypunctIcLb1EE24_M_initialize_moneypunctEPiPKc
# -Wl,--trace-symbol,_ZNSt10moneypunctIcLb0EED2Ev
# -Wl,--trace-symbol,_ZNKSt8messagesIwE6do_getEiiiRKSbIwSt11char_traitsIwESaIwEE
# -Wl,--trace-symbol,_ZNSt10moneypunctIwLb1EED1Ev
# -Wl,--trace-symbol,_ZNSt8numpunctIwED0Ev
# -Wl,--trace-symbol,_ZNSt10moneypunctIwLb1EED2Ev
# -Wl,--trace-symbol,_ZNSt10moneypunctIwLb0EED2Ev


		COMMAND_EXPAND_LISTS
		VERBATIM USES_TERMINAL
    )

	# Strip symbols to create a smaller plugin file
    add_custom_command(
        OUTPUT ${PLUGIN_FILE}
        DEPENDS ${PLUGIN_FILE_FULL}
        COMMAND ${CMAKE_STRIP} -g -v -o ${PLUGIN_FILE} ${PLUGIN_FILE_FULL}
		COMMAND ${CMAKE_SIZE_UTIL} ${PLUGIN_FILE}
        VERBATIM USES_TERMINAL
    )
    add_custom_target(plugin ALL DEPENDS ${PLUGIN_FILE})

    # Verify symbols will be resolved
    set(FIRMWARE_SYMTAB_PATH ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/api-symbols.txt)
    add_custom_command(
        TARGET plugin
        POST_BUILD
        COMMAND scripts/check_syms.py 
            --plugin ${PLUGIN_FILE}
            --api ${FIRMWARE_SYMTAB_PATH}
            # -v
        WORKING_DIRECTORY ${CMAKE_CURRENT_FUNCTION_LIST_DIR}
        VERBATIM USES_TERMINAL
    )

    # Helpful outputs for debugging plugin elf file:
    add_custom_command(
        OUTPUT ${PLUGIN_FILE_FULL}.nm
        DEPENDS ${PLUGIN_FILE_FULL}
        COMMAND ${CMAKE_NM} -CA ${PLUGIN_FILE_FULL} > ${PLUGIN_FILE_FULL}.nm
    )
    add_custom_command(
        OUTPUT ${PLUGIN_FILE_FULL}.readelf
        DEPENDS ${PLUGIN_FILE_FULL}
        COMMAND ${CMAKE_READELF} --demangle=auto -a -W ${PLUGIN_FILE_FULL} > ${PLUGIN_FILE_FULL}.readelf
    )
    add_custom_target(debugelf ALL DEPENDS 
        ${PLUGIN_FILE_FULL}.readelf
        ${PLUGIN_FILE_FULL}.nm
    )

    # Dissassembly can be take a long time/space, so don't always run:
    add_custom_command(
        OUTPUT ${PLUGIN_FILE_FULL}.diss
        DEPENDS ${PLUGIN_FILE_FULL}
        COMMAND ${CMAKE_OBJDUMP} -CDz --source ${PLUGIN_FILE_FULL} > ${PLUGIN_FILE_FULL}.diss
    )
    add_custom_target(debugdiss DEPENDS 
        ${PLUGIN_FILE_FULL}.diss
    )

	# TODO: ?? target to convert a dir of SVGs to PNGs?

endfunction()

