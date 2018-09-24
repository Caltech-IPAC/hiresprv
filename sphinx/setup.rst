.. _setup:

Instrument Configuration Instructions
=====================================

Afternoon Setup
===============

HIRES must be configured in a very specific way in order for the pipeline to function and produce reliable PRVs.
Carefully follow these instructions in order to ensure the pipeline is able to reduce your data.

* Start up the HIRES VNC sessions on the observing computer
* Start HIRES GUIs
    * Left-click on tan background
    * Select HIRES CONTROL MENU
    * Drag over to: START all HIRES GUIs w/ hexpocon
    * Respond to the prompts:
        * "Do you want to continue running the setup script?" type y and return
        * Enter observer names
        * Confirm data directory (e.g. /s/sdata125/hires1/20??monDD/)
            * Use the current UT date. (typically one day later than local calendar date), hit enter.
        * Set starting observation number at 1
* Now appearing on the 3 screens:
    1) HIRES dashboard, exposure meter dashboard, terminal
    2) XHIRES GUI, dewar level window
    3) SAO image: ds9
* Start the iodine cell:
    * Select from desktop pulldown: "HIRES control menu > Iodine cell menu > Start Iodine Cell"
    * Cell takes 45 minutes to warm up fully. A warm cell reads:
        * tempiod1 | 65 degrees
        * tempiod2 | 50 degrees  (+/- 0.1 degree)
* Check dewar level:
    * In a terminal type: ln2
    * The dewar level is also visible when using "START all HIRES GUIs" in the window with the XHIRES GUI.
    * Top off dewar (if level is below 70%)
        * right-click on tan background,
        * drag to "HIRES Control Menu"  and  "Initiate HIRES Dewar Fill"
    * dewar evaporation rate is 5% per hour and auto-refills at 10%. Always try avoid an auto refill.
    * If the dewar is filled after ~2 pm Hawaii Time, then it does not need refilled near sunset.
* Open the Mirror Covers
    * From XHIRES GUI > click ETC > Click OPEN RED
* Set up file names:
    * On HIRES dashboard, click on yellow "Start Here" button.
    * Click on "retrieve" to install directory for raw data and frame number.
    * Update "Filename root" with current date and underscore. (e.g. `20180201_`)
    * Click on "Commit" to set values.
* Set CCD parameters
    * CCD Binning: Enter in the left box: X = 3 , Y = 1 or click on "Binning" and pull down to "X3Y1".
    * Check/Set OUTDIR: directory for raw data
    * Check/Set OUTFILE: prefix of filenames, i.e. `20180201_`
    * Check CCD readout mode:
    * Gain = "low" (default)
    * Speed = "fast" (default)
* Spectrograph configuration:
    * Slit should read 14.08" (m slitname = opened)
    * Filter1 = clear (m fil1name = clear; using gui okay) (Formerly KV370)
    * Filter2 = clear (m fil2name = clear; using gui okay)
    * Collimator = red (This should always be set by SA)
    * In a terminal:
        * Set collimator focus: m cofraw = +70000; Use 's cofraw' to show value
        * Set camera focus: m cafraw = 0; Use 's cafraw to show value'
        * Move echelle and cross disperser angles with "A" button to positions from last HIRESprv night (get these values from your SA)
* Guide camera configuration:
    * Filters: BG38 + ND0.01 (BG38 is important, ND up to OA)


Spectrograph Alignment and Focus
================================

We must ensure that specific spectral lines fall on specific pixels on the detector and that the spectral lines are
as well-focused as possible.

* Turn OFF Exposure meter
* Lamp: Th-Ar #2
* Lamp Filter: NG3 filter
* In terminal window: 'm deckname = D5 (in lehoula window)'
* Iodine: Out
* ObsType = Object
* Texp: 10 sec (in brown "CCD" window, enter exposure time. Click "UpdateCCD" )
* Set x-disperser and echelle to values from previous HIRESprv night.
* Click "EXPOSE"
* Run focus and alignment analysis in IDL:  ``IDL> foc,inpfile='20180201_0001.fits'``
    * Check instructions from focus program and move echelle and cross-disperser as needed.
    * If focus program crashes, you may need to move echelle or cross disperser manually.
    * If note regarding 'Counts in lines too low' appears. Re-position lines manually.
    * Check fwhm focus value returned by the focus program. It should be in the range 2.28-2.40.
    * If the fwhm is greater than 2.40, try changing the cafraw (add 10,000 to the current value). Use the terminal command: m cafraw = 10000. Keep changing the cafraw value in steps of 10,000 until you observe a minimum in the fwhm values. (This should need to be done only rarely.)
* If manual grating moves are needed:
    * Horizontal: +0.001 deg of echelle rot moves lines left by 1 column
    * Vertical: +0.002 deg of X-disp rot moves lines down by 1 row
    * As a last resort change cafraw or cofraw on command line to focus (using m cafraw= and m cofraw=). Try cafraw first; steps of ~10,000 are needed in cafraw to make any appreciable difference in focus.


