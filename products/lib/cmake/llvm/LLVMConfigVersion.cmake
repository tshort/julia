set(PACKAGE_VERSION "6.0.1")

# LLVM is API-compatible only with matching major.minor versions
# and patch versions not less than that requested.
if("6.0" VERSION_EQUAL
    "${PACKAGE_FIND_VERSION_MAJOR}.${PACKAGE_FIND_VERSION_MINOR}"
   AND NOT "1" VERSION_LESS "${PACKAGE_FIND_VERSION_PATCH}")
  set(PACKAGE_VERSION_COMPATIBLE 1)
  if("1" VERSION_EQUAL
      "${PACKAGE_FIND_VERSION_PATCH}")
    set(PACKAGE_VERSION_EXACT 1)
  endif()
endif()
