"""
The HIRES PRV processing involves moving and reducing quite a lot of
data and can be quite lengthy.  Most of this processing is therefore
done in background.

The PRV Status class is used to check the state of the processing,
either in detail to watch progress or simply to check whether the 
workspace is 'busy'.  New processing will be rejected until the 
workspace is ready.
"""

class Status:
    """
    The HIRES PRV Status class initialization check for the existence of a
    login cookie and connects the user to their workspace.  Methods of this
    class return information on the current state or can be used to cancel
    processing.
    """

    def processing_status(self, format):
        """
        The HIRES PRV Status class processing_status method returns a summary of
        the progress of the current processing step.  For archive retrieval this
        includes each file transfer and each raw reduction operation.  For data
        reduction scripts, this includes the various steps in the IDL processing.

        An attempt has been made to update the processing status every few 
        seconds to a minute but a few operations will run longer.
        """
        
        print("processing status")

    def is_busy(self):
        """ (TBD) Documentation on Status.is_busy """
        print("hiresprv.Status.is_busy()")

    def cancel(self):
        """ (TBD) Documentation on Status.cancel """
        print("hiresprv.Status.cancel()")
