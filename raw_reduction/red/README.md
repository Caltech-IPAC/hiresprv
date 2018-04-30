Routines used to create 1-D spectra from raw 2-D spectra from Keck-HIRES.

The inupt and output directories for these routines are stored 
as environment variables. 

Three data formats are produced:
rdsk format: Used as input for the doppler code (Gain not applied)
.fits format: Standard fits format, identical to rdsk format.
.fits format-deblazed: These spectra have their blaze function removed, but
   are not continuum normalized. The first axis holds the data, the second
   axis holds the photon (poisson) errors. The third axis holds a wavelength
   value for every pixel, ie the wavelength solution.
   
Running the code.
 The reduction routines have been integrated with the cps-pipeline repo and
 runs from the doppler account. All three chips are reduced by the following
 routine:
 
 `> cps-pipe hires rreduce.sh   `