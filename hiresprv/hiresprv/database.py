"""
Each HIRES PRV pipeline server workspace contains a database
of all the HIRES radial velocity data retrieved from KOA for
the user.

The HIRES PRV Database class provides methods for querying that
database.  This information is primarily used to plan reduction
and analysis processing for specific sky targets.
"""

class Database:
    """
    A HIRES PRV pipeline login creates a cookie that allows reconnection to 
    a specific workspace.  Database class intialization uses that cookie to
    look up the users workspace and the class methods provide various ways of
    querying the data.
    """

    def search(self, sql, format):
        """
        The HIRES PRV Database search method is the most general mechanism for
        querying a workspace database.  The user has the freedom to provide a
        general SQL SELECT statement (specifying both the database columns to 
        be retrieved and constraints on the records returned.  The user can
        also select an output format (html, csv or IPAC ASCII).
        """

        print('workspace database records')

    def target_list(self):
        """ (TBD) Documentation on Database.target_list """
        print('hiresprv.Database.target_list()')

    def target_info(self, target):
        """ (TBD) Documentation on Database.target_info """
        print('hiresprv.Database.target_info()')

    def sqlite(self):
        """ (TBD) Documentation on Database.download_sqlite """
        print('hiresprv.Database.sqlite()')
