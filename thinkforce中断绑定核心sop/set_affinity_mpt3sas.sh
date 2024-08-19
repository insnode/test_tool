#!/bin/bash

function set_affinity() {
    temp_intf=`ls /proc/irq/**/mpt3sas*`
    for intf in $temp_intf ;
    do
        dir=`dirname $intf`
        base=`basename $intf`
        msi=${base#*msix}
        msi=${msi%:*}
        let id=$msi
        if [ $id -ge 40 ]; then
            let id=id-40;
        fi
        ((shift=id%32))
        ((value=1<<$shift))
        if [ $id -lt 32 ]; then
            affinity=`printf "0000,00000000,%08x" $value`
        else
            affinity=`printf "0000,%08x,00000000" $value`
        fi

        affinity=${affinity//,/}
        affinity=${affinity:10:10}${affinity:0:10}
        affinity=${affinity:0:4},${affinity:4:8},${affinity:12}

        if [ "$msi" == "0" ]; then
            affinity=ffff,ffffff00,00000000
        fi

        oldaffi=`cat $dir/smp_affinity`
        echo $affinity > $dir/smp_affinity
        if [ $? -eq 0 ]; then
            newaffi=`cat $dir/smp_affinity`
            echo "$msi: $oldaffi -> $newaffi"
            echo "$dir"
        else
            echo "$msi: $oldaffi [unchanged]"
        fi
    done
}

set_affinity
