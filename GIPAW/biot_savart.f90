! Copyright (C) 2001-2005 Quantum ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!

!-----------------------------------------------------------------------
SUBROUTINE interpolate_current(j_bare_s, j_bare)
  !-----------------------------------------------------------------------
  ! ... Interpolate the current to the fine mesh
  USE kinds,     ONLY : dp
  USE gvect,     ONLY : nrxx
  USE gsmooth,   ONLY : nrxxs
  USE lsda_mod,  ONLY : nspin
  !-- parameters ---------------------------------------------------------
  IMPLICIT none
  real(dp), intent(in)  :: j_bare_s(nrxxs,3,3,nspin)
  real(dp), intent(out) :: j_bare(nrxx,3,3,nspin)
  !-- local variables ----------------------------------------------------
  integer :: ispin, ipol, jpol
  
  do ispin = 1, nspin
    do ipol = 1, 3
      do jpol = 1, 3
        call interpolate(j_bare(1,ipol,jpol,ispin), j_bare_s(1,ipol,jpol,ispin), 1)
      enddo
    enddo
  enddo

END SUBROUTINE interpolate_current


!-----------------------------------------------------------------------
SUBROUTINE biot_savart(j_bare, B_ind, B_ind_r)
  !-----------------------------------------------------------------------
  !
  ! ... Compute the induced magentic field via the Biot-Savart law
  ! ... B_ind(r) = (1/c) \int d^3r' j(r') (r-r')/|r-r'|
  ! ... which in reciprocal space reads:
  ! ... B_ind(G) = (4\pi/c) (i G \times j(G))/G^2
  ! ... the G=0 is not computed here and is given by chi_bare
  ! ...
  ! ... Even in the USPP case the induced field is compute on the hard grid,
  ! ... because it's compatible with the symmetry operators
  USE kinds,                ONLY : DP
  USE constants,            ONLY : fpi
  USE wvfct,                ONLY : nbnd, npwx, npw, igk
  USE cell_base,            ONLY : tpiba
  USE gipaw_module,         ONLY : alpha
  USE lsda_mod,             ONLY : nspin
  USE gvect,                ONLY : ngm, gstart, g, gg, ecutwfc, gcutm, &
                                   nrxx, nrx1, nrx2, nrx3, nr1, nr2, nr3, nl
  !-- parameters ---------------------------------------------------------
  implicit none
  real(dp), intent(in)     :: j_bare(nrxx,3,3,nspin)
  real(dp), intent(out)    :: B_ind_r(nrxx,3,3,nspin)
  complex(dp), intent(out) :: B_ind(ngm,3,3,nspin)

  !-- local variables ----------------------------------------------------
  complex(dp), allocatable :: aux(:), j_of_g(:,:)
  real(dp) :: gk
  complex(dp) :: fact
  integer :: ig, ipol, jpol, ispin

  call start_clock('biot_savart')

  ! allocate memory
  allocate(aux(nrxx), j_of_g(1:ngm,3))  

  do ispin = 1, nspin
    do jpol = 1, 3

      ! transform current to reciprocal space
      j_of_g(:,:) = (0.d0,0.d0)
      do ipol = 1, 3
        aux(1:nrxx) = j_bare(1:nrxx,ipol,jpol,ispin)
        call cft3(aux, nr1, nr2, nr3, nrx1, nrx2, nrx3, -1)
        j_of_g(1:ngm,ipol) = aux(nl(1:ngm))
      enddo

      ! compute induced field in reciprocal space
      do ig = gstart, ngm
        fact = (0.0_dp,1.0_dp) * (alpha*fpi) / (gg(ig) * tpiba)
        B_ind(ig,1,jpol,ispin) = fact * (g(2,ig)*j_of_g(ig,3) - g(3,ig)*j_of_g(ig,2))
        B_ind(ig,2,jpol,ispin) = fact * (g(3,ig)*j_of_g(ig,1) - g(1,ig)*j_of_g(ig,3))
        B_ind(ig,3,jpol,ispin) = fact * (g(1,ig)*j_of_g(ig,2) - g(2,ig)*j_of_g(ig,1))
     enddo

      ! transform induced field in real space
      do ipol = 1, 3
        aux = (0.d0,0.d0)
        aux(nl(1:ngm)) = B_ind(1:ngm,ipol,jpol,ispin)
        call cft3(aux, nr1, nr2, nr3, nrx1, nrx2, nrx3, 1)
        B_ind_r(1:nrxx,ipol,jpol,ispin) = real(aux(1:nrxx))
      enddo

    enddo ! jpol
  enddo ! ispin

  deallocate(aux, j_of_g)
  call stop_clock('biot_savart')

END SUBROUTINE biot_savart

