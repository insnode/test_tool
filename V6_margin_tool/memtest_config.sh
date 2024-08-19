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
            # echo "TODO: Replace RestoreSetup By unicfg"
            ./uniCfg -d
            if [ $? == 0 ] ; then
                echo "$CONFIGFILE : RESTORESETUP SUCCESS" | tee -a "$CONFIGINFO"
                ./uniCfg -wf EquipDefaultSet.ini
                echo 1 > /proc/sys/kernel/watchdog
            else
                rm -f MEMSET_TEMP_INI
                echo "$CONFIGFILE : RESTORESETUP ERROR" | tee -a "$CONFIGINFO"
                echo 1 > /proc/sys/kernel/watchdog
                exit 1
            fi
        fi	
        if [ "$NAME" == "" ] || [ "$DATA" == "" ] || [ "$TEST" != "" ]; then	
            continue
        fi	
        
    done < MEMSET_TEMP_INI

    echo 0 > /proc/sys/kernel/watchdog
    echo "Set Equipment Mode Variable by uniCfg"
    while read i || [[ -n ${i} ]]
    do
        NAME=`echo $i | awk '{print $1}'`
        DATA=`echo $i | awk '{print $2}'`
        echo "$NAME:$DATA" >> "uniCfg_temp.ini"
    done < $FILE
    ./uniCfg -wf uniCfg_temp.ini
    rm -rf uniCfg_temp.ini

    echo 1 > /proc/sys/kernel/watchdog
    if [ $? == 0 ] ; then
        echo "$CONFIGFILE : UNICFG SUCCESS" | tee -a "$CONFIGINFO"
        return 0
    else
        rm -f MEMSET_TEMP_INI
        echo "$CONFIGFILE : UNICFG ERROR" | tee -a "$CONFIGINFO"
        exit 1
    fi
}

##########   main()     #############
#{
echo "Check Equipment Mode Flag"
result=`./uniCfg -r EquipMentModeFlag | grep -P -o "EquipMentModeFlag = \d*" | awk '{print $NF}'`
if [ "$result" == 1 ] ; then
    echo "Equipment Mode Flag has been set, exit"
    exit 1
fi

rm -f MEMSET_TEMP_INI

ls memset.ini > /dev/null 2>&1
if [ $? != 0 ] ; then
    echo "$CONFIGFILE : ERROR, Not find memset.ini" | tee -a "$CONFIGINFO"
    exit 1
fi

cat memset.ini > MEMSET_TEMP_INI
echo >> MEMSET_TEMP_INI

run_uniMem

echo "Read Equipment Mode Flag"
result=`./uniCfg -r EquipMentModeFlag | grep -P -o "EquipMentModeFlag = \d*" | awk '{print $NF}'`
if [ "$result" == 1 ] ; then
    echo "EquipMentModeFlags 1, Set ok" | tee -a "$CONFIGINFO"
fi

echo "$CONFIGFILE : SUCCESS" | tee -a "$CONFIGINFO"

rm -f MEMSET_TEMP_INI
exit 0
#}
