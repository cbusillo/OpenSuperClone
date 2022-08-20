#Make sure the prerequisite software is installed for unpacking and repacking the image. Open a terminal and run:
#sudo apt-get install squashfs-tools genisoimage

#set the working directory location
#don't add a / at the end here, that is taken care of in rest of the script
eval directory="~/live_cd"
#set the path to the source ISO
eval sourceiso="~/live_cd/xubuntu-14.04.5-desktop-i386.iso"
#set the output ISO name (and path)
eval outputiso="~/live_cd/xubuntu-14.04.5-desktop-hddlive"
#set the changelog file
eval changelogfile="~/hddsupertool/public/live_cd/changelog"
#set the version file
eval versionfile="~/hddsupertool/public/live_cd/version"

# A few things in case the build was aborted
sudo umount $directory/custom-img/mntiso
sudo umount $directory/custom-img/edit/dev

# Remove any files from previous build
sudo rm -rf $directory/custom-img
sudo rm $outputiso
sudo rm $directory/changelog.txt

#Create a fresh folder to begin work.
mkdir -p $directory/custom-img
cd $directory/custom-img

#Next, extract the contents of disc image.
mkdir mntiso
sudo mount -o loop $sourceiso mntiso
mkdir extract
sudo rsync --exclude=/casper/filesystem.squashfs -a mntiso/ extract

#Extract the filesystem with the following commands:
sudo unsquashfs mntiso/casper/filesystem.squashfs
sudo mv squashfs-root edit

#You’re going to need network access from within the chroot environment to download and install updated/new packages. Copy resolv.conf from your system into the freshly unpacked fs.
sudo cp /etc/resolv.conf edit/etc/

#Mount a few important working directories, and perform a few commands will make sure that everything goes smoothly while modifying packages:
sudo mount --bind /dev/ edit/dev
sudo chroot edit /bin/bash -c "mount -t proc none /proc"
sudo chroot edit /bin/bash -c "mount -t sysfs none /sys"
sudo chroot edit /bin/bash -c "mount -t devpts none /dev/pts"
sudo chroot edit /bin/bash -c "export HOME=/root"
sudo chroot edit /bin/bash -c "export LC_ALL=C"
sudo chroot edit /bin/bash -c "dbus-uuidgen > /var/lib/dbus/machine-id"
sudo chroot edit /bin/bash -c "dpkg-divert --local --rename --add /sbin/initctl"
sudo chroot edit /bin/bash -c "ln -s /bin/true /sbin/initctl"

# copy any files needed to the home directory of the edit
sudo cp -R ~/hddsupertool/public/live_cd/pro/* $directory/custom-img/edit/home

# change the isolinux.cfg file to change the timer
sudo sed -i -e 's/timeout.*/timeout 500/' $directory/custom-img/extract/isolinux/isolinux.cfg

# change the gfxboot.cfg file so the menu shows
sudo sed -i -e 's/hidden-timeout/timeout-hidden/g' $directory/custom-img/extract/isolinux/gfxboot.cfg

# change the txt.cfg file to change the install menu item to our own
sudo sed -i -e 's/menu label ^Install Xubuntu/menu label ^HDDLiveCD disable ataX easy boot edit, just change X/g' $directory/custom-img/extract/isolinux/txt.cfg
sudo sed -i -e 's|append  file=/cdrom/preseed/xubuntu.seed boot=casper only-ubiquity initrd=/casper/initrd.lz quiet splash ---|append  file=/cdrom/preseed/xubuntu.seed boot=casper initrd=/casper/initrd.lz quiet splash --- libata.force=X:disable|g' $directory/custom-img/extract/isolinux/txt.cfg

# remove the desktop icon for installing the os
sudo rm -f $directory/custom-img/edit/usr/share/applications/ubiquity.desktop

# This next section allows for adding automated commands to run within chroot
cat << 'EOF' > $directory/custom-img/custom-commands.sh
###############################################################
###############################################################
###### PUT YOUR CUSTOMIZATION COMMANDS IN THE AREA BELOW ######
###############################################################

add-apt-repository ppa:maarten-baert/simplescreenrecorder -y
apt-get update
apt-get install simplescreenrecorder -y
apt-get install gromit-mpx -y
apt-get install screenruler -y
apt-get install gcc -y
apt-get install g++ -y
apt-get install make -y
apt-get install sleuthkit -y
apt-get install ntfs-3g -y
apt-get install exfat-fuse -y
apt-get install exfat-utils -y
apt-get install gnu-fdisk -y
apt-get install gparted -y
apt-get install smartmontools -y
apt-get install testdisk -y
apt-get install gnuplot-nox -y
apt-get install gnuplot-x11 -y
apt-get install hfsplus -y
apt-get install hfsutils -y
apt-get install hfsprogs -y
apt-get install libusb-0.1 -y
apt-get install bless -y
apt-get install wxhexeditor -y

cd home
chmod -R 755 *
cd hddsuperclone
make install
cd ..
cd hddscviewer
make install
cd ..
cd ddrutility
make
make install
cd ..
cd ddrescue
./configure --enable-non-posix
make
make install
cd ..
cd ddrescueview-linux-i386
cp ddrescueview /usr/local/bin/
cd ..
cd hdparm
make
make install
cd ..
cd dmde-lin32-con
cp -R * /usr/local/bin/
cd ..
mkdir -p xubuntu/Desktop
cp HDDSuperClone-desktop xubuntu/Desktop/HDDSuperClone.desktop
cp HDDSuperTool-desktop xubuntu/Desktop/HDDSuperTool.desktop
cp HDDSCViewer-desktop xubuntu/Desktop/HDDSCViewer.desktop
cp Terminal-desktop xubuntu/Desktop/Terminal.desktop
cp DMDE-desktop xubuntu/Desktop/DMDE.desktop
cp DisableScreensaver-desktop xubuntu/Desktop/DisableScreensaver.desktop
chmod 755 xubuntu/Desktop/HDDSuperClone.desktop
chmod 755 xubuntu/Desktop/HDDSuperTool.desktop
chmod 755 xubuntu/Desktop/HDDSCViewer.desktop
chmod 755 xubuntu/Desktop/Terminal.desktop
chmod 755 xubuntu/Desktop/DMDE.desktop
chmod 755 xubuntu/Desktop/DisableScreensaver.desktop

# disable automount for pcmanfm (LXDE)
sed -i -e 's/mount_on_startup=1/mount_on_startup=0/g' /etc/xdg/pcmanfm/default/pcmanfm.conf
sed -i -e 's/mount_removable=1/mount_removable=0/g' /etc/xdg/pcmanfm/default/pcmanfm.conf
sed -i -e 's/autorun=1/autorun=0/g' /etc/xdg/pcmanfm/default/pcmanfm.conf
sed -i -e 's/mount_on_startup=1/mount_on_startup=0/g' /etc/xdg/pcmanfm/xubuntu/pcmanfm.conf
sed -i -e 's/mount_removable=1/mount_removable=0/g' /etc/xdg/pcmanfm/xubuntu/pcmanfm.conf
sed -i -e 's/autorun=1/autorun=0/g' /etc/xdg/pcmanfm/xubuntu/pcmanfm.conf

#disable automount for thunar (XFCE)
sed -z 's/<property name="automount-media" type="empty">\n    <property name="enabled" type="bool" value="true"/<property name="automount-media" type="empty">\n    <property name="enabled" type="bool" value="false"/' -i /etc/xdg/xdg-xubuntu/xfce4/xfconf/xfce-perchannel-xml/thunar-volman.xml
sed -z 's/<property name="automount-drives" type="empty">\n    <property name="enabled" type="bool" value="true"/<property name="automount-drives" type="empty">\n    <property name="enabled" type="bool" value="false"/' -i /etc/xdg/xdg-xubuntu/xfce4/xfconf/xfce-perchannel-xml/thunar-volman.xml
sed -z 's/<property name="autobrowse" type="empty">\n    <property name="enabled" type="bool" value="true"/<property name="autobrowse" type="empty">\n    <property name="enabled" type="bool" value="false"/' -i /etc/xdg/xdg-xubuntu/xfce4/xfconf/xfce-perchannel-xml/thunar-volman.xml
sed -z 's/<property name="automount-media" type="empty">\n    <property name="enabled" type="bool" value="true"/<property name="automount-media" type="empty">\n    <property name="enabled" type="bool" value="false"/' -i /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/thunar-volman.xml
sed -z 's/<property name="automount-drives" type="empty">\n    <property name="enabled" type="bool" value="true"/<property name="automount-drives" type="empty">\n    <property name="enabled" type="bool" value="false"/' -i /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/thunar-volman.xml
sed -z 's/<property name="autobrowse" type="empty">\n    <property name="enabled" type="bool" value="true"/<property name="autobrowse" type="empty">\n    <property name="enabled" type="bool" value="false"/' -i /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/thunar-volman.xml


###############################################################
###### PUT YOUR CUSTOMIZATION COMMANDS IN THE AREA ABOVE ######
###############################################################
###############################################################
EOF
sudo cp -f $directory/custom-img/custom-commands.sh $directory/custom-img/edit/
sudo chroot edit /bin/bash -c "chmod 755 custom-commands.sh"
sudo chroot edit /bin/bash -c "./custom-commands.sh"
sudo chroot edit /bin/bash -c "rm -f custom-commands.sh"

# Now we will open a chroot command prompt for any commands that you wish to enter manually
echo
echo "*************************************"
echo "You are now in chroot of the ISO."
echo "You can now run customization commands."
echo "When done type 'exit' and the build will continue."
echo "*************************************"
echo
#sudo chroot edit

#You are almost there! Time to clean up:
sudo chroot edit /bin/bash -c "apt-get autoremove && apt-get autoclean"
sudo chroot edit /bin/bash -c "rm -rf /tmp/* ~/.bash_history"
sudo chroot edit /bin/bash -c "rm /var/lib/dbus/machine-id"
sudo chroot edit /bin/bash -c "rm /sbin/initctl"
sudo chroot edit /bin/bash -c "dpkg-divert --rename --remove /sbin/initctl"
sudo chroot edit /bin/bash -c "umount /proc || umount -lf /proc"
sudo chroot edit /bin/bash -c "umount /sys"
sudo chroot edit /bin/bash -c "umount /dev/pts"
sudo umount edit/dev

#These final steps will actually produce the ISO.
#Generate a new file manifest:
sudo chmod +w extract/casper/filesystem.manifest
sudo chroot edit dpkg-query -W --showformat='${Package} ${Version}n' > filesystem.manifest
sudo mv -f filesystem.manifest extract/casper/
sudo cp extract/casper/filesystem.manifest extract/casper/filesystem.manifest-desktop
sudo sed -i '/ubiquity/d' extract/casper/filesystem.manifest-desktop
sudo sed -i '/casper/d' extract/casper/filesystem.manifest-desktop

#Compress the filesystem:
#sudo mksquashfs edit extract/casper/filesystem.squashfs -b 1048576
sudo mksquashfs edit extract/casper/filesystem.squashfs -b 1M -comp xz -Xdict-size 100%

#Update filesystem size (needed by the installer):
printf $(sudo du -sx --block-size=1 edit | cut -f1) | sudo tee extract/casper/filesystem.size
echo

#Delete the old md5sum:
cd extract
sudo rm md5sum.txt

#…and generate a fresh one:
sudo su -c "find -type f -print0 | sudo xargs -0 md5sum | grep -v isolinux/boot.cat > md5sum.txt"

#And finally, create the ISO.
sudo genisoimage -D -r -V "$IMAGE_NAME" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o $outputiso .
sudo umount $directory/custom-img/mntiso

# Set some variables
version=$(head -1 ~/hddsupertool/public/live_cd/version)
if [ "$(uname -m | grep '64')" != "" ]; then
  arch="x64"
else
  arch="x86"
fi
size="$(stat -c %s $outputiso | numfmt --to=si)"

# Rename the iso
newiso=$outputiso.$version.$arch.$size.iso
sudo rm $newiso
sudo mv $outputiso $newiso

#create a checksum file for the iso, nice to have if you plan on sharing it
sudo rm $newiso.checksum.txt
echo "md5sum:" > $newiso.checksum.txt
md5sum -b $newiso >> $newiso.checksum.txt
echo "" >> $newiso.checksum.txt
echo "sha1sum:" >> $newiso.checksum.txt
sha1sum -b $newiso >> $newiso.checksum.txt

#Copy the changelog
cp  $changelogfile $directory/changelog.txt

