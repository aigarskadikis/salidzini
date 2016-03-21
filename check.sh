#!/bin/sh

#this code is tested un fresh 2015-11-21-raspbian-jessie-lite Raspberry Pi image
#by default this script should be located in two subdirecotries under the home

#sudo apt-get update -y && sudo apt-get upgrade -y
#sudo apt-get install git -y
#mkdir -p /home/pi/detect && cd /home/pi/detect
#git clone https://github.com/catonrug/salidzini.git && cd salidzini && chmod +x check.sh && ./check.sh

#check if script is located in /home direcotry
pwd | grep "^/home/" > /dev/null
if [ $? -ne 0 ]; then
  echo script must be located in /home direcotry
  return
fi

#it is highly recommended to place this directory in another directory
deep=$(pwd | sed "s/\//\n/g" | grep -v "^$" | wc -l)
if [ $deep -lt 4 ]; then
  echo please place this script in deeper directory
  return
fi

#set application name based on directory name
#this will be used for future temp directory, database name, google upload config, archiving
appname=$(pwd | sed "s/^.*\///g")

#set temp directory in variable based on application name
tmp=$(echo ../tmp/$appname)

#create temp directory
if [ ! -d "$tmp" ]; then
  mkdir -p "$tmp"
fi

#set data directory in variable based on application name
data=$(echo ../data/$appname)

#create data directory
if [ ! -d "$data" ]; then
  mkdir -p "$data"
fi

#check if database directory has prepared 
if [ ! -d "../db" ]; then
  mkdir -p "../db"
fi

#set database variable
db=$(echo ../db/$appname.db)

#if database file do not exist then create one
if [ ! -f "$db" ]; then
  touch "$db"
fi

#check if google drive config directory has been made
#if the config file exists then use it to upload file in google drive
#if no config file is in the directory there no upload will happen
if [ ! -d "../gd" ]; then
  mkdir -p "../gd"
fi

itemlist=$(cat <<EOF
samsung evo 850 250gb -msata
samsung evo 850 500gb -msata
raspberry pi 2 1gb
raspberry pi 3 1gb
htc nexus 9 32gb
htc nexus 9 16gb
samsung microsd evo 8gb
samsung microsd evo 16gb
samsung microsd evo 32gb
samsung microsd evo 64gb
samsung microsd evo plus 64gb
samsung microsd evo 128gb
samsung microsd evo plus 128gb
zbox nano ci323
zbox nano ci321
2x8gb 1600Mhz sodimm ddr3l
indesit dif16b1aeu
playstation 4 console 500gb
philips 40pft4200
samsung ue-40j5100
asrock beebox n3000
asus z580ca
acme ch12
extra line
EOF
)

printf %s "$itemlist" | while IFS= read -r item
do {

fullpricename=$(wget -qO- "https://www.salidzini.lv/search.php?q=`echo "$item" | sed "s/ /\+/g"`" | \
sed "s/<div/\n<div/g;s/<\/div/\n<\/div/g" | \
grep "^<" | \
grep -A1 -m1 "item_price" | \
grep -v "item_price" | \
sed "s/&nbsp;/ /g;s/[<>]/\n/g" | \
grep -i "eur")

price=$(echo "$fullpricename" | sed "s/ .*$//g")
filename=$(echo "$item" | sed "s/ /\./g")
DATE=$(date "+%Y/%m/%d %H:%M")

echo "$fullpricename" | grep -i "eur"
if [ $? -eq 0 ]; then

#if the price has been already in log
if [ -f $data/$filename.txt ]; then

	#calculate if the prise is lower
	tail -1 $data/$filename.txt | grep "$price"
	if [ $? -eq 0 ]; then
		echo $item price has not been changed
		echo
	else
		echo now $item price is $price
		echo setting item into database..
		echo $DATE $fullpricename>> $data/$filename.txt
		emails=$(cat ../maintenance | sed '$aend of file')
		printf %s "$emails" | while IFS= read -r onemail
		do {
		python ../send-email.py "$onemail" "$item" "https://www.salidzini.lv/search.php?q=`echo "$item" | sed "s/ /\+/g"`

`cat $data/$filename.txt`"
		} done
		echo
	fi

else
	echo now $item price is $price
	echo setting item into database..
	echo $DATE $fullpricename> $data/$filename.txt
	echo

fi

else

#if item never has audited and do not exist today, then need to create database
if [ ! -f "$data/$filename.txt" ]; then
  touch "$data/$filename.txt"
fi

echo $item are no longer on market
tail -1 $data/$filename.txt | grep "no longer on market"
if [ $? -ne 0 ]; then
echo $DATE no longer on market>> $data/$filename.txt
emails=$(cat ../maintenance | sed '$aend of file')
printf %s "$emails" | while IFS= read -r onemail
do {
python ../send-email.py "$onemail" "$item" "https://www.salidzini.lv/search.php?q=`echo "$item" | sed "s/ /\+/g"`

`cat $data/$filename.txt`"
} done
else
echo the email will be sended if the item goes up again
fi
echo

fi

} done

#clean and remove whole temp direcotry
rm $tmp -rf > /dev/null
