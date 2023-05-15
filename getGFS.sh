#/bin/bash
# 
# Version: 0.1 date: 2023/05/05
#          -.- date: 202-/--/--
# 
# Script to download selected GFS 0.25 data for a forecast 
# period from the NCEP NOAA database
# 
#
# Author: Jose Luis Rodriguez-Solis
#         jrodriguez@cicese.edu.mx
#         
#
#
#|- - - - - - - - - - - - - - - - - - - - - - - - - - - - -|
#|                                                         |
#|                     BEGIN USER SECTION                  |
#|                                                         |
#|- - - - - - - - - - - - - - - - - - - - - - - - - - - - -|
#
#
# enclose your subregion
# choose your latitude and longitude coordinates
# description:
#                bottomlat: south latitude
#                toplat   : north latitude
#                rightlon : west longitude
#                leftlon  : east longitude
#
# FORMAT: integer

bottomlat=5
toplat=45
rightlon=-140
leftlon=-30

#
# The first version just  00z or 12z   run  is donwloaded.
# At 08:00 hrs [PST UTC-8]  the 00z run is desire, but  if 
# it is not available  the  12z run of the day before will
# be instead. Also  option run can be changed for the 00z, 
# 06z,12z and 18z.
#
#
#                run      : 00
#                           12
#
# FORMAT: integer

run=00


#
# time step and period of forecast required
#
#
# FORMAT: integer

days=1              #number of days
timestep=3          #the time step forecast (3 or 6)

#




#
# Date is choosen by user or automatically. If option -on-
# is selected user must especify the date of the data re--
# quired. Option -off- let the script download the 00z run 
# data if it is available, otherwise  the  12z run of  the
# day before will be download.
#
# UserDate option must be in the format yyyymmdd. 
# Example: 20230511 for May 11th 2023.
#
#
#                UserDate : off
#                           yyyymmdd
#
# FORMAT: character
              
UserDate="off"

# 
# Path directory where data will be stored. A folder  will
# be created with the format yyyymmdd_rr. This option  can
# be turned -off-  and  then  the script  creates a folder 
# where it is running
#
#
#                PathToStore: off
#                             your/path/to/data
#
# FORMAT: character

PathToStore='off'

#
#|- - - - - - - - - - - - - - - - - - - - - - - - - - - - -|
#|                                                         |
#|                     END USER SECTION                    |
#|                                                         |
#|- - - - - - - - - - - - - - - - - - - - - - - - - - - - -|
#
#
# 
echo ''
echo '---------'
echo 'Data download begins'
#
#
# _________________________________________________________
#
#
#                      Begin program
#
# _________________________________________________________
#
#
# variables
# 
#
#


# ------ Where I am?
ScriptDir=`pwd`

# 
ni=0               # the first forecast

steps=$(( 24 / $timestep ))
nf=$(( $days * $steps ))


if [ $UserDate = 'off' ]; then
  
  # ------ what day is today
  today=`date -d" 0 days" +%Y%m%d`                 # date in yyyymmdd
  hour=`date -d" 0 days" +%k| sed 's/[^0-9]//g'`   # hour in integer
  yesterday=`date -d" -1 days" +%Y%m%d`            # yesterday

else

  # check if UserDate is a valid date 
  if [[ $UserDate != [0-9][0-9][0-9][0-9][0-1][0-9][0-3][0-9] ]]; then
	echo " "
	echo '-------------------------------------------------'
  	echo "ERROR: Not a valid date or date is not in the yyyymmdd format."
	echo "-------------------------------------------------"
	echo ""
	exit
  else
  	today=$(echo $UserDate)
  fi

fi

#
#
# # Checking if especified directory exists
#
#
echo ''

if [ $PathToStore = 'off' ]; then

  PathToDir=${today}"_"${run}
  echo $PathToDir
  rm -rf ${PathToDir}
  mkdir -p ${PathToDir}
  echo "Data will be stored in: "$ScriptDir'/'$PathToDir

else

  if [ -d ${PathToStore} ]; then
	PathToDir=${PathToStore}"/"${today}"_"$run
	rm -rf ${PathToDir}
        mkdir -p ${PathToDir}
        echo "Data will be stored in: "$PathToDir
  else
	echo '-------------------------------------------------'
  	echo "ERROR: Directory "$PathToStore" does not exist."
	echo 'Verify directory in PathToStore user option  or'
	echo 'turn in -off- mode'
	echo '-------------------------------------------------'
	echo ''
	echo ''
 	exit 
  fi

fi

#
#
# Checking if data url exists. Try with the 000 forecast
#
#
s_url_01="https://nomads.ncep.noaa.gov/cgi-bin/filter_gfs_0p25.pl?file=gfs.t"${run}
s_url_02="z.pgrb2.0p25.f000&all_lev=on&all_var=on&"
s_url_03="leftlon="${leftlon}"&rightlon="${rightlon}"&toplat="${toplat}"&bottomlat="${bottomlat}"&dir=%2Fgfs."${today}"%2F"${run}"%2Fatmos"
# the url data
url=$s_url_01$s_url_02$s_url_03

#
#
# 
#
echo ''
echo '---------'
echo 'checking if the url exists...'
echo ''
echo '...'
echo ''


#
#
if [[ `curl --head $url 2>&1 | grep 'HTTP/1.1 200 OK'` ]]; then
#
#       --------------
#       The URL exists
#       --------------
#
  echo '---------'
  echo 'Yes. URL exists'
  echo ''
  echo '---------'
  echo 'downloading...'
  #  ------ downloading data
  for i in $(seq -f "%03g" $ni $timestep $nf)
        do
	s_url_02="z.pgrb2.0p25.f"${i}"&all_lev=on&all_var=on&"
	url=$s_url_01$s_url_02$s_url_03
	wget  $url -O $PathToDir"/gfs."$today"."$run"."$i".grb"
  done


else 
#
#       --------------
#       The URL does not exist. Let's try yesterday 12z run
#       --------------
# 
#
  echo '---------'
  echo 'No. The URL does not exist. Trying with 12Z run'

  run='12'
  s_url_03="leftlon="${leftlon}"&rightlon="${rightlon}"&toplat="${toplat}"&bottomlat="${bottomlat}"&dir=%2Fgfs."${yesterday}"%2F"${run}"%2Fatmos"
  s_url_02="z.pgrb2.0p25.f000&all_lev=on&all_var=on&"

  url=$s_url_01$s_url_02$s_url_03
 
  # ------  
  if [[ `curl --head $url 2>&1 | grep 'HTTP/1.1 200 OK'` ]]; then

	if [ $PathToStore = 'off' ]; then
	 	rm -rf ${PathToDir}
	  	PathToDir=${yesterday}"_"${run}
	  	mkdir -p ${PathToDir}
	  	
	else
		rm -rf ${PathToDir}
	  	PathToDir=${PathToStore}"/"${yesterday}"_"$run
	      	mkdir -p ${PathToDir}
	fi
	  
	echo '---------'
	echo 'downloading...'
	echo ''
	#  ------ 
	for i in $(seq -f "%03g" $ni $timestep $nf)
	do
	s_url_02="z.pgrb2.0p25.f"${i}"&all_lev=on&all_var=on&"
	url=$s_url_01$s_url_02$s_url_03
	wget  $url -O $PathToDir"/gfs."${today}"."${run}"."${i}".grb"
	done

  else

	echo '-------------------------------------------------'
  	echo "ERROR: the url does not exist."
	echo 'Verify date availability or turn the option UserDate '
	echo 'in -off- mode'
	echo '-------------------------------------------------'
	echo ''
	echo ''
        rm -rf ${PathToDir}
 	exit 
  fi

fi
#
# _________________________________________________________
#
#
#                      End program
#
# _________________________________________________________
#
#
echo ''
echo '---------'
echo 'Done ...'










