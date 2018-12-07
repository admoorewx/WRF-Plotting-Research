#!/bin/sh

cat << arpsin | sed -e 's/ *$//' > /home/admoore/arpsplt.arpsin

!
!     ##################################################################
!     ##################################################################
!     ######                                                      ######
!     ######      INPUT FILE FOR ARPSPLT IN NAMELIST FORMAT       ######
!     ######                (ARPS Package 5.3)                    ######
!     ######                                                      ######
!     ######                     Developed by                     ######
!     ######     Center for Analysis and Prediction of Storms     ######
!     ######                University of Oklahoma                ######
!     ######                                                      ######
!     ##################################################################
!     ##################################################################
!
!-----------------------------------------------------------------------
!
!  This file contains the control parameters for ARPSPLT in the NAMELIST
!  format. ARPSPLT is a graphical post-processing program for ARPS.
!
!  Note that only lines between &NAMELIST_NAME and / are read as the
!  input data, and there must be a blank space in front of the '&' sign.
!  Comments can be written between these data blocks. We are using '!'
!  in the first column of comment line only to distinguish them from the
!  data statement.
!
!-----------------------------------------------------------------------
!
!   Author:
!     Ming Xue (8/31/1994)
!
!   Modification history:
!     see src/arpsplt/HISTORY.
!
*-----------------------------------------------------------------------
!
!  Message passing namelist
!
!  nproc_x     : processor number in X direction
!  nproc_y     : processor number in Y direction
!  max_fopen   : Maximum number of files allowed open when reading or
!                writing, a number smaller than the number of processors
!                can be used if dictated by the computing platform.
!                When readsplit = 1, max_fopen will be reset to
!                nproc_x*nproc_y in the code.
!  nproc_node  : Specify processes number allocated in one node. This option
!                will ensure only one process doing I/O per node. If you
!                do not know how the processes will be allocated, let it be 0.
!
!    NOTE:   case 1: nprocx_in >= nproc_x OR nprocy_in >= nproc_y
!               case 1.a  nproc_node = 0 or 1,  max_fopen will be used.
!               case 1.b  nproc_node > 1, max_fopen will be ignored.
!                  The program will set max_fopen = nproc_x*nproc_y
!
!            case 2: nprocx_in = 1 AND nprocy_in =1, both max_fopen &
!                    nproc_node are ignored. The program will set
!                    max_fopen = nproc_x*nproc_y and nproc_node = 1.
!
!  NOTE: Parameter nprocx_in and nprocy_in play an role even in no-mpi mode.
!
!  nprocx_in : Number patches of the data files to be read.
!              It can be 1 or equals to nproc_x or is a multiple of nproc_x.
!
!  nprocy_in : Same as nprocx_in but in Y direction. It must be either 1 or
!              a multiple of nproc_y
!
!  nprocx_lw  The patch number of the most western patch for the subdomain
!             to be plotted. If the whole domain from a specific run
!             will be handled, nprocx_lw shoud be 1.
!
!  nprocy_lw  The patch number of the lowest patch for the subdomain
!             to be plotted. If the whole domain from a specific run
!             will be used, nprocy_lw should be 1.
!
!----------------------------------------------------------------------=*

 &message_passing
   nproc_x = 1,
   nproc_y = 1,
   max_fopen  = 8,
   nproc_node = 3,

   nprocx_in = 1,
   nprocy_in = 1,
   nprocx_lw = 1,
   nprocy_lw = 1,
 /

*-----------------------------------------------------------------------
!
!  This namelist block sets the input history data format and
!  history data files.
!
!  hinfmt  History data dump format option. The available options are:
!          = 0, no data dump is produced;
!          = 1, unformatted binary data dump;
!          = 2, formatted ascii data dump;
!          = 3, NCSA HDF4 format data dump;
!          = 4, Packed binary data dump;
!          = 5, dump for Savi3D visualization package;
!          = 6, binary allowing data point skip;
!          = 7, NetCDF format;
!          = 8, NetCDF format (Multiple time levels in one file);
!          = 9, GrADS data dump;
!          = 10, GRIB data dump.
!          = 11, Vis5D data dump.
!
!  hdmpinopt = Indicate the way history data files are specified.
!            = 1, Data are at a constant time interval given start and
!                 end times.  The files names are constucted using ARPS
!                 history data naming convention given file header
!                 (runname plus directory name in arps).
!            = 2, Data files are explicitly listed.
!
!  hdmpfheader  History data file name header (not including '.' at the end),
!               corresponding to runname plus directory name.
!               e.g., hdmpfheader='./may20'.  (For hdmpinopt=1.)
!
!  hdmpftrailer Whatever character string following the time in the history
!               file name. Usually it is for version number, grid number etc.
!               E.g., hdmpftrailer='.g01.01'. If none, set to ''.
!               Note: DO NOT include '.gz' associated with file compression.
!               (For hdmpinopt=1.)
!
!  tintvdmpin  Time interval between history data dumps used (hdmpinopt=1).
!  tbgndmpin   Time at which input history data begins (hdmpinopt=1).
!  tenddmpin   Time at which input history data ends (hdmpinopt=1).
!
!  grdbasfn    Name of base-state and grid data file (hdmpinopt=2).
!  nhisfile    Number of history files to be processed (hdmpinopt=2).
!  hisfile(i)  History data files to be processed (hdmpinopt=2).
!
!  Note: Domain dimensions nx, ny and nz are obtained from file grdbasfn.
!
!----------------------------------------------------------------------=*
!
 &history_data
   hinfmt = 3,
   hdmpinopt    = 2,

     hdmpfheader = '/scratch/admoore/arps5.4.23/run/out/May092016NR',
     hdmpftrailer= '',
     tintv_dmpin = 0.0,
     tbgn_dmpin  = 10.0,
     tend_dmpin  = 10.0,

!     grdbasfn = 'may20.hdfgrdbas',
     grdbasfn = '/scratch/admoore/arps5.4.23/run/out/May092016NR.hdfgrdbas',
     nhisfile = 1,
     hisfile(1) = '/scratch/admoore/arps5.4.23/run/out/May092016NR.hdf0${seconds}',
     hisfile(2) = 'may20.hdf003600',
     hisfile(3) = 'may20.hdf007200',
 /
!
*-----------------------------------------------------------------------
!
!  Layout options
!
!  layout  Page orientation
!        = 1, portrait (vertical)
!        = 2, landscape (horizontal)
!
!  Vertical length of paper (plotting space) with the width being 1.0
!  Only useful for PS version of ZXPLOT. The NCAR graphics plotting
!  space is always 1x1.
!
!  nxpic  Number of columns plotted on each page
!  nypic  Number of rows plotted on each page
!
!  inwfrm  Option to begin a new page for each history file
!        = 0, mixed data times may appear on a page
!        = 1, new page for each history file
!
!----------------------------------------------------------------------=*
!
 &page_setup
   layout = 1,
   paprlnth = 1.5,
   nxpic  = 1,
   nypic  = 1,
   inwfrm = 1,
 /
!
*-----------------------------------------------------------------------
!
!  iorig  Option to reset x-y origin of physical domain.
!       = 0, default, use original coordinates stored in x and y in history file.
!       = 1, grid origin is reset by adding xgrdorg (m) and ygrdorg (m) stored in the
!            history data to the x and y coordinates.
!       = 2, grid origin is changed by setting 
!              x(i) = x(i)- (x(2)+xgrdorg)+ xorig*1000
!              y(j) = y(j)- (y(2)+ygrdorg)+ yorig*1000
!            where x and y are the coordinate arrays as defined inside ARPS 
!            and  xorig and yorig are given below in km.
!       = 3, grid origin is reset by adding xorig and yorig (km) specified
!            below to the x and y coordinates.
!
!  xorig,yorig  Coordinate origin of the model physical domain (km)
!               Used when iorig=2 or 3.
!
!  xbgn, xend  Plotting domain bounds in x direction (km)
!              IF both are zero, entire domain in this direction is plotted.
!  ybgn, yend  Plotting domain bounds in y direction (km)
!  zbgn, zend  Plotting domain bounds in z direction (km)
!  zsoilbgn, zsoilend
!              Plotting domain bounds in z direction (m) for the soil model
!              Note: zsoilbgn and zsoilend measure the distance
!                    of a soil model level from the ground surface.
!                    Both of them are negative, and
!                    zsoilbgn is closer to the ground surface and therefore
!                    should be greater than zsoilend.
!
!  yxstrch      Stretching factor for x-y plots
!  zxstrch      Stretching factor for x-z plots
!  zystrch      Stretching factor for y-z plots
!  zhstrch      Stretching factor for arbitrary vertical slices.
!               Note: if 0.0 is specified, the plotting will be squared.
!
!  lblmag       Global magnification factor for labels (1.0 by default).
!  lnmag        Global line width magnification factor. Currently
!               effective for the PS version only.
!
!  winsiz       Global plotting window magnification factor (1.0 by default).
!  margnx       X-axis margin of picture space. (0.1 by default).
!  margny       Y-axis margin of picture space. (0.1 by default).
!               (If color bar is horizontal, use margny=0.15.)
!  pcolbar      Position of color bar.
!               1 (default) - horizontal
!               2 - vertical
!
!  iskip,jskip  The grid points to be skipped when plotting. For example,
!               for every other points, iskip = 1, jskip = 1. The default (0)
!               skips nothing.
!
!               Notes:
!                 1. Vector plots use different stride values, see istride, jstride below,
!                 2. in MPI mode, the skipped grid is based on local grid. So it
!                    may plot different data points as serial run or a run with
!                    different processor configuration.
!
!---------------------------------------------------------------------=*
!
 &plotting_setup
   iorig   = 0,
     xorig   = 0.0,
     yorig   = 0.0,
   xbgn     = 0.0,  xend     = 0.0,
   ybgn     = 0.0,  yend     = 0.0,
   zbgn     = 0.0,  zend     = 0.0,
   zsoilbgn = 0.0,  zsoilend = 0.0,
   iskip    = 0,    jskip = 0,

   yxstrch = 1.0,
   zxstrch = 0.0,
   zystrch = 3.0,
   zhstrch = 4.0,

   margnx  = 0.15,
   margny  = 0.15,

   winsiz  = 1.0,

   pcolbar = 2,
 /

*-----------------------------------------------------------------------
!
!  col_table : Option for color map.
!        = -1, user defined color map (color_map must be defined).
!        = 0,  black and white.
!        = 1,  blue to red.
!        = 2,  red to blue (reverse blue to red).
!        = 3,  Radar reflectivity.
!        = 4,  grey (white to black).
!        = 5,  multi-spectum color table.
!        color files color_map.ps/color_map.gmeta can be found in ftp site.
!
!  color_map:  Color map filename (used only if col_table = -1)
!              The file should be in ASCII format. Each line
!              contain three real values between 0.0 and 1.0 for
!              RGB (Red, Green, and Blue), for example,
!              0.5, 0.3, 0.7
!              The first line is the background color.
!              If col_table = -1, the user defined color is not
!              enough for use, the color will repeated use.
!
!----------------------------------------------------------------------=*
!
 &col_table_cntl
   col_table = -1,
   color_map = '/scratch/admoore/arps5.4.23/data/arpsplt/hubcaps5.pltcbar',
 /
!
*-----------------------------------------------------------------------
!
!  fontopt      Character font
!               = 1 lower resolution simple character
!               = 2 higher resolution simple character
!               = 3 or 4 higher quality character
!               ( default = 2 )
!
!  lbaxis       Axis labeling (0:off, 1:on)
!
!  axlbfmt      Format of axis numerical labels.
!               -1 (default) - automatically chosen
!               0 - integer
!               >0 - number of decimals.
!  axlbsiz      Size of the axis labels as the height in terms of the
!               fraction of vertical plotting space (typically 0.025).
!
!  haxisu       Units for horizontal axis. (used only if lbaxis=1)
!               0:km, 1:mile, 2:naut mile, 3:kft
!  vaxisu       Units for vertical axis. (used only if lbaxis=1)
!               0:km, 1:mile, 2:naut mile, 3:kft
!
!  tickopt      Tick option. 0:auto, 1:user defined (see below).
!  hmintick     Horizontal minor tick interval (km) (Used only if tickopt=1.)
!  hmajtick     Horizontal major tick interval (km) (Used only if tickopt=1.)
!  vmintick     Vertical minor tick interval (km) (Used only if tickopt=1.)
!  vmajtick     Vertical major tick interval (km) (Used only if tickopt=1.)
!
!  presaxis_no  Number of levels to label on a vertical pressure axis
!		(=0: no pressure axis)
!  pres_val     Pressure levels to label on a vertical pressure axis (Used
!		only if presaxis_no >=1)
!
!  ctrlbopt     Contour labeling option
!               =0, no label
!               =1, label in real number format (default)
!               =2, label in integer format
!
!  ctrlbfrq     n, every nth contours relative to the reference contour
!               (typically zero contours) are labeled.
!
!  ctrlbsiz     Contour label size as its height in terms of the
!               fraction of vertical plotting space (typically 0.025)
!
!  ctrstyle     Contour plotting style
!               = 1, positive solid, negative dashed, zero line dotted
!               = 2, all in solid
!               = 3, all dashed
!
!  lbmaskopt    Option to mask/blank out labeled areas on contours or
!               labeled curves.
!               = 0, no. =1, yes.
!
!----------------------------------------------------------------------=*
!
 &style_tuning

   lblmag  = 1.0,
   lnmag   = 1,

   fontopt   = 2,

   lbaxis  = 1,
   axlbfmt   = 1,
   axlbsiz   = 0.025,
     haxisu  = 0,
     vaxisu  = 0,

   tickopt = 0,
     hmintick = 10.,
     hmajtick = 20.0,
     vmintick = 0.5,
     vmajtick = 1.0,

   presaxis_no = 0,
     pres_val = 1100.,850., 700.,500.,400.,300.,250.,200.,150.,100.,

   ctrlbopt  = 1,
   ctrstyle  = 1,
   ctrlbfrq  = 2,
   ctrlbsiz  = 0.02,
   lbmaskopt = 1,
 /
!
*-----------------------------------------------------------------------
!
!  smooth: Option for applying 9-point smoothing to the plotted fields.
!          = 0, no smoothing.
!          = 1, smoothing.
!
!----------------------------------------------------------------------=*
!
 &smooth_cntl
   smooth =1,
 /
!
*-----------------------------------------------------------------------
!
!  Options for plotting special titles
!
!    ntitle     Number of lines in the title (0:off, maximum 3). (Available
!		only when nxpic=nypic=1)
!    titcol     Title color.
!    title(1)   First line of the special title.
!    titsiz     Size of title text (relative to lblmag)
!
!---------------------------------------------------------------------=*
!
 &title_setup
  ntitle = 1,
  titcol = 1,
  titsiz = 2.3,
     title(1) = 'ARPS Nature Run',
     title(2) = 'The second line of the title',
     title(3) = 'The third line of the title',
 /
!
*-----------------------------------------------------------------------
!
!  Option for plotting footers
!
!    wpltime    = 1 write plotting time on lower right of plot
!               = 0 display footer_r.
!    footer_l   = Text displayed at lower left of each frame.
!                 (default is ARPS/PLOT if footer_l='')
!    footer_c   = Text displayed at lower center of each frame. (Default is
!                 "runname" if footer_c=''.)
!    footer_r   = Text displayed at lower right of each frame (if wpltime=0).
!
!---------------------------------------------------------------------=*
!
 &footer_setup
   wpltime = 1,
   footer_l   = 'ARPS/ZXPLOT ',
   footer_c   = '',
   footer_r   = '',
 /
!
*-----------------------------------------------------------------------
!
!  ovrmap  Option to overlay political map on horizontal plane plots
!                = 0, no map overlay.
!                = 1, overlay map on all of the frames.
!
!  latgrid,longrid (degrees)
!                The lat and lon intervals for grid lines in the map.
!                < -900. No grid line
!                = 0.0   Automatically determined by the program.
!                > 0.0   Interval set in degrees.
!                < 0.0   Grid lines plus axis annotation. 
!                        Grid internal is the absolute value of latgrid (and longrid).
!
!  nmapfile      Number of map data files to be plotted (maximum is 10)
!  mapfile       Mapdata file name(s).
!  mapcol        Map color index (>=1)
!  mapline_style line style of map
!                = 1 thin dashed lines
!                = 2 thin full lines
!                = 3 thick full lines
!
!---------------------------------------------------------------------=*
!
 &map_plot
   ovrmap = 1,
   latgrid = 0, longrid = 0, mapgridcol = 10,
   nmapfile = 3,
     mapfile(1) = '/scratch/admoore/arps5.4.23/data/arpsplt/world_coast.mapdata',mapcol(1)=1, mapline_style(1)=3,
     mapfile(2) = '/scratch/admoore/arps5.4.23/data/arpsplt/us_state.mapdata',   mapcol(2)=1, mapline_style(2)=3,
     mapfile(3) = '/scratch/admoore/arps5.4.23/data/arpsplt/us_spcounty.mapdata',mapcol(3)=1, mapline_style(3)=3,
 /
!
*-----------------------------------------------------------------------
!
!  missing value fill up
!  missfill-opt  fill up one color for missing value
!              = 1 color fill on missing value area
!              = 0 do not fill any color on missing value area
!
!  missval_colind the color index for fill missing value area
!
!---------------------------------------------------------------------=*
!
 &multi_setup
   missfill_opt = 0,
   missval_colind = 03,
 /
!
*-----------------------------------------------------------------------
!
!  nslice_xy  Number of x-y slices to be plotted.
!  slice_xy   k-index for x-y slice(s)
!           = -1, for center
!           = -2, through max w
!           >  0, k-index
!
!---------------------------------------------------------------------=*
!
 &xy_slice_cntl
   nslice_xy = 1,
   slice_xy =  2, -2,
 /
!
!-----------------------------------------------------------------------
!
!  nslice_xz  Number of x-z slices to be plotted.
!  slice_xz   j-index for x-z slice(s)
!           = -1, for center
!           = -2, through max w
!           >  0, j-index
!
!-----------------------------------------------------------------------
!
 &xz_slice_cntl
   nslice_xz = 0,
   slice_xz  = 220,-1, -2,
 /
!
!-----------------------------------------------------------------------
!
!  nslice_yz  Number of y-z slices to be plotted.
!  slice_yz   i-index for y-z slice(s)
!           = -1, for center
!           = -2, through max w
!           >  0, i-index
!
!-----------------------------------------------------------------------
!
 &yz_slice_cntl
   nslice_yz = 0,
   slice_yz  = -1, -1, -2,
 /
!
!-----------------------------------------------------------------------
!
!  nslice_h  Number of constant-height slices to be plotted.
!
!            IF nslice_h = -1 AND trajc_plt_opt is not 0, the number
!            of constant-height slices to be plotted will be
!            equal to the number of trajectories that will be plotted,
!            as determined by control parameters ntrajc_start,ntrajc_end,
!            and ntrajc_stride for trajectory plotting.
!            In this case, for each trajectory, the height of the slice
!            is equal to the parcel height at the time of the current
!            history data being plotted.
!
!  slice_h   Height (km MSL) of the horizontal slice(s) (repeat for > 1 slice)
!            If the specified height is negative, the slice will be at
!            the absolute value of the height in km AGL.
!            They are not used when nslice_h=-1 AND trajc_plt_opt is not 0.
!
!-----------------------------------------------------------------------
!
 &h_slice_cntl
   nslice_h  = 0,
   slice_h   = 1.0, 4.0, 8.0,
 /
!
!-----------------------------------------------------------------------
!
!  nslice_xy_soil  Number of x-y slices to be plotted for the soil model.
!  slice_xy_soil   k-index for x-y slice(s)
!           = -1, for center
!           >  0, k-index (1 .. nzsoil)
!
!-----------------------------------------------------------------------
!
 &xy_soil_slice_cntl
   nslice_xy_soil = 0,
   slice_xy_soil = 2,-1,
 /
!
!-----------------------------------------------------------------------
!
!  nslice_xz_soil  Number of x-z slices to be plotted for the soil model.
!  slice_xz_soil   j-index for x-z slice(s)
!           = -1, for center
!           >  0, j-index
!
!-----------------------------------------------------------------------
!
 &xz_soil_slice_cntl
   nslice_xz_soil = 0,
   slice_xz_soil  = 2,-1,
 /
!
!-----------------------------------------------------------------------
!
!  nslice_yz_soil  Number of y-z slices to be plotted for the soil model.
!  slice_yz_soil   i-index for y-z slice(s)
!           = -1, for center
!           >  0, i-index
!
!-----------------------------------------------------------------------
!
 &yz_soil_slice_cntl
   nslice_yz_soil = 0,
   slice_yz_soil  = 2, -1,
 /
!
!-----------------------------------------------------------------------
!
!  nslice_v  Number of arbitrary vertical slice(s) to be plotted.
!
!  xpnt1(1),ypnt1(1) Coordinates (km) of first point of first slice.
!  xpnt2(1),ypnt2(1) Coordinates (km) of second point of first slice.
!
!  Coordinates are repeated for each slice as in the following:
!   xpnt1(1),ypnt1(1),xpnt2(1),ypnt2(1),
!   xpnt1(2),ypnt1(2),xpnt2(2),ypnt2(2),
!
! NOTE: It is not recommended in MPI mode because the local arrays
!       may be too small to hold the vertical slice. The program will
!       be abort.
!
!-----------------------------------------------------------------------
!
 &v_slice_cntl
   nslice_v = 0,
   xpnt1(1) = 0.0,   xpnt1(2) = 64.0,
   ypnt1(1) = 0.0,   ypnt1(2) =  0.0,
   xpnt2(1) = 64.0,  xpnt2(2) = 0.00,
   ypnt2(1) = 64.0,  ypnt2(2) = 64.0,
 /
!
!-----------------------------------------------------------------------
!
!  nslice_p  Number of constant-pressure slices to be plotted.
!  slice_p   Pressure (mb) of the pressure slice(s) (repeat for > 1 slice)
!
!-----------------------------------------------------------------------
!
 &p_slice_cntl
   nslice_p  = 0,
   slice_p   = 500.0,700.0,500.,
 /
!
!-----------------------------------------------------------------------
!
!  nslice_pt Number of isentropic surfaces to plot.
!  slice_pt  Potential temperature of isentropic surfaces (K).
!
!  (NOT IMPLEMENTED YET).
!
!-----------------------------------------------------------------------
!
 &pt_slice_cntl
   nslice_pt = 0,
   slice_pt  = 300.0, 350.0,
 /
!
!-----------------------------------------------------------------------
!
!  imove  Option to subtract a specified constant domain translation speed
!         from the wind field
!
!        = 0, default, no domain translation
!        = 1, add domain translation speed (umove, vmove) read in from
!             this namelist file to the wind field before plotting
!        = 2, add domain translation speed (umove, vmove) storged in the
!             history data to the wind field before plotting
!
!  umove, vmove  Domain translation speed components to be added to u,v (m/s)
!         Used by option imove = 1 only.
!
!-----------------------------------------------------------------------
!
 &domain_move
   imove = 0,
   umove = 0.0, vmove = 0.0,
 /
!
!-----------------------------------------------------------------------
!
!  Control parameters for contour plotting and color-filled contouring,
!
!  Note that each block contains the options for a single variable,
!  and each variable block has the same format.
!
!  For example, for u, we have
!
!  uplot   Option for plotting variable u
!        = 0, no contour plot
!        = 1, single color plot
!        = 2, color filling
!        = 3, HDF image
!        = 4, color contour
!        = 5, color filling + contour plot
!
!  Additional options/switches for plotting u:
!
!  uinc    Contour interval
!        = 0 Contour interval will be set automatically.
!        = -9999.  Option to avoid having a small contour interval when the
!          data values are small.  Contour intervals will be set according
!          to uminc and umaxc when the real min and max are between uminc
!	   and umaxc.
!
!  uminc   Minimum contour for u.
!          = -9999.0 to set automatically.
!
!  umaxc   Maximum contour for u.
!          = -9999.0 to set automatically.
!          If both uminc=umaxc=0, they will be set automatically.
!
!  uovr    Overlay option.
!        = 0, first field on a plot
!        = 1, this field will be overlaid on the preceding field.
!
!  ucol1  Color of plotted field.
!         Color of the plotted field. (For uplot=2 or 4, the index of the
!	  first color.)
!
!  ucol2  Index of last color (uplot=2 or 4 only).
!        (When the number of colors needed is more then ucol2-ucol1+1, the
!	  color will repeat from ucol1 to ucol2.)
!
!  uprio Priority for u.
!        >=1 priority number; lower number has higher priority.
!        = 0, default.
!        (Once priority numbers are set, the order of plotting will follow
!	  the priority number beginning with 1, then plot the priority=0
!	  variable according to the order of in the program.)
!
!  uhlf  Contour highlight frequency. Every uhlf contours relative
!        to the reference contour are hightlighted with thick lines.
!        uhlf=1 means every contour is highlighted. Default: 4.
!
!  uzro  Attributes of zero contours
!        = 0, zero line are suppressed.
!        = 1, zero lines are drawn as dotted lines.
!        = 2, zero lines are drawn as dotted-dashed lines.
!        = 3 (default), zero lines are drawn as thick full lines.
!
!  Similiarly, for other variables:
!
!    hplot    - height (10m) of constant pressure or isentropic surface
!               Plot only when nslice_p>0 or nslice_pt>0.
!    thkplot  - Thickness (10m) between a given pressure level (specified
!               as slice_p) and a reference pressure level (p_ref) hpa.
!               Plot only when nslice_p>0.
!    msfplt   - Montgomery Streamfunction (10m) (for isentropic sfc plotting only)
!    tplot    - temperature
!             tunits - The unit 'F' or 'C'. F-Fahrenheit C-Celsius.
!    vplot    - total v-velocity (m/s)
!    vhplot   - horiz. wind speed (m/s)
!             vhunits- 1:m/s 2:knots 3:MPH
!    vsplot   - vertical wind shear (1/s)
!    wplot    - total w-velocity (m/s)
!    ptplot   - total potential temperature (K)
!    ipvplt   - Isentropic potential vorticity (IPV unit).
!               For isentropic sfc plotting only.
!    pplot    - total pressure (Pa)
!
!-----------------------------------------------------------------------
!
 &sclrplt_cntl1
   hplot =0, hinc =4.0, hminc = 0.0, hmaxc = 0.0, hovr=1, hhlf=1, hzro=3,
             hcol1=1,   hcol2=42,    hprio=2,
   thkplt=0, thkinc=2.0, thkminc=0.0,thkmaxc=0.0, thkovr=1, thkhlf=1,thkzro=3,
             thkcol1=1,  thkcol2=24, thkprio=2,
   msfplt=0, msfinc=0.0,msfminc=0.0, msfmaxc=0.0, msfovr=0,msfhlf=4,msfzro=3,
             msfcol1=28, msfcol2=42,  msfprio=1,
   tplot =0, tinc =50.0, tminc = 50.0, tmaxc = 99.0, tovr=1, thlf=400, tzro=2,
             tcol1=1,   tcol2=18,    tprio=3,     tunits = 'F',
   uplot =0, uinc =2.0, uminc = 0.0, umaxc = 0.0, uovr=0, uhlf=1, uzro=3,
             ucol1=3,   ucol2=24,    uprio=0,
   vplot =0, vinc =2.0, vminc = 0.0, vmaxc = 0.0, vovr=0, vhlf=4, vzro=3,
             vcol1=3,   vcol2=24,    vprio=0,
   vhplot=0, vhinc=4.0, vhminc= 0.0, vhmaxc=100.0,  vhovr=0, vhhlf=1,vhzro=3,
             vhcol1=46,  vhcol2=69,   vhprio=1,    vhunits=1,
   vsplot=0, vsinc=0.0, vsminc= 0.0, vsmaxc= 0.0, vsovr=0, vshlf=4,vszro=3,
             vscol1=3,  vscol2=24,   vsprio=0,
   wplot =0, winc =2.5, wminc = 0.0, wmaxc = 0.0, wovr=1,  whlf=4, wzro=0,
             wcol1=23,   wcol2=23,    wprio=2,
   ptplot=0, ptinc=0.0, ptminc= 0.0, ptmaxc= 0.0, ptovr=0, pthlf=4,ptzro=3,
             ptcol1=3,  ptcol2=24,   ptprio=0,
   ipvplt=0, ipvinc=1.0,ipvminc=-3.0, ipvmaxc=15.0, ipvovr=0,ipvhlf=4,ipvzro=3,
             ipvcol1=28, ipvcol2=42,  ipvprio=3,
   pplot =0, pinc =0.0, pminc = 0.0, pmaxc = 0.0, povr=0,  phlf=4, pzro=3,
             pcol1=1,   pcol2=24,    pprio=0,
 /
!
!-----------------------------------------------------------------------
!
!  Repeated as in sclrplt_cntl1 for the variables listed below:
!
!    qvplot   - total water vapor specific humidity (g/kg)
!    qscalarplot(index) - scalar microphysics array plotting
!              - depending on the microphysics scheme used
!                the value for the index will be associated with
!                a different species and/or moment.  The following
!                shows the values for the different microphysics
!                schemes currently in ARPS:
!      
!      Lin  scheme: 1=QC,2=QR,3=QI,4=QS,5=QH
!
!      WSM6 scheme: 1=QC,2=QR,3=QI,4=QS,5=QG
!
!      MY1  scheme: 1=QC,2=QR,3=QI,4=QS,5=QG,6=QH
!
!      MY2  scheme: 1=QC,2=QR,3=QI,4=QS,5=QG,6=QH
!                   7=NC,8=NR,9=NI,10=NS,11=NG,12=NH
!
!      MY3  scheme: 1=QC,2=QR,3=QI,4=QS,5=QG,6=QH
!                   7=NC,8=NR,9=NI,10=NS,11=NG,12=NH
!                       13=ZR,14=ZI,15=ZS,16=ZG,17=ZH
!
!           where Q=mixing ratio (g/kg), N=number concentration (#/m^3)
!                 Z=radar reflectivity (mm^6/m^3) - note: NOT in logarithmic units
!                 see rfplot for plotting radar reflectivity in logarithmic 
!                 units.
!                 C=cloud,R=rain,I=ice crystals,S=snow,G=graupel,H=hail
!
!    qwplot   - total water mixing ratio (g/kg)
!    qtplot   - total water mixing ratio and water vapor (g/kg)
!
!-----------------------------------------------------------------------
!
 &sclrplt_cntl2
   qvplot=0, qvinc =0.0,qvminc= 0.0, qvmaxc= 0.0, qvovr=0, qvhlf=4,qvzro=3,
             qvcol1=1,  qvcol2=24,   qvprio=0,
   qscalarplot(1)=0,qscalarinc(1)=0.0,qscalarminc(1)=0.0,qscalarmaxc(1)=0.0,
             qscalarovr(1)=1,qscalarhlf(1)=4,qscalarzro(1)=0,
             qscalarcol1(1)=1,qscalarcol2(1)=24,qscalarprio(1)=2,
   qscalarplot(2)=0,qscalarinc(2)=0.0,qscalarminc(2)=0.0,qscalarmaxc(2)=0.0,
             qscalarovr(2)=0,qscalarhlf(2)=4,qscalarzro(2)=0,
             qscalarcol1(2)=113,qscalarcol2(2)=155,qscalarprio(2)=1,
   qwplot=0, qwinc =1.0,qwminc= 0.0, qwmaxc= 0.0, qwovr=0, qwhlf=4,qwzro=3,
             qwcol1=3,  qwcol2=24,   qwprio=0,
   qtplot=0, qtinc =0.0,qtminc= 0.0, qtmaxc= 0.0, qtovr=0, qthlf=4,qtzro=3,
             qtcol1=1,  qtcol2=24,   qtprio=0,
 /
!
!-----------------------------------------------------------------------
!
!  Repeated as in sclrplt_cntl1 for the variables listed below:
!
!    kmhplt   - Horizontal turb. mixing coef. for momentum (m**2/s)
!    kmvplt   - Vertical turb. mixing coef. for momentum (m**2/s)
!    tkeplt   - Turbulent Kinetic Energy ((m/s)**2)
!    rhplot   - relative humidity (non-dimensional)
!    tdplot   - dew-point temperature
!             tdunits - 'F' or 'C'. F-Fahrenheit C-Celsius.
!
!    NOTE> polarimetric variables are available only for internal uses.
!    For external users, dualpol should be set to 0 (dualpol = 0). 
!    dualpol  - Radar reflectivity and polarimetric variables
!             = 0, Only for reflectivity (Z)
!                  Use rfopt to select reflectivity formula
!             = 1, Jung, Zhang, and Xue (MWR, 2008) (parameterized formulas)
!                  for both reflectivity and polarimetric variables
!                  DSDs assume exponetial distribution. 
!                  If DSDS are not exponential, use dualpol = 0 or 2.
!                  (Works for rfopt = 2,8,9, but *NOT FOR 11*)
!             = 2, Jung, Zhang, and Xue (JAMC, 2010) (T-matrix table)
!                  for both reflectivity and polarimetric variables
!                  (Works for rfopt = 2,8,9,11)
!                 <Note> This option is available in the assimilation system but not tested.
!             =10, the same as dualpol == 0 with attenutation (not availabl yet)
!                  (Only works for rfopt = 2)
!       rfopt   - Option for calculating reflectivity field
!               < 100 ( =mphyopt  Microphysics option. [Refer mphyopt in "arps.input"] )
!               > 100 WRF schemes (For HWT spring experiments)
!               = 101 mp_physics=1 (Kessler)
!               = 102 mp_physics=2 (Lin)
!               = 103 mp_physics=3 (WSM 3-class)
!               = 104 mp_physics=4 (WSM 5-classes)
!               = 105 mp_physics=5 (Ferrier)
!               = 106 mp_physics=6 (WSM 6-classes)
!               = 108 mp_physics=8 (Thompson)
!               > 200 To be added
!       rsadir   Directory path where the radar scattering amplitude tables
!                are stored (for dualpol = 2). (Tables are produced externally.)
!       wavelen  Wavelengh of radar in mm (WSR-88D: 107, CASA: 31.9)
!       graupel_ON  Option to indicate the presence of graupel for mphyopt = 8,9,10,11
!               = 0    No graupel is included.
!               = 1    Graupel is included.
!       hail_ON     Option to indicate the presence of hail for mphyopt = 8,9,10,11
!               = 0    No hail is included.   
!               = 1    Hail is included. 
!
!    rfplot   - Radar reflectivity (dBZ)
!    rfcplt   - composite Radar reflectivity (dBZ)
!    pteplt   - equivalent potential temperature (K)
!    zdrplt   - Differential reflectivity (dB)
!    kdpplt   = Specific differential phase (deg/km)
!    zdpplt   = Reflectivity difference (mm^6/m^3)
!    rhvplt   = Cross-correlation coefficient
!
!-----------------------------------------------------------------------
!
 &sclrplt_cntl3
   kmhplt=0, kmhinc =0.0,kmhminc=0.0,kmhmaxc=0.0, kmhovr=0, kmhhlf=4,kmhzro=3,
             kmhcol1=1,  kmhcol2=24, kmhprio=0,
   kmvplt=0, kmvinc =0.0,kmvminc=0.0,kmvmaxc=0.0, kmvovr=0, kmvhlf=4,kmvzro=3,
             kmvcol1=1,  kmvcol2=24, kmvprio=0,
   tkeplt=0, tkeinc =0.0,tkeminc=0.0,tkemaxc=0.0, tkeovr=0, tkehlf=4,tkezro=3,
             tkecol1=1,  tkecol2=24, tkeprio=0,
   rhplot=0, rhinc  =0.1,rhminc =0.0,rhmaxc =0.0, rhovr =0, rhhlf =1,rhzro=3,
             rhcol1 =1,  rhcol2 =25, rhprio =0,
   tdplot=0, tdinc  =3.0,tdminc =0.0,tdmaxc =0.0, tdovr =0, tdhlf =4,tdzro=3,
             tdcol1 =1,  tdcol2 =24, tdprio =0,   tdunits = 'C',
   dualpol = 0,
     rfopt =2,
     rsadir = '/home/yjung/arps5.3/data/scatt/S-band',
     wavelen = 107.,
     graupel_ON = 1,
     hail_ON = 1,
   rfplot=0, rfinc  =5.0,rfminc =5.0,rfmaxc =75.0, rfovr =0, rfhlf =400,rfzro=3,
             rfcol1 =28,  rfcol2 =42, rfprio =0,
   rfcplt=2, rfcinc =5.0,rfcminc=5.0,rfcmaxc=75.0,rfcovr=0, rfchlf=1,rfczro=3,
             rfccol1=3,  rfccol2=24, rfcprio=0,
   pteplt=0, pteinc =5.0,pteminc=5.0,ptemaxc=80.0,pteovr=0, ptehlf=4,ptezro=3,
             ptecol1=28, ptecol2=42, pteprio=0,
   zdrplt=0, zdrinc =0.5,zdrminc=0.0,zdrmaxc=7.0,zdrovr=0, zdrhlf=8,zdrzro=3,
             zdrcol1=4,  zdrcol2=30, zdrprio=10,
   kdpplt=0, kdpinc =0.4,kdpminc=0.0,kdpmaxc=5.0,kdpovr=0, kdphlf=400,kdpzro=3,
             kdpcol1=8,  kdpcol2=30, kdpprio=11,
   zdpplt=0, zdpinc =4.0,zdpminc=0.0,zdpmaxc=20.0,zdpovr=0, zdphlf=400,zdpzro=0,
             zdpcol1=4,  zdpcol2=30, zdpprio=8,
   rhvplt=0, rhvinc =0.01,rhvminc=0.90,rhvmaxc=1.0,rhvovr=0, rhvhlf=400,rhvzro=3,
             rhvcol1=4,  rhvcol2=30, rhvprio=12,
 /
!
!-----------------------------------------------------------------------
!
!  Repeated as in sclrplt_cntl1 for the variables listed below:
!
!    upplot   - perturbation u-velocity (m/s)
!    vpplot   - perturbation v-velocity (m/s)
!    wpplot   - perturbation w-velocity (m/s)
!    ptpplt   - perturbation potential temperature (K)
!    ppplot   - perturbation pressure (Pa)
!    qvpplt   - perturbation water vapor specific humidity (g/kg)
!    vorpplt  - vertical vorticity component (1/s)
!    divpplt  - horizontal divergence (1/s)
!    divqplt  - horizontal divergence of moisture (g/kg/s)
!
!-----------------------------------------------------------------------
!
 &sclrplt_cntl_prt1
   upplot =0, upinc =0.0, upminc =0.0, upmaxc =0.0, upovr=0, uphlf=4,upzro=3,
              upcol1=1,   upcol2=24,   upprio=0,
   vpplot =0, vpinc =0.0, vpminc =0.0, vpmaxc =0.0, vpovr=0, vphlf=4,vpzro=3,
              vpcol1=1,   vpcol2=24,   vpprio=0,
   wpplot =0, wpinc =0.0, wpminc =0.0, wpmaxc =0.0, wpovr=0, wphlf=4,wpzro=0,
              wpcol1=1,   wpcol2=24,   wpprio=0,
   ptpplt =0, ptpinc=1.0, ptpminc=-4.5, ptpmaxc=4.5, ptpovr=1,ptphlf=1,ptpzro=0,
              ptpcol1=119,  ptpcol2=128,  ptpprio=4,
   ppplot =0, ppinc =0.0, ppminc =0.0, ppmaxc =0.0, ppovr=1, pphlf=4,ppzro=3,
              ppcol1=1,   ppcol2=24,   ppprio=0,
   qvpplt =0, qvpinc=1.0, qvpminc=-4.5, qvpmaxc=4.5, qvpovr=0,qvphlf=4,qvpzro=3,
              qvpcol1=119,  qvpcol2=128,  qvpprio=0,
   vorpplt=0,vorpinc=0.0, vorpminc=0.0,vorpmaxc=0.0,vorpovr=0,vorphlf=4,vorpzro=0,
              vorpcol1=1, vorpcol2=24, vorpprio=0,
   divpplt=0,divpinc=3.0, divpminc=-12,divpmaxc=12,divpovr=0,divphlf=4,divpzro=0,
              divpcol1=1, divpcol2=24, divpprio=0,
   divqplt=0,divqinc=0.0, divqminc=0.0,divqmaxc=0.0,divqovr=0,divqhlf=4,divqzro=0,
              divqcol1=1, divqcol2=24, divqprio=0,
 /
!
!-----------------------------------------------------------------------
!
!  Repeated as in sclrplt_cntl1 for the variables listed below:
!
!    gricplt  - Richardson Number
!    avorplt  - Absolute Vorticity *1000(1/s)
!    rhiplot  - relative humidity with ice (non-dimensional)
!
!-----------------------------------------------------------------------
!

 &sclrplt_cntl_prt2
   gricplt=0,gricinc=0.0, gricminc=0.0,  gricmaxc=0.0,gricovr=0,grichlf=4,
             griczro=3,   griccol1=1,   griccol2=24, gricprio=0,
   avorplt=0,avorinc=0.0, avorminc=0.0,  avormaxc=0.0,avorovr=0,avorhlf=4,
             avorzro=3,   avorcol1=1,   avorcol2=24, avorprio=0,
   rhiplot=0,rhiinc=0.0,  rhiminc= 0.0,  rhimaxc= 0.0, rhiovr=0, rhihlf=4,
             rhizro=3,    rhicol1=1,  rhicol2=25,  rhiprio=0,
 /

!
!-----------------------------------------------------------------------
!
!  Control parameters for plotting wind vector fields.
!
!  istride, jstride, kstride  Stride for plotting wind vectors
!        = 0, automatic,
!        = other integers, vectors are plotted every
!          istride (jstride, kstride) number of grid points.
!
!  vtrplt  Option for plotting the total wind vector
!        = 0 no wind vector plot
!        = 1 wind vector plot
!
!        vtrunit Unit vector
!           = 0 automatic default
!
!        vtrunits- Units 1:m/s 2:knots 3:MPH to be used in the plot
!
!        vtrtype - Type of wind vector. 1:arrow, 2:barb
!
!  vtpplt  Flag for plotting the perturbation wind vectors; options similar
!	   to vtrplt.
!
!  vagplt  Flag for plotting the ageostrophic wind vectors; options similar
!	   to vtrplt. For pressure surface plotting only. PT sfc to be added.
!
!  xuvplt  Flag for plotting the total horiz wind (u,v) in cross-sections.
!          (x-z, or y-z, or xy-z) (only works when xuvtype=2)
!
!  strmplt Option for plotting storm motion (a 2-D field).
!
!-----------------------------------------------------------------------
!

 &vctrplt_cntl
  istride = 2,
  jstride = 2,
  kstride = 1,
  vtrplt  = 0, vtrunit =10.0, vtrovr = 1, vtrcol1 =1,vtrcol2 =24,vtrprio=3,
               vtrunits = 1, vtrtype= 1,
  vtpplt  = 0, vtpunit = 0.0, vtpovr = 0, vtpcol1 =1,vtpcol2 =24,vtpprio=0,
               vtpunits = 1, vtptype= 1,
  vagplt  = 0, vagunit =30.0, vagovr = 1, vagcol1 =1,vagcol2 =24,vagprio=3,
               vagunits = 1, vagtype= 1,
  xuvplt  = 0, xuvunit =0.0, xuvovr = 0, xuvcol1 =1,xuvcol2 =24,xuvprio=0,
               xuvunits = 1, xuvtype= 2,
  strmplt = 0, strmunit =0.0,strmovr = 0,strmcol1 =1,strmcol2 =24,strmprio=0,
               strmunits = 1,strmtype= 1,
 /

!
!-----------------------------------------------------------------------
!
!  Control parameters for plotting streamline variables.
!
!  vtrstrm - Option for plotting total-wind streamlines
!          = 0 no wind streamline plot
!          = 1 wind streamline plot
!  vtpstrm - Option for plotting the perturbation wind streamlines
!
!  If vtrstmcol2 > vtrstmcol1, the streamlines will be colored according to
!  the interpolated magnitudes and the number of threshold levels is
!  determined by the difference between vtrstmcol2 and vtrstmcol1.
!
!-----------------------------------------------------------------------
!

 &strmplt_cntl
   vtrstrm = 0, vtrstmovr = 0, vtrstmcol1=1,vtrstmcol2=24,vtrstmprio=0,
   vtpstrm = 0, vtpstmovr = 0, vtpstmcol1=1,vtpstmcol2=24,vtpstmprio=0,
 /

!
!-----------------------------------------------------------------------
!
!  Control parameters for plotting surface variables (See sclrplt_cntl1)
!
!  trnplt    - Plot terrain (m) (see ovrtrn above)
!  wetcanplt - Canopy water amount (mm)
!  raincplt  - Cumulus convective rain
!     racunit=0 (mm) racunit=1 (inches)
!  raingplt  - Grid supersaturation rain
!     ragunit=0 (mm) ragunit=1 (inches)
!  raintplt  - Total rain (rainc+raing)
!     ratunit=0 (mm) ratunit=1 (inches)
!
!  rainicplt  - Accumulated convective rain between two successive time
!               levels (determined by input file list)
!     raicunit=0 (mm) raicunit=1 (inches)
!  rainigplt  - Accumulated grid supersatuation rain between two
!               successive time levels
!     raigunit=0 (mm) raigunit=1 (inches)
!  rainitplt  - Total rain between two successive time levels
!     raitunit=0 (mm) raitunit=1 (inches)
!
!-----------------------------------------------------------------------
!

 &sfc_plot1
   trnplt   =0,trninc  =0.0, trnminc =0.0, trnmaxc =0.0, trnovr=0, trnhlf=4,
               trnzro=3,     trncol1=1,   trncol2=24,   trnprio=0,
   wetcanplt=0,wcpinc  =0.0, wcpminc  =0.0,wcpmaxc  =0.0,wcpovr=0, wcphlf=4,
               wcpzro=3,     wcpcol1=1,    wcpcol2=24,   wcpprio=0,
   raincplt =0,raincinc=0.0, raincminc=0.0,raincmaxc=0.0,racovr=0, rachlf=4,
               raczro=3,     raccol1=1,    raccol2=24,   racprio=0, racunit=0,
   raingplt =0,rainginc=0.0, raingminc=0.0,raingmaxc=0.0,ragovr=0, raghlf=4,
               ragzro=3,     ragcol1=1,    ragcol2=24,   ragprio=0, ragunit=0,
   raintplt =0,raintinc=0.0, raintminc=0.0,raintmaxc=0.0,ratovr=0, rathlf=4,
               ratzro=3,     ratcol1=1,    ratcol2=24,   ratprio=0, ratunit=0,

   rainicplt =0,rainicinc=0.0, rainicminc=0.0,rainicmaxc=0.0,raicovr=0, raichlf=4,
               raiczro=3,     raiccol1=1,    raiccol2=24,   raicprio=0, raicunit=0,
   rainigplt =0,rainiginc=0.0, rainigminc=0.0,rainigmaxc=0.0,raigovr=0, raighlf=4,
               raigzro=3,     raigcol1=1,    raigcol2=24,   raigprio=0, raigunit=0,
   rainitplt =0,rainitinc=0.0, rainitminc=0.0,rainitmaxc=0.0,raitovr=0, raithlf=4,
               raitzro=3,     raitcol1=1,    raitcol2=24,   raitprio=0, raitunit=0,
 /
!
!-----------------------------------------------------------------------
!
!  Control parameters for plotting soil variables (See sclrplt_cntl1)
!
!  tsoilplt   - Soil temperature (K)
!  qsoilplt  -  Soil moisture (m**3/m**3)
!
!-----------------------------------------------------------------------
!

 &soil_plot
   tsoilplt =0,tsoilinc=1.0, tsoilminc=0.0,tsoilmaxc=0.0,tsoilovr=0, tsoilhlf=4,
               tsoilzro=3,     tsoilcol1=1,    tsoilcol2=24,   tsoilprio=0,
   qsoilplt =0,qsoilinc=0.2, qsoilminc=0.0,qsoilmaxc=0.0,qsoilovr=0,qsoilhlf=4,
               qsoilzro=3,   qsoilcol1=1,  qsoilcol2=24, qsoilprio=0,
 /
!
!-----------------------------------------------------------------------
!
!  Control parameters for more surface variables (See sclrplt_cntl1)
!
!  pslplt    - Sea level pressure (mb)
!              (Reference: Benjamin, S.G. and P. R. Miller: MWR, vol.118,
!               No.10, Page 2100-2101)
!  capeplt   - CAPE (J/kg)
!  cinplt    - CIN (J/kg)
!  thetplt   - theta_E (K)
!  heliplt   - helicity (m**2/s**2)
!  uhplt     - updraft helicity (m**2/s**2)
!  brnplt    - Bulk Richardson Number (Weisman and Klemp)
!  brnuplt   - Bulk Richardson Shear (1/s)
!  brnuplt   - Bulk Richardson Shear Denominator (m2/s2)
!  srlfplt   - Storm-relative low-level flow (m/s) (0-2km AGL)
!  srmfplt   - Storm-relative mid-level flow (m/s) (2-9km AGL)
!
!-----------------------------------------------------------------------
!

 &sfc_plot2
   pslplt   =0,pslinc=0.0,  pslminc=0.0,  pslmaxc=0.0,  pslovr=0,  pslhlf=4,
               pslzro=3,    pslcol1=1,    pslcol2=46,   pslprio=0,
   capeplt  =0,capeinc=0.0, capeminc=0.0, capemaxc=0.0, capovr=0,  caphlf=4,
               capzro=3,    capcol1=1,    capcol2=46,   capprio=0,
   cinplt   =0,cininc=0.0,  cinminc=0.0,  cinmaxc=0.0,  cinovr=0,  cinhlf=4,
               cinzro=3,    cincol1=1,    cincol2=20,   cinprio=0,
   thetplt  =0,thetinc=0.0, thetminc=0.0, thetmaxc=0.0, theovr=0,  thehlf=4,
               thezro=3,    thecol1=1,    thecol2=46,   theprio=0,
   heliplt  =0,heliinc=0.0, heliminc=0.0, helimaxc=0.0, helovr=0,  helhlf=4,
               helzro=3,    helcol1=1,    helcol2=46,   helprio=1,
   uhplt    =0,uhinc=0.0,   uhminc=0.0,   uhmaxc=0.0,   uhovr=0,   uhhlf=4,
               uhzro=3,     uhcol1=72,    uhcol2=93,    uhprio=1,
               uhmnhgt=2000., uhmxhgt=5000.,
   brnplt   =0,brninc=0.0,  brnminc=0.0,  brnmaxc=0.0,  brnovr=0,  brnhlf=4,
               brnzro=3,    brncol1=1,   brncol2=46,   brnprio=0,
   brnuplt  =0,brnuinc=0.0, bruminc=0.0,  brumaxc=0.0,  brnuovr=0, brnuhlf=4,
               brnuzro=3,   brnucol1=1,  brnucol2=46,  bruprio=0,
   srlfplt  =0,srlfinc=0.0, srlminc=0.0,  srlmaxc=0.0,  srlfovr=0, srlfhlf=4,
               srlfzro=3,   srlfcol1=1,  srlfcol2=46,  srlprio=0,
   srmfplt  =0,srmfinc=0.0, srmminc=0.0,  srmmaxc=0.0,  srmfovr=0, srmfhlf=4,
               srmfzro=3,   srmfcol1=1,  srmfcol2=46,  srmprio=0,
 /

!
!-----------------------------------------------------------------------
!
!  Control parameters for yet more surface variables (See sclrplt_cntl1)
!
!  liplt     - Sfc-based lifted index (K)
!  capsplt   - Cap strength (K)
!  blcoplt   - Boundary layer convergence (1/s)
!  viqcplt   - Vert. integrated qc (kg/m2)
!  viqrplt   - Vert. integrated qr (kg/m2)
!  viqiplt   - Vert. integrated qi (kg/m2)
!  viqsplt   - Vert. integrated qs (kg/m2)
!  viqhplt   - Vert. integrated qh (kg/m2)
!  vilplt    - Vert. integrated liquid (qc,qr) (kg/m2)
!
!-----------------------------------------------------------------------
!

 &sfc_plot3
   liplt   =0,  liinc=0.0,    liminc=0.0,     limaxc=0.0,    liovr=0,   lihlf=4,
                lizro=3,      licol1=1,      licol2=46,     liprio=0,
   capsplt =0,  capsinc=0.0,  capsminc=0.0,   capsmaxc=0.0,  capsovr=0, capshlf=4,
                capszro=3,    capscol1=1,     capscol2=46,   capsprio=0,
   blcoplt =0,  blcoinc=0.0,  blcominc=0.0,   blcomaxc=0.0,  blcoovr=0, blcohlf=4,
                blcozro=3,    blcocol1=1,     blcocol2=46,   blcoprio=0,
   viqcplt =0,  viqcinc=0.1,  viqcminc=0.0,   viqcmaxc= 1.8, viqcovr=0, viqchlf=4,
                viqczro=0,    viqccol1=1,     viqccol2=46,   viqcprio=0,
   viqrplt =0,  viqrinc=0.0,  viqrminc=0.0,   viqrmaxc=0.0,  viqrovr=0, viqrhlf=4,
                viqrzro=3,    viqrcol1=1,     viqrcol2=46,   viqrprio=0,
   viqiplt =0,  viqiinc=0.0,  viqiminc=0.0,   viqimaxc=0.0,  viqiovr=0, viqihlf=4,
                viqizro=3,    viqicol1=1,     viqicol2=46,   viqiprio=0,
   viqsplt =0,  viqsinc=0.0,  viqsminc=0.0,   viqsmaxc=0.0,  viqsovr=0, viqshlf=4,
                viqszro=3,    viqscol1=1,     viqscol2=46,   viqsprio=0,
   viqhplt =0,  viqhinc=0.0,  viqhminc=0.0,   viqhmaxc= 0.0, viqhovr=0, viqhhlf=4,
                viqhzro=3,    viqhcol1=1,     viqhcol2=46,   viqhprio=0,
   vilplt  =0,  vilinc=0.0,   vilminc=0.0,    vilmaxc=0.0,   vilovr=0,  vilhlf=4,
                vilzro=3,     vilcol1=1,      vilcol2=46,    vilprio=0,
 /

!
!-----------------------------------------------------------------------
!
!  Control parameters for still more surface variables (See sclrplt_cntl1)
!
!  viiplt    - Vert. integrated ice (qi,qs,qh) (kg/m2)
!  vicplt    - Vert. integrated condensate (qc,qr,qi,qs,qh) (kg/m2)
!  ctcplt    - Convective temperature (Celsius)
!  vitplt    - vertically integrated total water ( kg/m**2)
!  pwplt     - precipitable water vapor (cm)
!  tprplt    - Total precip. rate, tprunits - 1 (mm/h), 2 (inch/h)
!  gprplt    - Grid-scale precip. rate, gprunits - 1 (mm/h), 2 (inch/h)
!  cprplt    - Convective precip. rate, cprunits - 1 (mm/h), 2 (inch/h)
!
!-----------------------------------------------------------------------
!

 &sfc_plot4
   viiplt  =0, viiinc=0.0, viiminc=0.0, viimaxc=0.0, viiovr=0, viihlf=4,
               viizro=3,   viicol1=1,   viicol2=24,  viiprio=0,
   vicplt  =0, vicinc=0.0, vicminc=0.0, vicmaxc=0.0, vicovr=0, vichlf=4,
               viczro=3,   viccol1=1,   viccol2=24,  vicprio=0,
   ctcplt  =0, ctcinc=0.0, ctcminc=0.0, ctcmaxc=0.0, ctcovr=0, ctchlf=4,
               ctczro=3,   ctccol1=1,   ctccol2=24,  ctcprio=0,
   vitplt  =0, vitinc=0.0, vitminc=0.0, vitmaxc=0.0, vitovr=0, vithlf=4,
               vitzro=3,   vitcol1=1,   vitcol2=24,  vitprio=0,
   pwplt   =0, pwinc=0.0,  pwminc=0.0,  pwmaxc=0.0,  pwovr=0,  pwhlf=4,
               pwzro=3,    pwcol1=1,    pwcol2=24,   pwprio=0,
   tprplt  =0, tprinc=0.0, tprminc=0.0, tprmaxc=0.0, tprovr=0, tprhlf=4,
               tprzro=3,   tprcol1=1,   tprcol2=24,  tprprio=0, tprunits=1,
   gprplt  =0, gprinc=0.0, gprminc=0.0, gprmaxc=0.0, gprovr=0, gprhlf=4,
               gprzro=3,   gprcol1=1,   gprcol2=24,  gprprio=0, gprunits=1,
   cprplt  =0, cprinc=0.0, cprminc=0.0, cprmaxc=0.0, cprovr=0, cprhlf=4,
               cprzro=3,   cprcol1=1,   cprcol2=24,  cprprio=0, cprunits=1,
 /

!
!-----------------------------------------------------------------------
!
!  Control parameters for plotting surface characteristics fields
!  (See sclrplt_cntl1)
!
!  soiltpplt - Soil type
!    soiltpn   Soil type number (1 to 4)
!  vegtpplt  - Vegetation type
!  laiplt    - Leaf Area Index
!  rouplt    - Surface roughness
!  vegplt    - Vegetation fraction
!  snowdplt  - Snow depth
!
!-----------------------------------------------------------------------
!
 &sfc_cha_plot
   soiltpplt=0,soiltpinc=0.0, soiltpminc=0.0, soiltpmaxc=0.0,styovr=0, styhlf=4,
               styzro=3,   stycol1=1,    stycol2=24,    styprio=0,  soiltpn = 1,
   vegtpplt=0,vegtpinc=0.0,  vegtpminc =0.0,  vegtpmaxc=0.0, vtyovr=0, vtyhlf=4,
              vtyzro=3,      vtycol1=1,       vtycol2=24,    vtyprio=0,
   laiplt  =0,laiinc  =0.0,  laiminc   =0.0,  laimaxc  =0.0, laiovr=0, laihlf=4,
              laizro=3,      laicol1=1,       laicol2=24,    laiprio=0,
   rouplt  =0,rouinc  =0.0,  rouminc   =0.0,  roumaxc  =0.0, rouovr=0, rouhlf=4,
              rouzro=3,      roucol1=1,       roucol2=24,    rouprio=0,
   vegplt  =0,veginc  =0.0,  vegminc   =0.0,  vegmaxc  =0.0, vegovr=0, veghlf=4,
              vegzro=3,      vegcol1=1,       vegcol2=24,    vegprio=0,
   snowdplt=0,snowdinc=0.0, snowdminc=0.0, snowdmaxc=0.0, snowdovr=0,snowdhlf=4,
              snowdzro=3, snowdcol1=1, snowdcol2=24, snowdprio=0,
 /
!
!-----------------------------------------------------------------------
!
!  Options for plotting irregularly spaced contours for selected fields.
!
!  setcontopt  - Option for setting irregularly contour intervals.
!                = 0 no set for irregularly contour
!                = 1 set for irregularly contour
!  setcontnum  - number of variables need  to set irregularly contour
!                intervals.
!
!  setcontvar  - name of field (same name as option for plotting the
!		 variable, e.g., raintplt).
!
!  setconts(1, #var) - Contour values (maximum 20 values, in ascending order)
!              #var - the number of name of plots.
!
!-----------------------------------------------------------------------
!

 &setcont_cntl
   setcontopt = 0,
   setcontnum = 6,

   setcontvar(1) = 'raintplt',
   setconts(1,1) = 0.01,0.1,0.25,1.0,2.0,5.0,10.0,15.0,20.0,25.0,50.0,75.0,200.0,250.0,

   setcontvar(2) = 'wplot',
   setconts(1,2) = -10.,-5.,-2.,-1.,-0.5,-0.1,0.1,0.5,1.,2.,5.,10.,

   setcontvar(3) = 'viqcplt',
   setconts(1,3) = 0.1,1.,2.,5.,10.,20.,40.,70.,100.,

   setcontvar(4) = 'qcplot',
   setconts(1,4) = 0.01,0.1,0.2,0.5,1.,2.,5.,10.,15.,20.,

   setcontvar(5) = 'tprplt',
   setconts(1,5) = 0.01,0.1,0.25,1.0,2.0,5.0,10.0,15.0,20.0,25.0,50.0,75.0,200.0,250.0,

   setcontvar(6) = 'cprplt',
   setconts(1,6) = 0.01,0.1,0.25,1.0,2.0,5.0,10.0,15.0,20.0,25.0,50.0,75.0,200.0,250.0,
 /

!
!-----------------------------------------------------------------------
!
!  Contouring 2D and 3D fields read in from individual files.
!
!    2D and 3D arrays are stored individually in files runname.varnamssssss,
!    where varnam is 6-character variable name, and ssssss is 6-digit time in
!    seconds.  (e.g may20.usfc__003600, variable name is usfc__, if the
!    history file is may20.grb003600) ( more info see readvar ).
!
!  arbvaropt   Option to plot arbitrary variables (0:off, 1:on)
!              >= 11 Plot arbitrary variables only (read grid & base file only)
!              NOTE that the runname will be decoded from the history file name
!              instead of that read in from the history file. So the history files
!              should be specified even they are not read. The history files
!              have two roles when arbvaropt >= 11
!              1. provide runname;
!              2. provide forecast time.
!              These two are used for constructing 2D / 3D file names.
!
!  var3dnum  number of 3D arbitrary variables. (Maximum 20)
!  var3d     name of the arbitrary variable (e.g., "uforce")
!  dirname3d input directory. './' for current directory,
!  finfmt3d  3D field file format
!            = 1, binary
!            = 3, HDF 4
!            = 7, netCDF
!
! filename3d file name that contains the 3D arbitrary variable
!            If it is empty, old file name is use and the pattern is
!            runname.FMTXXXXXX000000
!            where "runname" is read in from file "grdbasfn" above,
!            FMT is 3 character format string (hdf, bin, net etc.),
!            XXXXXX is the 6 character variable ID specified by "var3d",
!            000000 is 6 digit forecast time encoded in file name "hisfile" above.
!
!  var2dnum  number of 2D arbitrary variables. (Maximum 20)
!  var2d     name of the arbitrary variable (e.g., "usfc__")
!  dirname2d input directory. './' for current directory,
!  finfmt2d  2D field file format
!
!  var*dplot, var*dinc, var*dminc, var*dmaxc, var*dovr, var*dhlf,
!            var*dzro, var*dcol1, var*dcol2 and var*dprio same as the
!            regular plot. See explanation for uplot)
!
!  vtr2dnum  number of 2d vector variables.
!  iastride  == 0, use istride by default, same for jastride
!            /= 0, use this stride step
!
!-----------------------------------------------------------------------
!
 &arbvar_cntl

   
   arbvaropt = 0,

   var3dnum = 0,
   var3d(1) = 'refmos', dirname3d(1) = './', finfmt3d (1) = 3,
   filename3d(1) = ' '
     var3dplot(1)=2, var3dinc (1)=5.0, var3dminc(1)=5.0, var3dmaxc(1)=70.0,
     var3dovr (1)=1, var3dhlf (1)=4,   var3dzro (1)=3,   var3dcol1(1)=0,
     var3dcol2(1)=20,var3dprio(1)=0,

   var3d(2) = 'vforce', dirname3d(2) = './', finfmt3d (2) = 1,
   filename3d(2) = ' ',
     var3dplot(2)=1, var3dinc (2)=0.0, var3dminc(2)=0.0, var3dmaxc(2)=0.0,
     var3dovr (2)=0, var3dhlf (2)=4,   var3dzro (2)=0,   var3dcol1(2)=1,
     var3dcol2(2)=24,var3dprio(2)=0,

   var2dnum = 1,

   var2d(1) = 'refmos', dirname2d(1) = '/scratch/mtmorris/runs_20160411/small_grid_1km_sfc88donly/', finfmt2d (1) = 3,
   filename2d(1) = '88dmosaic_2130Z',
     var2dplot(1)=2, var2dinc (1)=5.0, var2dminc(1)=5.0, var2dmaxc(1)=70.0,
     var2dovr (1)=1, var2dhlf (1)=1,   var2dzro (1)=3,   var2dcol1(1)=0,
     var2dcol2(1)=20,var2dprio(1)=0,

   var2d(2) = 'vsfc__', dirname2d(2) = './', finfmt2d (2) = 1,
   filename2d(2) = ' ',
     var2dplot(2)=1, var2dinc (2)=0.0, var2dminc(2)=0.0, var2dmaxc(2)=0.0,
     var2dovr (2)=0, var2dhlf (2)=4,   var2dzro (2)=0,   var2dcol1(2)=1,
     var2dcol2(2)=24,var2dprio(2)=0,

   vtr2dnum=0
   vtru2d(1) ='k7uwnd',  vtrv2d(1) ='k7vwnd',
   diruv2d(1)='./', finfmtuv2d(1)=3,
   filenameu2d(1) = ' ', filenamev2d(1) = ' ',
   iastride(1) = 5, jastride(1) = 5,
     vtraplt (1)=1,vtraunit (1)=10.0,vtraovr (1)=0,vtracol1(1)=1,vtracol2(1)=24,
     vtraprio(1)=3,vtraunits(1)=1,   vtratype(1)=1,

 /
!
!-----------------------------------------------------------------------
!
!  Overlay rectangular boxes in horizontal cross-sections (typically
!  showing the locations of nested grids).
!
!   number_of_boxes : Number of boxes to plot.
!   boxcol         - box color.
!   bctrx, bctry   - coordinate of the center of the box (km).
!                    which is relative to remapped xorig,yorig
!   blengx, blengy - length of the box (km).
!
!-----------------------------------------------------------------------
!

 &plot_boxes
   number_of_boxes = 0,
   boxcol = 1,
   bctrx(1) = 50., bctry(1) = 50., blengx(1) = 336., blengy(1) = 336.,
 /

!
!-----------------------------------------------------------------------
!
!  Plot arbitrary lines and polygons.
!
!   number_of_polys       : Number of polylines to plot (Maximum 10).
!   polycol               : polyline color.
!   vertx(V, #polys)      :  X coordinate of vertex (km).
!   verty(V, #polys)      :  Y coordinate of vertex (km).
!                            (V :  Number of vertices, maximum 20)
!                            (#polys :  the number of the polygon)
!
!-----------------------------------------------------------------------
!

 &plot_polylines
   number_of_polys = 0,
   polycol = 1,

   vertx(1,1)=810,verty(1,1)=0.0,vertx(2,1)=810,verty(2,1)=1620,
   vertx(1,2)=324,verty(1,2)=0.0,vertx(2,2)=324,verty(2,2)=1620,
   vertx(1,3)=1296,verty(1,3)=0.0,vertx(2,3)=1296,verty(2,3)=1620,
   vertx(1,4)=0.0,verty(1,4)=810,vertx(2,4)=1620,verty(2,4)=810,
   vertx(1,5)=0.0,verty(1,5)=324,vertx(2,5)=1620,verty(2,5)=324,
   vertx(1,6)=0.0,verty(1,6)=1296,vertx(2,6)=1620,verty(2,6)=1296,
   vertx(1,7)=0.0,verty(1,7)=0.0,vertx(2,7)=1620,verty(2,7)=1620,
   vertx(1,8)=0.0,verty(1,8)=1620,vertx(2,8)=1620,verty(2,8)=0.0,
 /

!
*-----------------------------------------------------------------------
!
!  Plot trajectories read in from output of arpstrajc program
!  Dan Dawson 12/03/2004
!
!  Significant update: Ming Xue, 1/20/2010.
!  Added the following control parameters, removed a few.
!
!  Plot trajectories projected to 2D xy, xz, yz planes or
!  constant height or pressure levels. The trajectories are read in
!  from file trajc_fn_in, as produced by arpstrajc program.
!  
! trajc_plt_opt /= 0 Overlay trajectories on slices.
!                = 1 Overlay trajectories on slices.
!                = 2 In addition to 1, plot vertical cross sections along
!                    the trajectories.
!     When trajc_plt_opt /= 0 and nslice_h=-1 (or any negative value),
!     constant-height horizontal cross sections are plotted at the height
!     of the trajectory air parcel at the history data time.
!
! ntimes The number of sets of trajectories to be read in (from trajc_fn_in)
!        and plotted.  Generally set to 1. Max. number = 30.
!
!        Only ntimes=1 is supported (no more than 1 set of trajectories)
!        by the trajectory-following cross section plotting.
!
! trajc_fn_in() List of file names containing the trajectory data.
!
! trajc_plt_bgn_time  Start time of points along the trajectory to be plotted.
! trajc_plt_end_time  End time of points along the trajectory to be plotted.
!
!       When trajc_plt_bgn_time = trajc_plt_end_time = 0.0, all points  
!       on the trajectory are plotted.
! 
!       When trajc_plt_bgn_time -9999.0, the time of the history data  
!       being plotted is used as the start time.
!
!       When trajc_plt_end_time -9999.0, the time of the history data  
!       being plotted is used as the end time.
!
! ntrajc_start  Starting number of the trajectory in each set to plot.
! ntrajc_end    Ending number of the trajectory in each set to plot.
!               IF negative, it will be set to the total number of
!               trajectories in each set.
! ntrajc_stride Every ntrajc_stride-th trajectory is plotted.
!
! traj_col Color index (based on the chosen color table) of trajectories
!                to be plotted. Max number of trajectories = 30.
!
! trajc_lbl_opt : Type of labels to plot along side the trajectories.
!
!       Label type: 1 - plot the coordinate for the dimension not plotted 
!                 For x-y cross sections (model level or constant 
!                 height, pressure level), it's height MSL (km). 
!                 For x-z planes, it's y coordinate (km).
!                 For y-z planes, it's z coordinate. 
!                 For vertical cross sections through two arbitary
!                 points, it's the distance from the plane. 
!       Label type: 2 - plot the time of the trajectory points in model time min.
!       Label type: 3 - plot the time of the trajectory points in UTC.
!
! trajc_lbl_siz : Label size defined as the factor of min(height,width)
!                 of plot muliplied by lblmag defined earlier.
! trajc_lbl_frq : Frequency of label plotting in terms of the
!                 number of points along the trajectory.
! trajc_lbl_fmt : Format of trajectory labeling.
!               -1 (default) - automatically chosen
!                0 - integer
!               >0 - number of decimals.
!
! trajc_mkr_typ : Type of markers to label on the trajectories
!                 Marker type: 0-none, 1-circle 2-uptriangle 
!                              3-downtriangle 4-square 5-diamond
!                 Markers No. 6-10 correspond to the filled version of 1-5.
! trajc_mkr_siz : Marker size defined as the factor of min(height,width) 
!                 of plot muliplied by lblmag defined earlier.
! trajc_mkr_frq : Frequency of marker plotting in terms of the 
!                 number of points along the trajectory.
!
!---------------------------------------------------------------------=*
!
 &plot_trajectories

   trajc_plt_opt = 0,

   ntimes = 1,
   trajc_fn_in(1) ='May_20_1km.trajc_001800-005400_003600',

   trajc_plt_bgn_time = 0.0,
   trajc_plt_end_time = 0.0,

   ntrajc_start = 1,
   ntrajc_end =   -1,
   ntrajc_stride = 1,

   traj_col(1) = 29, traj_col(2) = 30, traj_col(3) = 31,
   traj_col(4) = 32, traj_col(5) = 33, traj_col(6) = 34,
   traj_col(7) = 35, traj_col(8) = 36, traj_col(9) = 37,
   traj_col(10)= 38, traj_col(11)= 39, traj_col(12)= 40,
   traj_col(13)= 41, traj_col(14)= 42, traj_col(15)= 43,
   traj_col(16)= 44, traj_col(17)= 45,

   trajc_lbl_opt = 1,
   trajc_lbl_frq = 5,
   trajc_lbl_siz = 0.01 ,
   trajc_lbl_fmt = 1,

   trajc_mkr_typ = 6,
   trajc_mkr_frq = 1,
   trajc_mkr_siz = 0.0015,
 /
!
!-----------------------------------------------------------------------
!
!  Overlay wind vectors (arrows or barbs) on multiple frames.
!
!  ovrlaymulopt = Option to overlay wind vectors on multiple plots (0:off, 1:on)
!  ovrname     -  either 'vtrplt' or 'xuvplt'
!  ovrmul_num  -  number of plots.
!  ovrmulname  -  Plot variable names to overlay wind arrows (not vtrplt or
!                 xuvplt).  No two of these may have same priority, and the
!                 priority must >0. The priority of vtrplt and xuvplt are
!		  set to zero.  All of the fields must be turned on.
!
!-----------------------------------------------------------------------
!
 &ovrlay_mul
   ovrlaymulopt = 0,
   ovrname = 'vtrplt',
   ovrmul_num = 4,
   ovrmulname(1) = 'uplot',
   ovrmulname(2) = 'vplot',
   ovrmulname(3) = 'avorplt',
   ovrmulname(4) = 'ppplot',
 /

!
!-----------------------------------------------------------------------
!
!  ovrtrn  Option to overlay terrain on every x-y plot.
!	   (0:off, 1:on. Must also turn on trnplt below.)
!
!-----------------------------------------------------------------------
!

 &ovr_terrain
   ovrtrn = 0,
 /

!
*-----------------------------------------------------------------------
!
!  Wireframe/isosurface options (available for NCARgraphics version only).
!
!  w3dplt  Option to plot a 3-d wireframe of w
!        = 0, do not plot w wireframe
!        = 1, plot w wireframe
!  wisosf  Value of w for isosurface (m/s)
!        = -1 automatically determined
!  q3dplt  Option to plot a 3-d wireframe of qc+qr
!        = 0, do not plot qc+qr wireframe
!        = 1, plot qc+qr wireframe
!  qisosf  Value of qc+qr isosurface (kg/kg)
!
!  NOTE: this part is still not MPI-ied because it calls a NCAR graphics
!        internal subroutine. So it will not be suitable for jobs over
!        large domain.
!
!---------------------------------------------------------------------=*
!

 &wirfrm_plot
   w3dplt = 0,
   wisosf = -0.1,
   q3dplt = 0,
   qisosf = 0.1,
 /

!
*-----------------------------------------------------------------------
!
! Options for plotting station observations
!
! ovrobs      : Option for overlaying observations (0:off, 1:on)
! nsfcobfl    : Number of surface observation files
! obscol      : Color
! obs_marktyp : Symbol type: 1-circle 2-uptriangle 3-downtriangle 4-square
!               5-diamond
! obs_marksz  : Symbol size
! obs_valsz   : The size of characters when the observation values are plotted
! sfcobfl     : Files containing obs (LAPS Surface Observation format)
!
!---------------------------------------------------------------------=*
!

 &plot_obs
   ovrobs=0,
   nsfcobfl=1,
   obscol=10,
   obs_marktyp = 1,
   obs_marksz = 0.015,
!   sfcobfl(1)='/home/mtmorris/arpsverif/verification_lso/onemin201604112300.lso',
   sfcobfl(1)='/work/mtmorris/20160411/laps/MADISmetar/MADISmetar201604112150_ASOSonly.lso',
   sfcobfl(2)='/work/mtmorris/20160411/laps/MADISmeso/MADISmeso201604112150.lso',
   sfcobfl(3)='/work/mtmorris/20160411/laps/understory/understory201604112150.lso',
   sfcobfl(4)='/work/mtmorris/20160411/laps/gst/moped201604112150.lso',
   
   obs_valsz = 0.015,
!   obs_valsz = 0.01,
 /

!
*-----------------------------------------------------------------------
!
!  Options for overlaying station locations and writing the field values at
!  those locations.
!
! ovrstaopt   : Option for overlaying station information (0:off, 1:on).
! ovrstan     : Overlay station name (0:off, 1:on).
! ovrstam     : Overlay station symbol (0:off, 1:on).
! ovrstav     : Overlay interpolated value of the field(s) (0:off, 1:on).
! wrtstax     : Write station name along axis (for cross-sections) (0:off, 1:on)
! wrtstad     : the distance (km) for write station name along axis.
! stacol      : Color for interpolated value and station name along axis.
! markprio    : Only plot stations whose priority is <= markprio
!               (Low numbers has higher priority.)
! nsta_typ    : Number of station types to plot.
! sta_marktyp : Symbol type: 1-circle 2-uptriangle 3-downtriangle 4-square
!               5-diamond, 6-filled_circle 7-filled_uptriangle
!               8-filled_downtriangle 9-filled_squal 10-filled_diamond
! sta_typ     : Station type (e.g., 91 ,92).
! sta_markcol : Symbol color
! sta_marksz  : Symbol size
! stalofl     : Station file name
!
!              Example of station file:
!           #      ST        Site name           Lat      Lon    Elev Type
!           #.....|..|........................|.......|........|.....|....|
!           GCK    KS Garden_City_Muni          37.930 -100.730   880  911
!           BUM    MO Butler/VOR                38.267  -94.483   320  922
! Type is a two-digit number (91) and a one-digit priority (1)
!
!---------------------------------------------------------------------=*
!

 &plot_sta
   ovrstaopt = 0,
   ovrstan = 0,
   ovrstam = 0,
   ovrstav = 0,
   wrtstax = 0,
   wrtstad = 100.0,
   stacol=20,
   markprio = 1,
   nsta_typ = 0,
    sta_typ(1) = 91,sta_marktyp(1)=5,sta_markcol(1)=13,sta_marksz(1)=0.01,
    sta_typ(2) = 92,sta_marktyp(2)=6,sta_markcol(2)=5,sta_marksz(2)=0.004,
   stalofl='aa-dfw.meta',
 /

!
*-----------------------------------------------------------------------
!
!  Plot vertical profiles at specifies locations.
!
!  profopt Option to plot vertical profiles (0:off, 1:on)
!
!  nprof   Number of profiles to be plotted.
!  xprof(1),yprof(1) Coordinates (km) of first profile.
!  Coordinates repeated for each requested profile.
!
!  npicprof   Option to overlay all profiles
!           = 0 all points in same plot,
!           = 1 in separate plot
!
!  uprof      Option for plotting u profile (0:off, 1:on)
!
!  uprmin     Graph minimum of variable u (m/s)
!           = 0.0 automatic
!  uprmax     Graph maximum of variable u (m/s)
!           = 0.0 automatic
!
!  Repeated for other variables as listed below:
!
!    vprof    - total v-velocity (m/s)
!    wprof    - total w-velocity (m/s)
!    ptprof   - total potential temperature (K)
!    pprof    - total pressure (Pa)
!    qvprof   - total water vapor specific humidity (g/kg)
!    qcprof   - cloud water mixing ratio  (g/kg)
!    qrprof   - rain  water mixing ratio  (g/kg)
!    qiprof   - cloud ice mixing ratio  (g/kg)
!    qsprof   - snow mixing ratio (g/kg)
!    qhprof   - hail mixing ratio (g/kg)
!    kmhprof  - Horizontal turb. mixing coef. for momentum (m**2/s)
!    kmvprof  - Vertical turb. mixing coef. for momentum (m**2/s)
!    tkeprof  - Turbulent Kinetic Energy ((m/s)**2)
!    rhprof   - relative humidity (non-dimensional)
!    rfprof   - Radar reflectivity (dBZ)
!    pteprf   - equivalent potential temperature (K)
!    upprof   - perturbation u-velocity (m/s)
!    vpprof   - perturbation v-velocity (m/s)
!    wpprof   - perturbation w-velocity (m/s)
!    ptpprf   - perturbation potential temperature (K)
!    ppprof   - perturbation pressure (Pa)
!    qvpprf   - perturbation water vapor specific humidity (g/kg)
!    vorpprf  - vertical vorticity component (1/s)
!    divpprf  - horizontal divergence (1/s)
!
!  zprofbgn  Lower limit of z in profile. (km)
!  zprofend  Upper limit of z in profile. (km)
!
!  Soil model profiles
!
!    tsoilprof - soil temperature (K)
!    qsoilprof - soil moisture (m**3/m**3)
!
!    zsoilprofbgn  Lower limit of zsoil in profile. (m)
!    zsoilprofend  Upper limit of zsoil in profile. (m)
!
!  nxprpic   Number of columns in each profile page plotted
!  nyprpic   Number of rows in each profile page plotted
!
!---------------------------------------------------------------------=*
!

 &profile_cntl
   profopt = 0,
   nprof = 4,
   xprof(1) =  1.0, yprof(1) =  1.0,
   xprof(2) = 10.0, yprof(2) = 10.0,
   xprof(3) = 30.0, yprof(3) = 30.0,
   xprof(4) = 35.0, yprof(4) = 45.0,
   npicprof = 0,
   uprof   = 0, uprmin  = 0.0, uprmax  = 0.0,
   vprof   = 0, vprmin  = 0.0, vprmax  = 0.0,
   wprof   = 0, wprmin  = 0.0, wprmax  = 0.0,
   ptprof  = 0, ptprmin = 0.0, ptprmax = 0.0,
   pprof   = 0, pprmin  = 0.0, pprmax  = 0.0,
   qvprof  = 0, qvprmin = 0.0, qvprmax = 0.0,
   qcprof  = 0, qcpmin  = 0.0, qcpmax  = 0.0,
   qrprof  = 0, qrpmin  = 0.0, qrpmax  = 0.0,
   qiprof  = 0, qipmin  = 0.0, qipmax  = 0.0,
   qsprof  = 0, qspmin  = 0.0, qspmax  = 0.0,
   qhprof  = 0, qhpmin  = 0.0, qhpmax  = 0.0,
   kmhprof = 0, kmhpmin = 0.0, kmhpmax = 0.0,
   kmvprof = 0, kmvpmin = 0.0, kmvpmax = 0.0,
   tkeprof = 0, tkepmin = 0.0, tkepmax = 0.0,
   rhprof  = 0, rhpmin  = 0.0, rhpmax  = 0.0,
   rfprof  = 0, rfpmin  = 0.0, rfpmax  = 0.0,
   pteprf  = 0, ptepmin = 0.0, ptepmax = 0.0,
   upprof  = 0, uppmin  = 0.0, uppmax  = 0.0,
   vpprof  = 0, vppmin  = 0.0, vppmax  = 0.0,
   wpprof  = 0, wppmin  = 0.0, wppmax  = 0.0,
   ptpprf  = 0, ptppmin = 0.0, ptppmax = 0.0,
   ppprof  = 0, pppmin  = 0.0, pppmax  = 0.0,
   qvpprf  = 0, qvppmin = 0.0, qvppmax = 0.0,
   vorpprf = 0, vorppmin= 0.0, vorppmax= 0.0,
   divpprf = 0, divppmin= 0.0, divppmax= 0.0,
   zprofbgn= -10., zprofend = 10.,
   tsoilprof = 1, tsoilprofmin= 0.0, tsoilprofmax= 0.0,
   qsoilprof = 1, qsoilprofmin= 0.0, qsoilprofmax= 0.0,
   zsoilprofbgn= -10., zsoilprofend = 10.,
   nxprpic = 3, nyprpic =3,
 /

!
*-----------------------------------------------------------------------
!
!  Graph file output options
!
!  dirname:     Output directory
!  outfilename: Default is "runname.ps" for Postscript output, and "gmeta"
!               for NCARG output when outfilename is empty.
!
!  NOTE: When using NCAR Graphic, there are two other ways to change
!        the output file name instead of the default "gmeta".
!
!        1. Use "ncargrun" script as:
!             ncargrun -o desired_metafile_name bin/arpspltncar < arpsplt.input
!        2. Set environment variable "NCARG_GKS_OUTPUT" as:
!             setenv NCARG_GKS_OUTPUT desired_metafile_name
!
!  iwtype:     Output graphic format for NCAR Graphics only
!
!     1                                         GMETA
!     9                                         PNG
!
!    11       portrait                          pdf
!    12       landscape                         pdf
!
!    20       portrait        color             ps
!    21       portrait        color             eps
!    22       portrait        color             epsi
!    23       portrait        monochrome        ps
!    24       portrait        monochrome        eps
!    25       portrait        monochrome        epsi
!    26       landscape       color             ps
!    27       landscape       color             eps
!    28       landscape       color             epsi
!    29       landscape       monochrome        ps
!    30       landscape       monochrome        eps
!    31       landscape       monochrome        epsi
!
!    To reverse background and foregrounda colors (if col_table /= -1),
!    add 100 to iwtype. It is useful when users desire a white
!    background instead of the default black background with gmeta file.
!
! NOTE: Parameters "outfilename" and iwtype > 100 do not work with PNG file,
!       because PNG support is just an experimental feature at present and there is
!       still no support from the NCAR Graphic Group. The default output
!       file name is always 'gmeta.png' and the background is always
!       'black'. 
!
!---------------------------------------------------------------------=*
!

 &output
   dirname     = '/scratch/admoore/arps5.4.23/images',
   outfilename = 'NR${seconds}',
   iwtype      = 9,
   lvldbg      = 0,
 /

arpsin
