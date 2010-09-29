!
! Copyright (C) 2001-2009 GIPAW and Quantum ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!-----------------------------------------------------------------------
PROGRAM gipaw_main
  !-----------------------------------------------------------------------
  !
  ! ... This is the main driver of the magnetic response program. 
  ! ... It controls the initialization routines.
  ! ... Features: NMR chemical shifts
  !...            EPR g-tensor
  ! ... Ported to Espresso by:
  ! ... D. Ceresoli, A. P. Seitsonen, U. Gerstamnn and  F. Mauri
  ! ...
  ! ... References (NMR):
  ! ... F. Mauri and S. G. Louie Phys. Rev. Lett. 76, 4246 (1996)
  ! ... F. Mauri, B. G. Pfrommer, S. G. Louie, Phys. Rev. Lett. 77, 5300 (1996)
  ! ... T. Gregor, F. Mauri, and R. Car, J. Chem. Phys. 111, 1815 (1999)
  ! ... C. J. Pickard and F. Mauri, Phys. Rev. B 63, 245101 (2001)
  ! ... C. J. Pickard and F. Mauri, Phys. Rev. Lett. 91, 196401 (2003)
  ! ...
  ! ... References (g-tensor):
  ! ... C. J. Pickard and F. Mauri, Phys. Rev. Lett. 88, 086403 (2002)
  ! ...
  USE kinds,           ONLY : DP
  USE io_global,       ONLY : stdout, ionode, ionode_id
  USE io_files,        ONLY : prefix, tmp_dir, nd_nmbr
  USE klist,           ONLY : nks
  USE mp,              ONLY : mp_bcast
  USE cell_base,       ONLY : tpiba
  USE cellmd,          ONLY : cell_factor
  USE gipaw_module,    ONLY : job, q_gipaw, gipaw_readin, gipaw_allocate, gipaw_setup, &
                              gipaw_openfil, print_clock_gipaw, &
                              gipaw_summary
  USE control_flags,   ONLY : io_level, gamma_only
  USE mp_global,       ONLY : mp_startup
  USE environment,     ONLY : environment_start
  USE lsda_mod,        ONLY : nspin

  !------------------------------------------------------------------------
  IMPLICIT NONE
  CHARACTER (LEN=9)   :: code = 'GIPAW'
  !------------------------------------------------------------------------

  ! ... and begin with the initialization part
#ifdef __PARA
  CALL mp_startup ( )
#endif
  CALL environment_start ( code )
  !
  CALL gipaw_readin()
  io_level = 1
 
  ! read ground state wavefunctions
  cell_factor = 1.1d0
  call read_file
  call gipaw_openfil
  
  if ( gamma_only ) call errore ( 'gipaw_main', 'gamma_only == .true.', 1 )
  
  CALL gipaw_allocate()
  CALL gipaw_setup()
  CALL gipaw_summary()
  CALL print_clock( 'GIPAW' )
  
  ! convert q_gipaw into units of tpiba
  q_gipaw = q_gipaw / tpiba
  
  ! calculation
  select case ( trim(job) )
  case ( 'nmr' )
     call suscept_crystal   
     
  case ( 'g_tensor' )
     if (nspin /= 2) call errore('gipaw_main', 'g_tensor is only for spin-polarized', 1)
     call g_tensor_crystal
     
  case ( 'f-sum' )
     call suscept_crystal
     
  case ( 'efg' )
     call efg
     
  case ( 'hyperfine' )
     call hyperfine
     
  case default
     call errore('gipaw_main', 'wrong or undefined job in input', 1)
  end select
  
  ! print timings and stop the code
  CALL print_clock_gipaw()
  CALL stop_code( .TRUE. )
  
  STOP
  
END PROGRAM gipaw_main
