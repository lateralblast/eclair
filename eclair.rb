#!/usr/bin/env ruby

# Name:         eclair (ESX Command Line Automation In Ruby)
# Version:      0.0.9
# Release:      1
# License:      CC-BA (Creative Commons By Attrbution)
#               http://creativecommons.org/licenses/by/4.0/legalcode
# Group:        System
# Source:       N/A
# URL:          http://lateralblast.com.au/
# Distribution: ESX(i)
# Vendor:       UNIX
# Packager:     Richard Spindler <richard@lateralblast.com.au>
# Description:  Ruby script to drive/setup ESX(i)

require 'net/ssh'
require 'net/scp'
require 'etc'
require 'expect'
require 'getopt/std'
require 'selenium-webdriver'
require 'phantomjs'
require 'nokogiri'

# Set some defaults

script    = $0
options   = "AbCDf:hl:LP:r:Rs:Sp:u:UVyZ"
username  = ""
password  = ""
mode      = "check"
doaction  = ""
filename  = ""
patchdir  = Dir.pwd+"/patches"
release   = "5.5.0"
download  = "n"
reboot    = "n"

# VMware URLs

product_url = "https://www.vmware.com/patchmgr/findPatch.portal"
depot_url   = "http://hostupdate.vmware.com/software/VUM/PRODUCTION/main/vmw-depot-index.xml"

# Password file (can be used so username and password are not shown in command line)
# ESX password file has the format "host:user:password"
# If all systems have the same username and password then an entry of:
# ALL:username:password or *:username:password will work

esx_password_file = Etc.getpwuid.dir+"/.esxpasswd"

# If file exists give it sensible permissions

if File.exist?(esx_password_file)
  %x[chmod 600 #{esx_password_file}]
end


# Print usage information

def print_usage(script,options)
  puts
  puts "Usage: "+script+" -["+options+"]"
  puts
  puts "-h:\tPrint usage information"
  puts "-V:\tPrint version information"
  puts "-U:\tUpdate ESX if newer patch level is available"
  puts "-Z:\tDowngrade ESX to earlier release"
  puts "-L:\tList all available versions in local patch directory"
  puts "-R:\tList all available versions in VMware depot"
  puts "-A:\tDownload available patches to local patch directory"
  puts "-C:\tCheck if newer patch level is available"
  puts "-r:\tUpgrade or downgrade to a specific release"
  puts "-s:\tHostname"
  puts "-p:\tPassword"
  puts "-f:\tSource file for update"
  puts "-D:\tPatch directory (default is patches in sames directory as script)"
  puts "-y:\tPerform action (if not given you will be prompted before upgrades)"
  puts "-S:\tSetup ESXi (Syslog, NTP, etc)"
  puts "-l:\tCheck if a particular patch is in the local repository"
  puts "-b:\tPerform reboot after patch installation (not default)"
  puts
  return
end

# Get version information fro script header

def get_version(script)
  file_array = IO.readlines script
  version    = file_array.grep(/^# Version/)[0].split(":")[1].gsub(/^\s+/,'').chomp
  packager   = file_array.grep(/^# Packager/)[0].split(":")[1].gsub(/^\s+/,'').chomp
  name       = file_array.grep(/^# Name/)[0].split(":")[1].gsub(/^\s+/,'').chomp
  return version,packager,name
end

# Print script version information

def print_version(script)
  (version,packager,name) = get_version(script)
  puts name+" v. "+version+" "+packager
  exit
end

# Get command line arguments
# Print help if given none

if !ARGV[0]
  print_usage(script,options)
  exit
end

begin
  opt = Getopt::Std.getopts(options)
rescue
  print_usage(script,options)
  exit
end

# Print version

if opt["V"]
  print_version(script)
  exit
end

# Prient usage

if opt["h"]
  print_usage(script,options)
end

# Set local patch director if given -P options

if opt["P"]
  patchdir = opt["P"]
end

# If given -U option set mode to upgrade

if opt["U"]
  mode = "up"
end

# If given -C option set mode to check/compare only

if opt["C"]
  mode = "check"
end

# If given -Z option set mode to downgrade

if opt["Z"]
  mode = "down"
end

# If given  -y option perform tasks without asking

if opt["y"]
  doaction = "y"
end

# If given -r option set te release number of ESX (e.g. 5.1.0)

if opt["r"]
  release = opt["r"]
end

# If given -b option reboot after patch installation

if opt["b"]
  reboot = "y"
end

# Routine to check a file exists
# If just given a patch number it tries to determine if a file that matches
# the patch number is available in the repository.

def check_file(filename,patchdir)
  if !filename.match(/\//)
    patch_list = Dir.entries(patchdir)
    filename   = patch_list.grep(/#{filename}/)[0].chomp
    filename   = patchdir+"/"+filename
  end
  if !File.exist?(filename)
    puts "File:  "+filename+" does not exist"
    exit
  else
    puts "File:  "+filename
  end
  return filename
end

# Get the local version of update installed on and ES host

def get_local_version(ssh_session,filename)
  local_version = ssh_session.exec!("esxcli software profile get 2>&1 |head -1 |cut -f3 -d-").chomp
  return ssh_session,local_version
end

# Get the local version of OS installed on and ES host

def get_os_version(ssh_session)
  os_version   = ssh_session.exec!("uname -r").chomp
  return ssh_session,os_version
end

# Get the latest version of update available on the VMware site or in local repository

def get_depot_version(ssh_session,filename,depot_url,os_version)
  if !filename.match(/[A-z]/)
    ssh_session.exec!("esxcli network firewall ruleset set -e true -r httpClient")
    depot_version = ssh_session.exec!("esxcli software sources profile list -d #{depot_url} 2>&1 | grep '#{os_version}' |head -1 |awk '{print $1}'").chomp
  else
    tmp_dir = "/tmp/esxzip"
    if !File.directory?(tmp_dir)
      Dir.mkdir(tmp_dir)
    end
    %x[unzip -o #{filename} metadata.zip -d #{tmp_dir}]
    depot_version = %x[unzip -l #{tmp_dir}/metadata.zip |awk '{print $4}' |grep '^profiles' |grep standard].chomp
    depot_version = depot_version.split(/\//)[1].split("-")[0..-2].join("-")
  end
  return ssh_session,depot_version
end

# Compare the local version of update installed on the ESX host with what is
# available on the VMware site on in the local repository

def compare_versions(local_version,depot_version,mode)
  if local_version.match(/-/)
    local_version = local_version.gsub(/-standard/,"")
  end
  if depot_version.match(/-/)
    depot_version = depot_version.split(/-/)[2]
  end
  puts "Current:   "+local_version
  puts "Available: "+depot_version
  if mode =~ /up|check/
    if depot_version > local_version
      puts "Depot patch level is newer than installed version"
      update_available = "y"
    else
      update_available = "n"
      puts "Local patch level is up to date"
    end
  else
    if depot_version < local_version
      puts "Depot patch level is lower than installed version"
      update_available = "y"
    else
      update_available = "n"
      puts "Local patch level is up to date"
    end
  end
  if mode == "check"
    exit
  end
  return update_available
end

# Actual routine to Update/Downgrade ESX host software

def update_software(ssh_session,hostname,username,password,local_version,depot_version,filename,mode,doaction,depot_url,reboot)
  update_available = compare_versions(local_version,depot_version,mode)
  if update_available == "y" and mode != "check"
    if filename.match(/[A-z]/)
      patch_file = File.basename(filename)
      depot_dir  = "/scratch/downloads"
      depot_file = depot_dir+"/"+patch_file
      ssh_session.exec!("mkdir #{depot_dir}")
      puts "Copying local file "+filename+" to "+hostname+":"+depot_file
      Net::SCP.upload!(hostname, username, filename, depot_file, :ssh => { :password => password })
      depot_version = ssh_session.exec!("esxcli software sources profile list -d=#{depot_file} |grep standard |awk '{print $1}'").chomp
    end
    if doaction != "y"
      while doaction !~ /y|n/
        print "Install update [y,n]: "
        doaction = gets.chomp
      end
    end
    if doaction == "y"
      if filename.match(/[A-z]/)
        puts "Installing "+depot_version+" from "+depot_file
        output = ssh_session.exec!("esxcli software profile install -d=#{depot_file} -p=#{depot_version}")
      else
        puts "Installing "+depot_version+" from "+depo_url
        ssh_session.exec!("esxcli network firewall ruleset set -e true -r httpClient")
        output = ssh_session.exec!("esxcli software profile update -d=#{depot_url} -p=#{depot_version}")
      end
    else
      puts "Not installing patch "+local_version
      exit
    end
    puts output
    if output.match(/Reboot Required: true/) and reboot == "y"
      puts "Rebooting"
      ssh_session.exec!("reboot")
    end
  end
  return ssh_session
end

# Main routing called to Update/Downgrade ESX software

def update_esxi(hostname,username,password,filename,mode,doaction,depot_url,reboot)
  begin
    Net::SSH.start(hostname, username, :password => password, :paranoid => false) do |ssh_session|
      (ssh_session,os_version)    = get_os_version(ssh_session)
      (ssh_session,local_version) = get_local_version(ssh_session,filename)
      (ssh_session,depot_version) = get_depot_version(ssh_session,filename,depot_url,os_version)
      ssh_session = update_software(ssh_session,hostname,username,password,local_version,depot_version,filename,mode,doaction,depot_url,reboot)
    end
  rescue Net::SSH::HostKeyMismatch => host
    puts "Existing key found for "+hostname
    if doaction != "y"
      while doaction !~ /y|n/
        print "Update host key [y,n]: "
        doaction = gets.chomp
      end
    end
    if doaction == "y"
      puts "Updating host key for "+hostname
      host.remember_host!
    else
      exit
    end
    retry
  end
  return
end

# Get a list of patches in the local repository

def list_local_patches(patchdir)
  if File.directory?(patchdir)
    file_list = Dir.entries(patchdir)
    file_list.each do |local_file|
      if local_file.match(/zip$/)
        puts local_file
      end
    end
  end
end

# Get a list of the available patches on the vmware site and put them into a hash
# Need to send dropdown box seletions twice to ensure they stick
# Need to search for button to click via src tag due to malformed HTML

def get_vmware_patch_info(product_url,username,password,release)
  update_list = {}
  update = ""
  driver = Selenium::WebDriver.for :phantomjs
  driver.get(product_url)
  driver.find_element(:name => "product").find_element(:css,"option[value='ESXi (Embedded and Installable)']").click
  driver.find_element(:name => "product").find_element(:css,"option[value='ESXi (Embedded and Installable)']").click
  driver.find_element(:name => "version").send_keys(release)
  driver.find_element(:name => "version").send_keys(release)
  driver.find_element(:xpath,"//*[@src='/patchmgr/resources/images/support_search_button.gif']").click
  page = driver.page_source
  page = Nokogiri::HTML.parse(page)
  info = page.css("span").css("input")
  info.each do |download|
    value = download["value"]
    if !value.match(/http/)
      update = value
    else
      if value.match(/ESX/)
        update_list[update] = value
      end
    end
  end
  return update_list
end

# Process the hash of patches returned from the VMware site and check they are
# in the local repository, if the download option is given download the patches
# if they are not in the local repository

def process_vmware_patch_info(patch_list,download,patchdir)
  patch_list.each do |patch_no, patch_url|
    puts "Update:   "+patch_no
    puts "Download: "+patch_url
    local_file = patch_url.split(/\?/)[0]
    local_file = File.basename(local_file)
    local_file = patchdir+"/"+local_file
    missing    = "n"
    if File.exist?(local_file)
      puts "Present:  "+local_file
      missing = "n"
    else
      puts "Missing:  "+local_file
      missing = "y"
    end
    if download == "y" and missing == "y"
      %x[wget "#{patch_url}" -O "#{local_file}"]
    end
  end
  return
end

# If given -L option list patches in local repository

if opt["L"]
  list_local_patches(patchdir)
  exit
end

# If the password isn't given on the command line, try to retrieve it from
# the .esxpasswd file. Otherwise ask for it.

def get_password(esx_password_file,hostname)
  if File.exist?(esx_password_file)
    all_check = %x[cat #{esx_password_file} |egrep "^\\*:|^ALL:"]
    if all_check.match(/\*|ALL/)
      password = %x[cat #{esx_password_file} |cut -f3 -d:].chomp
    else
      password = %x[cat #{esx_password_file} |grep '^#{hostname}' |cut -f3 -d:].chomp
    end
  else
    while password !~/[A-z]|[0-9]/ do
      print "Password: "
      gets password
    end
  end
  return password
end

# If the username isn't given on the command line, try to retrieve it from
# the .esxpasswd file. Otherwise ask for it.

def get_username(esx_password_file,hostname)
  if File.exist?(esx_password_file)
    all_check = %x[cat #{esx_password_file} |egrep "^\\*:|^ALL:"]
    if all_check.match(/\*|ALL/)
      username = %x[cat #{esx_password_file} |cut -f2 -d:].chomp
    else
      username = %x[cat #{esx_password_file} |grep '^#{hostname}' |cut -f2 -d:].chomp
    end
  else
    while username !~ /[A-z]/
      print "Username: "
      gets username
    end
  end
  return username
end

# Check if a particular patch is in the local repository

if opt["l"]
  patch_no = opt["l"]
  puts "Patch: "+patch_no
  filename = check_file(patch_no,patchdir)
  exit
end

# If given the -A option download patches that are not in the local repository

if opt["A"]
  download = "y"
end

# If given the -A or -R option check the available patches on the VMware site
# Also checks if they are present in the local repository

if opt["R"] or opt["A"]
  patch_list = get_vmware_patch_info(product_url,username,password,release)
  process_vmware_patch_info(patch_list,download,patchdir)
  exit
end

if opt["U"] or opt["C"] or opt["D"]
  if !opt["s"]
    puts "No server name given"
    exit
  else
    hostname = opt["s"]
  end
  if password !~ /[A-z]/
    if !opt["p"]
      password = get_password(esx_password_file,hostname)
    else
      password = opt["p"]
    end
  end
  if username !~ /[A-z]/
    if !opt["u"]
      username = get_username(esx_password_file,hostname)
    else
      username = opt["u"]
    end
  end
  if opt["f"]
    filename = opt["f"]
    filename = check_file(filename,patchdir)
  end
  hostname = opt["s"]
  if opt["U"] or opt["C"] or opt["Z"]
    update_esxi(hostname,username,password,filename,mode,doaction,depot_url,reboot)
  end
  exit
end
