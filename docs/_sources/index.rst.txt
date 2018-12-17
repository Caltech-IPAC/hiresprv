Documentation for the HIRES Radial Velocity Processing Environment
******************************************************************

This is a radial velocity processing environment that can be used to transform raw `Keck/HIRES <https://www2.keck.hawaii.edu/inst/hires/>`_ spectra into
publication-ready precision radial velocities (PRVs). Data collected only in the prescribed :ref:`HIRES-PRV configuration <setup>` will be compatible with this PRV
processing environment.

A Python API provides a convenient way to interact with the service running on `NExScI <http://nexsci.caltech.edu>`_ servers. The
source code for the Python package is on `GitHub <https://github.com/Caltech-IPAC/hiresprv>`_.

Please post any questions regarding the HIRES-PRV configuration or the NExScI PRV
processing environment to the `GitHub issue tracker <https://github.com/Caltech-IPAC/hiresprv/issues>`_.


Installation Instructions
=========================
We recommend that users first install `Anaconda Python <https://www.anaconda.com/download/>`_ or a similar scientific computing environment for Python.

Python 3.6 or greater is required.

The HIRES-PRV Python package can be installed from PyPI:

.. code-block:: bash

    $ pip install hiresprv


Planning and Conducting Observations
====================================
There are several important considerations for observers wishing to utilize the HIRES PRV configuration.
Only data collected in the specified HIRES-PRV configuration and according to the recommendations
summarized below can be processed properly within the NExScI HIRES-PRV environment.

* Observers new to the HIRES-PRV configuration should treat this configuration as a "new" instrument, which comes with requirements from Keck observatory. If you have not previously observed in the HIRES-PRV mode then you must be trained in person at Keck Headquarters in Waimea.
* The echelle and cross disperser angles must be set at specific angles as part of the :ref:`afternoon setup <alignment>` and must not be changed during the night.
* A minimum of three PRV observations with the iodine cell inserted on a given target are required before any PRVs will be produced.
* The minimum signal-to-noise ratio per pixel for each iodine-in RV observation must be at least 70 with the optimal SNR being 200.
* One high SNR (at least 100 per pixel) :ref:`template observation <template>` of the target without the iodine cell must be collected before any PRVs can be measured.
* The optimal SNR for the iodine-out template is 2x the typical iodine-in observation.
* Each iodine-out template observation must be bracketed by 2-5 exposures of :ref:`bright, rapidly-rotating stars <bstars>` with the iodine cell in for calibration.
* Individual exposure times should be no longer than 1 hour.
* Target names must be resolvable by Simbad to obtain accurate coordinates and proper motions

See link below for detailed instrument configuration and observing instructions.
   * :ref:`Observing Instructions <setup>`


Data Reduction Tutorial
=======================
The reduction of HIRES PRV data consists of four basic steps.
   1) Transfer files from the `Keck Observatory Archive (KOA) <https://www2.keck.hawaii.edu/koa/public/koa.php>`_ and extract into 1D spectra.
   2) Construct a template from an iodine-free observation of your target star.
   3) Analyze each PRV observation collected with the iodine cell in the light path
   4) Concatenate into an PRV timeseries.

We have provided a sample tutorial to guide you through the reduction. The tutorial is a Jupyter notebook.
Please note have not tested the notebook itself and do not guarantee its performance.
   * :ref:`data_reduction_overview`


Understanding the Outputs
=========================
Calibrated and extracted 1D spectra, PRV timeseries for any stars with sufficient data, and the database of your observations
can be downloaded to your local machine from your workspace on the server.

The contents of those files are documented here:
   * :ref:`outputs`


Velocity Precision
==================
We have performed a comparison of the velocities produced by this service to archival velocities derived from
those same observations. We find consistent results and comparable precision.

See link below for a prediction of RV precision as a function of signal to noise ratio.
    * :ref:`performance`


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
