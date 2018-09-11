"""
KOA archive access functions for the HIRES PRV pipeline reduction service.  
After finding matching data, the files are copied to the user's pipeline
workspace and raw data reduction is performed.  Because of pipeline requirements,
data is always processed a full night at a time.
"""

class Archive:
    """
    The HIRES PRV Archive class provides methods for searching the
    KOA Archive for radial velocity data from the HIRES instrument.
    This data is downloaded to a permanent workspace on the PRV 
    pipeline machine and basic raw reduction is performed.
    """

    def search_by_dates(self, dates):
        
        """Search archive by set of dates.

        The user's KOA credentials (given at login) are used to search the
        Keck On-line Archive (KOA).  Matching data are copied to the user's
        workspace and raw reduction (conversion to 1D spectra, barycentric
        correction, etc.) is performed.  Results are logged in the workspace
        database table.  All this is done in background; this function 
        returns almost immediately with an acknowledgement.

        Args:
            dates (multi-line or comma-delimited string or array of strings) 
                dates for data to be processed, in YYYY-MM-DD format.

        Returns:
            JSON structure with status ('ok' or 'error')  and a message string
            e.g., {'status':'error', 'msg':'Failed to connect to KOA'}

        """

        print("{status':'ok', 'msg':'Processing dates in background.'}")
