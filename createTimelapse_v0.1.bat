REM Avoid to show too much verbose
@echo off

REM Explanation for the user
echo This script is developed with the purpose of concatenating and transforming action camera clips into timelapse.
echo INSTRUCTIONS:
echo 1. ALWAYS HAVE A BACKUP COPY OF THE FILES TO BE PROCESSED.
echo 2. USE THIS BAT IN AN ISOLATED FOLDER AND EXCLUSIVELY FOR THIS WORK.
echo 3. THE CONCATENATION ORDER OF THE FILES WILL BE THE SAME AS THE ALPHABETICAL ORDER OF THE FILES. IF NECESSARY, RENAME THEM BEFORE EXECUTION.
echo 4. THE RESULTING FILE WILL HAVE THE NAME OF THE .bat FOLDER.
echo 5. USE AT YOUR OWN RISK.

set /p confirmation=Are you sure you want to run this script? (yes/no)
if /i "%confirmation%" neq "yes" (
	echo The script has finished, press any key to exit...
	pause > nul
	exit /b
)

REM This allows that variables can change their value in a for loop
setlocal enabledelayedexpansion

REM Show the videos duration and calculates the total
set totalDuration=0

echo Video duration        Filename
echo -------------------------------------------

for %%F in (*.mov *.mp4) do (
    for /f "tokens=*" %%a in ('ffmpeg -i "%%F" 2^>^&1 ^| find "Duration"') do (
        for /f "tokens=1,2 delims=, " %%b in ("%%a") do (
            echo %%c          %%F
            for /f "tokens=1-4 delims=:., " %%d in ("%%c") do (
                set /a "hours=1%%d-100, minutes=1%%e-100, seconds=1%%f-100, centiseconds=1%%g-100"
                set /a "durationInSeconds=((hours * 3600) + (minutes * 60) + seconds) * 100 + centiseconds"
                set /a "totalDuration+=durationInSeconds"
            )
        )
    )
)

for /F %%A in ('powershell "[math]::Round(%totalDuration% / 100 / 60, 2)"') do set "totalDurationInMinutes=%%A"
REM Change the "," for a "." compatible with the ffmpeg command
set "totalDurationInMinutes=!totalDurationInMinutes:,=.! "

echo -------------------------------------------
echo Total Duration: %totalDurationInMinutes% minutes



REM Ask for the new duration and calculates the speed for the process
:setDuration
set /p newDuration=How long do you want the new video to be? (minutes, use dot "." to decimal)
for /F %%A in ('powershell "[math]::Round(%totalDurationInMinutes% / %newDuration%, 2)"') do set "speed=%%A"
REM Change the "," for a "." compatible with the ffmpeg command
set "speed=!speed:,=.! "

echo To make the new video last %newDuration% minutes, we will speed up the video to x%speed% speed.

set /p confirmation=Do you agree? (yes, no)
if /i "%confirmation%" neq "yes" (
	if /i "%confirmation%"=="no" (
		goto :setDuration
	) else (
		echo The script has finished, press any key to exit...
		pause > nul
		exit /b
	)
)

REM Create the folder timelapse for the new videos
if not exist "timelapse" (
    mkdir "timelapse"
    echo Folder created: timelapse
) else (
    echo The folder "timelapse" already exists.
)

REM Create timelapse videos inside timelapse folder
for %%F in (*.mov *.mp4) do (
	ffmpeg -i "%%F" -vf "setpts=PTS/%speed%" -r 60 -an ".\timelapse\timelapse_%%F"
)

REM Get folder name to name the timelapse result
set "directoryRute=%CD%"
for %%I in ("%directoryRute%") do set "folderName=%%~nxI"

REM Concatenate timelapse videos into a sigle video
set "fileList=.\timelapse\fileList.txt"
if exist "%fileList%" del "%fileList%"

for %%F in (.\timelapse\timelapse_*.mov .\timelapse\timelapse_*.mp4) do (
    echo file '%%~nxF' >> "%fileList%"
)

echo Text file generated: %fileList%

ffmpeg -safe 0 -f concat -i %fileList% -c copy "%folderName%_timelapse.MOV"

echo The script has finished, %folderName%_timelapse.MOV was created, press any key to exit...
pause > nul
exit /b