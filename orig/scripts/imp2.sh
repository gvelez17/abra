#!/bin/sh

for x in `ls /home/sites/iwtucson/oldbiz/*.html`
do
./imp2.pl $x
done

