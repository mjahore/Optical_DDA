! This Fortran77 program will correct dielectric data for surface damping
! effects present in plasmonic nanoparticles. For more details, see 
! Chapter 3 of M. J. A. Hore's PhD Dissertation (Univ. of Pennsylvania, 2012)
!
! Most importantly, note that wp, vF, and tau need to be specific to the material.
! As they exist in this program (hard coded, blah!) they're specific to Au. In addition
! you will need to replace a_eff by the effective radius that pertains to your DDA calculations.
! In that sense, this program needs to be run for each distinct nanoparticle dimension.
!
! Author: M. J. A. Hore, July 2025
!         hore@case.edu
!
      program dielectric_correction
      implicit none
      integer j
      double precision wp, w, tau, tau_a, h_bar, c
      double precision lambda, n, k, eps_r, eps_i
      double precision mag, a_eff
      double precision vF
      complex eps_b, eps_s
      complex I

      I     = (0.0, 1.0)      ! sqrt(-1)
      c     = 299792458.d0    ! Speed of light, m/s
      h_bar = 6.582119569d-16 ! Reduced Planck's const, eV s

      ! Effective radius
      a_eff = 15.6e-9          ! Units of meters

      ! Plasma frequency
      wp    = 8.55 / h_bar       ! 8.55 eV for Gold
      vF    = 1.41d6             ! Fermi velocity for Gold
      tau   = h_bar / 0.108d0    ! 0.108 eV for Gold
      tau_a = a_eff / vF    
       
    
      open(12, file="Au_weaver_uncorrected.dat")
      open(13, file="Au_weaver")

      do j=1, 21
       read(12,*) lambda, n, k, eps_r, eps_i

       ! Angular frequency from wavelength:
       w = 2.0 * 3.14159e0 * (c/(lambda * 1e-6))

       ! Form bulk dielectric function
       eps_b = eps_r + I*eps_i

       ! Correct for surface damping
       eps_s = eps_b + (wp**2/(w*(w + I/tau)) - 
     >                  wp**2/(w*(w + I/tau + I/tau_a)))

       eps_r = real(eps_s)
       eps_i = aimag(eps_s)

       ! Convert to refractive index + extinction.
       mag = dsqrt(eps_r**2 + eps_i**2)

       n = dsqrt(0.5d0 * (mag + real(eps_s)))
       k = dsqrt(0.5d0 * (mag - aimag(eps_s)))

       write(13,*) lambda, n, k, real(eps_s), aimag(eps_s)
      enddo     

      close(12)
      close(13)
      stop
      end
