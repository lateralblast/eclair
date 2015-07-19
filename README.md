![alt tag](https://raw.githubusercontent.com/lateralblast/eclair/master/VMware_Stack.png)

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
  - io/console

Installation
------------

```
$ brew install wget
$ gem install net-ssh
$ gem install net-scp
$ gem install etc
$ grem install expect
$ gem install getopt
$ gem install selenium
$ selenium install
$ gem install selenium-wbedriver
$ gem install phantomjs
$ gem install nokogiri -- --use-system--libraries
```

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
Usage: eclair.rb -[AbCDef:Hhl:kK:LMP:r:Rs:Sp:u:UVyZ]

-h:	Print usage information
-V:	Print version information
-U:	Update ESX if newer patch level is available
-Z:	Downgrade ESX to earlier release
-L:	List all available versions in local patch directory
-M:	List all available versions in VMware depot
-A:	Download available patches to local patch directory
-C:	Check if newer patch level is available
-r:	Upgrade or downgrade to a specific release
-s:	Hostname
-p:	Password
-f:	Source file for update
-D:	Patch directory (default is patches in sames directory as script)
-y:	Perform action (if not given you will be prompted before upgrades)
-S:	Setup ESXi (Syslog, NTP, etc)
-l:	Check if a particular patch is in the local repository
-b:	Perform reboot after patch installation (not default)
-k:	Show license keys
-K:	Install license key
-R:	Reboot server
-H:	Shutdown server
-e:	Execute a command on a server
```

Examples
--------

Check update installed on ESX host against what is available on VMware site:

```
$ ./eclair.rb -C -s 192.168.1.223
Username: root
Password: 
Current:   0.8.2809111
Available: 0.11.2809209
Depot patch level is newer than installed version
```

Do a dry-run (answer no to install):

```
./eclair.rb -U -s 192.168.1.223
Username: root
Password: 
Current:   0.8.2809111
Available: 0.11.2809209
Depot patch level is newer than installed version
Install update [y,n]: n
Performing Dry Run - No updates will be installed
Installation Result
   Message: Dryrun only, host not changed. The following installers will be applied: [BootBankInstaller, LockerInstaller]
   Reboot Required: true
   VIBs Installed: VMware_bootbank_esx-base_6.0.0-0.11.2809209, VMware_bootbank_lsu-lsi-lsi-mr3-plugin_1.0.0-2vmw.600.0.11.2809209, VMware_bootbank_lsu-lsi-megaraid-sas-plugin_1.0.0-2vmw.600.0.11.2809209, VMware_bootbank_misc-drivers_6.0.0-0.11.2809209, VMware_bootbank_sata-ahci_3.0-21vmw.600.0.11.2809209, VMware_bootbank_scsi-bnx2i_2.78.76.v60.8-1vmw.600.0.11.2809209, VMware_locker_tools-light_6.0.0-0.11.2809209
   VIBs Removed: VMware_bootbank_esx-base_6.0.0-0.8.2809111, VMware_bootbank_lsu-lsi-lsi-mr3-plugin_1.0.0-1vmw.600.0.0.2494585, VMware_bootbank_lsu-lsi-megaraid-sas-plugin_1.0.0-1vmw.600.0.0.2494585, VMware_bootbank_misc-drivers_6.0.0-0.0.2494585, VMware_bootbank_sata-ahci_3.0-21vmw.600.0.0.2494585, VMware_bootbank_scsi-bnx2i_2.78.76.v60.8-1vmw.600.0.0.2494585, VMware_locker_tools-light_6.0.0-0.0.2494585
   VIBs Skipped: VMWARE_bootbank_mtip32xx-native_3.8.5-1vmw.600.0.0.2494585, VMware_bootbank_ata-pata-amd_0.3.10-3vmw.600.0.0.2494585, VMware_bootbank_ata-pata-atiixp_0.4.6-4vmw.600.0.0.2494585, VMware_bootbank_ata-pata-cmd64x_0.2.5-3vmw.600.0.0.2494585, VMware_bootbank_ata-pata-hpt3x2n_0.3.4-3vmw.600.0.0.2494585, VMware_bootbank_ata-pata-pdc2027x_1.0-3vmw.600.0.0.2494585, VMware_bootbank_ata-pata-serverworks_0.4.3-3vmw.600.0.0.2494585, VMware_bootbank_ata-pata-sil680_0.4.8-3vmw.600.0.0.2494585, VMware_bootbank_ata-pata-via_0.3.3-2vmw.600.0.0.2494585, VMware_bootbank_block-cciss_3.6.14-10vmw.600.0.0.2494585, VMware_bootbank_cpu-microcode_6.0.0-0.0.2494585, VMware_bootbank_ehci-ehci-hcd_1.0-3vmw.600.0.0.2494585, VMware_bootbank_elxnet_10.2.309.6v-1vmw.600.0.0.2494585, VMware_bootbank_emulex-esx-elxnetcli_10.2.309.6v-0.0.2494585, VMware_bootbank_esx-dvfilter-generic-fastpath_6.0.0-0.0.2494585, VMware_bootbank_esx-tboot_6.0.0-0.0.2494585, VMware_bootbank_esx-xserver_6.0.0-0.0.2494585, VMware_bootbank_ima-qla4xxx_2.02.18-1vmw.600.0.0.2494585, VMware_bootbank_ipmi-ipmi-devintf_39.1-4vmw.600.0.0.2494585, VMware_bootbank_ipmi-ipmi-msghandler_39.1-4vmw.600.0.0.2494585, VMware_bootbank_ipmi-ipmi-si-drv_39.1-4vmw.600.0.0.2494585, VMware_bootbank_lpfc_10.2.309.8-2vmw.600.0.0.2494585, VMware_bootbank_lsi-mr3_6.605.08.00-6vmw.600.0.0.2494585, VMware_bootbank_lsi-msgpt3_06.255.12.00-7vmw.600.0.0.2494585, VMware_bootbank_lsu-hp-hpsa-plugin_1.0.0-1vmw.600.0.0.2494585, VMware_bootbank_lsu-lsi-lsi-msgpt3-plugin_1.0.0-1vmw.600.0.0.2494585, VMware_bootbank_lsu-lsi-mpt2sas-plugin_1.0.0-1vmw.600.0.0.2494585, VMware_bootbank_lsu-lsi-mptsas-plugin_1.0.0-1vmw.600.0.0.2494585, VMware_bootbank_misc-cnic-register_1.78.75.v60.7-1vmw.600.0.0.2494585, VMware_bootbank_net-bnx2_2.2.4f.v60.10-1vmw.600.0.0.2494585, VMware_bootbank_net-bnx2x_1.78.80.v60.12-1vmw.600.0.0.2494585, VMware_bootbank_net-cnic_1.78.76.v60.13-2vmw.600.0.0.2494585, VMware_bootbank_net-e1000_8.0.3.1-5vmw.600.0.0.2494585, VMware_bootbank_net-e1000e_2.5.4-6vmw.600.0.0.2494585, VMware_bootbank_net-enic_2.1.2.38-2vmw.600.0.0.2494585, VMware_bootbank_net-forcedeth_0.61-2vmw.600.0.0.2494585, VMware_bootbank_net-igb_5.0.5.1.1-5vmw.600.0.0.2494585, VMware_bootbank_net-ixgbe_3.7.13.7.14iov-20vmw.600.0.0.2494585, VMware_bootbank_net-mlx4-core_1.9.7.0-1vmw.600.0.0.2494585, VMware_bootbank_net-mlx4-en_1.9.7.0-1vmw.600.0.0.2494585, VMware_bootbank_net-nx-nic_5.0.621-5vmw.600.0.0.2494585, VMware_bootbank_net-tg3_3.131d.v60.4-1vmw.600.0.0.2494585, VMware_bootbank_net-vmxnet3_1.1.3.0-3vmw.600.0.0.2494585, VMware_bootbank_nmlx4-core_3.0.0.0-1vmw.600.0.0.2494585, VMware_bootbank_nmlx4-en_3.0.0.0-1vmw.600.0.0.2494585, VMware_bootbank_nmlx4-rdma_3.0.0.0-1vmw.600.0.0.2494585, VMware_bootbank_nvme_1.0e.0.35-1vmw.600.0.0.2494585, VMware_bootbank_ohci-usb-ohci_1.0-3vmw.600.0.0.2494585, VMware_bootbank_qlnativefc_2.0.12.0-5vmw.600.0.0.2494585, VMware_bootbank_rste_2.0.2.0088-4vmw.600.0.0.2494585, VMware_bootbank_sata-ata-piix_2.12-10vmw.600.0.0.2494585, VMware_bootbank_sata-sata-nv_3.5-4vmw.600.0.0.2494585, VMware_bootbank_sata-sata-promise_2.12-3vmw.600.0.0.2494585, VMware_bootbank_sata-sata-sil24_1.1-1vmw.600.0.0.2494585, VMware_bootbank_sata-sata-sil_2.3-4vmw.600.0.0.2494585, VMware_bootbank_sata-sata-svw_2.3-3vmw.600.0.0.2494585, VMware_bootbank_scsi-aacraid_1.1.5.1-9vmw.600.0.0.2494585, VMware_bootbank_scsi-adp94xx_1.0.8.12-6vmw.600.0.0.2494585, VMware_bootbank_scsi-aic79xx_3.1-5vmw.600.0.0.2494585, VMware_bootbank_scsi-bnx2fc_1.78.78.v60.8-1vmw.600.0.0.2494585, VMware_bootbank_scsi-fnic_1.5.0.45-3vmw.600.0.0.2494585, VMware_bootbank_scsi-hpsa_6.0.0.44-4vmw.600.0.0.2494585, VMware_bootbank_scsi-ips_7.12.05-4vmw.600.0.0.2494585, VMware_bootbank_scsi-megaraid-mbox_2.20.5.1-6vmw.600.0.0.2494585, VMware_bootbank_scsi-megaraid-sas_6.603.55.00-2vmw.600.0.0.2494585, VMware_bootbank_scsi-megaraid2_2.00.4-9vmw.600.0.0.2494585, VMware_bootbank_scsi-mpt2sas_19.00.00.00-1vmw.600.0.0.2494585, VMware_bootbank_scsi-mptsas_4.23.01.00-9vmw.600.0.0.2494585, VMware_bootbank_scsi-mptspi_4.23.01.00-9vmw.600.0.0.2494585, VMware_bootbank_scsi-qla4xxx_5.01.03.2-7vmw.600.0.0.2494585, VMware_bootbank_uhci-usb-uhci_1.0-3vmw.600.0.0.2494585, VMware_bootbank_xhci-xhci_1.0-2vmw.600.0.0.2494585
```

Update (answer yes to install) without reboot:

```
$ ./eclair.rb -U -s 192.168.1.223
Username: root
Password: 
Current:   0.8.2809111
Available: 0.11.2809209
Depot patch level is newer than installed version
Install update [y,n]: y
Installing 6.0.0-0.11.2809209 from http://hostupdate.vmware.com/software/VUM/PRODUCTION/main/vmw-depot-index.xml
Installation Result
   Message: The update completed successfully, but the system needs to be rebooted for the changes to be effective.
   Reboot Required: true
   VIBs Installed: VMware_bootbank_esx-base_6.0.0-0.11.2809209, VMware_bootbank_lsu-lsi-lsi-mr3-plugin_1.0.0-2vmw.600.0.11.2809209, VMware_bootbank_lsu-lsi-megaraid-sas-plugin_1.0.0-2vmw.600.0.11.2809209, VMware_bootbank_misc-drivers_6.0.0-0.11.2809209, VMware_bootbank_sata-ahci_3.0-21vmw.600.0.11.2809209, VMware_bootbank_scsi-bnx2i_2.78.76.v60.8-1vmw.600.0.11.2809209, VMware_locker_tools-light_6.0.0-0.11.2809209
   VIBs Removed: VMware_bootbank_esx-base_6.0.0-0.8.2809111, VMware_bootbank_lsu-lsi-lsi-mr3-plugin_1.0.0-1vmw.600.0.0.2494585, VMware_bootbank_lsu-lsi-megaraid-sas-plugin_1.0.0-1vmw.600.0.0.2494585, VMware_bootbank_misc-drivers_6.0.0-0.0.2494585, VMware_bootbank_sata-ahci_3.0-21vmw.600.0.0.2494585, VMware_bootbank_scsi-bnx2i_2.78.76.v60.8-1vmw.600.0.0.2494585, VMware_locker_tools-light_6.0.0-0.0.2494585
   VIBs Skipped: VMWARE_bootbank_mtip32xx-native_3.8.5-1vmw.600.0.0.2494585, VMware_bootbank_ata-pata-amd_0.3.10-3vmw.600.0.0.2494585, VMware_bootbank_ata-pata-atiixp_0.4.6-4vmw.600.0.0.2494585, VMware_bootbank_ata-pata-cmd64x_0.2.5-3vmw.600.0.0.2494585, VMware_bootbank_ata-pata-hpt3x2n_0.3.4-3vmw.600.0.0.2494585, VMware_bootbank_ata-pata-pdc2027x_1.0-3vmw.600.0.0.2494585, VMware_bootbank_ata-pata-serverworks_0.4.3-3vmw.600.0.0.2494585, VMware_bootbank_ata-pata-sil680_0.4.8-3vmw.600.0.0.2494585, VMware_bootbank_ata-pata-via_0.3.3-2vmw.600.0.0.2494585, VMware_bootbank_block-cciss_3.6.14-10vmw.600.0.0.2494585, VMware_bootbank_cpu-microcode_6.0.0-0.0.2494585, VMware_bootbank_ehci-ehci-hcd_1.0-3vmw.600.0.0.2494585, VMware_bootbank_elxnet_10.2.309.6v-1vmw.600.0.0.2494585, VMware_bootbank_emulex-esx-elxnetcli_10.2.309.6v-0.0.2494585, VMware_bootbank_esx-dvfilter-generic-fastpath_6.0.0-0.0.2494585, VMware_bootbank_esx-tboot_6.0.0-0.0.2494585, VMware_bootbank_esx-xserver_6.0.0-0.0.2494585, VMware_bootbank_ima-qla4xxx_2.02.18-1vmw.600.0.0.2494585, VMware_bootbank_ipmi-ipmi-devintf_39.1-4vmw.600.0.0.2494585, VMware_bootbank_ipmi-ipmi-msghandler_39.1-4vmw.600.0.0.2494585, VMware_bootbank_ipmi-ipmi-si-drv_39.1-4vmw.600.0.0.2494585, VMware_bootbank_lpfc_10.2.309.8-2vmw.600.0.0.2494585, VMware_bootbank_lsi-mr3_6.605.08.00-6vmw.600.0.0.2494585, VMware_bootbank_lsi-msgpt3_06.255.12.00-7vmw.600.0.0.2494585, VMware_bootbank_lsu-hp-hpsa-plugin_1.0.0-1vmw.600.0.0.2494585, VMware_bootbank_lsu-lsi-lsi-msgpt3-plugin_1.0.0-1vmw.600.0.0.2494585, VMware_bootbank_lsu-lsi-mpt2sas-plugin_1.0.0-1vmw.600.0.0.2494585, VMware_bootbank_lsu-lsi-mptsas-plugin_1.0.0-1vmw.600.0.0.2494585, VMware_bootbank_misc-cnic-register_1.78.75.v60.7-1vmw.600.0.0.2494585, VMware_bootbank_net-bnx2_2.2.4f.v60.10-1vmw.600.0.0.2494585, VMware_bootbank_net-bnx2x_1.78.80.v60.12-1vmw.600.0.0.2494585, VMware_bootbank_net-cnic_1.78.76.v60.13-2vmw.600.0.0.2494585, VMware_bootbank_net-e1000_8.0.3.1-5vmw.600.0.0.2494585, VMware_bootbank_net-e1000e_2.5.4-6vmw.600.0.0.2494585, VMware_bootbank_net-enic_2.1.2.38-2vmw.600.0.0.2494585, VMware_bootbank_net-forcedeth_0.61-2vmw.600.0.0.2494585, VMware_bootbank_net-igb_5.0.5.1.1-5vmw.600.0.0.2494585, VMware_bootbank_net-ixgbe_3.7.13.7.14iov-20vmw.600.0.0.2494585, VMware_bootbank_net-mlx4-core_1.9.7.0-1vmw.600.0.0.2494585, VMware_bootbank_net-mlx4-en_1.9.7.0-1vmw.600.0.0.2494585, VMware_bootbank_net-nx-nic_5.0.621-5vmw.600.0.0.2494585, VMware_bootbank_net-tg3_3.131d.v60.4-1vmw.600.0.0.2494585, VMware_bootbank_net-vmxnet3_1.1.3.0-3vmw.600.0.0.2494585, VMware_bootbank_nmlx4-core_3.0.0.0-1vmw.600.0.0.2494585, VMware_bootbank_nmlx4-en_3.0.0.0-1vmw.600.0.0.2494585, VMware_bootbank_nmlx4-rdma_3.0.0.0-1vmw.600.0.0.2494585, VMware_bootbank_nvme_1.0e.0.35-1vmw.600.0.0.2494585, VMware_bootbank_ohci-usb-ohci_1.0-3vmw.600.0.0.2494585, VMware_bootbank_qlnativefc_2.0.12.0-5vmw.600.0.0.2494585, VMware_bootbank_rste_2.0.2.0088-4vmw.600.0.0.2494585, VMware_bootbank_sata-ata-piix_2.12-10vmw.600.0.0.2494585, VMware_bootbank_sata-sata-nv_3.5-4vmw.600.0.0.2494585, VMware_bootbank_sata-sata-promise_2.12-3vmw.600.0.0.2494585, VMware_bootbank_sata-sata-sil24_1.1-1vmw.600.0.0.2494585, VMware_bootbank_sata-sata-sil_2.3-4vmw.600.0.0.2494585, VMware_bootbank_sata-sata-svw_2.3-3vmw.600.0.0.2494585, VMware_bootbank_scsi-aacraid_1.1.5.1-9vmw.600.0.0.2494585, VMware_bootbank_scsi-adp94xx_1.0.8.12-6vmw.600.0.0.2494585, VMware_bootbank_scsi-aic79xx_3.1-5vmw.600.0.0.2494585, VMware_bootbank_scsi-bnx2fc_1.78.78.v60.8-1vmw.600.0.0.2494585, VMware_bootbank_scsi-fnic_1.5.0.45-3vmw.600.0.0.2494585, VMware_bootbank_scsi-hpsa_6.0.0.44-4vmw.600.0.0.2494585, VMware_bootbank_scsi-ips_7.12.05-4vmw.600.0.0.2494585, VMware_bootbank_scsi-megaraid-mbox_2.20.5.1-6vmw.600.0.0.2494585, VMware_bootbank_scsi-megaraid-sas_6.603.55.00-2vmw.600.0.0.2494585, VMware_bootbank_scsi-megaraid2_2.00.4-9vmw.600.0.0.2494585, VMware_bootbank_scsi-mpt2sas_19.00.00.00-1vmw.600.0.0.2494585, VMware_bootbank_scsi-mptsas_4.23.01.00-9vmw.600.0.0.2494585, VMware_bootbank_scsi-mptspi_4.23.01.00-9vmw.600.0.0.2494585, VMware_bootbank_scsi-qla4xxx_5.01.03.2-7vmw.600.0.0.2494585, VMware_bootbank_uhci-usb-uhci_1.0-3vmw.600.0.0.2494585, VMware_bootbank_xhci-xhci_1.0-2vmw.600.0.0.2494585
```


Older Examples
--------------

Check update installed on ESX host against what is available on VMware site:

```
$ ./eclair.rb -C -s 192.168.1.183
Current:   20140404001
Available: 20140404001
Local patch level is up to date
```

Check update installed on ESX host against a patch ID in the local repository:

```
$ ./eclair.rb -C -s 192.168.1.183 -f ESXi550-201404020
File:  /Users/spindler/Code/eclair/patches/ESXi550-201404020.zip
Current:   20140302001
Available: 20140401020s
Depot patch level is newer than installed version
```

Check update installed on ESX host against a patch file in the local repository:

```
$ ./eclair.rb -C -s 192.168.1.183 -f ./patches/ESXi550-201404020.zip
File:  /Users/spindler/Code/eclair/patches/ESXi550-201404020.zip
Current:   20140302001
Available: 20140401020s
Depot patch level is newer than installed version
```

Updating an ESXi host from a patch in the local repository (without confirmation and reboot):

```
$ ./eclair.rb -U -s 192.168.1.183 -f ESXi550-201404001 -y -b
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
$ ./eclair.rb -R -r 5.1.0
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

Show license keys:

```
$ ./eclair.rb -k -s 192.168.1.224
Username: root
Password: 
[200] Sending request for installed licenses...[200] Complete, result is:
   serial: 00000-00000-00000-00000-00000
   vmodl key: eval
   name: Evaluation Mode
   total: 1
   used:  1
   unit: host
   Properties:
     [ProductName] = VMware ESX Server
     [ProductVersion] = 6.0
     [evaluation] = License has not been set, evaluation Period in effect.
     [expirationHours] = 1439
     [expirationMinutes] = 5
     [expirationDate] = 2015-09-17T08:32:29.125538Z
     [system_time] = 2015-07-19T09:27:29.130636Z
     [feature] = vsmp:0 ("Unlimited virtual SMP")
     [feature] = h264remote ("H.264 for Remote Console Connections")
     [feature] = esxHost ("vCenter agent for VMware host")
     [feature] = vimapi ("vSphere API")
     [feature] = vstorage ("Storage APIs")
     [feature] = vmsafe ("VMsafe")
     [feature] = vmotion ("vSphere vMotion")
     [feature] = xswitchvmotion ("X-Switch vMotion")
     [feature] = das ("vSphere HA")
     [feature] = dr ("vSphere Data Protection")
     [feature] = endpoint ("vShield Endpoint")
     [feature] = replication ("vSphere Replication")
     [feature] = vshield ("vShield Zones")
     [feature] = hotplug ("Hot-Pluggable virtual HW")
     [feature] = svmotion ("vSphere Storage vMotion")
     [feature] = smartcard ("Shared Smart Card Reader")
     [feature] = ft:4 ("vSphere FT (up to 4 virtual CPUs)")
     [feature] = vvolumes ("Virtual Volumes")
     [feature] = storageawarenessapi ("APIs for Storage Awareness")
     [feature] = spbm ("Storage-Policy Based Management")
     [feature] = drs ("vSphere DRS")
     [feature] = serialuri:2 ("Remote virtual Serial Port Concentrator")
     [feature] = mpio ("MPIO / Third-Party Multi-Pathing")
     [feature] = vaai ("vSphere Storage APIs for Array Integration")
     [feature] = bigdataex ("Big Data Extensions")
     [feature] = rem ("Reliable Memory")
     [feature] = dvs ("vSphere Distributed Switch")
     [feature] = hostprofile ("vSphere Host Profiles")
     [feature] = autodeploy ("vSphere Auto Deploy")
     [feature] = sriov ("SR-IOV")
     [feature] = sioshares ("vSphere Storage I/O Control")
     [feature] = dpvmotion ("Direct Path vMotion")
     [feature] = storagedrs ("vSphere Storage DRS")
     [feature] = metrovmotion ("vSphere vMotion Metro")
     [feature] = viewaccel ("vSphere View Accelerator")
     [feature] = appha ("vSphere App HA")
     [feature] = vflash ("vSphere Flash Read Cache")
     [feature] = contentlib ("Content Library")
     [feature] = xvcvmotion ("Cross Virtual Center vMotion")
     [feature] = vgpu ("vGPU")
     [FileVersion] = 6.0.0.11
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e16-suite-vsom-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e18-robo-c3-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e4-c2-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e2-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e6-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e4-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e8-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e11-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e9-eoem-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e8-eoem-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e7-eoem-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e1-eoem-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e2-eoem-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e17-suite-vsom-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e14-suite-vcloud5-c1-201006
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e14-suite-vcloud6-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e6-sub-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e7-sub-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e13-suite-vcloud5-c1-201006
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e13-suite-vcloud6-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e5-sub-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-eval-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e12-suite-vcloud5-c1-201006
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e12-suite-vcloud6-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e3-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e1-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e7-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e3-c2-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e5-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e9-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e10-c3-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e5-robo-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e7-robo-c3-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e6-robo-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e15-suite-vsom-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e8-sub-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e9-sub-c1-201306
     [Localized] = <Not supported type for value: 0x1f2b8ce0>

[200] End of report.
```

Install license key:

```
$ ./eclair.rb -s 192.168.1.224 -K AAAAA-BBBBB-CCCCC-DDDDD-EEEEE
Username: root
Password: 

   serial: AAAAA-BBBBB-CCCCC-DDDDD-EEEEE
   vmodl key: esx.essentialsPlus.cpuPackage
   name: VMware vSphere 6 Essentials Plus
   total: 0
   used:  1
   unit: cpuPackage
   Properties:
     [ProductName] = VMware ESX Server
     [ProductVersion] = 6.0
     [count_disabled] = This license is unlimited
     [feature] = vsmp:0 ("Unlimited virtual SMP")
     [feature] = h264remote ("H.264 for Remote Console Connections")
     [feature] = esxHost ("vCenter agent for VMware host")
     [feature] = vimapi ("vSphere API")
     [feature] = vstorage ("Storage APIs")
     [feature] = vmsafe ("VMsafe")
     [feature] = vmotion ("vSphere vMotion")
     [feature] = xswitchvmotion ("X-Switch vMotion")
     [feature] = das ("vSphere HA")
     [feature] = dr ("vSphere Data Protection")
     [feature] = endpoint ("vShield Endpoint")
     [feature] = replication ("vSphere Replication")
     [feature] = vshield ("vShield Zones")
     [addon] = hotplug ("Hot-Pluggable virtual HW")
     [addon] = drs ("vSphere DRS")
     [addon] = svmotion ("vSphere Storage vMotion")
     [FileVersion] = 6.0.0.11
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e16-suite-vsom-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e18-robo-c3-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e4-c2-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e2-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e6-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e4-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e8-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e11-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e9-eoem-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e8-eoem-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e7-eoem-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e1-eoem-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e2-eoem-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e17-suite-vsom-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e14-suite-vcloud5-c1-201006
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e14-suite-vcloud6-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e6-sub-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e7-sub-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e13-suite-vcloud5-c1-201006
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e13-suite-vcloud6-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e5-sub-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-eval-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e12-suite-vcloud5-c1-201006
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e12-suite-vcloud6-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e3-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e1-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e7-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e3-c2-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e5-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e9-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e10-c3-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e5-robo-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e7-robo-c3-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e6-robo-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e15-suite-vsom-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e8-sub-c1-201306
     [LicenseFilePath] = /usr/lib/vmware/licenses/site/license-esx-60-e9-sub-c1-201306
     [Localized] = <Not supported type for value: 0x1f2b8590>
[200] Command Complete.
Result: Success

```

List the patches in the local repository:

```
$ ./eclair.rb -L
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

