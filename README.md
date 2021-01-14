# amdgpu-ocl

### WARNING

As of 14.01.2021 the script does not yet work with the new ROCr based OpenCL driver in amdgpu-pro 20.45.
Since 20.45 is only required for Big Navi and known to have several issues, stick with 20.40 for Polaris, Vega and Navi.  
-
  
This script extracts the OpenCL bits and bobs from the official AMDGPU-PRO driver provided by AMD.
These files are then packaged into a .deb file with very few  dependencies.
Installing the resulting file on top of the open source amdgpu driver, you will be able to use official AMDGPU-PRO OpenCL on unsupported distributions like Ubuntu's interim releases, Debian or Mint. 

Download the latest AMDGPU-PRO driver for Ubuntu and run the script with the archive as its only parameter.
The archive can be in the same directory or placed elsewhere. In the later case the script copies it to the local directory.


Usage:
```
root@hostname:~# ./create_amdgpu-ocl-pkg.sh amdgpu-pro-20.40-1147286-ubuntu-20.04.tar.xz
Processing driver archive:
 Extracting amdgpu-pro-20.40-1147286-ubuntu-20.04.tar.xz  done
  Extracting opencl-amdgpu-pro-icd_20.40-1147286_amd64.deb done
    Extracting data.tar.xz done
  Extracting opencl-orca-amdgpu-pro-icd_20.40-1147286_amd64.deb done
    Extracting data.tar.xz done
  Extracting libdrm-amdgpu-amdgpu1_2.4.100-1147286_amd64.deb done
    Extracting data.tar.xz done
Copying files to package directory done

Building package (allow up to 2min):
dpkg-deb: building package 'amdgpu-ocl' in 'amdgpu-ocl_20.40-1147286.deb'.

amdgpu-ocl_20.40-1147286.deb content:
drwxr-xr-x root/root         0 2020-10-10 00:12 ./
drwxr-xr-x root/root         0 2020-09-23 03:03 ./etc/
drwxr-xr-x root/root         0 2020-09-23 03:03 ./etc/OpenCL/
drwxr-xr-x root/root         0 2020-09-23 03:03 ./etc/OpenCL/vendors/
-rw-r--r-- root/root        20 2020-09-23 03:03 ./etc/OpenCL/vendors/amdocl-orca64.icd
-rw-r--r-- root/root        15 2020-09-23 03:03 ./etc/OpenCL/vendors/amdocl64.icd
drwxr-xr-x root/root         0 2020-10-10 00:12 ./opt/
drwxr-xr-x root/root         0 2020-10-10 00:12 ./opt/amdgpu/
drwxr-xr-x root/root         0 2020-10-10 00:12 ./opt/amdgpu/share/
drwxr-xr-x root/root         0 2020-10-10 00:12 ./opt/amdgpu/share/libdrm/
drwxr-xr-x root/root         0 2020-10-10 00:12 ./usr/
drwxr-xr-x root/root         0 2020-10-10 00:12 ./usr/lib/
-rw-r--r-- root/root  85284568 2020-10-10 00:12 ./usr/lib/libamdocl-orca64.so
-rw-r--r-- root/root  36847400 2020-09-23 03:03 ./usr/lib/libamdocl12cl64.so
-rw-r--r-- root/root  93898608 2020-09-23 03:03 ./usr/lib/libamdocl64.so
-rw-r--r-- root/root     51840 2020-09-23 03:03 ./usr/lib/libdrm_amdgpo.so.1.0.0
lrwxrwxrwx root/root         0 2020-10-10 00:12 ./opt/amdgpu/share/libdrm/amdgpu.ids -> /usr/share/libdrm/amdgpu.ids
lrwxrwxrwx root/root         0 2020-10-10 00:12 ./usr/lib/libdrm_amdgpo.so.1 -> libdrm_amdgpo.so.1.0.0

Use dpkg -i amdgpu-ocl_20.40-1147286.deb to install it.
```
Install the driver with 
```
dpkg -i amdgpu-ocl_20.40-1147286.deb
```

On Ubuntu and most likely other Debian derivatives you will also need to install the ICD loader **ocl-icd-libopencl1**.
Use clinfo to verify the OpenCL part of amdgpu-pro is in place and active:
```
user@hostname:~# clinfo | egrep "Platform Version|Device Version|Driver Version"
  Platform Version                                OpenCL 2.1 AMD-APP (3180.7)
  Device Version                                  OpenCL 2.0 AMD-APP (3180.7)
  Driver Version                                  3180.7 (PAL,HSAIL)
user@hostname:~# 
```
These device and driver strings confirm that the AMDGPU-PRO OpenCL driver is in place. In case ROCm or Mesa OpenCL driver were present, these strings would look differently.

Mesa + clover:
```
  Platform Version                                OpenCL 1.1 Mesa 17.3.0
  Device Version                                  OpenCL 1.1 Mesa 17.3.0
  Driver Version                                  17.3.0
```


Your GPU can now be used for OpenCL work.  
Go find some gravitational waves or gamma-ray pulsar binaries at https://einsteinathome.org/ 
