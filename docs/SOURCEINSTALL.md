# Source Install V 21.0-0

Build and install from sources is possible.  However, the source build for AOMP is complex for several reasons.
- Many repos are required.
- Requires that Cuda SDK 10/11 is installed for NVIDIA GPUs. ROCm does not need to be installed for AOMP.
- It is a bootstrapped build. The built and installed LLVM compiler is used to build library components.
- Additional package dependencies are required that are not required when installing the AOMP package.

## Source Build Prerequisites

To build and test AOMP from source you must:
```
1. Install certain distribution packages,
2. Build CMake 3.25.2 from source. This can be done with ./build_prereq.sh,
3. Ensure the KFD kernel module is installed and operating,
4. Create the Unix video group, and
5. Install spack if required.
```
[This link](SOURCEINSTALL_PREREQUISITE.md) provides detailed instructions to satisfy all the AOMP source build requirements.

## Clone and Build AOMP

AOMP now uses a manifest file to specify the git repositories to clone.
We studied the use of the google repo command and found it was too compilicated for development
as compared to manually cloning the repos specified in a manifest file.
The script clone\_aomp.sh issues a sequence of "git clone" and "git pull" commands
by parsing information in the manifest file associated with a particular release.

<b>Choose a Build Version (Development or Release)</b> The development version is the next version to be released. It is possible that the development version is broken due to regressions that often occur during development.

Here are the commands to do a source build of AOMP:

<b>Development Branch:</b>
```
   export AOMP_VERSION=21.0
   export AOMP_REPOS=$HOME/git/aomp${AOMP_VERSION}
   mkdir -p $AOMP_REPOS
   cd $AOMP_REPOS
   git clone -b aomp-dev https://github.com/ROCm-Developer-Tools/aomp
```

The development version is the next version to be released.  It is possible that the development version is broken due to regressions that often occur during development.
These commands will build a previous release of AOMP such as aomp-20.0-2.<br>
<b>Release Branch:</b>
```
   export AOMP_VERSION=20.0
   export AOMP_REPOS=$HOME/git/aomp${AOMP_VERSION}
   mkdir -p $AOMP_REPOS
   cd $AOMP_REPOS
   git clone -b aomp-20.0-2 https://github.com/ROCm-Developer-Tools/aomp
```
<b>Clone and build:</b>
```
   $AOMP_REPOS/aomp/bin/clone_aomp.sh
   $AOMP_REPOS/aomp/bin/build_prereq.sh
   nohup $AOMP_REPOS/aomp/bin/build_aomp.sh &
```

<b>Optional build of math libraries (aomp-hip-libraries):</b>
This build can take a long time especially with multiple GPU ARCHS. The user can limit these by setting ROCMLIBS_GFXLIST=gfx90a or ROCMLIBS_GFXLIST="gfx90a;gfx1010".<br>
A full list of currently supported architectures, ROCMLIBS_GFXLIST, can be found in aomp/bin/aomp_common_vars.
```
   $AOMP_REPOS/aomp/bin/rocmlibs/clone_rocmlibs.sh
   $AOMP_REPOS/aomp/bin/rocmlibs/build_rocmlibs.sh
```

Change the value of AOMP\_REPOS to the directory name where you want to store all the repositories needed for AOMP. All the AOMP repositories will consume more than 12GB. Furthermore, each AOMP component will be built in a subdirectory of $AOMP\_REPOS/build which will consume an additional 6GB. So it is recommened that the directory $AOMP\_REPOS have more than 20GB of free space before beginning. It is recommended that $AOMP\_REPOS name include the value of AOMP\_VERSION as shown above. It is also recommended to put the values of AOMP\_VERSION and AOMP\_REPOS in a login profile (such as .bashrc) so future incremental build scripts will correctly find your sources.

Warning: the clone\_aomp.sh, and build\_aomp.sh are expected to take a long time to execute. As such we recommend the use of nohup to run build\_aomp.sh. It is ok to run build\_aomp.sh without nohup. The clone and build time will be affected by the performance of the filesystem that contains $AOMP\_REPOS.

There is a "list" option on the clone\_aomp.sh that provides useful information about each AOMP repository.
```
   $AOMP_REPOS/aomp/bin/clone_aomp.sh list
```
The above command will produce output like this showing you the location and branch of the repos in the AOMP\_REPOS directory and if there are any discrepencies with respect to the manifest file.<br>

<b>USED manifest file: /work/grodgers/git/aomp21.0/aomp/bin/../manifests/aompi_21.0.xml</b><br>
```
  repo src       branch                 path                 repo name    last hash    updated           commitor         for author
  --------       ------                 ----                 ---------    ---------    -------           --------         ----------
       emu  amd-staging         llvm-project lightning/ec/llvm-project f986706166c9 2023-12-06      Ron Lieberman            JP Lehr
       emu  amd-staging   SPIRV-LLVM-Translator  SPIRV-LLVM-Translator 0659e45216b2 2024-12-04            AlexVlx            AlexVlx
       roc     aomp-dev                flang                     flang 88b81b0a8ead 2023-11-30             GitHub    Emma Pilkington
       roc     aomp-dev          aomp-extras               aomp-extras 7097f3e2ba36 2023-12-04      Ron Lieberman      Ron Lieberman
       roc     aomp-dev                 aomp                      aomp df5b5d8ddffa 2023-12-05 Dhruva Chakrabarti Dhruva Chakrabarti
       roc   rocm-6.3.x          rocprofiler               rocprofiler 4e190a02e60e 2023-10-30             GitHub      Ammar ELWazir
       roc   rocm-6.3.x            roctracer                 roctracer 6fbf7673aa7f 2023-07-13 Ranjith Ramakrishnan Ranjith Ramakrishnan
       roc   rocm-6.3.x            ROCdbgapi                 ROCdbgapi df1a8df2be08 2023-07-28       Lancelot SIX       Lancelot SIX
       roc   rocm-6.3.x               ROCgdb                    ROCgdb 157eed788288 2023-07-28       Lancelot SIX       Lancelot SIX
       roc   rocm-6.3.x                  hip                       hip 80681169ae20 2023-08-15        Julia Jiang        Julia Jiang
       roc   rocm-6.3.x                  clr                       clr 1949b1621a80 2023-09-21        Julia Jiang        Julia Jiang
       roc   rocm-6.3.x             rocminfo                  rocminfo c8db38ede264 2023-06-02       Mark Searles       Mark Searles
       roc rocm-rel-6.3           rocm-cmake                rocm-cmake 15cbb2e47f0b 2023-07-11   Lauren Wrubleski   Lauren Wrubleski
       roc   rocm-6.3.x         rocr-runtime              ROCR-Runtime b2b6811571bf 2023-09-15      David Yat Sin      David Yat Sin
       roc   rocm-6.3.x roct-thunk-interface      ROCT-Thunk-Interface 5268ea80e32a 2023-08-09     David Belanger     David Belanger
     rocsw rocm-rel-6.3              hipfort                   hipfort 41f33eeaa3f7 2023-09-07             Sam Wu    dependabot[bot]
```
For more information, or if you are interested in joining the development of AOMP, please read the AOMP developers README file located here [README](../bin/README.md).
