""" 
The HIRES PRV pipeline is used to retrieve user-specified radial velocity 
data from the KOA archive to a user-specific pipeline server workspace, 
automatically perform raw data reduction (converting the 2D spectral files 
to 1D spectra) and then run user-defined reduction scripts to ultimately
generate RV curves for specific sky objects.

The data is retrieved a day at a time (a full night's data is needed for
the raw reduction).  Metadata for all the files retrieved is stored in a
workspace/user-specific database table, which is user-searchable and 
provides the information needed to construct reduction scripts.

Both the archive retrieval and reduction steps can be quite lengthy
(often hours), so this is done in background and there are tools for
monitoring the state of the processing.
"""
