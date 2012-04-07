// Copyright (C) 2011-2012 by the BEM++ Authors
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

#include "../common/config_trilinos.hpp"

#include "discrete_scalar_valued_source_term.hpp"

#include <iostream>

#ifdef WITH_TRILINOS
#include <Teuchos_ArrayRCP.hpp>
#endif

namespace Bempp
{

template <typename ValueType>
DiscreteScalarValuedSourceTerm<ValueType>::DiscreteScalarValuedSourceTerm(
        const arma::Col<ValueType>& vec)
{
#ifdef WITH_TRILINOS
    const size_t size = vec.n_rows;
    Teuchos::ArrayRCP<ValueType> data(size);
    for (int i = 0; i < size; ++i)
        data[i] = vec(i);
    this->initialize(Thyra::defaultSpmdVectorSpace<ValueType>(size),
                     data, 1 /* stride */);
#else
    m_vec = vec;
#endif
}

template <typename ValueType>
void DiscreteScalarValuedSourceTerm<ValueType>::dump() const
{
#ifdef WITH_TRILINOS
    std::cout << asVector() << std::endl; // inefficient
#else
    std::cout << m_vec << std::endl;
#endif
}

template <typename ValueType>
arma::Col<ValueType> DiscreteScalarValuedSourceTerm<ValueType>::asVector() const
{
#ifdef WITH_TRILINOS
    const size_t size = this->range()->dim();
    arma::Col<ValueType> col(size);
    for (int i = 0; i < size; ++i)
        col(i) = this->getPtr()[i];
    return col;
#else
    return m_vec;
#endif
}


#ifdef COMPILE_FOR_FLOAT
template class DiscreteScalarValuedSourceTerm<float>;
#endif
#ifdef COMPILE_FOR_DOUBLE
template class DiscreteScalarValuedSourceTerm<double>;
#endif
#ifdef COMPILE_FOR_COMPLEX_FLOAT
#include <complex>
template class DiscreteScalarValuedSourceTerm<std::complex<float> >;
#endif
#ifdef COMPILE_FOR_COMPLEX_DOUBLE
#include <complex>
template class DiscreteScalarValuedSourceTerm<std::complex<double> >;
#endif

} // namespace Bempp

