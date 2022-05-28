# What does this do?
These scripts will set up a container as a build environment that once run downloads all the newest sources for ReVanced and builds them into a working youtube.apk\/youtube-musik.apk.


# Requirements
- A working Podman installation.
  - You can test it with `podman run -it --rm ubuntu:22.04 /bin/bash`, it should give you a useable shell.
- A Github user and token for Gradle, see ReVanced 1. instructions [on their Github](https://github.com/revanced/revanced-documentation/wiki/Building-the-ReVanced-patcher).
- A rooted Android device.
- An Android sdk for Linux from https://developer.android.com/studio/
  - Has to be run once to accept license agreements and download basic tools.
  - Assumed to be at ~/android with the sdk being at ~/android/Sdk.

# Usage 
There are two ways to use this container.
- Run it without a phone connected.
  - This will create a revanced.apk in the `shared` directory, you will have to setup mount and mount scripts yourself.

- Run it with a phone connected.
  - This will create a revanced.apk like the phoneless run but will also try to install it directly to a connected Android device. 


First you need to run `build.sh` once to create the build image, it contains git, java, adb and not much else.    
Then you will have to put the `youtube.apk` and `gradle.properties` in the `shared` directory and run `run.sh`, it will download all Repositories and build them. To update in the future you will only have to rerun this command unless the java version changes.

# Troubleshooting
If you are having problems then you can delete the `cache` directory, it contains the gradle cache and will make gradle redownload and compile everything.
To manually run the patcher set `--env EXIT_TO_BASH=1` in `run.sh`
To override applied patches see the "-l" option of the cli for possible patches and set the PATCHES variable to your list `--env PATCHES="patch1 patch2[...]"` in `run.sh`

# Contributors 
Thanks to [CnC-Robert](https://github.com/CnC-Robert) for allowing me to use his [ReVanced script](https://github.com/CnC-Robert/revanced-cli-script) as a base to create build.sh.
