#!/bin/bash

max=98;
free=$(df -m | grep /dev/sda1 | awk '{print $5}' | sed '{s/.$//;}')
if [ "$free" -gt "$max" ];
then
echo "WARNING!!! On the Server running out of space on your hard drive. Freespace = " $free "%";
ema clearlogs ;
fi