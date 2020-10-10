#!/bin/bash
#
# This script will extract several OpenCL libraries from the official amdgpu-pro drivers.
# There are then packaged into a DEB file that can be easily installed/removed through dpkg.
# There is no need to install any other components from AMDGPU-PRO to get OpenCL support.
# You will need to install and ICD loader like ocl-icd-libopencl1 though 
#
# Tested and working with AMDGPU-PRO 18.50, 19.10, 19.30, 19.50, 20.10 20.20 and 20.40
# Tested and broken with AMDGPU-PRO 17.50 (incompatible naming)
#
scriptversion=0.6

if [[ $1 == "" ]]; then
	echo "No driver archive provided"
	exit 1
elif [ ! -e $1 ]; then
	echo "File $1 does not exist"
	exit 2
fi

driverarchivename=$1
driverdir=$(dirname ${driverarchivename})
drivername=$(basename ${driverarchivename})
archivefields=$(echo ${drivername} | sed 's/.tar.xz//g' | awk -F"-" '{ print $1" "$2" "$3" "$4" "$5" "$6 }')
read prefix1 prefix2 major minor postfix1 postfix2 <<< $archivefields
prefix="${prefix1}-${prefix2}-"
postfix="-${postfix1}-${postfix2}"

srcdir=$(pwd)
pkgdir="${srcdir}/amdgpu-ocl"
pkgname=amdgpu-ocl_${major}-${minor}.deb

if [[ ${srcdir} == "/" ]]; then 
	echo "Please don't work in /, this script might destroy your system."; 
	exit 1; 
fi

if [ ! -e $drivername ]; then
	echo "Doesn't exist in local directory"
	cp -pr ${driverarchivename} ${srcdir} && echo "Successfully copied to ${srcdir}!"
fi

archiveprocessing() {

	echo "Processing driver archive:"
	printf " Extracting ${drivername} - "
	tar xJf ${drivername} && printf "done"
        echo 

	printf "  Extracting opencl-amdgpu-pro-icd_${major}-${minor}_amd64.deb - "
	mkdir -p "${srcdir}/opencl"
	cd "${srcdir}/opencl"
	ar x "${srcdir}/${prefix}${major}-${minor}${postfix}/opencl-amdgpu-pro-icd_${major}-${minor}_amd64.deb" && printf "done"
	echo 
	printf "    Extracting data.tar.xz - "
	tar xJf data.tar.xz && printf "done"
        echo 

	printf  "  Extracting opencl-orca-amdgpu-pro-icd_${major}-${minor}_amd64.deb - "
	ar x "${srcdir}/${prefix}${major}-${minor}${postfix}/opencl-orca-amdgpu-pro-icd_${major}-${minor}_amd64.deb" && printf "done"
	echo 
	printf "    Extracting data.tar.xz - "	
	tar xJf data.tar.xz && printf "done"
	echo 
	cd opt/amdgpu-pro/lib/x86_64-linux-gnu
	sed -i "s|libdrm_amdgpu|libdrm_amdgpo|g" libamdocl-orca64.so 

	#
	# build libdrm file name first
	#
	libdrm_pkg=$(ls -ld ${srcdir}/${prefix}${major}-${minor}${postfix}/libdrm-amdgpu-amdgpu1_*-${minor}_amd64.deb | awk -F"/" '{ print $NF }')
	printf "  Extracting ${libdrm_pkg} - "
	mkdir -p "${srcdir}/libdrm"
	cd "${srcdir}/libdrm"
	ar x "${srcdir}/${prefix}${major}-${minor}${postfix}/${libdrm_pkg}" && printf "done"
        echo

	printf "    Extracting data.tar.xz - "
	tar xJf data.tar.xz && printf "done"
        echo

	printf "Copying files to package directory "
	cd opt/amdgpu/lib/x86_64-linux-gnu
	rm "libdrm_amdgpu.so.1"
	mv "libdrm_amdgpu.so.1.0.0" "libdrm_amdgpo.so.1.0.0"
	ln -s "libdrm_amdgpo.so.1.0.0" "libdrm_amdgpo.so.1" 

	mkdir -p ${pkgdir}/etc
	mkdir -p ${pkgdir}/usr/lib
	mv "${srcdir}/opencl/etc" "${pkgdir}/"
	mv "${srcdir}/opencl/opt/amdgpu-pro/lib/x86_64-linux-gnu/libamdocl64.so" "${pkgdir}/usr/lib/"
	mv "${srcdir}/opencl/opt/amdgpu-pro/lib/x86_64-linux-gnu/libamdocl-orca64.so" "${pkgdir}/usr/lib/"
	mv "${srcdir}/opencl/opt/amdgpu-pro/lib/x86_64-linux-gnu/libamdocl12cl64.so" "${pkgdir}/usr/lib/"
	mv "${srcdir}/libdrm/opt/amdgpu/lib/x86_64-linux-gnu/libdrm_amdgpo.so.1.0.0" "${pkgdir}/usr/lib/"
	mv "${srcdir}/libdrm/opt/amdgpu/lib/x86_64-linux-gnu/libdrm_amdgpo.so.1" "${pkgdir}/usr/lib/"

	mkdir -p "${pkgdir}/opt/amdgpu/share/libdrm"
	cd "${pkgdir}/opt/amdgpu/share/libdrm"
	ln -s /usr/share/libdrm/amdgpu.ids amdgpu.ids 
	echo "done"
	echo
}

buildprep() {

	mkdir -p ${pkgdir}
	cd ${pkgdir}
	mkdir -p DEBIAN

	#
	# Fill postinst script
	#
	echo "ln -s -f /usr/lib/x86_64-linux-gnu/libOpenCL.so.1 /usr/lib/x86_64-linux-gnu/libOpenCL.so" > DEBIAN/postinst
	echo "exit 0" >> DEBIAN/postinst
	chmod 755 DEBIAN/postinst

	#
	# Create control file
	#
	echo "Package: amdgpu-ocl" > DEBIAN/control
	echo "Version: ${major}.${minor}-${scriptversion}" >> DEBIAN/control
	echo "Section: base" >> DEBIAN/control
	echo "Priority: optional" >> DEBIAN/control
	echo "Architecture: amd64" >> DEBIAN/control
	echo "Depends: bash, binutils, sed, tar, coreutils" >> DEBIAN/control
	echo "Maintainer: anonymous <noemail@spam.com" >> DEBIAN/control
	echo "Description: OpenCL userspace driver as provided in the amdgpu-pro ${major}-${minor} driver stack." >> DEBIAN/control
 	echo "  This package is intended to work alongside the free amdgpu stack." >> DEBIAN/control
 	echo "  This should work on Ubuntu LTS as well as interim releases, recent Mint or Debian that are unsupported by the official driver." >> DEBIAN/control

	sudo chown -R root:root ${pkgdir}
}

builddeb() {
	echo "Building package (allow up to 2min):"
	cd ${srcdir}
	dpkg-deb --build amdgpu-ocl ${pkgname}
	echo
	
	echo "${pkgname} content:"
	dpkg -c ${pkgname}
	echo
	echo "Use dpkg -i ${pkgname} to install it."
}

cleanup() {
        # Clean up previous attempts
        rm -rf ${srcdir}/opencl
        rm -rf ${srcdir}/libdrm
        rm -rf ${pkgdir}
}

####################################################
# done defining functions, lets get some work done #
####################################################

archiveprocessing
buildprep
builddeb
cleanup
