How To: Package the Ceph Barclamp for Dell Crowbar
=====================

In order to use this script you should download it to the directory where your barclamp's folder is stored:

```bash
$ wget https://raw.github.com/jgalvez/package-ceph-barclamp/master/package-ceph.sh
```

Then give the application execute permissions:

```bash
$ chmod +x package-ceph.sh
```

Finally you must execute the script with a single argument, the folder which contains your ceph barclamp:

```bash
$ ./package-ceph.sh barclamp-ceph/
```

When completed you should have a ceph.tar.gz file in your current directory.

This tarball should be uploaded to your admin node, once there extract and install it:

```bash
$ tar zxvf ceph.tar.gz
$ sudo /opt/dell/bin/barclamp_installer.rb /path/to/bar --force
```

Using --force will overwrite any files from a previous install of the same barclamp.

You may need to restart your crowbar-webserver at this point:

```bash
$ sudo bluepill crowbar-webserver restart
```