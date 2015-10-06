#pylint: disable-msg=too-many-arguments

"""Definition of sparse boundary operators."""


def identity(domain, range_, dual_to_range,
             label="IDENTITY", symmetry='no_symmetry',
             parameters=None):
    """Return the identity operator."""

    import bempp.api
    from bempp.core.operators.boundary.sparse import identity_ext
    from bempp.api.assembly import LocalBoundaryOperator
    from bempp.api.assembly.abstract_boundary_operator import ElementaryAbstractLocalOperator

    if parameters is None:
        parameters = bempp.api.global_parameters

    return LocalBoundaryOperator(\
            ElementaryAbstractLocalOperator(
            identity_ext(parameters, domain._impl, range_._impl,
                         dual_to_range._impl, "", symmetry)),
            parameters=parameters, label=label)

def maxwell_identity(space,
                     label="MAXWELL_IDENTITY", symmetry='no_symmetry',
                     parameters=None):
    """Return the Maxwell identity operator."""

    import bempp.api
    from bempp.core.operators.boundary.sparse import maxwell_identity_ext
    from bempp.api.assembly import LocalBoundaryOperator
    from bempp.api.assembly.abstract_boundary_operator import ElementaryAbstractLocalOperator

    if parameters is None:
        parameters = bempp.api.global_parameters

    return LocalBoundaryOperator(\
            ElementaryAbstractLocalOperator(
            maxwell_identity_ext(parameters, space._impl, space._impl,
                                 space._impl, "", symmetry)),
            parameters=parameters, label=label)

def laplace_beltrami(domain, range_, dual_to_range,
                     label="LAPLACE_BELTRAMI", symmetry='no_symmetry',
                     parameters=None):
    """Return the Laplace-Beltrami operator."""

    import bempp.api
    from bempp.core.operators.boundary.sparse import laplace_beltrami_ext
    from bempp.api.assembly import LocalBoundaryOperator
    from bempp.api.assembly.abstract_boundary_operator import ElementaryAbstractLocalOperator

    if parameters is None:
        parameters = bempp.api.global_parameters

    return LocalBoundaryOperator(\
            ElementaryAbstractLocalOperator(
            laplace_beltrami_ext(parameters, domain._impl, range_._impl,
                                 dual_to_range._impl, "", symmetry)),
            parameters=parameters, label=label)

def multitrace_identity(grid, parameters=None):
    """Return the multitrace identity operator."""

    from bempp.api.assembly import BlockedOperator
    import bempp.api

    const_space = bempp.api.function_space(grid, "DUAL", 0)
    lin_space = bempp.api.function_space(grid, "B-P", 1)

    blocked_operator = BlockedOperator(2,2)

    blocked_operator[0, 0] = identity(lin_space, lin_space, const_space, parameters=parameters)
    blocked_operator[1, 1] = identity(const_space, const_space, lin_space, parameters=parameters)

    return blocked_operator
