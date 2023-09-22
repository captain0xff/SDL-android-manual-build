# SDL-android-manual-build
Builds a SDL app for android without using gradle.

## Supported Platforms
The scripts has been tested on windows and linux, though it should also work on MacOS.  
If you are on linux use the `build.sh` or use the `win-build.sh` if you are a windows user.  
For windows you need an environment like MSYS2 for running the shell script. We are trying to add a windows batch script.

## Usage
1. Install the android sdk and ndk for your platform.
2. Choose `build.sh` or `win-build.sh` depending on your platform.
3. Modify the paths in the script as per your project and setup.
4. Build and install the apk with `./build.sh --deploy`.
5. Run `./build.sh --help` to see all the supported options.

## Known Issues
