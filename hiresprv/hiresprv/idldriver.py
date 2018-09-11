"""
The principle processing of the HIRES PRV pipeline is done by a
set of IDL scripts developed over several decades.  This processing
is quite intensive and takes a long time and so is run in the 
background.

The HIRES PRV idlDriver class provides functionality that allows
the user to submit radial velocity data reduction scripts that 
get sent to a sequence of these IDL scripts.
"""

class idlDriver:
    """
    The idlDriver class intialization checks for cookie indicating a previous
    login that connects to the user to a PRV pipeline workspace.  This
    workspace is populated with data from the KOA Archive using Archive class
    methods.
    """

    def run(self, script):
        """
        The HIRES PRV idlDriver class run method is given a script of steps to
        run on the data in a workspace.  These steps include creating a
        template spectrum for a sky target, reducing a specific radial velocity
        measurement using such a template, and creating an RV curve from a set
        of reduced RV measurements.
        """

        print("Processing PRV script.")
