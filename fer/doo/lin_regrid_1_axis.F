	SUBROUTINE LIN_REGRID_1_AXIS(	cx_lims, axis, dst_lo, dst_hi,
     .					src, msrc, dst, mdst,
     .					ss12, coef )

*
*
*  This software was developed by the Thermal Modeling and Analysis
*  Project(TMAP) of the National Oceanographic and Atmospheric
*  Administration''s (NOAA) Pacific Marine Environmental Lab(PMEL),
*  hereafter referred to as NOAA/PMEL/TMAP.
*
*  Access and use of this software shall impose the following
*  obligations and understandings on the user. The user is granted the
*  right, without any fee or cost, to use, copy, modify, alter, enhance
*  and distribute this software, and any derivative works thereof, and
*  its supporting documentation for any purpose whatsoever, provided
*  that this entire notice appears in all copies of the software,
*  derivative works and supporting documentation.  Further, the user
*  agrees to credit NOAA/PMEL/TMAP in any publications that result from
*  the use of this software or in any product that includes this
*  software. The names TMAP, NOAA and/or PMEL, however, may not be used
*  in any advertising or publicity to endorse or promote any products
*  or commercial entity unless specific written permission is obtained
*  from NOAA/PMEL/TMAP. The user also understands that NOAA/PMEL/TMAP
*  is not obligated to provide the user with any support, consulting,
*  training or assistance of any kind with regard to the use, operation
*  and performance of this software nor to provide the user with any
*  updates, revisions, new versions or "bug fixes".
*
*  THIS SOFTWARE IS PROVIDED BY NOAA/PMEL/TMAP "AS IS" AND ANY EXPRESS
*  OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
*  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
*  ARE DISCLAIMED. IN NO EVENT SHALL NOAA/PMEL/TMAP BE LIABLE FOR ANY SPECIAL,
*  INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER
*  RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF
*  CONTRACT, NEGLIGENCE OR OTHER TORTUOUS ACTION, ARISING OUT OF OR IN
*  CONNECTION WITH THE ACCESS, USE OR PERFORMANCE OF THIS SOFTWARE. 
*
*
* 	Using data values from src organized on grid src_grd, interpolate to
* 	values dst on grid dst_grd.

* 	msrc and mdst point to data structures in COMMON/XVARIABLES/ which
* 	specify the subscript bounds of src and dst within their respective
* 	grids.

* 	Both src and dst are assumed to be 4 dimensional structures
*	with regridding needed along axis "axis"

*	ss12 holds the indices of nearest grid nodes on src_grd for nodes
*	on dst_grd. COEF holds the interpolation coefficients.

*	The interpolation algorithm is taken from Numerical Recipes, Chapter 3,
*	Section "Interpolation in Two or More Dimensions"

* 	programmer - Jerry Davison
* 	NOAA/PMEL,Seattle,WA - Tropical Modeling and Analysis Program
* 	written for VAX computer under VMS operating system
* 	revision 1.0 - 5.2.88
* V205:   8/3/89 - major re-write (regrid along 1 axis only of 4D structure)
*	10/11/89 - modified array declarations using XMEM_SUBSC.CMN
* v570 *acm* 5/04 Range of subscripts might be negative, and contain 
*                 -111 among them. Allow regridding, using the flag 
*                 ok_neg111 to distinguish this case from the flag 
*                 unspecified_int4.
* v580 *acm* 11/04 Fix the definition of ok_neg111; if -111 is at
*                  either end of the interval we cannot distinguish
*                  it as a valid index from its use as the bad flag.
* V68  *acm* 1/12  changes for double-precision ferret.
*        2/12 *kms* Add E and F dimensions (use nferdims in tmap_dims.parm)

        IMPLICIT NONE
        include 'tmap_dims.parm'
	include 'ferret.parm'
	include 'xvariables.cmn'
	include	'xmem_subsc.cmn'
	include 'xcontext.cmn'

* CALLING ARGUMENT DECLARATIONS:
	INTEGER	  cx_lims, axis, dst_lo, dst_hi, msrc, mdst
	INTEGER   ss12(	dst_lo:dst_hi )
	REAL    src( m1lox:m1hix,m1loy:m1hiy,m1loz:m1hiz,
     .               m1lot:m1hit,m1loe:m1hie,m1lof:m1hif ),
     .          dst( m2lox:m2hix,m2loy:m2hiy,m2loz:m2hiz,
     .               m2lot:m2hit,m2loe:m2hie,m2lof:m2hif ),
     .		coef( dst_lo:dst_hi )

* INTERNAL VARIABLE DECLARATIONS:
        LOGICAL TM_FPEQ, OK_neg111
	INTEGER i, j, k, l, m, n,
     .		ss, src_lo, src_hi, src_grd, dst_grd
	REAL	bad_src, bad_dst, z1, z2, c1, c2

********************************************************************************

* LIMITS FOR CALCULATION
        src_lo = mr_lo_ss(msrc,axis)
        src_hi = mr_hi_ss(msrc,axis)

* FLAG FOR BAD/MISSING DATA
        bad_src = mr_bad_data(msrc)
        bad_dst = mr_bad_data(mdst)

* source and destination grids
	src_grd = mr_grid( msrc )
	dst_grd = mr_grid( mdst )

* DETERMINE (LOWER) src_grd INDEX OF NEAREST NEIGHBORS ON src_grd AXES
* FOR NODES ON dst_grd AXES, AND COMPUTE FRACTIONAL POSITIONS OF dst_grd
* NODES WITH RESPECT TO src_grd.
	CALL GET_LINEAR_COEF(	src_lo, src_hi, src_grd,
     .				dst_lo, dst_hi, dst_grd,
     .				axis, ss12, coef )

* For a modulo longitude axis, the range of subscripts might be negative, 
* and contain -111 among them. ok_neg111 distinguishes between this and 
* the flag unspecified_int4.

        ok_neg111 = (ss12(dst_lo) .LT. unspecified_int4 .AND.
     .               ss12(dst_hi) .GT. unspecified_int4) .OR.
     .              (ss12(dst_lo) .GT. unspecified_int4 .AND.
     .               ss12(dst_hi) .LT. unspecified_int4) 

* CONVERT THE DATA TO dst_grd
	IF ( axis .EQ. x_dim ) THEN
	   DO 110 i = dst_lo, dst_hi

* interpolation coefficients
	      ss = ss12(i)
	      c2 = coef(i)
	      c1 = 1.0 - c2

* special case: exact overlap of source and dest points
	      IF ( TM_FPEQ(c1, 1.0) ) THEN
	         DO 100 n = cx_lo_s6(cx_lims), cx_hi_s6(cx_lims)
	         DO 100 m = cx_lo_s5(cx_lims), cx_hi_s5(cx_lims)
	         DO 100 l = cx_lo_s4(cx_lims), cx_hi_s4(cx_lims)
	         DO 100 k = cx_lo_s3(cx_lims), cx_hi_s3(cx_lims)
	         DO 100 j = cx_lo_s2(cx_lims), cx_hi_s2(cx_lims)
 100	         dst(i,j,k,l,m,n) = src(ss,j,k,l,m,n)
	         GOTO 110
	      ELSEIF ( ss .EQ. unspecified_int4 .AND. 
     .                 .NOT. ok_neg111 ) THEN
* ... this should never happen in FERRET 2.00+
	         DO 102 n = cx_lo_s6(cx_lims), cx_hi_s6(cx_lims)
	         DO 102 m = cx_lo_s5(cx_lims), cx_hi_s5(cx_lims)
	         DO 102 l = cx_lo_s4(cx_lims), cx_hi_s4(cx_lims)
	         DO 102 k = cx_lo_s3(cx_lims), cx_hi_s3(cx_lims)
	         DO 102 j = cx_lo_s2(cx_lims), cx_hi_s2(cx_lims)
 102		 dst(i,j,k,l,m,n) = bad_dst
	         GOTO 110
	      ENDIF

* regular interpolation
	      DO 105 n = cx_lo_s6(cx_lims), cx_hi_s6(cx_lims)
	      DO 105 m = cx_lo_s5(cx_lims), cx_hi_s5(cx_lims)
	      DO 105 l = cx_lo_s4(cx_lims), cx_hi_s4(cx_lims)
	      DO 105 k = cx_lo_s3(cx_lims), cx_hi_s3(cx_lims)
	      DO 105 j = cx_lo_s2(cx_lims), cx_hi_s2(cx_lims)

* surrounding source data points
	         z1 = src(ss  ,j,k,l,m,n)
	         z2 = src(ss+1,j,k,l,m,n)

* interpolate
	         IF (z1 .EQ. bad_src .OR. z2 .EQ. bad_src ) THEN
		    dst(i,j,k,l,m,n) = bad_dst
	         ELSE
	            dst(i,j,k,l,m,n) = c1*z1 + c2*z2
	         ENDIF

 105	      CONTINUE
 110	   CONTINUE

	ELSEIF ( axis .EQ. y_dim ) THEN
	   DO 210 j = dst_lo, dst_hi

* interpolation coefficients
	      ss = ss12(j)
	      c2 = coef(j)
	      c1 = 1.0 - c2

* special case: exact overlap of source and dest points
	      IF ( TM_FPEQ(c1, 1.0) ) THEN
	         DO 200 n = cx_lo_s6(cx_lims), cx_hi_s6(cx_lims)
	         DO 200 m = cx_lo_s5(cx_lims), cx_hi_s5(cx_lims)
	         DO 200 l = cx_lo_s4(cx_lims), cx_hi_s4(cx_lims)
	         DO 200 k = cx_lo_s3(cx_lims), cx_hi_s3(cx_lims)
	         DO 200 i = cx_lo_s1(cx_lims), cx_hi_s1(cx_lims)
 200	         dst(i,j,k,l,m,n) = src(i,ss,k,l,m,n)
	         GOTO 210
	      ELSEIF ( ss .EQ. unspecified_int4 .AND. 
     .                 .NOT. ok_neg111 ) THEN
* ... this should never happen in FERRET 2.00+
	         DO 202 n = cx_lo_s6(cx_lims), cx_hi_s6(cx_lims)
	         DO 202 m = cx_lo_s5(cx_lims), cx_hi_s5(cx_lims)
	         DO 202 l = cx_lo_s4(cx_lims), cx_hi_s4(cx_lims)
	         DO 202 k = cx_lo_s3(cx_lims), cx_hi_s3(cx_lims)
	         DO 202 i = cx_lo_s1(cx_lims), cx_hi_s1(cx_lims)
 202		 dst(i,j,k,l,m,n) = bad_dst
	         GOTO 210
	      ENDIF

* regular interpolation
	      DO 205 n = cx_lo_s6(cx_lims), cx_hi_s6(cx_lims)
	      DO 205 m = cx_lo_s5(cx_lims), cx_hi_s5(cx_lims)
	      DO 205 l = cx_lo_s4(cx_lims), cx_hi_s4(cx_lims)
	      DO 205 k = cx_lo_s3(cx_lims), cx_hi_s3(cx_lims)
	      DO 205 i = cx_lo_s1(cx_lims), cx_hi_s1(cx_lims)

* surrounding source data points
	         z1 = src(i,ss  ,k,l,m,n)
	         z2 = src(i,ss+1,k,l,m,n)

* interpolate
	         IF (z1 .EQ. bad_src .OR. z2 .EQ. bad_src ) THEN
		    dst(i,j,k,l,m,n) = bad_dst
	         ELSE
	            dst(i,j,k,l,m,n) = c1*z1 + c2*z2
	         ENDIF

 205	      CONTINUE
 210	   CONTINUE

	ELSEIF ( axis .EQ. z_dim ) THEN
	   DO 310 k = dst_lo, dst_hi

* interpolation coefficients
	      ss = ss12(k)
	      c2 = coef(k)
	      c1 = 1.0 - c2

* special case: exact overlap of source and dest points
	      IF ( TM_FPEQ(c1, 1.0) ) THEN
	         DO 300 n = cx_lo_s6(cx_lims), cx_hi_s6(cx_lims)
	         DO 300 m = cx_lo_s5(cx_lims), cx_hi_s5(cx_lims)
	         DO 300 l = cx_lo_s4(cx_lims), cx_hi_s4(cx_lims)
	         DO 300 j = cx_lo_s2(cx_lims), cx_hi_s2(cx_lims)
	         DO 300 i = cx_lo_s1(cx_lims), cx_hi_s1(cx_lims)
 300	         dst(i,j,k,l,m,n) = src(i,j,ss,l,m,n)
	         GOTO 310
	      ELSEIF ( ss .EQ. unspecified_int4 .AND. 
     .                 .NOT. ok_neg111 ) THEN
* ... this should never happen in FERRET 2.00+
	         DO 302 n = cx_lo_s6(cx_lims), cx_hi_s6(cx_lims)
	         DO 302 m = cx_lo_s5(cx_lims), cx_hi_s5(cx_lims)
	         DO 302 l = cx_lo_s4(cx_lims), cx_hi_s4(cx_lims)
	         DO 302 j = cx_lo_s2(cx_lims), cx_hi_s2(cx_lims)
	         DO 302 i = cx_lo_s1(cx_lims), cx_hi_s1(cx_lims)
 302		 dst(i,j,k,l,m,n) = bad_dst
	         GOTO 310
	      ENDIF

* regular interpolation
	      DO 305 n = cx_lo_s6(cx_lims), cx_hi_s6(cx_lims)
	      DO 305 m = cx_lo_s5(cx_lims), cx_hi_s5(cx_lims)
	      DO 305 l = cx_lo_s4(cx_lims), cx_hi_s4(cx_lims)
	      DO 305 j = cx_lo_s2(cx_lims), cx_hi_s2(cx_lims)
	      DO 305 i = cx_lo_s1(cx_lims), cx_hi_s1(cx_lims)

* surrounding source data points
	         z1 = src(i,j,ss  ,l,m,n)
	         z2 = src(i,j,ss+1,l,m,n)

* interpolate
	         IF (z1 .EQ. bad_src .OR. z2 .EQ. bad_src ) THEN
		    dst(i,j,k,l,m,n) = bad_dst
	         ELSE
	            dst(i,j,k,l,m,n) = c1*z1 + c2*z2
	         ENDIF

 305	      CONTINUE
 310	   CONTINUE

	ELSEIF ( axis .EQ. t_dim ) THEN
	   DO 410 l = dst_lo, dst_hi

* interpolation coefficients
	      ss = ss12(l)
	      c2 = coef(l)
	      c1 = 1.0 - c2

* special case: exact overlap of source and dest points
	      IF ( TM_FPEQ(c1, 1.0) ) THEN
	         DO 400 n = cx_lo_s6(cx_lims), cx_hi_s6(cx_lims)
	         DO 400 m = cx_lo_s5(cx_lims), cx_hi_s5(cx_lims)
	         DO 400 k = cx_lo_s3(cx_lims), cx_hi_s3(cx_lims)
	         DO 400 j = cx_lo_s2(cx_lims), cx_hi_s2(cx_lims)
	         DO 400 i = cx_lo_s1(cx_lims), cx_hi_s1(cx_lims)
 400	         dst(i,j,k,l,m,n) = src(i,j,k,ss,m,n)
	         GOTO 410
	      ELSEIF ( ss .EQ. unspecified_int4 .AND. 
     .                 .NOT. ok_neg111 ) THEN
* ... this should never happen in FERRET 2.00+
	         DO 402 n = cx_lo_s6(cx_lims), cx_hi_s6(cx_lims)
	         DO 402 m = cx_lo_s5(cx_lims), cx_hi_s5(cx_lims)
	         DO 402 k = cx_lo_s3(cx_lims), cx_hi_s3(cx_lims)
	         DO 402 j = cx_lo_s2(cx_lims), cx_hi_s2(cx_lims)
	         DO 402 i = cx_lo_s1(cx_lims), cx_hi_s1(cx_lims)
 402		 dst(i,j,k,l,m,n) = bad_dst
	         GOTO 410
	      ENDIF

* regular interpolation
	      DO 405 n = cx_lo_s6(cx_lims), cx_hi_s6(cx_lims)
	      DO 405 m = cx_lo_s5(cx_lims), cx_hi_s5(cx_lims)
	      DO 405 k = cx_lo_s3(cx_lims), cx_hi_s3(cx_lims)
	      DO 405 j = cx_lo_s2(cx_lims), cx_hi_s2(cx_lims)
	      DO 405 i = cx_lo_s1(cx_lims), cx_hi_s1(cx_lims)

* surrounding source data points
	         z1 = src(i,j,k,ss,  m,n)
	         z2 = src(i,j,k,ss+1,m,n)

* interpolate
	         IF (z1 .EQ. bad_src .OR. z2 .EQ. bad_src ) THEN
		    dst(i,j,k,l,m,n) = bad_dst
	         ELSE
	            dst(i,j,k,l,m,n) = c1*z1 + c2*z2
	         ENDIF

 405	      CONTINUE
 410	   CONTINUE

	ELSEIF ( axis .EQ. e_dim ) THEN
	   DO 510 m = dst_lo, dst_hi

* interpolation coefficients
	      ss = ss12(m)
	      c2 = coef(m)
	      c1 = 1.0 - c2

* special case: exact overlap of source and dest points
	      IF ( TM_FPEQ(c1, 1.0) ) THEN
	         DO 500 n = cx_lo_s6(cx_lims), cx_hi_s6(cx_lims)
	         DO 500 l = cx_lo_s4(cx_lims), cx_hi_s4(cx_lims)
	         DO 500 k = cx_lo_s3(cx_lims), cx_hi_s3(cx_lims)
	         DO 500 j = cx_lo_s2(cx_lims), cx_hi_s2(cx_lims)
	         DO 500 i = cx_lo_s1(cx_lims), cx_hi_s1(cx_lims)
 500	         dst(i,j,k,l,m,n) = src(i,j,k,l,ss,n)
	         GOTO 510
	      ELSEIF ( ss .EQ. unspecified_int4 .AND. 
     .                 .NOT. ok_neg111 ) THEN
* ... this should never happen in FERRET 2.00+
	         DO 502 n = cx_lo_s6(cx_lims), cx_hi_s6(cx_lims)
	         DO 502 l = cx_lo_s4(cx_lims), cx_hi_s4(cx_lims)
	         DO 502 k = cx_lo_s3(cx_lims), cx_hi_s3(cx_lims)
	         DO 502 j = cx_lo_s2(cx_lims), cx_hi_s2(cx_lims)
	         DO 502 i = cx_lo_s1(cx_lims), cx_hi_s1(cx_lims)
 502		 dst(i,j,k,l,m,n) = bad_dst
	         GOTO 510
	      ENDIF

* regular interpolation
	      DO 505 n = cx_lo_s6(cx_lims), cx_hi_s6(cx_lims)
	      DO 505 l = cx_lo_s4(cx_lims), cx_hi_s4(cx_lims)
	      DO 505 k = cx_lo_s3(cx_lims), cx_hi_s3(cx_lims)
	      DO 505 j = cx_lo_s2(cx_lims), cx_hi_s2(cx_lims)
	      DO 505 i = cx_lo_s1(cx_lims), cx_hi_s1(cx_lims)

* surrounding source data points
	         z1 = src(i,j,k,l,ss  ,n)
	         z2 = src(i,j,k,l,ss+1,n)

* interpolate
	         IF (z1 .EQ. bad_src .OR. z2 .EQ. bad_src ) THEN
		    dst(i,j,k,l,m,n) = bad_dst
	         ELSE
	            dst(i,j,k,l,m,n) = c1*z1 + c2*z2
	         ENDIF

 505	      CONTINUE
 510	   CONTINUE

	ELSEIF ( axis .EQ. f_dim ) THEN
	   DO 610 n = dst_lo, dst_hi

* interpolation coefficients
	      ss = ss12(n)
	      c2 = coef(n)
	      c1 = 1.0 - c2

* special case: exact overlap of source and dest points
	      IF ( TM_FPEQ(c1, 1.0) ) THEN
	         DO 600 m = cx_lo_s5(cx_lims), cx_hi_s5(cx_lims)
	         DO 600 l = cx_lo_s4(cx_lims), cx_hi_s4(cx_lims)
	         DO 600 k = cx_lo_s3(cx_lims), cx_hi_s3(cx_lims)
	         DO 600 j = cx_lo_s2(cx_lims), cx_hi_s2(cx_lims)
	         DO 600 i = cx_lo_s1(cx_lims), cx_hi_s1(cx_lims)
 600	         dst(i,j,k,l,m,n) = src(i,j,k,l,m,ss)
	         GOTO 610
	      ELSEIF ( ss .EQ. unspecified_int4 .AND. 
     .                 .NOT. ok_neg111 ) THEN
* ... this should never happen in FERRET 2.00+
	         DO 602 m = cx_lo_s5(cx_lims), cx_hi_s5(cx_lims)
	         DO 602 l = cx_lo_s4(cx_lims), cx_hi_s4(cx_lims)
	         DO 602 k = cx_lo_s3(cx_lims), cx_hi_s3(cx_lims)
	         DO 602 j = cx_lo_s2(cx_lims), cx_hi_s2(cx_lims)
	         DO 602 i = cx_lo_s1(cx_lims), cx_hi_s1(cx_lims)
 602		 dst(i,j,k,l,m,n) = bad_dst
	         GOTO 610
	      ENDIF

* regular interpolation
	      DO 605 m = cx_lo_s5(cx_lims), cx_hi_s5(cx_lims)
	      DO 605 l = cx_lo_s4(cx_lims), cx_hi_s4(cx_lims)
	      DO 605 k = cx_lo_s3(cx_lims), cx_hi_s3(cx_lims)
	      DO 605 j = cx_lo_s2(cx_lims), cx_hi_s2(cx_lims)
	      DO 605 i = cx_lo_s1(cx_lims), cx_hi_s1(cx_lims)

* surrounding source data points
	         z1 = src(i,j,k,l,m,ss  )
	         z2 = src(i,j,k,l,m,ss+1)

* interpolate
	         IF (z1 .EQ. bad_src .OR. z2 .EQ. bad_src ) THEN
		    dst(i,j,k,l,m,n) = bad_dst
	         ELSE
	            dst(i,j,k,l,m,n) = c1*z1 + c2*z2
	         ENDIF

 605	      CONTINUE
 610	   CONTINUE

	ENDIF

	RETURN
	END
