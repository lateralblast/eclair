![alt tag](https://raw.githubusercontent.com/lateralblast/eclair/master/eclair.jpg)

ECLAIR
======

ESX Command Line Automation In Ruby

Introduction
------------

Eclair is a ruby script that automates various aspects for ESXi configuration
and updating. The automation is done via SSH. This is done with the ruby net/ssh
and net/scp gems. The goal was to make a command line tool to do this so that I
could automate the process across a number of machines.

Eclair also has the capability of getting the latest patches from the WMware
website. Due to the use of Javascript on the VMware download site this had to
be achieved with a combination of the selenium-webdriver, phantomjs and nokogiri gems.

License
-------

This software is licensed as CC-BA (Creative Commons By Attrbution)

http://creativecommons.org/licenses/by/4.0/legalcode

Features
--------

Some of the features include:

- Upgrade/Downgrade ESXi
  - From local repository or from VMware
    - When using local reposity it copies update to /scratch/downloads on ESXi host and then installs
    - The local repository by default sits in a "patches" directory in the same directory as the script
- Get a list of available patches for a release of ESXi from the VMware web site
- Download any patches from the VMware site that are not in the local repository
- The ESXi username and password can be stored in a local file so they don't appear on the command line

Requirements
------------

Required software to run exlair:

- ruby
- wget
- ruby gems
  - net/ssh
  - net/scp
  - etc
  - expect
  - getopt/std
  - selenium-webdriver
  - phantomjs
  - nokogiri

Issues
------

Issues encountered:

- The URLs given by the VMware site are dynamic session based URLs, so will expire soon after the are created
  - If you are going to download them manually, you'll need to do it soon after you run the script

Todo:

- Setup an ESXi host
  - NTP
  - Syslog
  - SNMP
- Lockdown ESXi host


Usage
-----

You can find out the command line options available to you by using the -h option:

```
$ eclair.rb -[AbCDf:hl:LP:r:Rs:Sp:u:UVyZ]

-h:     Print usage information
-V:     Print version information
-U:     Update ESX if newer patch level is available
-Z:     Downgrade ESX to earlier release
-L:     List all available versions in local patch directory
-R:     List all available versions in VMware depot
-A:     Download available patches to local patch directory
-C:     Check if newer patch level is available
-r:     Upgrade or downgrade to a specific release
-s:     Hostname
-p:     Password
-f:     Source file for update
-D:     Patch directory (default is patches in sames directory as script)
-y:     Perform action (if not given you will be prompted before upgrades)
-S:     Setup ESXi (Syslog, NTP, etc)
-l:     Check if a particular patch is in the local repository
-b:     Perform reboot after patch installation (not default)
```

Examples
--------

Check update installed on ESX host against what is available on VMware site:

```
$ eclair.rb -C -s 192.168.1.183
Current:   20140404001
Available: 20140404001
Local patch level is up to date
```

Check update installed on ESX host against a patch ID in the local repository:

```
$ eclair.rb -C -s 192.168.1.183 -f ESXi550-201404020
File:  /Users/spindler/Code/eclair/patches/ESXi550-201404020.zip
Current:   20140302001
Available: 20140401020s
Depot patch level is newer than installed version
```

Check update installed on ESX host against a patch file in the local repository:

```
$ eclair.rb -C -s 192.168.1.183 -f ./patches/ESXi550-201404020.zip
File:  /Users/spindler/Code/eclair/patches/ESXi550-201404020.zip
Current:   20140302001
Available: 20140401020s
Depot patch level is newer than installed version
```

Updating an ESXi host from a patch in the local repository (without confirmation and reboot):

```
$ eclair.rb -U -s 192.168.1.183 -f ESXi550-201404001 -y -b
File:  /Users/spindler/Code/eclair/patches/ESXi550-201404001.zip
Current:   20140302001
Available: 20140404001
Depot patch level is newer than installed version
Copying local file /Users/spindler/Code/eclair/patches/ESXi550-201404001.zip to 192.168.1.183:/scratch/downloads/ESXi550-201404001.zip
Installing ESXi-5.5.0-20140404001-standard from /scratch/downloads/ESXi550-201404001.zip
Update Result
   Message: The update completed successfully, but the system needs to be rebooted for the changes to be effective.
   Reboot Required: true
   VIBs Installed: VMware_bootbank_esx-base_5.5.0-1.16.1746018, VMware_bootbank_lsi-mr3_0.255.03.01-2vmw.550.1.16.1746018, VMware_locker_tools-light_5.5.0-1.16.1746018
   VIBs Removed: VMware_bootbank_esx-base_5.5.0-1.15.1623387, VMware_bootbank_lsi-mr3_0.255.03.01-1vmw.550.0.0.1331820, VMware_locker_tools-light_5.5.0-1.15.1623387
   VIBs Skipped: VMware_bootbank_ata-pata-amd_0.3.10-3vmw.550.0.0.1331820, VMware_bootbank_ata-pata-atiixp_0.4.6-4vmw.550.0.0.1331820,
   VMware_bootbank_ata-pata-cmd64x_0.2.5-3vmw.550.0.0.1331820, VMware_bootbank_ata-pata-hpt3x2n_0.3.4-3vmw.550.0.0.1331820,
   VMware_bootbank_ata-pata-pdc2027x_1.0-3vmw.550.0.0.1331820, VMware_bootbank_ata-pata-serverworks_0.4.3-3vmw.550.0.0.1331820,
   VMware_bootbank_ata-pata-sil680_0.4.8-3vmw.550.0.0.1331820, VMware_bootbank_ata-pata-via_0.3.3-2vmw.550.0.0.1331820,
   VMware_bootbank_block-cciss_3.6.14-10vmw.550.0.0.1331820, VMware_bootbank_ehci-ehci-hcd_1.0-3vmw.550.0.0.1331820,
   VMware_bootbank_elxnet_10.0.100.0v-1vmw.550.0.0.1331820, VMware_bootbank_esx-dvfilter-generic-fastpath_5.5.0-0.0.1331820,
   VMware_bootbank_esx-tboot_5.5.0-0.0.1331820, VMware_bootbank_esx-xlibs_5.5.0-0.0.1331820, VMware_bootbank_esx-xserver_5.5.0-0.0.1331820,
   VMware_bootbank_ima-qla4xxx_2.01.31-1vmw.550.0.0.1331820, VMware_bootbank_ipmi-ipmi-devintf_39.1-4vmw.550.0.0.1331820,
   VMware_bootbank_ipmi-ipmi-msghandler_39.1-4vmw.550.0.0.1331820, VMware_bootbank_ipmi-ipmi-si-drv_39.1-4vmw.550.0.0.1331820,
   VMware_bootbank_lpfc_10.0.100.1-1vmw.550.0.0.1331820, VMware_bootbank_lsi-msgpt3_00.255.03.03-1vmw.550.1.15.1623387,
   VMware_bootbank_misc-cnic-register_1.72.1.v50.1i-1vmw.550.0.0.1331820, VMware_bootbank_misc-drivers_5.5.0-0.7.1474526,
   VMware_bootbank_mtip32xx-native_3.3.4-1vmw.550.1.15.1623387, VMware_bootbank_net-be2net_4.6.100.0v-1vmw.550.0.0.1331820,
   VMware_bootbank_net-bnx2_2.2.3d.v55.2-1vmw.550.0.0.1331820, VMware_bootbank_net-bnx2x_1.72.56.v55.2-1vmw.550.0.0.1331820,
   VMware_bootbank_net-cnic_1.72.52.v55.1-1vmw.550.0.0.1331820, VMware_bootbank_net-e1000_8.0.3.1-3vmw.550.0.0.1331820,
   VMware_bootbank_net-e1000e_1.1.2-4vmw.550.1.15.1623387, VMware_bootbank_net-enic_1.4.2.15a-1vmw.550.0.0.1331820,
   VMware_bootbank_net-forcedeth_0.61-2vmw.550.0.0.1331820, VMware_bootbank_net-igb_5.0.5.1.1-1vmw.550.1.15.1623387,
   VMware_bootbank_net-ixgbe_3.7.13.7.14iov-11vmw.550.0.0.1331820, VMware_bootbank_net-mlx4-core_1.9.7.0-1vmw.550.0.0.1331820,
   VMware_bootbank_net-mlx4-en_1.9.7.0-1vmw.550.0.0.1331820, VMware_bootbank_net-nx-nic_5.0.621-1vmw.550.0.0.1331820,
   VMware_bootbank_net-tg3_3.123c.v55.5-1vmw.550.1.15.1623387, VMware_bootbank_net-vmxnet3_1.1.3.0-3vmw.550.0.0.1331820,
   VMware_bootbank_ohci-usb-ohci_1.0-3vmw.550.0.0.1331820, VMware_bootbank_qlnativefc_1.0.12.0-1vmw.550.0.0.1331820,
   VMware_bootbank_rste_2.0.2.0088-4vmw.550.1.15.1623387, VMware_bootbank_sata-ahci_3.0-18vmw.550.1.15.1623387,
   VMware_bootbank_sata-ata-piix_2.12-9vmw.550.0.0.1331820, VMware_bootbank_sata-sata-nv_3.5-4vmw.550.0.0.1331820,
   VMware_bootbank_sata-sata-promise_2.12-3vmw.550.0.0.1331820, VMware_bootbank_sata-sata-sil24_1.1-1vmw.550.0.0.1331820,
   VMware_bootbank_sata-sata-sil_2.3-4vmw.550.0.0.1331820, VMware_bootbank_sata-sata-svw_2.3-3vmw.550.0.0.1331820,
   VMware_bootbank_scsi-aacraid_1.1.5.1-9vmw.550.0.0.1331820, VMware_bootbank_scsi-adp94xx_1.0.8.12-6vmw.550.0.0.1331820,
   VMware_bootbank_scsi-aic79xx_3.1-5vmw.550.0.0.1331820, VMware_bootbank_scsi-bnx2fc_1.72.53.v55.1-1vmw.550.0.0.1331820,
   VMware_bootbank_scsi-bnx2i_2.72.11.v55.4-1vmw.550.0.0.1331820, VMware_bootbank_scsi-fnic_1.5.0.4-1vmw.550.0.0.1331820,
   VMware_bootbank_scsi-hpsa_5.5.0-44vmw.550.0.0.1331820, VMware_bootbank_scsi-ips_7.12.05-4vmw.550.0.0.1331820,
   VMware_bootbank_scsi-lpfc820_8.2.3.1-129vmw.550.0.0.1331820, VMware_bootbank_scsi-megaraid-mbox_2.20.5.1-6vmw.550.0.0.1331820,
   VMware_bootbank_scsi-megaraid-sas_5.34-9vmw.550.1.15.1623387, VMware_bootbank_scsi-megaraid2_2.00.4-9vmw.550.0.0.1331820,
   VMware_bootbank_scsi-mpt2sas_14.00.00.00-3vmw.550.1.15.1623387, VMware_bootbank_scsi-mptsas_4.23.01.00-9vmw.550.0.0.1331820,
   VMware_bootbank_scsi-mptspi_4.23.01.00-9vmw.550.0.0.1331820, VMware_bootbank_scsi-qla2xxx_902.k1.1-9vmw.550.0.0.1331820,
   VMware_bootbank_scsi-qla4xxx_5.01.03.2-6vmw.550.0.0.1331820, VMware_bootbank_uhci-usb-uhci_1.0-3vmw.550.0.0.1331820
Rebooting
```

Get a list of the available patches for ESXi for 5.1.0:

```
$ eclair.rb -R -r 5.1.0
Update:   ESXi510-201404001
Download: https://download2.vmware.com/patch/software/VUM/OFFLINE/release-431-20140427-641697/ESXi510-201404001.zip?HashKey=b67d1404781d0d791f4f911065073499&AuthKey=1401676093_4dc39ad8083dbde1c34e6e526a5
45d5e
Missing:  /Users/spindler/Code/eclair/patches/ESXi510-201404001.zip
Update:   ESXi510-201402001
Download: https://download2.vmware.com/patch/software/VUM/OFFLINE/release-420-20140226-922881/ESXi510-201402001.zip?HashKey=67c081d74083f2c3a10f94000b43d2fd&AuthKey=1401676093_a33f4b25ac645443bcf2926c7f7
7f17b
Missing:  /Users/spindler/Code/eclair/patches/ESXi510-201402001.zip
Update:   ESXi510-201310001
Download: https://download2.vmware.com/patch/software/VUM/OFFLINE/release-402-20131016-227919/ESXi510-201310001.zip?HashKey=ba0c39f3a9ea054afbe3f5feb6d1d56d&AuthKey=1401676093_67e756d758478965261a19ca5dc
067bf
Missing:  /Users/spindler/Code/eclair/patches/ESXi510-201310001.zip
Update:   ESXi510-201307001
Download: https://download2.vmware.com/patch/software/VUM/OFFLINE/release-394-20130722-233368/ESXi510-201307001.zip?HashKey=df48dcad4875176724df7f8f850e7061&AuthKey=1401676093_5c0379a805748318d618ad827fe
97268
Missing:  /Users/spindler/Code/eclair/patches/ESXi510-201307001.zip
Update:   ESXi510-201305001
Download: https://download2.vmware.com/patch/software/VUM/OFFLINE/release-387-20130519-806235/ESXi510-201305001.zip?HashKey=15a0c1c2a4b929d0bf421c4d9705158f&AuthKey=1401676093_e2a0c5220bf9cb6c8644fd74d59
0c9c4
Missing:  /Users/spindler/Code/eclair/patches/ESXi510-201305001.zip
Update:   ESXi510-201303001
Download: https://download2.vmware.com/patch/software/VUM/OFFLINE/release-375-20130304-043403/ESXi510-201303001.zip?HashKey=87509815d8ae55ff4a8051707bbf2eaa&AuthKey=1401676093_645a458051fb743ab3b0ea2cde6
4cc5d
Missing:  /Users/spindler/Code/eclair/patches/ESXi510-201303001.zip
Update:   ESXi510-201212001
Download: https://download2.vmware.com/patch/software/VUM/OFFLINE/release-368-20121217-718319/ESXi510-201212001.zip?HashKey=d56cbde35ce7e3a5deb6932e4d878505&AuthKey=1401676093_88e26c9013bc8f8d205409097f9
7f6f6
Missing:  /Users/spindler/Code/eclair/patches/ESXi510-201212001.zip
Update:   ESXi510-201210001
Download: https://download2.vmware.com/patch/software/VUM/OFFLINE/release-364-20121022-316291/ESXi510-201210001.zip?HashKey=f9a8eb1fe79f6f379d4ef8015f037923&AuthKey=1401676093_695515bcc52410bd4da254ce667
be1a3
Missing:  /Users/spindler/Code/eclair/patches/ESXi510-201210001.zip
```

List the patches in the local repository:

```
$ eclair.rb -L
ESXi550-201404001.zip
ESXi550-201404020.zip
```

Example ~/.esxpasswd entry (same username and password for all hosts):

```
*:root:XXXX
```

Example ~/.esxpasswd entry (different password for different hosts):

```
host1:root:XXXX
host2:root:YYYY
```

