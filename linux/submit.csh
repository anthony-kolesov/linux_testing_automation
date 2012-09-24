#!/bin/csh
source /u/vijayb/.cshrc
module load grd
echo "Config : $config"
set workarea="${WORKSPACE}/${BUILD_NUMBER}/"
cd "$workarea/automated_scripts/linux"
echo "$workarea/automated_scripts/linux/"
echo "working under "
pwd
ls ./lib
echo "config file = $configfile"
echo "Test config = $testconfig"
if ( -e run.csh ) then
    rm -f run.csh
endif
touch run.csh

echo "qsub -cwd -V -P 'bnormal' -N 'linuxbuild' -o ${workarea}/output.log -e ${workarea}/error.log -l os_distribution=redhat,os_bit=64 ${workarea}/automated_scripts/linux/linux_build.pl -config $config -configfile $configfile -testconfig $testconfig"
echo "#\!/bin/csh" >>run.csh
echo "cwd=\`pwd\`" >>run.csh
echo "Working under directory $cwd">>run.csh
echo "qsub -cwd -V -P 'bnormal' -N 'linuxbuild' -o ${workarea}/output.log -e ${workarea}/error.log -l os_distribution=redhat,os_bit=64 ${workarea}/automated_scripts/linux/linux_build.pl -config $config -config_file $configfile -testconfig $testconfig" >>run.csh
chmod 755 run.csh
qsub -cwd -V -P 'bnormal' -N 'linuxbuild' -o ${workarea}/output.log -e ${workarea}/error.log -l os_distribution=redhat,os_bit=64 run.csh
while (1)
    if ( -e "${workarea}/alldone" ) then
        echo "Completed successfully"
	exit 0
        break
    else if ( -e "${workarea}/failed" ) then
	exit 1
    else
        sleep 100
    endif
end

