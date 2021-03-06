	SUBROUTINE SETUP_COLOR_TABLE (zwsid,ndx_lo,range)
*
*  This software was developed by the Thermal Modeling and Analysis
*  Project(TMAP) of the National Oceanographic and Atmospheric
*  Administration's (NOAA) Pacific Marine Environmental Lab(PMEL),
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
*	Sets the color map between ndx_lo and ndx_hi -- GKS FORTRAN binding
*	J Davison JISAO/PMEL/TMAP 4.29.88/6.15.88

*	Completely rewritten J Davison 7.27.89
*	Mod JD 4.18.90 allowing only one shade level
*       Mod JD 10.98 setup by percent, by_value, or by_level
* V63  *acm* 10/09 Changes for gfortran build
* PyFr *kms* 5/13 Add alpha channel (opaque)

        IMPLICIT NONE
        include         'parampl5_dat.decl'
        include         'PARAMPL5.DAT'
        include         'shade_vars.cmn'
        include         'cont_inc.decl'
        include         'CONT.INC'

	integer	zwsid,ndx_lo,range,ndx,t_cl,cl_0
	integer	ndx_hi,ndx_lop1,ndx_him1

 	real	del_lvl,lvl
	real	r_inc,g_inc,b_inc,a_inc,r_val,g_val,b_val,a_val

******************************************************************************
	
	if (rgb_mapping .eq. percent) then
*          SMOOTHLY INTERPOLATE COLORS TO RANGE
	   ndx_hi       = ndx_lo + range - 1
	   ndx_lop1	= ndx_lo + 1
	   ndx_him1	= ndx_hi - 1

	   if (range .eq. 2) goto 100
	   if (range .le. 1) goto 101
	   cl_0	        = 1
	   lvl	        = 0.0
	   del_lvl	= 100.0/real (range - 1)

*	   SET ALL COLORS IN SPECTRUM EXCEPT FIRST AND LAST

	   do 50 ndx = ndx_lop1,ndx_him1
	      lvl = lvl + del_lvl
	   
*	      LOCATE THIS LEVEL IN THE SPECIFIED SPECTRUM LEVELS
	      do 10 t_cl = cl_0,ncl-1
		 if (lvl .lt. slvl(t_cl+1)) then
		    cl_0 = t_cl
		    goto 20
		 end if
 10	      end do

*             FIND THE R,G,B,A VALUES TO SET THIS LEVEL
 20	      r_inc	= (sr(cl_0+1) - sr(cl_0))/(slvl(cl_0+1) - slvl(cl_0))
	      g_inc	= (sg(cl_0+1) - sg(cl_0))/(slvl(cl_0+1) - slvl(cl_0))
	      b_inc	= (sb(cl_0+1) - sb(cl_0))/(slvl(cl_0+1) - slvl(cl_0))
	      a_inc	= (sa(cl_0+1) - sa(cl_0))/(slvl(cl_0+1) - slvl(cl_0))
	      
	      r_val	= sr(cl_0) + r_inc*(lvl - slvl(cl_0))
	      g_val	= sg(cl_0) + g_inc*(lvl - slvl(cl_0))
	      b_val	= sb(cl_0) + b_inc*(lvl - slvl(cl_0))
	      a_val	= sa(cl_0) + a_inc*(lvl - slvl(cl_0))

*             NOW SET THE COLOR OF THIS INDEX/LEVEL
              IF ( overriding_alpha .GE. 0.0 ) a_val = overriding_alpha
	      call FGD_GSCR(zwsid,ndx,r_val,g_val,b_val,a_val)
 50	   end do

*	   SET R,G,B,A FOR FIRST AND LAST LEVELS
 100       IF ( overriding_alpha .GE. 0.0 ) THEN
              call FGD_GSCR(zwsid,ndx_hi,sr(ncl),sg(ncl),sb(ncl),overriding_alpha)
           ELSE
              call FGD_GSCR(zwsid,ndx_hi,sr(ncl),sg(ncl),sb(ncl),sa(ncl))
           ENDIF
 101       IF ( overriding_alpha .GE. 0.0 ) THEN
              call FGD_GSCR(zwsid,ndx_lo,sr(1),sg(1),sb(1),overriding_alpha)
           ELSE
              call FGD_GSCR(zwsid,ndx_lo,sr(1),sg(1),sb(1),sa(1))
           ENDIF

	else if (rgb_mapping .eq. by_value) then
	   if (ncl .eq. 0) then
	      ncl = 2
	      slvl(1) = zlev(1)
	      slvl(2) = zlev(nlev2)
	   end if

*          SMOOTHLY INTERPOLATE COLORS TO RANGE
	   ndx_hi       = ndx_lo + range - 1
	   ndx_lop1	= ndx_lo + 1
	   ndx_him1	= ndx_hi - 1

	   if (range .eq. 2) goto 200
	   if (range .le. 1) goto 201
	   cl_0	        = 1

*	   SET ALL COLORS IN SPECTRUM EXCEPT FIRST AND LAST
	   do 150 ndx = ndx_lo,ndx_hi
	      lvl = zlev(ndx - ndx_lo + 1)
	   
*	      LOCATE THIS LEVEL IN THE SPECIFIED SPECTRUM LEVELS
	      if (lvl .lt. slvl(1)) then
                 IF ( overriding_alpha .GE. 0.0 ) THEN
                    call FGD_GSCR(zwsid,ndx,sr(1),sg(1),sb(1),overriding_alpha)
                 ELSE
                    call FGD_GSCR(zwsid,ndx,sr(1),sg(1),sb(1),sa(1))
                 ENDIF
	      else if  (lvl .ge. slvl(ncl)) then
                 IF ( overriding_alpha .GE. 0.0 ) THEN
                    call FGD_GSCR(zwsid,ndx,sr(ncl),sg(ncl),sb(ncl),overriding_alpha)
                 ELSE
                    call FGD_GSCR(zwsid,ndx,sr(ncl),sg(ncl),sb(ncl),sa(ncl))
                 ENDIF
	      else
		 do 110 t_cl = cl_0,ncl-1
		    if (lvl .lt. slvl(t_cl+1)) then
		       cl_0 = t_cl
		       goto 120
		    end if
 110		 end do

*                FIND THE R,G,B VALUES TO SET THIS LEVEL
 120		 r_inc	= (sr(cl_0+1) - sr(cl_0))
     .  	      /(slvl(cl_0+1) - slvl(cl_0))

		 g_inc	= (sg(cl_0+1) - sg(cl_0))
     .  	      /(slvl(cl_0+1) - slvl(cl_0))

		 b_inc	= (sb(cl_0+1) - sb(cl_0))
     .  	      /(slvl(cl_0+1) - slvl(cl_0))
		 
		 a_inc	= (sa(cl_0+1) - sa(cl_0))
     .  	      /(slvl(cl_0+1) - slvl(cl_0))
		 
		 r_val	= sr(cl_0) + r_inc*(lvl - slvl(cl_0))
		 g_val	= sg(cl_0) + g_inc*(lvl - slvl(cl_0))
		 b_val	= sb(cl_0) + b_inc*(lvl - slvl(cl_0))
		 a_val	= sa(cl_0) + a_inc*(lvl - slvl(cl_0))

*                NOW SET THE COLOR OF THIS INDEX/LEVEL
                 IF ( overriding_alpha .GE. 0.0 ) a_val = overriding_alpha
		 call FGD_GSCR(zwsid,ndx,r_val,g_val,b_val,a_val)
	      end if
 150	   end do

	   goto 2000

*	   SET R,G,B FOR FIRST AND LAST LEVELS
 200       IF ( overriding_alpha .GE. 0.0 ) THEN
              call FGD_GSCR(zwsid,ndx_hi,sr(ncl),sg(ncl),sb(ncl),overriding_alpha)
           ELSE
              call FGD_GSCR(zwsid,ndx_hi,sr(ncl),sg(ncl),sb(ncl),sa(ncl))
           ENDIF
 201       IF ( overriding_alpha .GE. 0.0 ) THEN
              call FGD_GSCR(zwsid,ndx_lo,sr(1),sg(1),sb(1),overriding_alpha)
           ELSE
              call FGD_GSCR(zwsid,ndx_lo,sr(1),sg(1),sb(1),sa(1))
           ENDIF

	else if (rgb_mapping .eq. by_level) then
*	   ATOMIC COLORS -- AS MANY COLORS AS SET IN COLOR PALETTE
	   do 1000 ndx = ndx_lo, ndx_lo + ncl - 1
	      r_val = sr(ndx - ndx_lo + 1)    
	      g_val = sg(ndx - ndx_lo + 1)    
	      b_val = sb(ndx - ndx_lo + 1)    
	      a_val = sa(ndx - ndx_lo + 1)    

              IF ( overriding_alpha .GE. 0.0 ) a_val = overriding_alpha
	      call FGD_GSCR(zwsid,ndx,r_val,g_val,b_val,a_val)
 1000	   end do
	end if

 2000	return
	end
