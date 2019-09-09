#!/usr/bin/env ruby

# Name:         eclair (ESX Command Line Automation In Ruby)
# Version:      0.1.8
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

# Install gems if they can't be loaded

def install_gem(gem_name)
  if gem_name.match(/getopt/)
    install_name = "getopt"
  else
    install_name = gem_name.gsub(/\//,"-")
  end
  puts "Information:\tInstalling #{install_name}"
  %x[gem install #{install_name}]
  Gem.clear_paths
  require "#{gem_name}"
end

# Required gem list

gem_list = [ "net/ssh", "net/scp", "etc", "expect", "getopt/std", 
             "selenium-webdriver", "nokogiri", "io/console" ]

# Try to load gems

for gem_name in gem_list
  begin
    require "#{gem_name}"
  rescue LoadError
    install_gem(gem_name)
  end
end

# Set some defaults

script    = $0
options   = "ABCDef:Hhl:kK:LMP:r:Rs:Sp:u:UVyZv"
username  = ""
password  = ""
mode      = "check"
doaction  = ""
filename  = ""
patchdir  = Dir.pwd+"/patches"
release   = "6.0.0"
download  = "n"
reboot    = "n"

# VMware URLs

login_url   = "https://my.vmware.com/web/vmware/login"
product_url = "https://www.vmware.com/patchmgr/findPatch.portal"
depot_url   = "http://hostupdate.vmware.com/software/VUM/PRODUCTION/main/vmw-depot-index.xml"

# Password file (can be used so username and password are not shown in command line)
# ESX password file has the format "host:user:password"
# If all systems have the same username and password then an entry of:
# ALL:username:password or *:username:password will work

esx_password_file    = Etc.getpwuid.dir+"/.esxpasswd"
vmware_password_file = Etc.getpwuid.dir+"/.vmwarepasswd"

# If password files exist give them sensible permissions

[ esx_password_file, vmware_password_file ].each do |password_file|
  if File.exist?(password_file)
    file_stat = File.stat(password_file)
    file_mode = file_stat.mode.to_i
    if file_mode !~ /600/
      %x[chmod 600 #{password_file}]
    end
  end
end

# Compare versions

def compare_ver(curr_fw,avail_fw)
  ord_avail_fw = []
  counter      = 0
  avail_fw     = avail_fw.split(".")
  while counter < avail_fw.length
    digit = avail_fw[counter]
    if digit.match(/[A-z]/)
      ord_avail_fw[counter] = digit.ord
    else
      ord_avail_fw[counter] = digit
    end
    counter = counter+1
  end
  ord_avail_fw = ord_avail_fw.join(".")
  avail_fw     = avail_fw.join(".")
  ord_curr_fw  = []
  counter      = 0
  curr_fw      = curr_fw.split(".")
  while counter < curr_fw.length
    digit = curr_fw[counter]
    if digit.match(/[A-z]/)
      ord_curr_fw[counter] = digit.ord
    else
      ord_curr_fw[counter] = digit
    end
    counter = counter+1
  end
  ord_curr_fw  = ord_curr_fw.join(".")
  curr_fw      = curr_fw.join(".")
  versions     = [ ord_curr_fw, ord_avail_fw ]
  latest_fw    = versions.map{ |v| (v.split '.').collect(&:to_i) }.max.join '.'
  if latest_fw == ord_curr_fw
    return curr_fw
  else
    return avail_fw
  end
end

# Print usage information

def print_usage(script,options)
  puts
  puts "Usage: "+script+" -["+options+"]"
  puts
  puts "-h:\tPrint usage information"
  puts "-V:\tPrint version information"
  puts "-B:\tBackup ESX configuration"
  puts "-U:\tUpdate ESX if newer patch level is available"
  puts "-Z:\tDowngrade ESX to earlier release"
  puts "-L:\tList all available versions in local patch directory"
  puts "-M:\tList all available versions in VMware depot"
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
  puts "-k:\tShow license keys"
  puts "-K:\tInstall license key"
  puts "-R:\tReboot server"
  puts "-H:\tShutdown server"
  puts "-e:\tExecute a command on a server"
  puts "-v:\tVerbose mode"
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

# If given -K set license key

if opt["K"]
  license_key = opt["K"]
  command     = "vim-cmd vimsvc/license --set #{license_key}"
end

if opt["k"]
  command = "vim-cmd vimsvc/license --show"
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

# Verbose mode

if opt['v']
  $verbose_mode = true
else
  $verbose_mode = false
end

# Create password file



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
  (ssh_session,local_version) = ssh_session_exec(ssh_session,"esxcli software vib list |grep 'esx-base' |awk '{print $2}'")
  local_version = local_version.chomp
  if $verbose_mode == true
    puts "vSphere release: "+local_version
  end
  return ssh_session,local_version
end

# Get the local version of OS installed on and ES host

def get_os_version(ssh_session)
  (ssh_session,os_version) = ssh_session_exec(ssh_session,"uname -r")
  os_version = os_version.chomp
  if $verbose_mode == true
    puts "vSphere version: "+os_version
  end
  return ssh_session,os_version
end

def ssh_session_exec(ssh_session,command)
  if $verbose_mode == true
    puts "vSphere command: "+command
  end
  output = ssh_session.exec!(command)
  return ssh_session,output
end

# Get the latest version of update available on the VMware site or in local repository

def get_depot_version(ssh_session,filename,depot_url,os_version)
  if !filename.match(/[A-z]/)
    (ssh_session,output)        = ssh_session_exec(ssh_session,"esxcli network firewall ruleset set -e true -r httpClient")
    (ssh_session,depot_version) = ssh_session_exec(ssh_session,"esxcli software sources vib list -d #{depot_url} 2>&1 | grep '#{os_version}' |grep 'esx-base' |grep Update |awk '{print $2}' |tail -1")
    if !depot_version
      (ssh_sessionm,depot_version) = ssh_session_exec(ssh_session,"esxcli software sources vib list -d #{depot_url} 2>&1 | grep '#{os_version}' |grep 'esx-base' |grep Installed |awk '{print $2}' |tail -1")
    end
    depot_version = depot_version.chomp 
  else
    tmp_dir = "/tmp/esxzip"
    if !File.directory?(tmp_dir)
      Dir.mkdir(tmp_dir)
    end
    %x[unzip -o #{filename} metadata.zip -d #{tmp_dir}]
    depot_version = %x[unzip -l #{tmp_dir}/metadata.zip |awk '{print $4}' |grep '^profiles' |grep standard].chomp
    depot_version = depot_version.split(/\//)[1].split("-")[0..-2].join("-")
  end
  if $verbose_mode == true
    puts "Depot release: "+depot_version
  end
  return ssh_session,depot_version
end

# Compare the local version of update installed on the ESX host with what is
# available on the VMware site on in the local repository

def compare_versions(local_version,depot_version,mode)
  if local_version.match(/-/)
    local_version = local_version.split(/-/)[1]
  end
  if depot_version.match(/-/)
    depot_version = depot_version.split(/-/)[1]
  end
  puts "Current:   "+local_version
  puts "Available: "+depot_version
  if mode =~ /up|check/
    avail_fw = compare_ver(local_version,depot_version)
    if avail_fw.to_s != local_version.to_s
      puts "Depot patch level is newer than installed version"
      update_available = "y"
    else
      update_available = "n"
      puts "Local patch level is up to date"
    end
  else
    if depot_version.to_i < local_version.to_i
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

# download file from server

def download_server_file(hostname,username,password,remote_file,local_file)
  Net::SCP.download!(hostname, username, remote_file, local_file, :ssh => { :password => password })
  return
end

# upload file from server

def upload_server_file(hostname,username,password,remote_file,local_file)
  Net::SCP.upload!(hostname, username, remote_file, local_file, :ssh => { :password => password })
  return
end
  
# Actual routine to Update/Downgrade ESX host software

def update_software(ssh_session,hostname,username,password,local_version,depot_version,filename,mode,doaction,depot_url,reboot)
  update_available = compare_versions(local_version,depot_version,mode)
  if update_available == "y" and mode != "check"
    if filename.match(/[A-z]/)
      patch_file = File.basename(filename)
      depot_dir  = "/scratch/downloads"
      depot_file = depot_dir+"/"+patch_file
      (ssh_session,output) = ssh_session_exec(ssh_session,"mkdir #{depot_dir}")
      puts "Copying local file "+filename+" to "+hostname+":"+depot_file
      Net::SCP.upload!(hostname, username, filename, depot_file, :ssh => { :password => password })
    else
      depot_file = depot_url
    end
    if doaction != "y"
      while doaction !~ /y|n/
        print "Install update [y,n]: "
        doaction = gets.chomp
      end
    end
    if doaction == "y"
      puts "Installing "+depot_version+" from "+depot_file
      (ssh_session,output) = ssh_session_exec(ssh_session,"esxcli software vib update -d=#{depot_file}")
    else
      puts "Performing Dry Run - No updates will be installed"
      (ssh_session,output) = ssh_session_exec(ssh_session,"esxcli software vib update -d=#{depot_file} --dry-run")
    end
    puts output
    if output.match(/Reboot Required: true/) and reboot == "y"
      puts "Rebooting"
      (ssh_session,output) = ssh_session_exec(ssh_session,"reboot")
    end
  end
  return ssh_session
end

# Run a command on the server

def control_server(hostname,username,password,command)
  if $verbose_mode == true
    puts "vSphere Server:  "+hostname
    puts "vSphere Command: "+command
  end
  begin
    Net::SSH.start(hostname, username, :password => password, :verify_host_key => false) do |ssh_session|
      (ssh_session,output) = ssh_session_exec(ssh_session,command)
      return output
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
  return output
end

# Main routing called to Update/Downgrade ESX software

def update_esxi(hostname,username,password,filename,mode,doaction,depot_url,reboot)
  if $verbose_mode == true
    puts "Connecting to: "+hostname
  end
  begin
    Net::SSH.start(hostname, username, :password => password, :verify_host_key => false) do |ssh_session|
      (ssh_session,os_version)    = get_os_version(ssh_session)
      (ssh_session,local_version) = get_local_version(ssh_session,filename)
      (ssh_session,depot_version) = get_depot_version(ssh_session,filename,depot_url,os_version)
      exit
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

def get_vmware_patch_info(login_url,product_url,username,password,release)
  update_list = {}
  update = ""
  options = Selenium::WebDriver::Firefox::Options.new
  options.add_argument('--headless')
  driver = Selenium::WebDriver.for :firefox
  driver.get(login_url)
  driver.find_element(:id => "username").send_keys(username)
  driver.find_element(:id => "password").send_keys(password)
  driver.find_element(:id => "button-login").click
  driver.get(product_url)
  driver.find_element(:name => "product").find_element(:css,"option[value='ESXi (Embedded and Installable)']").click
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

# Update ESX password file

def update_esx_passwd_file(esx_hostname,esx_username,esx_password)
  esx_passwd_file = Dir.home+"/.esxpasswd"
  FileUtils.touch(esx_passwd_file)
  File.chmod(0600,esx_passwd_file)
  output_text = esx_hostname+":"+esx_username+":"+esx_password
  File.open(esx_passwd_file, 'a') { |file| file.write(output_text) }
  return
end

# Get ESX username

def get_esx_username()
  esx_username = ""
  while esx_username !~ /[A-z]/
    print "ESX Username: "
    STDOUT.flush
    esx_username = gets.chomp
  end
  return esx_username
end

# Get ESX password

def get_esx_password()
  esx_password = ""
  while esx_password !~/[A-Z]|[a-z]|[0-9]/ do
    print "ESX Password: "
    STDOUT.flush
    esx_password = STDIN.noecho(&:gets).chomp
  end
  return esx_password
end

# If a ~/,esxpasswd doesn't exist ask for details

def get_esx_details(esx_hostname)
  esx_passwd_file = Dir.home+"/.esxpasswd"
  esx_host_found  = false
  esx_info_change = false
  if !File.exist?(esx_passwd_file)
    esx_username = get_esx_username()
    esx_password = get_esx_password()
    update_esx_passwd_file(esx_hostname,esx_username,esx_password)
  else
    esx_data = File.readlines(esx_passwd_file)
    esx_data.each do |line|
      line.chomp
      if line.match(/^#{esx_hostname}:/)
        esx_host_found = true
        esx_details    = line.split(/:/)
        esx_username   = esx_details[1]
        if esx_username !~/[A-Z]|[a-z]/
          esx_username    = get_esx_username()
          esx_info_change = true
        end
        esx_password   = esx_details[2]
        if esx_password !~/[A-Z]|[a-z]|[0-9]/
          esx_password    = get_esx_password()
          esx_info_change = true
        end
        if esx_info_change == true
          update_esx_passwd_file(esx_hostname,esx_username,esx_password)
        end
      end
    end
    if esx_host_found == false
      esx_username = get_esx_username()
      esx_password = get_esx_password()
      update_esx_passwd_file(esx_hostname,esx_username,esx_password)
    end
  end
  return esx_username,esx_password
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

# If given -H shutdown server (halt)

if opt["H"]
  command = "halt"
end

# If given -R reboot server

if opt["R"]
  command = "reboot"
  reboot  = "y"
end

# If given -B run backup config command
  
if opt["B"]
  command = "vim-cmd hostsvc/firmware/backup_config"
end
  
# If given -f check file exists

if opt["f"]
  filename = opt["f"]
  filename = check_file(filename,patchdir)
end

if opt["s"]
  hostname = opt["s"]
end

# If given the -A or -R option check the available patches on the VMware site
# Also checks if they are present in the local repository

if opt["M"] or opt["A"]
  puts "Enter VMware Web Site Login"
  if username !~ /[A-z]/
    if !opt["u"]
      username = get_vmware_username(username,vmware_password_file)
    else
      username = opt["u"]
    end
  end
  if password !~ /[A-z]/
    if !opt["p"]
      password = get_vmware_password(password,vmware_password_file)
    else
      password = opt["p"]
    end
  end
  patch_list = get_vmware_patch_info(login_url,product_url,username,password,release)
  process_vmware_patch_info(patch_list,download,patchdir)
  exit
end

if opt["U"] or opt["C"] or opt["D"] or opt["K"] or opt["k"] or opt["H"] or opt["R"] or opt["e"] or opt["B"]
  if !hostname
    puts "No server name given"
    exit
  end
  if username !~ /[A-z]/
    if !opt["u"]
      (username,password) = get_esx_details(hostname)
    else
      username = opt["u"]
    end
  end
  if password !~ /[A-z]/
    if !opt["p"]
      (username,password) = get_esx_details(hostname)
    else
      password = opt["p"]
    end
  end
  if opt["U"] or opt["C"] or opt["Z"]
    update_esxi(hostname,username,password,filename,mode,doaction,depot_url,reboot)
  else
    if opt["K"] or opt["k"] or opt["H"] or opt["R"] or opt["e"] or opt["B"]
      output = control_server(hostname,username,password,command)
      puts output
      if opt["B"]
        remote_file = "/scratch/downloads/"+output.split(/\//)[-2..-1].join("/").chomp
        if !filename or !filename.match(/[A-z]/)
          local_file = "/tmp/"+remote_file.split(/\//)[-1]
        else
          local_file = filename
        end
        puts "Copying: "+hostname+":"+remote_file+" to "+local_file
        download_server_file(hostname,username,password,remote_file,local_file)
      end
    end
  end
  exit
end
