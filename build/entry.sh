#!/bin/bash

CWD="$(pwd)"
buildingrepos="Apktool revanced-patcher revanced-patches revanced-cli revanced-integrations"

# Colors
NORMAL=$(tput sgr0)
ERROR_COLOR=$(tput setaf 1)
UNDERLINE=$(tput smul)

# Function that handles compiling the repositories
function BuildIt {
        echo "${UNDERLINE}Building $buildingrepo${NORMAL}"
        cd $CWD/$buildingrepo
        if [[ "$buildingrepo" = "revanced-patches" || "$buildingrepo" = "revanced-patcher" ]]; then
                 ./gradlew publish
        else
                ./gradlew build
        fi
        RETURN_CODE="$?"
        cd $CWD
}

# Error reporting
function NotFound {
	echo "${ERROR_COLOR}$notfoundfile not found, did you mount the correct volume?${NORMAL}"
	exit 2
}

# Checking for needed files

if [[ ! -f /volume/youtube.apk ]]; then
	notfoundfile="youtube.apk"
	NotFound
fi

if [[ ! -d /android/Sdk ]]; then
	notfoundfile="android sdk"
	NotFound
fi

if [[ ! -f /volume/gradle.properties ]]; then
	notfoundfile="gradle.properties"
	NotFound
fi

if [ ! -f ~/.gradle/gradle.properties ]; then
	cat /volume/gradle.properties > ~/.gradle/gradle.properties
	echo 'org.gradle.java.home=/usr/lib/jvm/java-17-openjdk-amd64/' >> ~/.gradle/gradle.properties
fi




# Adb setup

if [ "$(adb devices 2>/dev/null | head -n-1 | tail -n+2)" = "" ]; then
        adb=0
else
	echo "${UNDERLINE}Found adb device${NORMAL}"
        adb=1
fi



# Github setup
git clone --depth 1 --single-branch https://github.com/revanced/revanced-patcher
git clone --depth 1 --single-branch https://github.com/revanced/revanced-patches
git clone --depth 1 --single-branch https://github.com/revanced/revanced-cli
git clone --depth 1 https://github.com/revanced/revanced-integrations
git clone --depth 1 https://github.com/revanced/Apktool
        # I don`t know why but whithout deleting these files Apktool doesn't build, upstream revanced actions https://github.com/revanced/Apktool/actions/runs/2378916602/workflow does it too
         rm -r Apktool/brut.j.common Apktool/brut.j.dir Apktool/brut.j.util Apktool/brut.apktool

chmod ug+x revanced-*/gradlew


# Compiling
for buildingrepo in $buildingrepos; do
        BuildIt
        if [ "$RETURN_CODE" -ne "0" ]; then
                echo "${ERROR_COLOR}buildingrepo build failed with exit code $RETURN_CODE${NORMAL}"
                abort=1
        fi
done

if [[ abort -eq 1 ]]; then
	echo "${ERROR_COLOR}Compiling failed, dropping to shell...${NORMAL}"
	exec bash
fi


# Preparing for patching

mkdir -p build/cache /volume

ls

find    revanced-cli/build/libs -name 'revanced-cli-*-all.jar' -exec cp {} build/revanced-cli-all.jar \;
cp      revanced-integrations/app/build/outputs/apk/release/app-release-unsigned.apk build/revanced-integrations.apk
cp      revanced-patches/build/libs/$(ls revanced-patches/build/libs/ | grep -Pv 'sources|javadoc') build/revanced-patches.jar
cp      revanced-patcher/build/libs/$(ls revanced-patcher/build/libs/ | grep -Pv 'sources|javadoc') build/revanced-patcher.jar

cd /root/build

cp /volume/youtube.apk .

# Patching
if [ ! -n "${EXIT_TO_BASH}" ]; then
	if [ $adb -eq 1 ]; then
        	echo "${UNDERLINE}Make sure the app + version you are patching is installed${NORMAL}"
	        sleep 1
        	java -jar revanced-cli-all.jar -a youtube.apk -d $(adb devices 2>/dev/null | grep -oP '^[^ ]*(?= *device)') -m revanced-integrations.apk -o revanced.apk -p revanced-patches.jar -t cache
	else
        	java -jar revanced-cli-all.jar -a youtube.apk -m revanced-integrations.apk -o revanced.apk -p revanced-patches.jar -t cache
	fi

	mkdir -p /volume/jars
	cp -f revanced-cli-all.jar revanced-integrations.apk revanced-patches.jar /volume/jars/

	# revanced-cli doesn't give the correct exit code, see if revanced is created instead and check for success that way
	cp -f revanced.apk /volume/revanced.apk
	if [ "$RETURN_CODE" -eq "0" ]; then
		exit 0
	else
		exit 1
	fi
else
	exec bash
fi
