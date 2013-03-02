#!/bin/bash

# Copyright 2013 Walter Zarnoch
# Licensed to stream, not to kill.
# You can modify this to your hearts content,
# I just ask that you keep the full repository intact
# to give credit where credit is due.

# Directory where your keyfiles will be located
# The $HOME is needed, since ~/ won't work all the time.
KEYFILE_DIRECTORY=$HOME"/.streamkeys/"

# Below settings are defaults, feel free to change them
DEFAULT_SERVICE="twitch"
DEFAULT_RES="1280x1024"
DEFAULT_FPS="10"
DEFAULT_DELAY="0"
DEFAULT_PRESET="slow"
DEFAULT_SCALE="2.5"
DEFAULT_VIDOFFSET="disabled"

# Uncomment the below line to enable sync, may be needed
#SYNC_OPTIONS="-vsync 2 -async 1"

# Function to check key file locations.
# Also sets $STREAM_KEY based on service name or -k overide
KEY_FILE_CHECK() {

# Check for keyfile override
if [ ! -z "$OVERRIDE_KEY" ]
then
KEYFILE=$KEYFILE_DIRECTORY$OVERRIDE_KEY
else
KEYFILE=$KEYFILE_DIRECTORY$SERVICE".key"
fi

# Check if the keyfile exists, prompt for creation and exit if it doesn't
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

# Function to display help file
SHOW_HELP() {
	echo 'Flag options are as follows.
-b "ustream|twitch|justin" Use ustream, twitch or justin. Defaults to '$DEFAULT_SERVICE'
-r "resolution" Capture resolution, eg 800x600. defaults to '$DEFAULT_RES'
-d "seconds" Delay for x seconds before getting screen res, defaults to '$DEFAULT_DELAY' seconds
-f "framerate" Framerate in fps for the stream, defaults to '$DEFAULT_FPS' FPS
-p "preset" Encoding preset to use, defaults to '$DEFAULT_PRESET'
-s "scale" Scales video output down. 2 would be 1/2 the size, etc. Defaults to 1/'$DEFAULT_SCALE'
-o "vidoffset" Video offset in HH:MM:SS.SS format, can be negative. ex "-00.00.02.00" to delay video by 2 seconds
               relative to audio. commonly used to fix A/V sync issues. Defaults to '$DEFAULT_VIDOFFSET'
-k "keyfile" Use the named keyfile instead of the service default. Usefull if you have multiple accounts with the same service.
-w Wait for user input before starting stream.'
exit
}

# Load defaults, do not edit these unless you have a good reason
SERVICE="$DEFAULT_SERVICE"
RES="$DEFAULT_RES"
FPS="$DEFAULT_FPS"
DELAY="$DEFAULT_DELAY"
PRESET="$DEFAULT_PRESET"
SCALE="$DEFAULT_SCALE"
VIDOFFSET="$DEFAULT_VIDOFFSET"

# Clear optind
OPTIND=1

# Grab options
while getopts "h?b:r:d:f:p:s:o:k:w" opt; do
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
         w)  WAIT="yes"
             ;;
     esac
done


# Check for keyfile and set $STREAM_URL based on service.
# If you have a service you'd wish to add, such as  another RTMP
# video service, add another elif before the final else statement
# There is a commented out example for foostreams.
# The default keyfile will be the same name as the service name.
if [ "$SERVICE" = "ustream" ]
then
	KEY_FILE_CHECK
	STREAM_URL="rtmp://1.272659.fme.ustream.tv/ustreamVideo/272659/$STREAM_KEY flashver=FMLE/3.0\20(compatible;\20FMSc/1.0)"

elif [ "$SERVICE" = "twitch" -o "$SERVICE" = "justin" ]
then

	KEY_FILE_CHECK
	STREAM_URL="rtmp://live-3c.justin.tv/app/$STREAM_KEY"

#elif [ "$SERVICE" = "foostreams" ]
#then
#
#	KEY_FILE_CHECK
#	STREAM_URL="rtmp://foo.example.com/fooapp/$STREAM_KEY"
#
else
	echo "Sorry, $SERVICE is an invalid service, please specify ustream, twitch, or justin."
	exit 1
fi




# Check if $DELAY > 0, and sleap for DELAY seconds.
# If $DELAY is 0, skip sleep entirely.
if [ "$DELAY" -gt "0" ]
then
	sleep "$DELAY"
fi

# Check if screen res is set to automatic, and if so, grab screen res
# for the root window. May need to be tweaked for multi-monitor
if [ "$RES" = "auto" ]
then
	RES=$(xwininfo -root | grep 'geometry'| awk '{print $2;}')

fi

# Check if we have a vid offset to pass, and if so, pass it on.
# Otherwise, do not pass option.
if [ ! "$VIDOFFSET" = "disabled" ]
then
	VIDOFFSET="-itsoffset $VIDOFFSET"
else
	VIDOFFSET=""

fi

# If wait is specified, wait for user to pres key before starting stream.
if [ "$WAIT" = "yes" ]
then
	read -p "Press [Enter] key to start streaming " DUMMYVAR
fi

# Build command line for ffmpeg, and start streaming.
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
