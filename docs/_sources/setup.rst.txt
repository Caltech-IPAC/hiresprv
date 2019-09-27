.. _setup:

Observing Instructions
**********************
HIRES must be configured properly and the observations must be conducted in a very specific way in order for the
pipeline to function and produce reliable PRVs.

*Carefully follow all instructions below in order to ensure the pipeline is able to reduce your data.*

.. _afternoon:

Afternoon Setup
===============

* Log into the observing computer and start up the HIRES VNC sessions as appropriate for your site
* Start HIRES GUIs
    * Left-click on tan background to access the "desktop pulldown menu"
    * Select "HIRES CONTROL MENU" > "START all HIRES GUIs w/ hexpocon"
    * Respond to the prompts:
        * "Do you want to continue running the setup script?" type y and return
        * Enter observer names
        * Confirm data directory (e.g. /s/sdata125/hires?/20??monDD/)
            * Use the current UT date. (typically one day later than local calendar date), hit enter.
            * The 'hires?' part of the path corresponds to your HIRES user account given by the SA
        * Set starting observation number at 1
* Now appearing on the 3 screens:
    1) HIRES dashboard, exposure meter dashboard, terminal
    2) XHIRES GUI, dewar level window
    3) SAO image: ds9
* Start the iodine cell:
    * From the desktop pulldown menu: "HIRES control menu" > "Iodine cell menu" > "Start Iodine Cell"
    * Cell takes 45 minutes to warm up fully. A warm cell reads:
        * tempiod1 | 65 degrees
        * tempiod2 | 50 degrees  (+/- 0.1 degree)
* Check ln2 dewar level:
    * In a terminal within the VNC session type: ``ln2``
    * The dewar level is also visible when using "START all HIRES GUIs" in the window with the XHIRES GUI.
    * Top off dewar (if level is below 70%)
        * Select "HIRES Control Menu" > "Initiate HIRES Dewar Fill" from the desktop pulldown menu
    * Dewar evaporation rate is 5% per hour and auto-refills at 10%. Always try to avoid an auto refill.
    * If the dewar is filled after ~2 pm Hawaii Time, then it does not need refilled near sunset.
* Open the Mirror Covers
    * On the XHIRES GUI window click ETC, then click OPEN RED
* Set up file names:
    * On HIRES dashboard, click on yellow "Start Here" button.
    * Click on "retrieve" to install directory for raw data and frame number.
    * Update "Filename root" with UT date for the night followed by an underscore. (e.g. `20180201_`)
    * Click on "Commit" to set values, then dismiss the window.
* Set CCD parameters
    * CCD Binning: Enter in the left box: X = 3 , Y = 1 or click on "Binning" and pull down to "X3Y1".
    * Check/Set OUTDIR: directory for raw data
    * Check/Set OUTFILE: prefix of filenames, i.e. `20180201_`
    * Check CCD readout mode: gain = "low" (default), speed = "fast" (default)
* Spectrograph configuration:
    * Slit should read 14.08" (``m slitname = opened``)
    * Filter1 = clear (``m fil1name = clear``; using gui okay)
    * Filter2 = clear (``m fil2name = clear``; using gui okay)
    * Collimator = red (This should always be set by SA)
    * Set collimator focus: ``m cofraw = +70000``; Use ``s cofraw`` to show value (±2000 units is insignificant)
    * Set camera focus: ``m cafraw = 0``; Use ``s cafraw`` to show value (±2000 units is insignificant)
    * Move echelle and cross disperser angles with "A" button to positions from last HIRES-PRV night (get these values from your SA)
* Guide camera configuration:
    * Filters: BG38 + ND0.01 (BG38 is important, ND up to OA)


.. _alignment:

Spectrograph Alignment and Focus
================================
Specific spectral lines must fall on specific pixels on the detector and that the spectral lines are
as well-focused as possible.

* Turn OFF Exposure meter
* Lamp: Th-Ar #2
* Lamp Filter: NG3 filter
* In terminal window: ``m deckname = D5`` (in a terminal window on lehoula)
* Iodine: Out
* ObsType = Object
* Texp: 10 sec (in brown "CCD" window, enter exposure time. Click "UpdateCCD")
* Set x-disperser and echelle to values from previous HIRES-PRV night.
* Click "EXPOSE"
* Run focus and alignment analysis in IDL:
    * Have your SA direct you to the location of the IDL alignment code
    * From within that directory launch IDL and run ``foc`` on the just-collected ThAr spectrum (e.g. ``IDL> foc,inpfile='20180201_0001.fits'``)
    * Check instructions from focus program and move echelle and cross disperser as needed.
    * If focus program crashes, you may need to move echelle or cross disperser manually.
    * If note regarding 'Counts in lines too low' appears re-position lines manually.
    * Check fwhm focus value returned by the focus program. It should be in the range 2.28-2.40.
    * If the fwhm is greater than 2.40, try changing the cafraw (add 10,000 to the current value). Use the terminal command: ``m cafraw = 10000``. Keep changing the cafraw value in steps of 10,000 until you observe a minimum in the fwhm values. (this should need to be done only rarely)
* If manual grating moves are needed:
    * First double check that you are at the same echelle and cross disperser positions from the last HIRES-PRV run
    * Run ``foc.pro`` with the ``/mark`` flag: ``IDL> foc,inpfile='20180201_0001.fits', /mark``
    * Note positions of bright lines relative to boxes drawn on echelle format
    * Estimate the appropriate moves to center the lines in the boxes. This may require some trial and error.
        * Horizontal: +0.001 deg of echelle rot moves lines left by 1 column
        * Vertical: +0.002 deg of X-disp rot moves lines down by 1 row


.. _calibrations:

Required Calibrations
=====================
The pipeline requires a very specific set of calibration data.

* Thorium-Argon exposures w/ B5
    * Turn OFF Exposure meter
    * Lamp: Th-Ar #2
    * Lamp Filter: ng3
    * Decker: B5 ``m deckname = B5`` (0.85 x 3.5 arcsec, ==> 4.0 pixel projected slit) *WARNING: Never use the HIRES GUI to switch deckers! Using the GUI will adjust cofraw/cafraw and the* :ref:`focus and alignment process <alignment>` *will need to be repeated.*
    * Iodine: Out
    * Exposure: 1 sec (take 1 or 2 at beginning and end of night)

* Thorium-Argon exposures w/ B1
    * Turn OFF Exposure meter
    * Lamp: Th-Ar #2
    * Lamp Filter: ng3
    * Decker: B5 ``m deckname = B5`` (0.85 x 3.5 arcsec, ==> 4.0 pixel projected slit)
    * Iodine: Out
    * Exposure: 2 sec (take 1 or 2 at beginning and end of night)

* Iodine cell calibrations w/ B1
    * Make sure cell is fully warmed up (see p.1) before taking these.
    * Turn OFF Exposure meter.
    * Lamp: Quartz2
    * Lamp Filter: ng3
    * Decker: B1 ``m deckname=B1`` (0.57 x 3.5 arcsec, ==> 3.0 pixel projected slit)
    * Iodine: In
    * Exposure: 3 secs
    * check saturation: < 20,000 counts on middle chip?
    * Check I2 line depth. In center of chip, it should be ~30%

* Iodine cell calibrations w/ B5
    * Make sure cell is fully warmed up (see p.1) before taking these.
    * Turn OFF Exposure meter.
    * Lamp: Quartz2
    * Lamp Filter: ng3
    * Decker: B5 ``m deckname=B5`` (0.57 x 3.5 arcsec, ==> 3.0 pixel projected slit)
    * Iodine: In
    * Exposure: 2 secs
    * check saturation: < 20,000 counts on middle chip?
    * Check I2 line depth. In center of chip, it should be ~30%

* Wideflats
    * Turn OFF Exposure meter
    * Lamp: Quartz2
    * Lamp Filter: ng3
    * Decker: C1 ``m deckname = C1`` (0.85 x 7.0 arcsec, ==> 4.0 pixel projected slit)
    * Iodine: Out
    * Exposure : 1 sec (check saturation: middle chip should have 10,000 < counts < 20,000)
    * Collect remaining exposures using the command ``exp_acq 49 ; m lampname=none ; m deckname=C2``. This command will:
        * Take 49 exposures with the current setup
        * Turn off all lamps
        * move to the C2 decker to prepare for the first stellar observation


.. _stars:

Observations of Stars
=====================
Instrumental configuration, considerations, and best practices for observing stars during the night.

* Use the C2 (0.85x14 arcsec) decker for RV observations of stars fainter than V=10 or during twilight, otherwise use B5 (0.86x3.5 arcsec)
* Check iodine temperature (should be 50C)
* Top off ln2 dewar ~30 min before sunset
* Open telescope monitoring GUIs from within ``kvnctel`` session
    * From a blue desktop background click and select: "K1 Guider Eavesdropping" > "Start Observer UI (MAGIQ)"
    * From a blue desktop background click and select: "K1 Telescope Status Menu" > "FACSUM"
    * From a blue desktop background click and select: "K1 Telescope Status  Menu" > "XMET"
* Start exposure meter
    * Click on the upper left button "System Start" on exposure meter.
    * Click on "Arm" in upper left of right panel to start target monitoring.
    * Default exposure level is 250000, equivalent to SNR ~200
* Set max exposure time as appropriate (in HIRES Dashboard CCD ExpTime)
    * Expected Exposure time: At V=8, S/N=300 in 300 seconds
    * Allow for longer than nominal exposure times in case of clouds
* Open HIRES hatch
* Check with OA that "slit guiding algorithm" is being used
* Once exposing on first star add a "fiducial mark" at the position of the star by right clicking the magic guider snapshot at the desired location
* During the night, continue to check:
    * Iodine temperature is 50/65C, and iodine is running
    * vertical angle mode is on and set to 0.
    * Filter #1 is "clear"
    * Filter #2 is "clear"
    * TV filters are "bg38" and "nd_0.01"
    * Iodine IN/OUT as appropriate
    * Periodically check seeing by using the projection cut tool in DS9. The pixel scale in the spatial dimension is ~0.3"
    * Ask the SA to run a telescope focus every ~3 hours or if you notice significant, unexplained degradation in your seeing estimates
* Start observing bright stars up to 20 min before 12 degree twilight:
    * High SNR observations of B stars should be the first and last observations of the night (one shot at start and one at end). See `Clubb et al. (2018) <http://adsabs.harvard.edu/abs/2018RNAAS...2a..44C>`_ for a selection of suitable B stars.
    * ``m deckname = C2`` (0.85 x 14.0 arcsec)
    * If seeing is > 2.0", then begin observing only 10 minutes before 12 deg twilight and use B5.
    * Likewise if seeing > 2.0" at the end of the night, use B5 in twilight and end 10 minutes after 12deg
    * *WARNING: use command line to change deckers, NOT HIRES GUI*
    * Avoid observing stars fainter than V~11 in twilight (morning or evening).
* During/after -12-degree twilight:
    * ``m deckname = B5`` (0.85 x 3.5 arcsec, ==> 4.0 pixel projected slit)
* In case of poor seeing (>2 arcsec)
    * Stick to V < 10 stars (throughput)
    * Use B5 decker. Sky subtraction does not work well when stellar PSF fills the slit (seeing > 2.5").
* Telescope wrap limits
    * From the south wrap, moving through the west, the north limit is an azimuth of 325 degrees.
    * From the north wrap, moving through the west, the south limit is an azimuth of 235 degrees.

.. _template:

Template Observations
=====================
* Templates should have 2-3x higher SNR than the iodine observations they will be used to analyze

.. _bstars:

* Templates must be bracketed by iodine-in observations of rapidly rotating B stars.
    * We recommend selecting B stars from `Clubb et al. (2018) <http://adsabs.harvard.edu/abs/2018RNAAS...2a..44C>`_
    * B stars should be near in the sky as possible to the target
    * Three consecutive exposures of two different B stars on either side of the target exposure(s) are recommended
    * The B star observations should be collected using the same decker as the template observation and exposed to 250k on the exposure meter

* Always ask the OA to focus the telescope before a template sequence
* Use the B3 decker for stars fainter than V=10, B1 for brighter stars, or E2 for very bright and very RV stable stars
* Consecutive exposures of the target star between the B stars will be stacked together to maximize SNR
* Total exposure time for the template exposure(s) should not exceed 1.5 hours

Target Lists
============
Create your target list during the day and upload to the Keck computers. Your SA can help you upload.

* Make a "script" for the full night of observations following the `Keck guidelines <https://www2.keck.hawaii.edu/observing/starlist.html>`_
* Target names must be resolvable by Simbad to obtain accurate coordinates and proper motions
* Consult the plot on the :ref:`RV performance page <performance>` when considering exposure times and signal to noise ratios
* Inform the operator of the path to your script you will use and ask them to load it into MAGIQ.
* Once the OA has loaded the list, click on 'Map OA starlist' from dropdown on MAGIQ (Useful for planning observations.)
* Use the middle mouse button to highlight the next target to observe.

Partial Nights
==============
The instrumental configuration is very sensitive. The focus and alignment should be rechecked in the event you receive a
handoff from a non HIRES-PRV user during the night.

* Setup HIRES as normal in the afternoon
* At the handoff:
    * Check the filename prefix and frame number
    * Set cofraw, cafraw, echelle and cross disperser to the correct positions.
    * Run :ref:`alignment and focus procedure <alignment>`
* Run through the HIRES setup instructions to ensure correct configuration

End of Night
============
You may leave the instrument set up during multi-night runs.

* If not the last night of the run:
    * Turn off exposure meter.
    * Close the hatch
    * Take B1/B5 iodine exposures.
    * Take B1/B5 thorium exposures.
    * Turn off lamps, but leave everything else open

* If last night of run:
    * From a desktop pulldown menu, select: "HIRES control menu" > "End of Night Shutdown"

Tips, Tricks, & Troubleshooting
===============================
* Cross-disperser oscillations:
    * If cross-disperser values are oscillating, reset by right-clicking blue background and selecting "HIRES Control Menu" > "Stop Cross-disperser Oscillation"
    * Avoid moving cross-disperser by increments >0.5 to help prevent oscillations. Move in multiple steps if needed.
* General tips about Keck observing: `<http://keckobservatory.org/about/observing/>`_
* Useful link with extra HIRES info: `<http://www2.keck.hawaii.edu/inst/hires/startup.html>`_
* In ds9, if the mouse, clicking and dragging is zooming, instead of drawing a cross section, choose Edit→Pointer
* When using the C2 decker, always be careful to center the star on the slit.
* Useful directories:
    * data: /s/sdata125/hires1/2011apr31/ (insert proper date)
    * guider snapshots: /s/nightly1/11/08/30 (where 11/08/30 is yr/mo/dy)
