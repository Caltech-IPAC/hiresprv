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
