#!/bin/bash

# --- Start standard header to set AOMP environment variables ----
realpath=`realpath $0`
thisdir=`dirname $realpath`
. $thisdir/aomp_common_vars
# --- end standard header ----

export AOMP=${AOMP:-/usr/lib/aomp}
export MPI_PATH=${HOME}/local/openmpi

export UMT_PATH=${HOME}/git/aomp-test/UMT
export UMT_INSTALL_PATH=${UMT_PATH}/umt_workspace/install

export LD_LIBRARY_PATH=${AOMP}/lib:${MPI_PATH}/lib:${LD_LIBRARY_PATH}

CC=${AOMP}/bin/clang
CXX=${AOMP}/bin/clang++
FC=${AOMP}/bin/flang

export PATH=${AOMP}/bin:${MPI_PATH}/bin:${PATH}

#Queried by patchrepo
export OMP_APPLY_ROCM_PATCHES=1

function usage(){
  echo ""
  echo "------------ Usage ---------------------"
  echo "./run_umt.sh [option]"
  echo "Options: build_umt, run_umt"
  echo "---------------------------------------"
  echo ""
}

# Build UMT
if [ "$1" == "build_umt" ]; then

    if [ ! -d "${UMT_PATH}" ]; then
        echo "*************************************************************************************"
        echo "UMT not found. Expecting the sources in ${UMT_PATH}". Call script with clone_umt first.
        echo "*************************************************************************************"
        exit 0;
    fi

    pushd ${UMT_PATH}
    mkdir -p ${UMT_INSTALL_PATH}
    pushd ${UMT_PATH}/umt_workspace

    git clone --recurse-submodules  https://github.com/LLNL/conduit.git conduit -b v0.9.0
    mkdir build_conduit
    pushd build_conduit
    cmake ${PWD}/../conduit/src -DCMAKE_INSTALL_PREFIX=${UMT_INSTALL_PATH} \
                                -DCMAKE_C_COMPILER=${CC} \
                                -DCMAKE_CXX_COMPILER=${CXX} \
                                -DCMAKE_Fortran_COMPILER=${FC} \
                                -DMPI_CXX_COMPILER=mpicxx \
                                -DMPI_Fortran_COMPILER=mpifort \
                                -DBUILD_SHARED_LIBS=OFF \
                                -DENABLE_TESTS=OFF \
                                -DENABLE_EXAMPLES=OFF \
                                -DENABLE_DOCS=OFF \
                                -DENABLE_FORTRAN=ON \
                                -DENABLE_MPI=ON \
                                -DENABLE_PYTHON=OFF
    make -j install
    popd

    # apply patch
    git reset --hard 30b0175228af4c5eb084c3e219db6a7cd3f27ead
    patchrepo $AOMP_REPOS_TEST/UMT

    # Build UMT
    mkdir build_umt
    pushd build_umt

    # Run CMake on UMT, compile, and install.
    cmake ${UMT_PATH}/src \
            -DCMAKE_BUILD_TYPE=Release \
    		-DSTRICT_FPP_MODE=YES \
            -DENABLE_OPENMP=YES \
    		-DENABLE_OPENMP_OFFLOAD=Yes \
            -DOPENMP_HAS_USE_DEVICE_ADDR=Yes \
    		-DOPENMP_HAS_FORTRAN_INTERFACE=NO \
            -DCMAKE_CXX_COMPILER=${CXX} \
    		-DCMAKE_Fortran_COMPILER=${FC} \
            -DMPI_CXX_COMPILER=${MPI_PATH}/bin/mpicxx \
            -DMPI_Fortran_COMPILER=${MPI_PATH}/bin/mpifort \
            -DCMAKE_INSTALL_PREFIX=${UMT_INSTALL_PATH} \
            -DCONDUIT_ROOT=${UMT_INSTALL_PATH} $1
    make -j install

    # undo patch
    removepatch ${AOMP_REPOS_TEST}/UMT
    popd

popd
exit 1
fi

# Run UMT
if [ "$1" == "run_umt" ]; then
    ${UMT_INSTALL_PATH}/bin/test_driver -c 10 -B local -d 8,8,0 --benchmark_problem 2
    ${UMT_INSTALL_PATH}/bin/test_driver -c 10 -B local -d 4,4,4 --benchmark_problem 2
    exit 1
fi

usage