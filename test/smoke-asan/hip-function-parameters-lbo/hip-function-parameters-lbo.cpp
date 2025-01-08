#define __HIP_PLATFORM_AMD__ 1
#include <hip/hip_runtime.h>

#define SHMEM_SIZE 32

void printHipError(hipError_t error) {
  printf("Hip Error: %s\n", hipGetErrorString(error));
}

bool hipCallSuccessfull(hipError_t error) {
  if (error != hipSuccess)
    printHipError(error);
  return error == hipSuccess;
}

__device__ void OffloadToGPU(int *d_ptr, __shared__ int *lds_ptr) {
  size_t iX = blockDim.x * blockIdx.x + threadIdx.x;
  lds_ptr[iX] = 2 * (iX + 1);
  __syncthreads();
  d_ptr[iX] = lds_ptr[iX];
}

__global__ void TestKernel(int *d_ptr) {
  __shared__ int lds_ptr[SHMEM_SIZE];
  OffloadToGPU(d_ptr, lds_ptr);
}

int main(int argc, char *argv[]) {
  int N = 33;
  size_t NBytes = N * sizeof(int);
  int *H_Ptr = new int[N];
  int *D_Ptr;
  int NumOfThreadBlocks = (N + 64 - 1) / 64;
  int ThreadBlockSize = 64;
  hipCallSuccessfull(hipMalloc(&D_Ptr, NBytes));
  hipCallSuccessfull(hipMemset(D_Ptr, 1, NBytes));
  hipLaunchKernelGGL(TestKernel, dim3(NumOfThreadBlocks), dim3(ThreadBlockSize),
                     SHMEM_SIZE, 0, D_Ptr);
  hipDeviceSynchronize();
  hipCallSuccessfull(hipMemcpy(H_Ptr, D_Ptr, NBytes, hipMemcpyDeviceToHost));
  hipCallSuccessfull(hipFree(D_Ptr));
  delete[] H_Ptr;
  return 0;
}

/// CHECK:=================================================================
/// CHECK-NEXT:=={{[0-9]+}}==ERROR: AddressSanitizer: heap-buffer-overflow on amdgpu device 0 at pc [[PC:0x[0-9a-fA-F]+]]
/// CHECK-NEXT:WRITE of size 4 in workgroup id (0,0,{{[0-9]+}})
/// CHECK-NEXT:  #0 [[PC]] in OffloadToGPU(int*, int*) at {{.*}}/aomp/test/smoke-asan/hip-function-parameters-lbo/hip-function-parameters-lbo.cpp:18:{{[0-9]+}}
/// CHECK-NEXT: (inlined by) TestKernel(int*) at {{.*}}/aomp/test/smoke-asan/hip-function-parameters-lbo/hip-function-parameters-lbo.cpp:25:{{[0-9]+}}
/// CHECK:{{0x[0-9a-fA-F]+}} is 160 bytes above an address from a device malloc (or free) call of size 192 from
/// CHECK-NEXT:  #0 0xfffffffffffffffc in ?? at ??:0:0
