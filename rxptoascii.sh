#!/bin/bash
#
# This script iterates through all ScanPos folders of a 
# RIEGL-Laserscan project and converts one scan per
# pose(the last recorded) to ascii-format using slam6d 
# with the riegllib.
# Each scan is saved to the defined folder with the following
# format: scan[PosNr].txt ($PosNr is the three digit number
# of the ScanPos)
#
# Example:
# ./rxptoascii.sh
# /path/to/rieglproj/
# /path/to/slam6d
# /path/to/rxpdir
# /path/to/asciidir
# 
# Example for scanpos001:
# /path/to/riegl/proj/SCANS/ScanPos001/SINGLESCANS/160624_120918.rxp
#
# produces:
# /path/to/rxpdir/scan001.rxp
# and
# /path/to/asciidir/scan001.3d

echo "Please enter project directory(FULL PATH)!"
read project_path
echo "Please enter slam6d root directory path(the slam6d-code folder FULL PATH)!"
read slam6d
echo "Please enter destination folder for renamed rxp-scans(FULL PATH)! If it is not existing it will be created."
read rxp_dir
echo "Please enter destination folder for converted scans(FULL PATH)! If it is not existing it will be created."
read scans_txt_path

if ! [ -a "$scans_txt_path" ]; then
    mkdir -p $scans_txt_path
fi

if ! [ -d "$scans_txt_path" ]; then
    echo "$scans_txt_path is existing but no directory. Please enter correct destination folder"
    exit
fi

if ! [ -a "$rxp_dir" ]; then
    mkdir -p $rxp_dir
fi

if ! [ -d "$rxp_dir" ]; then
    echo "$rxp_dir is existing but no directory. Please enter correct destination folder"
    exit
fi

if ! [ -a "$project_path" ]; then
    echo "$project_path is not existing. Please enter correct project path."
    exit
fi

if ! [ -d "$project_path" ]; then
    echo "$project_path is existing but no directory. Please enter correct project path."
    exit
fi

if ! [ -a "$slam6d" ]; then
    echo "$slam6d is not existing. Please enter correct slam6d path."
    exit
fi

if ! [ -d "$slam6d" ]; then
    echo "$slam6d is existing but no directory. Please enter correct slam6d path."
    exit
fi



# Determine how many scanposes are in this project.
# Folders must have the name scheme ScanPosXXX
scanposcount=0
for folder in $project_path/SCANS/ScanPos*;
do
    if [ -d "$folder" ]; then
        scanposcount=$(($scanposcount+1))
    fi
done

echo $scanposcount

#iterate over all scanposes
for i in `seq 1 $scanposcount`;
do
    # adding "0" or "00" prefix, because it has to be three digits numer(folder/file structure)
    if [ "$i" -lt "10" ]; then
        c="00$i"
    else
        if [ "$i" -lt "100" ]; then
            c="0$i"
        else
            c="$i"
        fi
    fi

    # the path where the actual scans of this iteration are located. Change to this path

    path="$project_path/SCANS/ScanPos$c/SINGLESCANS/"
    if [ -a "$path" ]; then
    
        cd $path 

        # get all .rxp-files(these are the scans of this position)
        # exclude monitor files.
        count=-1
        for j in !(*["m"]["o"]["n"]).rxp; do
            count=$(($count+1))
            echo $j
            names[$count]=$j
        done  

        latestscan=${names[0]}
        if [ -a "$latestscan" ]; then

            # if there is more than one scan, use the last one
            # luckily all the filenames of the scans have the same structure
            # simply compare their timestamps in the filename
            # (actually the whole filename is a timestamp (YYMMDD_hhmmss.rxp),
            # but the date is ignored)
            if [ "$count" -gt "0" ]; then
                timestamp=${latestscan:7:6}
                for k in `seq 1 $count`; do
                    tmp=${names[$k]}
                    echo $tmp
                    tmp=${tmp:7:6}
                    echo $tmp
                    if [ "$tmp" -gt "$timestamp" ]; then
                        latestscan=${names[$k]}
                        timestamp=$tmp
                    fi
                done
            fi

            echo "Copying $latestscan to scan$c.rxp"

            cp $latestscan scan$c.rxp

            echo "Creating dummypose: scan$c.pose"
            touch scan$c.pose
            echo -e "0 0 0\n0 0 0" > scan$c.pose
            

            echo "Converting scan$c.rxp"
            $slam6d/bin/slam6D -f rxp -s$i -e$i --exportAllPoints $path

            echo "Moving converted scans to destination directory ($path/points.pts to $scans_txt_path/scan$c.3d)"

            mv points.pts $scans_txt_path/scan$c.3d


            mv scan$c.rxp $rxp_dir
            mv scan$c.pose $rxp_dir
            mv scan$c.frames $rxp_dir

        else
            echo "There were no rxp-scans in $project_path/ScanPos$c"
        fi 
        else
            echo "$project_path/ScanPos$c/SINGLESCANS does not exist"
    fi
done
