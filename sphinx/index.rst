
Welcome to the HIRES PRV Reduction Service Documentation
========================================================

This is a radial velocity processing environment that can be used to transform raw spectra into
publication-ready precision radial velocities (PRVs) from Keck/HIRES spectra.

HIRES is now available in a dedicated precision radial velocity configuration.
Data collected in the prescribed HIRES-PRV configuration will be compatible with this radial velocity
processing environment which will produce wavelength-calibrated 1D spectra and
time-series of relative PRVs.

There are several important considerations for observers wishing to utilize the HIRES PRV configuration;
only data collected in the specified HIRES-PRV configuration and data collected according to the recommendations
summarized below can be processed properly within the NExScI HIRES processing environment.

* The echelle and cross disperser angles must be set at specific angles as part of the HIRES-PRV afternoon setup and must not be changed during the night.
* A minimum of 3 PRV observations with the iodine cell inserted for a given target are required. The minimum signal-to-noise ratio per pixel for each of these observations must be at least 70 with the optimal SNR being 200.
* One high SNR (at least 100 per pixel) template observation of the target with the iodine cell removed from the optical path. The optimal SNR for the iodine-out template is 2x the typical iodine-in observation. Several consecutive observations may be stacked to increase the SNR.
* Each iodine-out template observation must be bracketed by 2-5 exposures of bright, rapidly-rotating B stars with the iodine cell in for calibration. These stars should be as near as possible on the sky to the target star.
* Individual exposure times should be no longer than 1 hour and iodine-out template observations should span no more than 1.5 hours.
* Observers new to the HIRES-PRV configuration should treat this configuration as a "new" instrument.

A Python API provides an easy way to interact with the service. The
source code is available `here <https://github.com/Caltech-IPAC/hiresprv>`_.

Please post any questions regarding the HIRES-PRV configuration or the NExScI PRV processing environment to the GitHub issue tracker.


We reccomend users install Anaconda Python or a similar scientific computing environemnt for Python.


Installation Instructions
=========================

The HIRES-PRV Python library can be installed from PyPy:

.. code-block:: bash

    $ pip install hiresprv


Planning and Conducting Observations
====================================
* :ref:`setup`


Data Reduction Tutorial
=======================
* :ref:`data_reduction_overview`


Understanding the Outputs
=========================
* :ref:`outputs`

Table of Contents
=================

.. toctree::
   :maxdepth: 2
   :name: mastertoc
   :caption: Contents:

   setup
   data_reduction_overview
   outputs
   performance
   hiresprv

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`


This documentation was last updated on |today|.
