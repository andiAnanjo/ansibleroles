#!/usr/bin/bash

# set -e
# set -xv

merge() {
/usr/bin/mkdir "/var.tmp" "/opt.tmp"
/usr/bin/echo "STEP 01" >> /root/rsync.out
/usr/bin/rsync -aAlHX /var/ /var.tmp >> /root/rsync.out
/usr/bin/echo "$(/usr/bin/date +%y%m%d%H%M): rsync -aAlHX /var/ /var.tmp" >> /root/rsync.out
/usr/bin/sleep 5
/usr/bin/echo "STEP 02" >> /root/rsync.out
/usr/bin/rsync -aAlHXx /opt/ /opt.tmp >> /root/rsync.out
/usr/bin/echo "$(/usr/bin/date +%y%m%d%H%M): rsync -aAlHXx /opt/ /opt.tmp" >> /root/rsync.out
/usr/bin/sleep 5
/usr/bin/echo "STEP 03" >> /root/rsync.out
/usr/bin/sync
/usr/bin/umount -RAl /var && /usr/bin/mv /var /var.orig && /usr/bin/mv /var.tmp /var
/usr/bin/umount -RAl /opt && /usr/bin/mv /opt /opt.orig && /usr/bin/mv /opt.tmp /opt
for i in varlv loglv auditlv optlv; do xfs_admin -L $(basename $(lvs -o lv_path --noheadings| grep $i)) $(lvs -o lv_path --noheadings| grep $i) ;done
/usr/bin/echo "STEP 04" >> /root/rsync.out
/usr/bin/cp /etc/fstab /etc/fstab_beforeBoom
/usr/bin/sed -i -e '/\/opt /d' -e '/var/d' /etc/fstab
}

unmerge() {
/usr/bin/mkdir /var_mnt /opt_mnt
/usr/bin/echo "STEP 04" >> /root/rsync.out
/usr/bin/mount -t auto -L varlv /var_mnt
/usr/bin/mount -t auto -L loglv /var_mnt/log
/usr/bin/mount -t auto -L auditlv /var_mnt/log/audit
/usr/bin/mount -t auto -L optlv /opt_mnt
/usr/bin/echo "STEP 05" >> /root/rsync.out
/usr/bin/rsync -aAHX /var/ /var_mnt
/usr/bin/rsync -aAHXx /opt/ /opt_mnt
/usr/bin/sleep 5
/usr/bin/echo "STEP 06" >> /root/rsync.out
/usr/bin/sync
/usr/bin/sleep 5
/usr/bin/umount -RAl /var_mnt/log/audit
/usr/bin/umount -RAl /var_mnt/log
/usr/bin/umount -RAl /var_mnt && /usr/bin/rm -rf /var_mnt
/usr/bin/umount -RAl /opt_mnt && /usr/bin/rm -rf /opt_mnt
/usr/bin/echo "STEP 07" >> /root/rsync.out
/usr/bin/cp -f /etc/fstab_beforeBoom /etc/fstab
}

## main

# init vars
PRG=$$
RELEASE=$(lsb_release -r | awk '{print $2}')

# run only in rescue mode
until [ $(systemctl is-active rescue.target) = "active" ];do
  /bin/sleep 5
done

# do some checks
which sleep mv mkdir echo rsync umount reboot >> /root/rsync.out
echo "PATH=$PATH" >> /root/rsync.out
/usr/bin/pstree -alps $PRG >> /root/rsync.out
/usr/bin/systemctl status leapp-rescue-target >> /root/rsync.out


# start work
case "$RELEASE" in
  7.9)
    merge
    ;;
  8.8)
    unmerge
    ;;
  *)
    echo "NOTHING TO DO"
    ;;
esac

/usr/bin/echo "STEP REBOOT" >> /root/rsync.out
/sbin/reboot -f
