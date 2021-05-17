# time-lapse
A poor mans time-lapse with open source tools

# What it does
I did not found any satisfying solution for creating proper timelapse videos from still images. The problem, the time between my shots was not constant. Since I put my cam on a tripod and take a picture whenever a come by. Assembling this as equally length video looked utterly wrong. 
This thing here, will extract the recording time from each picture and calculate the duration to next picture. Each video will have the acording number of frames relative to the time for the next picture. 
For this to work, the images need to have a timestamp. The script does not do any resizing. This is much easyer if done during image export. 

usage:
./timelapse.sh -o outputir -s sourcdir 