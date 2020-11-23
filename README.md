<p align="center">
  <a href="https://nexsci.caltech.edu">
    <img src="https://github.com/Caltech-IPAC/hiresprv/blob/master/sphinx/_static/hiresprv_logoh.png?raw=true" width="500" align="center">
  </a>
</p>

# Keck HIRES PRV Pipeline Service Access

[![PyPI version](https://badge.fury.io/py/hiresprv.svg)](https://badge.fury.io/py/hiresprv)

##### [Documentation](https://caltech-ipac.github.io/hiresprv)


#### Version 3.0 released!

v3.0 presents minor changes to the code and functionality but your workspace initializes with all compatible HIRES data since the 2004 CCD upgrade already pre-processed.


#### Version 2.0 released!

v2.0 enables the following features:

* processing archival HIRES data collected in the correct configuration
* access to your workspace directory structure and the ability to download any file within it
* activate/deactive specific files/observations

See the <a href="https://caltech-ipac.github.io/hiresprv/tutorials/Advanced_Usage.html">advanced usage tutorial</a> to see how to use the new features.


<b>Note:</b> If you just want to use the library, you can install it with "<i>pip install hiresprv</i>".
The example Jupyter page can be downloaded from [this repo](Jupyter/HIRES_PRV_Service.ipynb)
and viewed <a href="https://caltech-ipac.github.io/hiresprv/tutorials/HIRES_PRV_Service.html">here</a>.

This repository contains all the software necessary to run the HIRES PRV pipeline remotely from Python
and reduce astronomical radial velocity measurements from that instrument.

The "hiresprv" directory contains the software itself, though most users will normally install it using
PyPI ("pip install hiresprv"). Use `pip install hiresprv --upgrade` to update to the latest version.

The "Jupyter" directory contains a Jupyter page that illustrated the end-to-end process of using the
Python tools for reduction.  This page has not been tested and inferring anything from it is done
at your own risk.

The "sphinx" directory contains documentation, including the library documents generated from in-line
Python docstrings, as a Sphinx document set.

The "docs" directory is a copy of the files generated by Sphinx.  This directory (and its name) are 
used primarily by Git Pages to make a web site for the project documentation.  To see that rendering
of the Sphinx documentation, see: https://caltech-ipac.github.io/hiresprv/index.html
