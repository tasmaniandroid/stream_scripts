#!/bin/bash

# CopyrightWalter Zarnoch
KEYFILE_DIRECTORY=$HOME"/.streamkeys/"

#Below settings are defaults, feel free to change them
DEFAULT_SERVICE="twitch"
DEFAULT_RES="1280x1024"
DEFAULT_FPS="10"
DEFAULT_DELAY="0"
DEFAULT_PRESET="slow"
DEFAULT_SCALE="2.5"
DEFAULT_VIDOFFSET="disabled"

#uncomment below line to enable sync, may be needed
#SYNC_OPTIONS="-vsync 2 -async 1"

#Function to check key file locations, and set $STREAM_KEY based on service or -k overide
KEY_FILE_CHECK() {

#check for keyfile override
if [ ! -z "$OVERRIDE_KEY" ]
then
KEYFILE=$KEYFILE_DIRECTORY$OVERRIDE_KEY
else
KEYFILE=$KEYFILE_DIRECTORY$SERVICE".key"
fi

#check if keyfile exists, prompt for creation and exit if it doesn't
if  [ ! -f $KEYFILE ]
then
	echo "$KEYFILE" 'not found.
Please create file '$KEYFILE'
Your stream key should be the only contents of the file.'
	exit 1
else
	KEY_LOCATION="$KEYFILE"
	STREAM_KEY=`cat "$KEY_LOCATION"`

fi
}

#Function to display help file
SHOW_HELP() {
	echo 'Flag options are as follows.
-b "ustream|twitch" Use ustream or twitch. Defaults to '$DEFAULT_SERVICE'
-r "resolution" capture resolution, eg 800x600. defaults to '$DEFAULT_RES'
-d "seconds" delay for x seconds before getting screen res, defaults to '$DEFAULT_DELAY' seconds
-f "framerate" framerate in fps for the stream, defaults to '$DEFAULT_FPS' FPS
-p "preset" encoding preset to use, defaults to '$DEFAULT_PRESET'
-s "scale" scales video output down. 2 would be 1/2 the size, etc. Defaults to 1/'$DEFAULT_SCALE'
-o "vidoffset" video offset in HH:MM:SS.SS format, can be negative. ex "-00.00.02.00" to delay video by 2 seconds
               relative to audio. commonly used to fix A/V sync issues. Defaults to '$DEFAULT_VIDOFFSET'
-k "keyfile" use the named keyfile instead of the service default. usefull if you have multiple accounts ' 
exit
}

#load defaults, do not edit these unless you have a good reason
SERVICE="$DEFAULT_SERVICE"
RES="$DEFAULT_RES"
FPS="$DEFAULT_FPS"
DELAY="$DEFAULT_DELAY"
PRESET="$DEFAULT_PRESET"
SCALE="$DEFAULT_SCALE"
VIDOFFSET="$DEFAULT_VIDOFFSET"
#clear optind

OPTIND=1
#grab options
while getopts "h?b:r:d:f:p:s:o:k:" opt; do
     case "$opt" in
         h|\?)
             SHOW_HELP
             ;;
         b)  SERVICE="$OPTARG"
             ;;
         r)  RES="$OPTARG"
             ;;
         d)  DELAY="$OPTARG"
             ;;
         f)  FPS="$OPTARG"
             ;;
         p)  PRESET="$OPTARG"
             ;;
         s)  scale="$OPTARG"
             ;;
         o)  VIDOFFSET="$OPTARG"
             ;;
         k)  OVERRIDE_KEY="$OPTARG"
             ;;
     esac
done


if [ "$SERVICE" = "ustream" ]
then
	KEY_FILE_CHECK
	STREAM_URL="rtmp://1.272659.fme.ustream.tv/ustreamVideo/272659/$STREAM_KEY flashver=FMLE/3.0\20(compatible;\20FMSc/1.0)"

elif [ "$SERVICE" = "twitch" ]
then

	KEY_FILE_CHECK
	STREAM_URL="rtmp://live-3c.justin.tv/app/$STREAM_KEY"

else
	echo "Sorry, $SERVICE is an invalid service, please specify ustream, twitch, or justin."
	exit 1
fi




#check if DELAY > 0, and sleap for DELAY seconds
if [ "$DELAY" -gt "0" ]
then
	sleep "$DELAY"
fi

#check if res is set to automatic, and if so, grab screen res
if [ "$RES" = "auto" ]
then
	RES=$(xwininfo -root | grep 'geometry'| awk '{print $2;}')

fi

#Check if we have a vid offset to deal with, and if so, deal with it.
if [ ! "$VIDOFFSET" = "disabled" ]
then
	VIDOFFSET="-itsoffset $VIDOFFSET"
else
	VIDOFFSET=""

fi
#build command line for ffmpeg
ffmpeg  $VIDOFFSET \
-f alsa -ac 2 -i default  \
-f x11grab \
-s "$RES" \
-r "$FPS" -i :0.0 \
-vf "scale=iw/""$SCALE"":-1" \
$SYNC_OPTIONS \
-vcodec libx264 -preset "$PRESET" -pix_fmt yuyv422 \
-acodec libmp3lame -ar 11025 \
-threads 0 \
-f flv "$STREAM_URL"
exit
