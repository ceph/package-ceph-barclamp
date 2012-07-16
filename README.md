package-ceph-barclamp
=====================

Script created to package up the ceph barclamp.

In order to use this script you should download it to the directory where your barclamp's folder is stored::

wget https://raw.github.com/jgalvez/package-ceph-barclamp/master/package-ceph.sh

Then give the application execute permissions::

chmod +x package-ceph.sh

Finally you must execute the script with a single argument, the folder which contains your ceph barclamp::

./package-ceph.sh barclamp-ceph/

When completed you should have a ceph.tar.gz file in your current directory.