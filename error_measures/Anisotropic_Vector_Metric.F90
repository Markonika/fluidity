#include "fdebug.h"

module anisotropic_vector_metric
!!< Implements the direction+magnitude combined anisotropic metric of
!!< T. Coupez and E. Hachem, "Solution of high-Reynolds incompressible
!!< flow with stabilized finite element and adaptive anisotropic
!!< meshing", Comput. Methods Appl. Mech. Engrg. 267 (2013) 65-85,
!!< Sections 2 and 3.
!!<
!!< The standard Hessian-based metric (interpolation_metric module)
!!< builds one metric per scalar component of a vector field and
!!< combines them by metric intersection. For a field like velocity
!!< that is dominated in magnitude by one feature (e.g. the lid
!!< boundary layer in a driven cavity), this starves weak,
!!< low-magnitude features (e.g. secondary/corner vortices) of
!!< refinement, because the intersected metric is driven by wherever
!!< the Hessian of the magnitude is largest.
!!<
!!< This module instead builds a single edge-based metric from a
!!< (dim+1)-component nodal field: the normalised direction of the
!!< vector field (dim components) plus its normalised magnitude (1
!!< component), combined in an L2 sense per edge (Coupez & Hachem,
!!< eq. in Section 3). Because streamline curvature now drives
!!< refinement independently of magnitude, weak vortex cores get
!!< refined just as reliably as the strong primary vortex.
!!<
!!< The metric construction itself follows the edge-based length
!!< distribution tensor / optimal stretching approach of Section 2,
!!< which targets a fixed total number of mesh nodes rather than an
!!< absolute error tolerance.

  use spud
  use fldebug
  use global_parameters, only: OPTION_PATH_LEN
  use vector_tools
  use metric_tools
  use sparse_tools
  use fields
  use state_module
  use field_options
  use merge_tensors
  use halos
  use parallel_fields, only: node_owned
  use parallel_tools, only: allsum, allmax
  use form_metric_field

  implicit none

  private
  public :: form_vector_interpolation_metric

  contains

  subroutine form_vector_interpolation_metric(state, metric)
    !!< Loop over all vector fields that have opted into the
    !!< direction+magnitude combined metric (via the
    !!< /adaptivity_options/direction_magnitude_combined schema
    !!< option) and merge their metric into the overall error_metric.
    type(state_type), dimension(:), intent(inout) :: state
    type(tensor_field), intent(inout) :: metric

    type(vector_field) :: field_v
    type(vector_field), pointer :: positions
    type(tensor_field) :: tmp_metric
    integer :: i, j

    do i=1,size(state)
      do j=1,vector_field_count(state(i))
        field_v = extract_vector_field(state(i), j)
        if (aliased(field_v)) cycle

        if (have_adapt_opt(trim(field_v%option_path), "/adaptivity_options/direction_magnitude_combined")) then
          ewrite(2,*) "++: Forming direction+magnitude combined metric for ", trim(field_v%name)

          positions => extract_vector_field(state(i), "Coordinate")
          call halo_update(field_v)

          call allocate(tmp_metric, metric%mesh, "DirectionMagnitudeMetric")
          call zero(tmp_metric)

          call compute_direction_magnitude_metric(field_v, positions, tmp_metric)

          call bound_metric(tmp_metric, state(1))
          call merge_tensor_fields(metric, tmp_metric)

          call deallocate(tmp_metric)
        end if
      end do
    end do

  end subroutine form_vector_interpolation_metric

  subroutine compute_direction_magnitude_metric(field, positions, metric)
    !!< Core implementation of Coupez & Hachem (2013), Sections 2-3,
    !!< for a single vector field.
    type(vector_field), intent(in) :: field
    type(vector_field), intent(in) :: positions
    type(tensor_field), intent(inout) :: metric

    type(csr_sparsity), pointer :: nnlist
    integer, dimension(:), pointer :: neighbours

    integer :: dim, ncomp, nnodes
    integer :: i, j, k, c

    real, allocatable, dimension(:) :: mag
    real :: mag_max
    real, allocatable, dimension(:,:) :: uh
    real, allocatable, dimension(:,:,:) :: grad_recovered
    real, allocatable, dimension(:) :: e_edge

    real, dimension(positions%dim) :: xij
    real, dimension(positions%dim, positions%dim) :: xi_tensor, xi_inv, m_accum
    real, dimension(positions%dim) :: rhs_vec

    real :: p_norm, lambda, sum_pow, e_ij, s_ij, reg
    integer :: target_nodes, stat, owned_count
    character(len=OPTION_PATH_LEN) :: opt_path
    real, parameter :: min_error = epsilon(0.0) * 1.0e3

    dim = positions%dim
    ncomp = dim + 1
    nnodes = node_count(field%mesh)

    nnlist => extract_nnlist(field)

    opt_path = trim(complete_field_path(field%option_path, stat=stat)) // &
      & "/adaptivity_options/direction_magnitude_combined"

    call get_option(trim(opt_path) // "/p_norm", p_norm, stat=stat, default=1.5)

    call get_option(trim(opt_path) // "/target_nodes", target_nodes, stat=stat)
    if (stat /= 0) then
      ! Default: preserve the current (global, owned) node count.
      owned_count = 0
      do i=1,nnodes
        if (node_owned(field%mesh, i)) owned_count = owned_count + 1
      end do
      call allsum(owned_count)
      target_nodes = max(owned_count, 1)
    end if

    ! --- Step 0: build the (dim+1)-component nodal field: normalised
    !     direction (dim components) + normalised magnitude (1 component).

    allocate(mag(nnodes))
    allocate(uh(nnodes, ncomp))

    do i=1,nnodes
      mag(i) = norm2(node_val(field, i))
    end do
    mag_max = maxval(mag)
    call allmax(mag_max)
    if (mag_max <= 0.0) mag_max = 1.0

    do i=1,nnodes
      if (mag(i) > 0.0) then
        uh(i, 1:dim) = node_val(field, i) / mag(i)
      else
        uh(i, 1:dim) = 0.0
      end if
      uh(i, ncomp) = mag(i) / mag_max
    end do

    deallocate(mag)

    ! --- Step 1: nodal gradient recovery via the length distribution
    !     tensor (Coupez & Hachem, Section 2.2 / eq. 6-7), applied to
    !     every component of uh independently.

    allocate(grad_recovered(nnodes, ncomp, dim))
    grad_recovered = 0.0

    do i=1,nnodes
      neighbours => row_m_ptr(nnlist, i)
      if (size(neighbours) == 0) cycle

      xi_tensor = 0.0
      do k=1,size(neighbours)
        j = neighbours(k)
        xij = node_val(positions, j) - node_val(positions, i)
        xi_tensor = xi_tensor + outer_product(xij, xij)
      end do
      xi_tensor = xi_tensor / real(size(neighbours))

      ! Tikhonov-style regularisation: guards against a singular
      ! length distribution tensor at nodes whose neighbours do not
      ! span all dim directions (e.g. certain boundary/corner nodes).
      reg = epsilon(0.0) * max(1.0, maxval(abs(xi_tensor)))
      do k=1,dim
        xi_tensor(k,k) = xi_tensor(k,k) + reg
      end do

      xi_inv = inverse(xi_tensor)

      do c=1,ncomp
        rhs_vec = 0.0
        do k=1,size(neighbours)
          j = neighbours(k)
          xij = node_val(positions, j) - node_val(positions, i)
          rhs_vec = rhs_vec + (uh(j,c) - uh(i,c)) * xij
        end do
        grad_recovered(i,c,:) = matmul(xi_inv, rhs_vec)
      end do
    end do

    ! --- Step 2: per-edge error, combining all ncomp components in an
    !     L2 sense (Coupez & Hachem, Section 3), and the global sum
    !     needed to solve for the optimal stretching factor under a
    !     fixed total node-count constraint (Section 2.5).

    allocate(e_edge(size(nnlist%colm)))
    e_edge = 0.0
    sum_pow = 0.0

    do i=1,nnodes
      neighbours => row_m_ptr(nnlist, i)
      do k=1,size(neighbours)
        j = neighbours(k)
        xij = node_val(positions, j) - node_val(positions, i)

        e_ij = 0.0
        do c=1,ncomp
          e_ij = e_ij + (0.5 * dot_product(grad_recovered(i,c,:) + grad_recovered(j,c,:), xij))**2
        end do
        e_ij = max(sqrt(e_ij), min_error)

        e_edge(nnlist%findrm(i) + k - 1) = e_ij

        if (node_owned(field%mesh, i)) then
          sum_pow = sum_pow + e_ij ** (p_norm / (p_norm + 2.0))
        end if
      end do
    end do

    call allsum(sum_pow)

    lambda = (sum_pow / real(target_nodes)) ** ((p_norm + 2.0) / p_norm)

    ! --- Step 3: form the nodal metric from the optimal stretching
    !     factors (Coupez & Hachem, eq. 9).

    do i=1,nnodes
      neighbours => row_m_ptr(nnlist, i)

      if (size(neighbours) == 0) then
        call set(metric, i, get_identity_tensor(dim))
        cycle
      end if

      m_accum = 0.0
      do k=1,size(neighbours)
        j = neighbours(k)
        xij = node_val(positions, j) - node_val(positions, i)
        e_ij = e_edge(nnlist%findrm(i) + k - 1)

        s_ij = (lambda / e_ij) ** (1.0 / (p_norm + 2.0))

        m_accum = m_accum + (s_ij**2) * outer_product(xij, xij)
      end do

      reg = epsilon(0.0) * max(1.0, maxval(abs(m_accum)))
      do k=1,dim
        m_accum(k,k) = m_accum(k,k) + reg
      end do

      m_accum = inverse(m_accum) / real(dim)

      call set(metric, i, m_accum)
    end do

    deallocate(uh)
    deallocate(grad_recovered)
    deallocate(e_edge)

  end subroutine compute_direction_magnitude_metric

  function get_identity_tensor(dim) result(ident)
    integer, intent(in) :: dim
    real, dimension(dim, dim) :: ident
    integer :: k

    ident = 0.0
    do k=1,dim
      ident(k,k) = 1.0
    end do
  end function get_identity_tensor

end module anisotropic_vector_metric
