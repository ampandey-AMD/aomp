#!/bin/bash
# 
#  build_project.sh:  Script to build the llvm, clang , and lld components of the AOMP compiler. 
#                  This clang 9.0 compiler supports clang hip, OpenMP, and clang cuda
#                  offloading languages for BOTH nvidia and Radeon accelerator cards.
#                  This compiler has both the NVPTX and AMDGPU LLVM backends.
#                  The AMDGPU LLVM backend is referred to as the Lightning Compiler.
#
# See the help text below, run 'build_project.sh -h' for more information. 
#
BUILD_TYPE=${BUILD_TYPE:-Release}

# --- Start standard header to set AOMP environment variables ----
realpath=`realpath $0`
thisdir=`dirname $realpath`
. $thisdir/aomp_common_vars
# --- end standard header ----

echo "LLVM PROJECTS TO BUILD:$AOMP_PROJECTS_LIST"
INSTALL_PROJECT=${INSTALL_PROJECT:-$LLVM_INSTALL_LOC}

WEBSITE="http\:\/\/github.com\/ROCm-Developer-Tools\/aomp"

# Check-openmp prep
# Patch rocr
ROCR_REPO_DIR=$AOMP_REPOS/$AOMP_ROCR_REPO_NAME
patchrepo $ROCR_REPO_DIR

# Patch llvm-project with ATD patch customized for amd-staging.
# WARNING: This patch (ATD_ASO_full.patch) rarely applies cleanly
#          because of its size and constant trunk merges to amd-staging.
#          This is why default is 0 (OFF).
REPO_DIR=$AOMP_REPOS/$AOMP_PROJECT_REPO_NAME
if [ "$AOMP_APPLY_ATD_AMD_STAGING_PATCH"  == 1 ] ; then
   patchrepo $REPO_DIR
fi

# End check-openmp prep

_qmathopt="-DFLANG_RUNTIME_F128_MATH_LIB=libquadmath"
if [ "$AOMP_PROC" == "ppc64le" ] ; then
   COMPILERS="-DCMAKE_C_COMPILER=/usr/bin/gcc-7 -DCMAKE_CXX_COMPILER=/usr/bin/g++-7"
   TARGETS_TO_BUILD="AMDGPU;${AOMP_NVPTX_TARGET}PowerPC"
else
   COMPILERS="-DCMAKE_C_COMPILER=$AOMP_CC_COMPILER -DCMAKE_CXX_COMPILER=$AOMP_CXX_COMPILER"
   if [ "$AOMP_PROC" == "aarch64" ] ; then
      TARGETS_TO_BUILD="AMDGPU;${AOMP_NVPTX_TARGET}AArch64"
      _qmathopt=""
   else
      TARGETS_TO_BUILD="AMDGPU;${AOMP_NVPTX_TARGET}X86"
   fi
fi

# When building from release source (no git), turn off test items that are not distributed
# also ubuntu 16.04 only has python 3.5 and lit testing needs 3.6 minimum, so turn off
# testing with ubuntu 16.04 which goes EOL in April 2021.
PN=$(cat /etc/os-release | grep "^PRETTY_NAME=" | cut -d= -f2)
DO_TESTS=${DO_TESTS:-"-DLLVM_BUILD_TESTS=ON -DLLVM_INCLUDE_TESTS=ON -DCLANG_INCLUDE_TESTS=ON"}
#-DCOMPILER_RT_INCLUDE_TESTS=OFF"

if [ $AOMP_STANDALONE_BUILD == 1 ] ; then
   standalone_word="_STANDALONE"
else
   standalone_word=""
fi

if [ "$AOMP_USE_NINJA" == 0 ] ; then
    AOMP_SET_NINJA_GEN=""
else
    AOMP_SET_NINJA_GEN="-G Ninja"
fi

if [ "$AOMP_LEGACY_OPENMP" != 0 ]; then
  LLVM_RUNTIMES="libcxx;libcxxabi;libunwind;compiler-rt"
else
  LLVM_RUNTIMES="libcxx;libcxxabi;libunwind;openmp;offload;compiler-rt"
fi

rocmdevicelib_loc_new=lib/llvm/lib/clang/$AOMP_MAJOR_VERSION/lib/amdgcn

GFXSEMICOLONS=`echo $GFXLIST | tr ' ' ';' `
MYCMAKEOPTS="-DCMAKE_BUILD_TYPE=$BUILD_TYPE
 -DCMAKE_INSTALL_PREFIX=$INSTALL_PROJECT
 -DLLVM_ENABLE_ASSERTIONS=ON
 -DLLVM_TARGETS_TO_BUILD=$TARGETS_TO_BUILD
 $COMPILERS
 -DLLVM_VERSION_SUFFIX=_AOMP${standalone_word}_$AOMP_VERSION_STRING
 -DCLANG_VENDOR=AOMP${standalone_word}_$AOMP_VERSION_STRING
 -DCLANG_DEFAULT_PIE_ON_LINUX=0
 -DBUG_REPORT_URL='https://github.com/ROCm-Developer-Tools/aomp'
 -DLLVM_ENABLE_BINDINGS=OFF
 -DLLVM_INCLUDE_BENCHMARKS=OFF
 $DO_TESTS $AOMP_ORIGIN_RPATH
 -DCLANG_DEFAULT_LINKER=lld
 $AOMP_SET_NINJA_GEN
 $_qmathopt
 -DLIBOMPTARGET_BUILD_DEVICE_FORTRT=ON
 -DLLVM_BUILD_LLVM_DYLIB=ON
 -DLLVM_LINK_LLVM_DYLIB=ON
 -DCLANG_LINK_CLANG_DYLIB=ON
 -DLIBOMPTARGET_EXTERNAL_PROJECT_HSA_PATH=$AOMP_REPOS/$AOMP_ROCR_REPO_NAME
 -DOFFLOAD_EXTERNAL_PROJECT_UNIFIED_ROCR=On
 -DLIBOMPTARGET_EXTERNAL_PROJECT_ROCM_DEVICE_LIBS_PATH=$AOMP_REPOS/$AOMP_PROJECT_REPO_NAME/amd/device-libs
 -DLLVM_EXTERNAL_PROJECTS=SPIRV_TRANSLATOR
 -DLLVM_EXTERNAL_SPIRV_TRANSLATOR_SOURCE_DIR=$AOMP_REPOS/SPIRV-LLVM-Translator
 -DROCM_DEVICE_LIBS_INSTALL_PREFIX_PATH=$AOMP_INSTALL_DIR
 -DROCM_DEVICE_LIBS_BITCODE_INSTALL_LOC=$rocmdevicelib_loc_new
 -DROCM_LLVM_BACKWARD_COMPAT_LINK="$AOMP_INSTALL_DIR/llvm"
 -DROCM_LLVM_BACKWARD_COMPAT_LINK_TARGET="./lib/llvm"
 -DLIBOMP_COPY_EXPORTS=OFF
 -DLIBOMPTARGET_ENABLE_DEBUG=ON
 -DLIBOMPTARGET_AMDGCN_GFXLIST=$GFXSEMICOLONS
 -DLIBOMP_USE_HWLOC=ON -DLIBOMP_HWLOC_INSTALL_DIR=$AOMP_SUPP/hwloc
 -DOPENMP_ENABLE_LIBOMPTARGET=1
 -DLIBOMP_SHARED_LINKER_FLAGS=-Wl,--disable-new-dtags
 -DLIBOMP_INSTALL_RPATH=$AOMP_ORIGIN_RPATH_LIST
 -DLIBOMPTARGET_INSTALL_RPATH=$AOMP_ORIGIN_RPATH_LIST
 -DLIBOMPTARGET_NO_SANITIZER_AMDGPU=1"
 
# -DCLANG_LINK_FLANG_LEGACY=ON

# Enable amdflang, amdclang, amdclang++, amdllvm.
# clang-tools-extra added to LLVM_ENABLE_PROJECTS above.
MYCMAKEOPTS="$MYCMAKEOPTS
$AOMP_CCACHE_OPTS
-DLLVM_ENABLE_PROJECTS='$AOMP_PROJECTS_LIST'
-DCLANG_ENABLE_AMDCLANG=ON
-DLLVM_ENABLE_RUNTIMES=$LLVM_RUNTIMES
-DLIBCXX_ENABLE_STATIC=ON
-DLIBCXXABI_ENABLE_STATIC=ON
"

# Enable Compiler-rt Sanitizer Build
if [ "$AOMP_BUILD_SANITIZER" == 1 ]; then
    MYCMAKEOPTS="$MYCMAKEOPTS -DSANITIZER_AMDGPU=1 -DSANITIZER_HSA_INCLUDE_PATH=$AOMP_REPOS/$AOMP_ROCR_REPO_NAME/runtime/hsa-runtime/inc -DSANITIZER_COMGR_INCLUDE_PATH=$AOMP_REPOS/$AOMP_PROJECT_REPO_NAME/amd/comgr/include"
fi

if [ "$1" == "-h" ] || [ "$1" == "help" ] || [ "$1" == "-help" ] ; then 
  help_build_aomp
fi

if [ $AOMP_STANDALONE_BUILD == 1 ] ; then 
   if [ ! -L $AOMP ] ; then 
     if [ -d $AOMP ] ; then 
        echo "ERROR: Directory $AOMP is a physical directory."
        echo "       It must be a symbolic link or not exist"
        exit 1
     fi
   fi
fi

# Make sure we can update the install directory
if [ "$1" == "install" ] ; then
   $SUDO mkdir -p $INSTALL_PROJECT
   $SUDO touch $INSTALL_PROJECT/testfile
   if [ $? != 0 ] ; then 
      echo "ERROR: No update access to $INSTALL_PROJECT"
      exit 1
   fi
   $SUDO rm $INSTALL_PROJECT/testfile
fi

# Fix the banner to print the AOMP version string. 
if [ $AOMP_STANDALONE_BUILD == 1 ] ; then
   cd $AOMP_REPOS/$AOMP_PROJECT_REPO_NAME
   MONO_REPO_ID=`git log | grep -m1 commit | cut -d" " -f2`
   SOURCEID="Source ID:$AOMP_VERSION_STRING-$MONO_REPO_ID"
   TEMPCLFILE="/tmp/clfile$$.cpp"
   ORIGCLFILE="$AOMP_REPOS/$AOMP_PROJECT_REPO_NAME/llvm/lib/Support/CommandLine.cpp"
   BUILDCLFILE=$ORIGCLFILE

   sed "s/LLVM (http:\/\/llvm\.org\/):/AOMP-${AOMP_VERSION_STRING} ($WEBSITE):\\\n $SOURCEID/" $ORIGCLFILE > $TEMPCLFILE
   if [ $? != 0 ] ; then
      echo "ERROR sed command to fix CommandLine.cpp failed."
      exit 1
   fi
fi

# Skip synchronization from git repos if nocmake or install are specified
if [ "$1" != "nocmake" ] && [ "$1" != "install" ] ; then
   echo 
   echo "This is a FRESH START. ERASING any previous builds in $BUILD_DIR/build/$AOMP_PROJECT_REPO_NAME"
   echo "Use ""$0 nocmake"" or ""$0 install"" to avoid FRESH START."
   rm -rf $BUILD_DIR/build/$AOMP_PROJECT_REPO_NAME
   mkdir -p $BUILD_DIR/build/$AOMP_PROJECT_REPO_NAME
else
   if [ ! -d $BUILD_DIR/build/$AOMP_PROJECT_REPO_NAME ] ; then 
      echo "ERROR: The build directory $BUILD_DIR/build/$AOMP_PROJECT_REPO_NAME does not exist"
      echo "       run $0 without nocmake or install options. "
      exit 1
   fi
fi

if [ $AOMP_STANDALONE_BUILD == 1 ] ; then
   cd $BUILD_DIR/build/$AOMP_PROJECT_REPO_NAME
   if [ -f $BUILDCLFILE ] ; then
      # only copy if there has been a change to the source.
      diff $TEMPCLFILE $BUILDCLFILE >/dev/null
      if [ $? != 0 ] ; then
         echo "Updating $BUILDCLFILE with corrected $SOURCEID"
         cp $TEMPCLFILE $BUILDCLFILE
      else
         echo "File $BUILDCLFILE already has correct $SOURCEID"
      fi
   else
      echo "Updating $BUILDCLFILE with $SOURCEID"
      cp $TEMPCLFILE $BUILDCLFILE
   fi
   rm $TEMPCLFILE
fi

cd $BUILD_DIR/build/$AOMP_PROJECT_REPO_NAME

if [ "$1" != "nocmake" ] && [ "$1" != "install" ] ; then
   echo
   echo " -----Running cmake ---- " 
   echo ${AOMP_CMAKE} $MYCMAKEOPTS  $AOMP_REPOS/$AOMP_PROJECT_REPO_NAME/llvm
   ${AOMP_CMAKE} $MYCMAKEOPTS $AOMP_REPOS/$AOMP_PROJECT_REPO_NAME/llvm 2>&1
   if [ $? != 0 ] ; then 
      echo "ERROR cmake failed. Cmake flags"
      echo "      $MYCMAKEOPTS"
      exit 1
   fi
fi

if [ "$1" = "cmake" ]; then
   exit 0
fi

echo
echo " -----Running make ---- " 

if [ "$AOMP_LIMIT_FLANG" == "1" ] ; then
   # Required for building flang-new on memory limited systems.
   echo ${AOMP_CMAKE} --build . -- -j $AOMP_JOB_THREADS clang lld compiler-rt
   ${AOMP_CMAKE} --build . -- -j $AOMP_JOB_THREADS clang lld compiler-rt

   echo ${AOMP_CMAKE} --build . -- -j $AOMP_FLANG_THREADS flang-new
   ${AOMP_CMAKE} --build . -- -j $AOMP_FLANG_THREADS flang-new
fi

# Build llvm-project in one step
echo "Running CMAKE in ${PWD}"
echo ${AOMP_CMAKE} --build . -j $AOMP_JOB_THREADS
${AOMP_CMAKE} --build . -j $AOMP_JOB_THREADS

if [ $? != 0 ] ; then
   echo "ERROR make -j $AOMP_JOB_THREADS failed"
   exit 1
fi

if [ "$1" == "install" ] ; then
   echo " -----Installing to $INSTALL_PROJECT ---- "
   $SUDO ${AOMP_CMAKE} --install .
   if [ $? != 0 ] ; then
      echo "ERROR make install failed "
      exit 1
   fi
   if [ $AOMP_STANDALONE_BUILD == 1 ] ; then 
      echo " "
      echo "------ Linking $INSTALL_PROJECT to $AOMP -------"
      if [ -L $AOMP ] ; then 
         $SUDO rm $AOMP   
      fi
      $SUDO ln -sf $AOMP_INSTALL_DIR $AOMP

   fi

   # add executables forgot by make install but needed for testing
   $SUDO cp -p $BUILD_DIR/build/$AOMP_PROJECT_REPO_NAME/bin/llvm-lit $LLVM_INSTALL_LOC/bin/llvm-lit
   # update map_config and llvm_source_root paths in the copied llvm-lit file
   SED_AOMP_REPOS=`echo $AOMP_REPOS | sed -e 's/\//\\\\\//g' `
   sed -ie "s/..\/..\/..\//$SED_AOMP_REPOS\//g" $LLVM_INSTALL_LOC/bin/llvm-lit

   $SUDO cp -p $BUILD_DIR/build/$AOMP_PROJECT_REPO_NAME/bin/FileCheck $LLVM_INSTALL_LOC/bin/FileCheck
   $SUDO cp -p $BUILD_DIR/build/$AOMP_PROJECT_REPO_NAME/bin/count $LLVM_INSTALL_LOC/bin/count
   $SUDO cp -p $BUILD_DIR/build/$AOMP_PROJECT_REPO_NAME/bin/not $LLVM_INSTALL_LOC/bin/not
   $SUDO cp -p $BUILD_DIR/build/$AOMP_PROJECT_REPO_NAME/bin/yaml-bench $LLVM_INSTALL_LOC/bin/yaml-bench
   cd $AOMP_REPOS/$AOMP_PROJECT_REPO_NAME
   git checkout llvm/lib/Support/CommandLine.cpp
   echo
   echo "SUCCESSFUL INSTALL to $INSTALL_PROJECT with link to $AOMP"
   echo
   if [ "$AOMP_APPLY_ATD_AMD_STAGING_PATCH"  == 1 ] ; then
      removepatch $REPO_DIR
   fi
   removepatch $ROCR_REPO_DIR
   amd_compiler_symlinks=("amdclang" "amdclang++" "amdclang-cl" "amdclang-cpp" "amdflang" "amdlld")
   if [ "$AOMP_SKIP_FLANG_NEW" == 1 ]; then
     amd_compiler_cfg=("clang" "clang++" "clang-cpp" "clang-${AOMP_MAJOR_VERSION}" "clang-cl" "flang")
     if [ -h $LLVM_INSTALL_LOC/bin/amdflang-new ]; then
       rm -f $LLVM_INSTALL_LOC/bin/amdflang-new
     fi
   else
     amd_compiler_cfg=("clang" "clang++" "clang-cpp" "clang-${AOMP_MAJOR_VERSION}" "clang-cl" "flang" "flang-new")
     # amdflang-new -> amdllvm symlink
     if [ ! -h "$LLVM_INSTALL_LOC/bin/amdflang-new" ] && [ -e "$LLVM_INSTALL_LOC/bin/flang-new" ]; then
       ln -s amdllvm ${LLVM_INSTALL_LOC}/bin/amdflang-new
     fi
   fi

   # Leaving this in just in case we decide to add the amd* symlinks in the top level bin directory.
   #for i in "${amd_compiler_symlinks[@]}"; do
   #   if [ -f "$LLVM_INSTALL_LOC/bin/$i" ] && [ ! -h $AOMP_INSTALL_DIR/bin/$i ]; then
   #      echo "Creating $i symlink: ${AOMP_INSTALL_DIR}/bin/$i -> ${LLVM_INSTALL_LOC}/bin/$i"
   #      cd ${AOMP_INSTALL_DIR}
   #      mkdir -p bin
   #      ln -s ../lib/llvm/bin/$i ${AOMP_INSTALL_DIR}/bin/$i
   #   fi
   #done
   # rocm.cfg content
   {
      echo "--rocm-path='<CFGDIR>/../../..'"
      echo "-frtlib-add-rpath"
    } > "${LLVM_INSTALL_LOC}/bin/rocm.cfg"

   for i in "${amd_compiler_cfg[@]}"; do
      if [ -f "${LLVM_INSTALL_LOC}/bin/$i" ]; then
         echo "Creating config file: ${i}.cfg in ${LLVM_INSTALL_LOC}/bin"
         config_file="${LLVM_INSTALL_LOC}/bin/${i}.cfg"
         {
            echo "@rocm.cfg"
         } > "$config_file"
         #cp ${LLVM_INSTALL_LOC}/bin/rocm.cfg $config_file
      fi
   done
else 
   echo 
   echo "SUCCESSFUL BUILD, please run:  $0 install"
   echo "  to install into $AOMP"
   echo 
fi
