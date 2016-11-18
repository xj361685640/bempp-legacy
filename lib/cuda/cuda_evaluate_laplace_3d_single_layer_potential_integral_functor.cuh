// Copyright (C) 2011-2012 by the Bem++ Authors
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#ifndef fiber_cuda_evaluate_laplace_3d_single_layer_potential_integral_functor_cuh
#define fiber_cuda_evaluate_laplace_3d_single_layer_potential_integral_functor_cuh

#include "cuda_evaluate_integral_functor.cuh"
#include "cuda_laplace_3d_single_layer_potential_kernel_functor.hpp"

#include <device_launch_parameters.h>

namespace Fiber {

template <typename BasisFunctionType, typename KernelType, typename ResultType>
__global__ void
RawCudaEvaluateLaplace3dSingleLayerPotentialKernelFunctorCached(
    const int elemPairIndexBegin, const unsigned int elemPairCount,
    const unsigned int testIndexCount,
    const int* __restrict__ testIndices, const int* __restrict__ trialIndices,
    const unsigned int testPointCount, const unsigned int trialPointCount,
    const unsigned int testElemCount,
    const typename ScalarTraits<BasisFunctionType>::RealType* testGeomData,
    const unsigned int trialElemCount,
    const typename ScalarTraits<BasisFunctionType>::RealType* trialGeomData,
    KernelType* __restrict__ kernelValues) {

  typedef typename ScalarTraits<BasisFunctionType>::RealType CoordinateType;

  // Each thread is working on one element pair
  const unsigned int i = blockIdx.x * blockDim.x + threadIdx.x;

  if (i < elemPairCount) {
//  if (i < elemPairCount * trialPointCount * testPointCount) {

    const int coordCount = 3;

    // Determine trial and test element indices
    const int elemPairIndex = elemPairIndexBegin + i;
    const int trialElemPosition = trialIndices[elemPairIndex / testIndexCount];
    const int testElemPosition = testIndices[elemPairIndex % testIndexCount];

//    // Determine trial and test element indices
//    const int localElemPairIndex = i % elemPairCount;
//    const int elemPairIndex = elemPairIndexBegin + localElemPairIndex;
//    const int trialElemPosition = trialIndices[elemPairIndex / testIndexCount];
//    const int testElemPosition = testIndices[elemPairIndex % testIndexCount];
//    const int trialPoint = i / (elemPairCount * testPointCount);
//    const int testPoint = (i % (elemPairCount * testPointCount)) / elemPairCount;

    // Evaluate kernel
    KernelType kernelValue;
    CoordinateType trialPointCoo[coordCount], testPointCoo[coordCount];
    for (size_t trialPoint = 0; trialPoint < trialPointCount; ++trialPoint) {
      for (size_t testPoint = 0; testPoint < testPointCount; ++testPoint) {
    #pragma unroll
        for (size_t coo = 0; coo < coordCount; ++coo) {
          trialPointCoo[coo] =
              trialGeomData[coo * trialPointCount * trialElemCount
                            + trialPoint * trialElemCount
                            + trialElemPosition];
          testPointCoo[coo] =
              testGeomData[coo * testPointCount * testElemCount
                           + testPoint * testElemCount
                           + testElemPosition];
        }
        CudaLaplace3dSingleLayerPotentialKernelFunctor<KernelType>::evaluate(
            testPointCoo, trialPointCoo, kernelValue);
        const size_t index = trialPoint * testPointCount * elemPairCount
                             + testPoint * elemPairCount
                             + i;
        kernelValues[index] = kernelValue;
//        kernelValues[i] = kernelValue;
      }
    }
  }
}

template <typename BasisFunctionType, typename KernelType, typename ResultType>
__global__ void
RawCudaEvaluateLaplace3dSingleLayerPotentialIntegralFunctorKernelCached(
    const int elemPairIndexBegin, const unsigned int elemPairCount,
    const unsigned int testIndexCount,
    const int* __restrict__ testIndices, const int* __restrict__ trialIndices,
    const unsigned int testPointCount, const unsigned int trialPointCount,
    const unsigned int testDofCount, const BasisFunctionType* __restrict__ testBasisValues,
    const unsigned int trialDofCount, const BasisFunctionType* __restrict__ trialBasisValues,
    const unsigned int testElemCount,
    const typename ScalarTraits<BasisFunctionType>::RealType*
    testIntegrationElements,
    const unsigned int trialElemCount,
    const typename ScalarTraits<BasisFunctionType>::RealType*
    trialIntegrationElements,
    const KernelType* __restrict__ kernelValues,
    ResultType* __restrict__ result) {

  typedef typename ScalarTraits<BasisFunctionType>::RealType CoordinateType;

  // Each thread is working on one dof pair
  const unsigned int i = blockIdx.x * blockDim.x + threadIdx.x;

  if (i < elemPairCount * trialDofCount * testDofCount) {

    // Determine trial and test element indices
    const int localElemPairIndex = i % elemPairCount;
    const int elemPairIndex = elemPairIndexBegin + localElemPairIndex;
    const int trialElemPosition = trialIndices[elemPairIndex / testIndexCount];
    const int testElemPosition = testIndices[elemPairIndex % testIndexCount];
    const int trialDof = i / (elemPairCount * testDofCount);
    const int testDof = (i % (elemPairCount * testDofCount)) / elemPairCount;

    // Gather integration elements
    const CoordinateType trialIntegrationElement =
        trialIntegrationElements[trialElemPosition];
    const CoordinateType testIntegrationElement =
        testIntegrationElements[testElemPosition];

    // Perform numerical integration
    ResultType sum = 0.;
    for (size_t trialPoint = 0; trialPoint < trialPointCount; ++trialPoint) {
      const CoordinateType trialWeight =
          trialIntegrationElement * constTrialQuadWeights[trialPoint];
      ResultType partialSum = 0.;
      for (size_t testPoint = 0; testPoint < testPointCount; ++testPoint) {
        const CoordinateType testWeight =
            testIntegrationElement * constTestQuadWeights[testPoint];
        const size_t index = trialPoint * testPointCount * elemPairCount
                             + testPoint * elemPairCount
                             + localElemPairIndex;
        partialSum +=
            kernelValues[index]
            * testBasisValues[testDof * testPointCount + testPoint]
            * trialBasisValues[trialDof * trialPointCount + trialPoint]
            * testWeight;
      }
      sum += partialSum * trialWeight;
    }
    result[i] = sum;
  }
}

template <typename BasisFunctionType, typename KernelType, typename ResultType>
__global__ void
RawCudaEvaluateLaplace3dSingleLayerPotentialIntegralFunctorCached(
    const int elemPairIndexBegin, const unsigned int elemPairCount,
    const unsigned int testIndexCount,
    const int* __restrict__ testIndices, const int* __restrict__ trialIndices,
    const unsigned int testPointCount, const unsigned int trialPointCount,
    const unsigned int testDofCount, const BasisFunctionType* __restrict__ testBasisValues,
    const unsigned int trialDofCount, const BasisFunctionType* __restrict__ trialBasisValues,
    const unsigned int testElemCount,
    const typename ScalarTraits<BasisFunctionType>::RealType* testGeomData,
    const typename ScalarTraits<BasisFunctionType>::RealType*
    testElemNormals,
    const typename ScalarTraits<BasisFunctionType>::RealType*
    testIntegrationElements,
    const unsigned int trialElemCount,
    const typename ScalarTraits<BasisFunctionType>::RealType* trialGeomData,
    const typename ScalarTraits<BasisFunctionType>::RealType*
    trialElemNormals,
    const typename ScalarTraits<BasisFunctionType>::RealType*
    trialIntegrationElements,
    ResultType* __restrict__ result) {

  typedef typename ScalarTraits<BasisFunctionType>::RealType CoordinateType;

  const unsigned int i = blockIdx.x * blockDim.x + threadIdx.x;

  if (i < elemPairCount) {

    const int coordCount = 3;

    // Determine trial and test element indices
    const int elemPairIndex = elemPairIndexBegin + i;
    const int trialElemPosition = trialIndices[elemPairIndex / testIndexCount];
    const int testElemPosition = testIndices[elemPairIndex % testIndexCount];

    // Gather integration elements
    const CoordinateType trialIntegrationElement =
        trialIntegrationElements[trialElemPosition];
    const CoordinateType testIntegrationElement =
        testIntegrationElements[testElemPosition];

    // Evaluate kernel
    KernelType kernelValues[10 * 10];
    CoordinateType trialPointCoo[coordCount], testPointCoo[coordCount];
    for (size_t trialPoint = 0; trialPoint < trialPointCount; ++trialPoint) {
      for (size_t testPoint = 0; testPoint < testPointCount; ++testPoint) {
        KernelType kernelValue;
#pragma unroll
        for (size_t coo = 0; coo < coordCount; ++coo) {
          trialPointCoo[coo] =
              trialGeomData[coo * trialPointCount * trialElemCount
                            + trialPoint * trialElemCount
                            + trialElemPosition];
          testPointCoo[coo] =
              testGeomData[coo * testPointCount * testElemCount
                           + testPoint * testElemCount
                           + testElemPosition];
        }
        CudaLaplace3dSingleLayerPotentialKernelFunctor<KernelType>::evaluate(
            testPointCoo, trialPointCoo, kernelValue);
        kernelValues[trialPoint * testPointCount + testPoint] = kernelValue;
      }
    }

    // Perform numerical integration
    for (size_t trialDof = 0; trialDof < trialDofCount; ++trialDof) {
      for (size_t testDof = 0; testDof < testDofCount; ++testDof) {
        ResultType sum = 0.;
        for (size_t trialPoint = 0; trialPoint < trialPointCount; ++trialPoint) {
          const CoordinateType trialWeight =
              trialIntegrationElement * constTrialQuadWeights[trialPoint];
          ResultType partialSum = 0.;
          for (size_t testPoint = 0; testPoint < testPointCount; ++testPoint) {
            const CoordinateType testWeight =
                testIntegrationElement * constTestQuadWeights[testPoint];
            partialSum +=
                kernelValues[trialPoint * testPointCount + testPoint]
                * testBasisValues[testDof * testPointCount + testPoint]
                * trialBasisValues[trialDof * trialPointCount + trialPoint]
                * testWeight;
          }
          sum += partialSum * trialWeight;
        }
        const size_t index = trialDof * testDofCount * elemPairCount
                             + testDof * elemPairCount
                             + i;
        result[index] = sum;
      }
    }
  }
}

template <typename BasisFunctionType, typename KernelType, typename ResultType>
__global__ void
RawCudaEvaluateLaplace3dSingleLayerPotentialIntegralFunctorNonCached(
    const int elemPairIndexBegin, const unsigned int elemPairCount,
    const unsigned int trialIndexCount,
    const int* __restrict__ testIndices, const int* __restrict__ trialIndices,
    const unsigned int testPointCount, const unsigned int trialPointCount,
    const unsigned int testDofCount, BasisFunctionType* testBasisValues,
    const unsigned int trialDofCount, BasisFunctionType* trialBasisValues,
    const unsigned int testElemCount, const unsigned int testVtxCount,
    const typename ScalarTraits<BasisFunctionType>::RealType* testVertices,
    const int* testElementCorners,
    const unsigned int trialElemCount, const unsigned int trialVtxCount,
    const typename ScalarTraits<BasisFunctionType>::RealType* trialVertices,
    const int* trialElementCorners,
    ResultType* __restrict__ result) {

  typedef typename ScalarTraits<BasisFunctionType>::RealType CoordinateType;

  const unsigned int i = blockIdx.x * blockDim.x + threadIdx.x;

  if (i < elemPairCount) {

    const int coordCount = 3;

    // Determine test and trial element indices
    const int elemPairIndex = elemPairIndexBegin + i;
    const int testElemPosition = testIndices[elemPairIndex / trialIndexCount];
    const int trialElemPosition = trialIndices[elemPairIndex % trialIndexCount];

    // Gather coordinates
    CoordinateType testElemVtx0[coordCount];
    CoordinateType testElemVtx1[coordCount];
    CoordinateType testElemVtx2[coordCount];

    CoordinateType trialElemVtx0[coordCount];
    CoordinateType trialElemVtx1[coordCount];
    CoordinateType trialElemVtx2[coordCount];

    for (int coo = 0; coo < coordCount; ++coo) {

      testElemVtx0[coo] =
          testVertices[testElementCorners[testElemPosition]+coo*testVtxCount];
      testElemVtx1[coo] =
          testVertices[testElementCorners[testElemPosition+testElemCount]+coo*testVtxCount];
      testElemVtx2[coo] =
          testVertices[testElementCorners[testElemPosition+2*testElemCount]+coo*testVtxCount];

      trialElemVtx0[coo] =
          trialVertices[trialElementCorners[trialElemPosition]+coo*trialVtxCount];
      trialElemVtx1[coo] =
          trialVertices[trialElementCorners[trialElemPosition+trialElemCount]+coo*trialVtxCount];
      trialElemVtx2[coo] =
          trialVertices[trialElementCorners[trialElemPosition+2*trialElemCount]+coo*trialVtxCount];
    }

    // Calculate normals and integration elements
    CoordinateType testElemNormal[coordCount];
    CoordinateType trialElemNormal[coordCount];

    testElemNormal[0] =
        (testElemVtx1[1] - testElemVtx0[1]) * (testElemVtx2[2] - testElemVtx0[2])
      - (testElemVtx1[2] - testElemVtx0[2]) * (testElemVtx2[1] - testElemVtx0[1]);
    testElemNormal[1] =
        (testElemVtx1[2] - testElemVtx0[2]) * (testElemVtx2[0] - testElemVtx0[0])
      - (testElemVtx1[0] - testElemVtx0[0]) * (testElemVtx2[2] - testElemVtx0[2]);
    testElemNormal[2] =
        (testElemVtx1[0] - testElemVtx0[0]) * (testElemVtx2[1] - testElemVtx0[1])
      - (testElemVtx1[1] - testElemVtx0[1]) * (testElemVtx2[0] - testElemVtx0[0]);

    trialElemNormal[0] =
        (trialElemVtx1[1] - trialElemVtx0[1]) * (trialElemVtx2[2] - trialElemVtx0[2])
      - (trialElemVtx1[2] - trialElemVtx0[2]) * (trialElemVtx2[1] - trialElemVtx0[1]);
    trialElemNormal[1] =
        (trialElemVtx1[2] - trialElemVtx0[2]) * (trialElemVtx2[0] - trialElemVtx0[0])
      - (trialElemVtx1[0] - trialElemVtx0[0]) * (trialElemVtx2[2] - trialElemVtx0[2]);
    trialElemNormal[2] =
        (trialElemVtx1[0] - trialElemVtx0[0]) * (trialElemVtx2[1] - trialElemVtx0[1])
      - (trialElemVtx1[1] - trialElemVtx0[1]) * (trialElemVtx2[0] - trialElemVtx0[0]);

    const CoordinateType testIntegrationElement =
        std::sqrt(testElemNormal[0]*testElemNormal[0]
                + testElemNormal[1]*testElemNormal[1]
                + testElemNormal[2]*testElemNormal[2]);
    const CoordinateType trialIntegrationElement =
        std::sqrt(trialElemNormal[0]*trialElemNormal[0]
                + trialElemNormal[1]*trialElemNormal[1]
                + trialElemNormal[2]*trialElemNormal[2]);

    // Calculate global points
    CoordinateType testElemGeomData[10 * coordCount], trialElemGeomData[10 * coordCount];
    for (int testPoint = 0; testPoint < testPointCount; ++testPoint) {
      const CoordinateType ptFun0 = constTestGeomShapeFun0[testPoint];
      const CoordinateType ptFun1 = constTestGeomShapeFun1[testPoint];
      const CoordinateType ptFun2 = constTestGeomShapeFun2[testPoint];
      for (int i = 0; i < coordCount; ++i) {
        testElemGeomData[coordCount * testPoint + i] =
            ptFun0 * testElemVtx0[i]
          + ptFun1 * testElemVtx1[i]
          + ptFun2 * testElemVtx2[i];
      }
    }
    for (int trialPoint = 0; trialPoint < trialPointCount; ++trialPoint) {
      const CoordinateType ptFun0 = constTrialGeomShapeFun0[trialPoint];
      const CoordinateType ptFun1 = constTrialGeomShapeFun1[trialPoint];
      const CoordinateType ptFun2 = constTrialGeomShapeFun2[trialPoint];
      for (int i = 0; i < coordCount; ++i) {
        trialElemGeomData[coordCount * trialPoint + i] =
            ptFun0 * trialElemVtx0[i]
          + ptFun1 * trialElemVtx1[i]
          + ptFun2 * trialElemVtx2[i];
      }
    }

    // Evaluate kernel
    KernelType kernelValues[10 * 10];
    CoordinateType testPointCoo[coordCount], trialPointCoo[coordCount];
    for (size_t testPoint = 0; testPoint < testPointCount; ++testPoint) {
      for (size_t trialPoint = 0; trialPoint < trialPointCount; ++trialPoint) {
        KernelType kernelValue;
        for (int coordIndex = 0; coordIndex < coordCount; ++coordIndex) {
          testPointCoo[coordIndex] = testElemGeomData[coordCount * testPoint + coordIndex];
          trialPointCoo[coordIndex] = trialElemGeomData[coordCount * trialPoint + coordIndex];
        }
        CudaLaplace3dSingleLayerPotentialKernelFunctor<KernelType>::evaluate(
            testPointCoo, trialPointCoo, kernelValue);
        kernelValues[testPoint * trialPointCount + trialPoint] = kernelValue;
      }
    }

    // Perform numerical integration
    ResultType localResult[36];
    for (size_t trialDof = 0; trialDof < trialDofCount; ++trialDof) {
      for (size_t testDof = 0; testDof < testDofCount; ++testDof) {
        ResultType sum = 0.;
        for (size_t trialPoint = 0; trialPoint < trialPointCount; ++trialPoint) {
          const CoordinateType trialWeight =
              trialIntegrationElement * constTrialQuadWeights[trialPoint];
          ResultType partialSum = 0.;
          for (size_t testPoint = 0; testPoint < testPointCount; ++testPoint) {
            const CoordinateType testWeight =
                testIntegrationElement * constTestQuadWeights[testPoint];
            partialSum +=
                kernelValues[testPoint * trialPointCount + trialPoint]
                * testBasisValues[testDof + testDofCount * testPoint]
                * trialBasisValues[trialDof + trialDofCount * trialPoint]
                * testWeight;
          }
          sum += partialSum * trialWeight;
        }
        localResult[testDof * trialDofCount + trialDof] = sum;
      }
    }

    // Copy local result to global device memory
    for (size_t trialDof = 0; trialDof < trialDofCount; ++trialDof) {
      for (size_t testDof = 0; testDof < testDofCount; ++testDof) {
        const size_t index = testDof * elemPairCount * trialDofCount
                             + trialDof * elemPairCount
                             + i;
        result[index] = localResult[testDof * trialDofCount + trialDof];
      }
    }
  }
}

} // namespace Fiber

#endif
