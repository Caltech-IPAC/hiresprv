#!/bin/sh

sed -i .bak -e 's/hiresprv.ipac.caltech.edu/prvdev.ipac.caltech.edu:9020/' hiresprv/archive.py
sed -i .bak -e 's/hiresprv.ipac.caltech.edu/prvdev.ipac.caltech.edu:9020/' hiresprv/auth.py
sed -i .bak -e 's/hiresprv.ipac.caltech.edu/prvdev.ipac.caltech.edu:9020/' hiresprv/database.py
sed -i .bak -e 's/hiresprv.ipac.caltech.edu/prvdev.ipac.caltech.edu:9020/' hiresprv/download.py
sed -i .bak -e 's/hiresprv.ipac.caltech.edu/prvdev.ipac.caltech.edu:9020/' hiresprv/idldriver.py
sed -i .bak -e 's/hiresprv.ipac.caltech.edu/prvdev.ipac.caltech.edu:9020/' hiresprv/status.py

rm -f hiresprv/*.bak
