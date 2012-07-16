#!/bin/bash

#Package Ceph Barclamp
#This script makes packaging the ceph barclamp simple (hopefully)
#jj.galvez@inktank.com

if [ ! -d "$1" ]; then
	echo "Pass the name of the barclamp folder you are trying to package."
	exit;
fi

if [ -f "$1/crowbar.yml" ]; then
	echo "Verified the crowbar.yml file exists."
else
	echo "No crowbar.yml file exists!"
	exit;
fi

workingdir=$1
name=`grep 'name: ' ${workingdir}/crowbar.yml | awk {'print \$2'}`
startdir=`pwd`

tmpfolder="/tmp/package-barclamp"
cachefolder="${tmpfolder}/cache"
mirrorfolder="${tmpfolder}/mirrors"
gemfolder="${workingdir}/cache/gems"

statusfile="${tmpfolder}/status"
sourcefile="${tmpfolder}/sources.list"

distrolist="ubuntu-12.04"
packagelist="ceph ceph-dbg ceph-common ceph-common-dbg libcephfs1 gdisk"
gemlist="open4"

echo "Creating tmp folders..."
mkdir -p $tmpfolder
mkdir -p $cachefolder
mkdir -p $mirrorfolder
echo "Done."

touch $sourcefile

echo "Writing to tmp sources.list..."
tee $sourcefile <<-'EOL'
deb http://gitbuilder.ceph.com/ceph-deb-precise-x86_64-basic/ref/master precise main
deb http://us-west-1.ec2.archive.ubuntu.com/ubuntu/ precise main restricted universe multiverse
deb http://us-west-1.ec2.archive.ubuntu.com/ubuntu/ precise-updates main restricted universe multiverse
deb http://us-west-1.ec2.archive.ubuntu.com/ubuntu/ precise-security main restricted universe multiverse
EOL
echo "Done."

echo "Creating an empty status file..."
cat /dev/null > ${statusfile}
echo "Done."

echo "Updating aptitude with tmp sources.list"
sudo apt-get -qq update -o=Dir::Cache::archives=${cachefolder} -o=Dir::State:status=${statusfile} -o=Dir::State=${tmpfolder} -o=Dir::Etc::sourcelist=${sourcefile}
echo "Done."

for distro in ${distrolist}; do

	distrocachedir="${workingdir}/cache/${distro}/pkgs"
	mkdir -p ${distrocachedir}

	for package in ${packagelist}; do
                echo "Grabbing dependencies for ${package}..."
		for dep in `echo $(apt-cache show -o=Dir::Cache::archives=${cachefolder} -o=Dir::State:status=${statusfile} -o=Dir::State=${tmpfolder} -o=Dir::Etc::sourcelist=${sourcefile} ${package} | grep Depends | awk -F'Depends: ' {'print $2'} | sed 's/([^()]*)//g' | sed 's/,/ /g' | sed 's/|/ /g')`; do 
			echo "Grabbing ${dep}..."
			sudo apt-get -qq install -y -d --reinstall --allow-unauthenticated -o=Dir::Cache::archives=${cachefolder} -o=Dir::State:status=${statusfile} -o=Dir::State=${tmpfolder} -o=Dir::Etc::sourcelist=${sourcefile} ${dep}
			echo "Done."
		done
		echo "Grabbing package ${package}"
		sudo apt-get -qq install -y -d --reinstall --allow-unauthenticated -o=Dir::Cache::archives=${cachefolder} -o=Dir::State:status=${statusfile} -o=Dir::State=${tmpfolder} -o=Dir::Etc::sourcelist=${sourcefile} ${package}
		echo "Done."
	done

	echo "Moving all downloaded packages from ${cachefolder}/ to ${distrocachedir}/..."
	sudo mv -f ${cachefolder}/*.deb ${distrocachedir}/
	echo "Files have been moved."

	echo "Correcting permissions..."
	sudo chown $USER:$(id -gn $USER) ${distrocachedir}/*.deb
	echo "Permissions fixed."

	echo "Generating Packages.gz for ${distrocachedir}/"
	cd ${distrocachedir}/
	dpkg-scanpackages . /dev/null 2>/dev/null | gzip -9 > Packages.gz
	echo "Done."

done

cd ${workingdir}

echo "Making folder for gems."
mkdir -p ${gemfolder}
cd ${gemfolder}
echo "Done."

echo "Downloading Gems..."
for gem in ${gemlist}; do
	gem fetch ${gem}
done
echo "Done."

echo "Removing tmp folder..."
sudo rm -rf $tmpfolder
echo "Done."

echo "Setting aptitude back to normal."
sudo apt-get -qq update
echo "Done."

echo "Tar this package up..."
cd ${startdir}
tar zcvf ${name}.tar.gz $workingdir/
echo "${name}.tar.gz has been generated."