# SDL-android-manual-build
Builds a SDL app for android without using gradle.

## Supported Platforms
The scripts has been tested on windows and linux, though it should also work on MacOS.  
If you are on linux use the `build.sh` or use the `win-build.sh` if you are a windows user.  
For windows you need an environment like MSYS2 for running the shell script. We are trying to add a windows batch script.

## Usage
1. Install the android sdk and ndk for your platform.
2. Choose `build.sh` or `win-build.sh` depending on your platform.
3. Modify the paths in script as per your project and setup.
4. Build and install the apk with `./build.sh --deploy`.


## Known Issues
Currently changing the **package name** is not allowed as SDL hardcodes org.libsdl.app in its sources. If the package name is modified either through the scripts or directly in the AndroidManifest.xml the app will crash as it will not be able to find org.libsdl.app.SDLActivity
