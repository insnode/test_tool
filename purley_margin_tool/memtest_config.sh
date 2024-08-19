#!/bin/bash
project_code=`echo $0 |sed  -n "s/.*\/\(.*\)_.*/\1/p"`
CONFIGINFO="Equipment_save.txt"
CONFIGFILE=$project_code"_config.sh"
MEMSET_TEMP_INI=memTemp.ini

run_uniMem()
{
FILE="memset.ini"
while read i
do
	LINE=`echo $i | grep '='`
	if [ $? == 0 ] ; then
		continue
	fi
	LINE_LNX=`echo $i |sed 's/\r$/\n/'`
	NAME=`echo $LINE_LNX |awk -F " " '{print $1 }'`
	DATA=`echo $LINE_LNX |awk -F " " '{print $2 }'`
	TEST=`echo $LINE_LNX |awk -F " " '{print $3 }'`
	if [ "$NAME" == "EquipMentModeFlag" ] && [ "$DATA" == "1" ] ; then
	    echo 0 > /proc/sys/kernel/watchdog
		./uniMem RestoreSetup
	    if [ $? == 0 ] ; then
	        echo "$CONFIGFILE : RESTORESETUP SUCCESS">>"$CONFIGINFO"
	        echo "$CONFIGFILE : RESTORESETUP SUCCESS"
			./uniCfg -wf EquipDefaultSet.ini
			echo 1 > /proc/sys/kernel/watchdog
        else
	        rm -f MEMSET_TEMP_INI
	        echo "$CONFIGFILE : RESTORESETUP ERROR">>"$CONFIGINFO"
	        echo "$CONFIGFILE : RESTORESETUP ERROR"
			echo 1 > /proc/sys/kernel/watchdog
	        exit 1
        fi
	fi	
	if [ "$NAME" == "" ] || [ "$DATA" == "" ] || [ "$TEST" != "" ]; then	
		continue
	fi	
	#echo "$NAME $DATA">>"$FILE"
	
done < MEMSET_TEMP_INI

echo "./uniMem memset.ini"
echo 0 > /proc/sys/kernel/watchdog
printf "\n**************** Set Equipment Mode Variable by uniMem ****************\n"
./uniMem $FILE
echo 1 > /proc/sys/kernel/watchdog
if [ $? == 0 ] ; then
	echo "$CONFIGFILE : UNIMEM SUCCESS">>"$CONFIGINFO"
	echo "$CONFIGFILE : UNIMEM SUCCESS"
	return 0
else
	rm -f MEMSET_TEMP_INI
	echo "$CONFIGFILE : UNIMEM ERROR">>"$CONFIGINFO"
	echo "$CONFIGFILE : UNIMEM ERROR"
	exit 1
fi
}

##########   main()     #############
#{

##########   CheckEquipmentModeFlag()     #############
printf "\n*************** check Equipment Mode Flag ***************\n"
./uniMem -r EquipmentModeFlag > EquipmentModeFlag.txt
cat EquipmentModeFlag.txt|awk -F " "  '{ print $2}{exit $2}'

if [ $? == 1 ] ; then
printf "\n******** Equipment Mode Flag has been set , exit ********\n"
exit 1
fi

rm -f MEMSET_TEMP_INI

ls memset.ini > /dev/null 2>&1
if [ $? != 0 ] ; then
	echo "$CONFIGFILE : ERROR, Not find memset.ini">>"$CONFIGINFO"
	echo "$CONFIGFILE : ERROR, Not find memset.ini"
	exit 1
fi

cat memset.ini > MEMSET_TEMP_INI
echo >> MEMSET_TEMP_INI

run_uniMem

##########   ReadEquipmentModeFlag()     #############
printf "\n**************** Read Equipment Mode Flag ****************\n"
./uniMem -r EquipmentModeFlag > EquipmentModeFlag.txt
######## search the second value end return the value
cat EquipmentModeFlag.txt|awk -F " "  '{ print $2}{exit $2}'
if [ $? == 1 ] ; then
printf "\nEquipmentModeFlags 1,Set ok!\n"
echo "EquipmentModeFlags 1,Set ok" >> "$CONFIGINFO"
rm EquipmentModeFlag.txt
fi

echo "$CONFIGFILE : SUCCESS">>"$CONFIGINFO"
echo "$CONFIGFILE : SUCCESS"

rm -f MEMSET_TEMP_INI

exit 0

#}
