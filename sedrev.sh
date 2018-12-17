#!/bin/sh

sed -i .bak -e 's/prvdev.ipac.caltech.edu:9020/hiresprv.ipac.caltech.edu/' hiresprv/archive.py
sed -i .bak -e 's/prvdev.ipac.caltech.edu:9020/hiresprv.ipac.caltech.edu/' hiresprv/auth.py
sed -i .bak -e 's/prvdev.ipac.caltech.edu:9020/hiresprv.ipac.caltech.edu/' hiresprv/database.py
sed -i .bak -e 's/prvdev.ipac.caltech.edu:9020/hiresprv.ipac.caltech.edu/' hiresprv/download.py
sed -i .bak -e 's/prvdev.ipac.caltech.edu:9020/hiresprv.ipac.caltech.edu/' hiresprv/idldriver.py
sed -i .bak -e 's/prvdev.ipac.caltech.edu:9020/hiresprv.ipac.caltech.edu/' hiresprv/status.py

rm -f hiresprv/*.bak
