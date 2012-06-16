%{
#include "assembly/standard_local_assembler_factory_for_operators_on_surfaces.hpp"
  %}


%warnfilter(401) Bempp::StandardLocalAssemblerFactoryForOperatorsOnSurfaces;

%include "assembly/standard_local_assembler_factory_for_operators_on_surfaces.hpp"


namespace Bempp
{
BEMPP_PYTHON_DECLARE_CLASS_TEMPLATED_ON_BASIS_AND_RESULT(StandardLocalAssemblerFactoryForOperatorsOnSurfaces);


}





%pythoncode %{

  def standardLocalAssemblerFactoryForOperatorsOnSurfaces(basisFunctionType='float64',resultType='float64',accuracyOptions=None):
      if basisFunctionType is not None: dtype1=checkType(basisFunctionType)
      if resultType is not None: dtype2=checkType(resultType)
      if accuracyOptions is None: accuracyOptions=AccuracyOptions()
      name='StandardLocalAssemblerFactoryForOperatorsOnSurfaces'
      return constructObjectTemplatedOnBasisAndResult(name, basisFunctionType, resultType,accuracyOptions)
		      
	  %}