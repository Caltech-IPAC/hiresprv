.. _performance:

Velocity Precision
******************

Consult the plot below when considering exposure times needed to achieve a desired RV precision. This does not
factor in any additional sources of instrumental and/or astrophysical noise.

.. figure:: _static/snr_vs_err.png
    :width: 50%
    :align: center
    :alt: radial velocity fit

    Photon-limited single measurement precision as a function of exposure meter setting and signal to noise ratio.
    The red line traces the lower 30th percentile of the individual measurements shown in grey. Signal to noise ratios
    below 70 (indicated with grey shading) are not officially supported by the pipeline and may produce erratic results.


Known Planet Recovery
=====================

We demonstrated the ability to detect the PRV signatures of small planets by analyzing one year of archival data collected
on the star HD 7924 in addition to the sample nights referenced in the :ref:`tutorial <data_reduction_overview>`. This star is known to host three small planets (`Howard et al. 2009 <http://adsabs.harvard.edu/cgi-bin/nph-data_query?bibcode=2009ApJ...696...75H&db_key=AST&link_type=ABSTRACT>`_;
`Fulton et al. 2015 <http://adsabs.harvard.edu/cgi-bin/bib_query?arXiv:1504.06629>`_). We use `RadVel <http://radvel.readthedocs.io>`_ to fit the data, seeding the fit
with the known orbital periods. We can successfully recover the correct velocity semi-amplitude (K) and mass for planet b with only ~75% of the data presented
in `Howard et al. (2009) <http://adsabs.harvard.edu/cgi-bin/nph-data_query?bibcode=2009ApJ...696...75H&db_key=AST&link_type=ABSTRACT>`_.

.. figure:: _static/HD7924_rv_multipanel.png
    :width: 50%
    :align: center
    :alt: radial velocity fit

    Fit results for HD 7924.
