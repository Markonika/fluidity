#include "fdebug.h"

module directional_element_length_module
!!< Streamline-aligned element length h_K, as used for the VMS
!!< stabilisation parameters of T. Coupez and E. Hachem, "Solution of
!!< high-Reynolds incompressible flow with stabilized finite element
!!< and adaptive anisotropic meshing", Comput. Methods Appl. Mech.
!!< Engrg. 267 (2013) 65-85, eq. 14:
!!<
!!<   h_K = 2 |v_h| / sum_{i=1}^{N_K} |v_h . grad(phi_i)|
!!<
!!< On highly anisotropic (highly stretched) elements, the usual
!!< isotropic choices for h_K (e.g. the minimum or maximum edge
!!< length) either over- or under-stabilise, because they ignore the
!!< element's orientation relative to the flow. Measuring the element
!!< diameter in the direction of the local velocity instead keeps the
!!< stabilisation consistent with the anisotropic mesh produced by the
!!< direction+magnitude combined metric (anisotropic_vector_metric
!!< module).

  use fldebug

  implicit none

  private
  public :: directional_element_length

  contains

  function directional_element_length(ele_velocity, dshape) result(h_k)
    !!< ele_velocity: a single representative velocity vector for the
    !!<   element (e.g. the mean of its nodal values).
    !!< dshape: physical-space shape function gradients at a single
    !!<   representative point in the element (dimension(nloc, dim)).
    !!<   For affine (straight-sided, P1) elements these are constant
    !!<   over the element, matching the P1 context of eq. 14.
    real, dimension(:), intent(in) :: ele_velocity
    real, dimension(:,:), intent(in) :: dshape
    real :: h_k

    real :: v_mag, denom
    integer :: iloc, nloc

    nloc = size(dshape, 1)
    assert(size(dshape, 2) == size(ele_velocity))

    v_mag = norm2(ele_velocity)

    if (v_mag <= epsilon(0.0)) then
      ! No local flow direction to align with. The caller should fall
      ! back to an isotropic element length in this case.
      h_k = -1.0
      return
    end if

    denom = 0.0
    do iloc=1,nloc
      denom = denom + abs(dot_product(ele_velocity, dshape(iloc,:)))
    end do

    if (denom <= epsilon(0.0)) then
      h_k = -1.0
      return
    end if

    h_k = 2.0 * v_mag / denom

  end function directional_element_length

end module directional_element_length_module
