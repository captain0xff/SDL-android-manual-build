# App details
APP_LABEL=Game
APK_NAME=apk-debug.apk
DOMAIN_NAME=com
COMPANY_NAME=captain
PRODUCT_NAME=game
TARGET_SDK=33
MIN_SDK=21
TARGET_ARCH=arm64-v8a
ACTIVITY_NAME=GameActivity


# Project details
PROJECT_ROOT=`pwd`
NATIVE_SRC_PATH=$PROJECT_ROOT/src
ANDROID_PROJECT_PATH=$PROJECT_ROOT/android-project
RES_PATH=$ANDROID_PROJECT_PATH/res
# The folder must be names assets
ASSETS_PATH=$ANDROID_PROJECT_PATH/assets # Comment this line to stop the assets from being added
JAVA_SRC_PATH=$ANDROID_PROJECT_PATH/java_glue
ANDROID_MANIFEST_PATH=$ANDROID_PROJECT_PATH/AndroidManifest.xml


# Dev-tools details
SDK_PATH=$ANDROID_HOME
BUILD_TOOLS_VERSION=35.0.0-rc4
BUILD_TOOLS=$SDK_PATH/build-tools/$BUILD_TOOLS_VERSION
PLATFORMS=$SDK_PATH/platforms
NDK_VERSION=27.0.11902837
NDK_HOME=$SDK_PATH/ndk/$NDK_VERSION
CMAKE_VERSION=3.22.1
CMAKE_HOME=$SDK_PATH/cmake/$CMAKE_VERSION
PLATFORM_TOOLS=$SDK_PATH/platform-tools


# Build details
BUILD_FOLDER_PATH=$PROJECT_ROOT/build
BUILD_OUTPUT_PATH=$BUILD_FOLDER_PATH/output
BUILD_INTERMEDIATES_PATH=$BUILD_FOLDER_PATH/intermediates
JAVA_INTERMEDIATES_PATH=$BUILD_INTERMEDIATES_PATH/obj
DEX_PATH=$BUILD_INTERMEDIATES_PATH
NATIVE_LIBS_PATH=$BUILD_INTERMEDIATES_PATH/lib/$TARGET_ARCH
NATIVE_BUILD_PATH=$BUILD_INTERMEDIATES_PATH/native
JAVA_BUILD_PATH=$BUILD_INTERMEDIATES_PATH/java-build


# Exit on error
set -e


# Add the app details to the project and prepare it for building
prepare_project() {
	echo "INFO: Preparing the project..."

	# Update the package name
	PACKAGE_NAME_OLD=`grep -w "package" $ANDROID_MANIFEST_PATH | head -1`
	PACKAGE_NAME_NEW="	package=\"$DOMAIN_NAME.$COMPANY_NAME.$PRODUCT_NAME\""
	if [ "$PACKAGE_NAME_OLD" != "$PACKAGE_NAME_NEW" ]; then
		sed -i "s#$PACKAGE_NAME_OLD#$PACKAGE_NAME_NEW#g" $ANDROID_MANIFEST_PATH
	else
		echo "INFO: Package name not updated."
	fi

	# Update the minSdkVersion
	MIN_SDK_OLD=`grep -w "android:minSdkVersion" $ANDROID_MANIFEST_PATH | head -1`
	MIN_SDK_NEW="    <uses-sdk android:minSdkVersion=\"$MIN_SDK\""
	if [ "$MIN_SDK_OLD" != "$MIN_SDK_NEW" ]; then
		sed -i "s#$MIN_SDK_OLD#$MIN_SDK_NEW#g" $ANDROID_MANIFEST_PATH
	else
		echo "INFO: minSdkVersion not updated."
	fi

	# Update the targetSdkVersion
	TARGET_SDK_OLD=`grep -w "android:targetSdkVersion" $ANDROID_MANIFEST_PATH | head -1`
	TARGET_SDK_NEW="          android:targetSdkVersion=\"$TARGET_SDK\" />"
	if [ "$TARGET_SDK_OLD" != "$TARGET_SDK_NEW" ]; then
		sed -i "s#$TARGET_SDK_OLD#$TARGET_SDK_NEW#g" $ANDROID_MANIFEST_PATH
	else
		echo "INFO: targetSdkVersion not updated."
	fi

	# Update the app name
	APP_NAME_OLD=`grep -w "name" $RES_PATH/values/strings.xml | head -1`
	APP_NAME_NEW="    <string name=\"app_name\">$APP_LABEL</string>"
	if [ "$APP_NAME_OLD" != "$APP_NAME_NEW" ]; then
		sed -i "s#$APP_NAME_OLD#$APP_NAME_NEW#g" $RES_PATH/values/strings.xml
	else
		echo "INFO: App label not updated."
	fi

	# Update the activity name
	ACTIVITY_NAME_OLD=`grep -w "        <activity android:name" $ANDROID_MANIFEST_PATH | head -1`
	ACTIVITY_NAME_NEW="        <activity android:name=\"$ACTIVITY_NAME\""
	if [ "$ACTIVITY_NAME_OLD" != "$ACTIVITY_NAME_NEW" ]; then
		sed -i "s#$ACTIVITY_NAME_OLD#$ACTIVITY_NAME_NEW#g" $ANDROID_MANIFEST_PATH
	else
		echo "INFO: Activity name not updated in $ANDROID_MANIFEST_PATH"
	fi

	# Add the ACTIVITY_NAME.java if it doesn't exist else modify the existing one
	if [ -f "$JAVA_SRC_PATH/$ACTIVITY_NAME.java" ]; then
		PACKAGE_NAME_OLD=`grep -w "package" $JAVA_SRC_PATH/$ACTIVITY_NAME.java | head -1`
		PACKAGE_NAME_NEW="package $DOMAIN_NAME.$COMPANY_NAME.$PRODUCT_NAME;"
		if [ "$PACKAGE_NAME_OLD" != "$PACKAGE_NAME_NEW" ]; then
			sed -i "s#$PACKAGE_NAME_OLD#$PACKAGE_NAME_NEW#g" $JAVA_SRC_PATH/$ACTIVITY_NAME.java
		else
			echo "INFO: Package name not updated in $JAVA_SRC_PATH/$ACTIVITY_NAME.java."
		fi

		ACTIVITY_NAME_OLD=`grep -w "extends SDLActivity" $JAVA_SRC_PATH/$ACTIVITY_NAME.java | head -1`
		ACTIVITY_NAME_NEW="public class $ACTIVITY_NAME extends SDLActivity {}"
		if [ "$ACTIVITY_NAME_OLD" != "$ACTIVITY_NAME_NEW" ]; then
			sed -i "s#$ACTIVITY_NAME_OLD#$ACTIVITY_NAME_NEW#g" $JAVA_SRC_PATH/$ACTIVITY_NAME.java
		else
			echo "INFO: Activity name not updated in $JAVA_SRC_PATH/$ACTIVITY_NAME.java."
		fi
	else
		echo "INFO: File $JAVA_SRC_PATH/$ACTIVITY_NAME.java doesn't exist. Creating a new file..."
		echo "package $DOMAIN_NAME.$COMPANY_NAME.$PRODUCT_NAME;" >> $JAVA_SRC_PATH/$ACTIVITY_NAME.java
		echo >> $JAVA_SRC_PATH/$ACTIVITY_NAME.java
		echo "import org.libsdl.app.SDLActivity;" >> $JAVA_SRC_PATH/$ACTIVITY_NAME.java
		echo >> $JAVA_SRC_PATH/$ACTIVITY_NAME.java
		echo "public class $ACTIVITY_NAME extends SDLActivity {}" >> $JAVA_SRC_PATH/$ACTIVITY_NAME.java
		echo >> $JAVA_SRC_PATH/$ACTIVITY_NAME.java
	fi
}


# Build sdl and the project to generate the shared libraries
compile_native() {
	mkdir -p $NATIVE_LIBS_PATH
	mkdir -p $NATIVE_BUILD_PATH

	if [ ! -e $NATIVE_BUILD_PATH/build.ninja ]; then
		echo "INFO: Generating CMake the project..."

		$CMAKE_HOME/bin/cmake -H$PROJECT_ROOT \
			-DCMAKE_SYSTEM_NAME=Android \
			-DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
			-DCMAKE_SYSTEM_VERSION=$TARGET_SDK \
			-DANDROID_PLATFORM=android-$TARGET_SDK \
			-DANDROID_ABI=$TARGET_ARCH \
			-DCMAKE_ANDROID_ARCH_ABI=$TARGET_ARCH \
			-DANDROID_NDK=$NDK_HOME \
			-DCMAKE_ANDROID_NDK=$NDK_HOME \
			-DCMAKE_TOOLCHAIN_FILE=$NDK_HOME/build/cmake/android.toolchain.cmake \
			-DCMAKE_MAKE_PROGRAM=$CMAKE_HOME/bin/ninja \
			-DCMAKE_LIBRARY_OUTPUT_DIRECTORY=$NATIVE_LIBS_PATH \
			-DCMAKE_RUNTIME_OUTPUT_DIRECTORY=$NATIVE_LIBS_PATH \
			-DCMAKE_BUILD_TYPE=Debug \
			-DCMAKE_COLOR_DIAGNOSTICS=ON \
			-B $NATIVE_BUILD_PATH \
			-GNinja \
			-DANDROID_APP_PLATFORM=android-$TARGET_SDK \
			-DANDROID_STL=c++_static
	fi

	echo "INFO: Compiling the native code..."

	$CMAKE_HOME/bin/ninja -C $NATIVE_BUILD_PATH SDL3-shared main
}


# Compile the java code and generate classes.dex
compile_java() {
	if [ ! -e $JAVA_BUILD_PATH/build.ninja ]; then
		echo "INFO: Generating CMake the project for java"

		cmake -H$JAVA_SRC_PATH\
			-DJAVA_SRC_PATH=$JAVA_SRC_PATH \
			-DPLATFORMS=$PLATFORMS \
			-DTARGET_SDK=$TARGET_SDK \
			-DBUILD_TOOLS=$BUILD_TOOLS \
			-DBUILD_INTERMEDIATES_PATH=$BUILD_INTERMEDIATES_PATH \
			-B $JAVA_BUILD_PATH \
			-GNinja
			# -DJAVA_INTERMEDIATES_PATH=$JAVA_INTERMEDIATES_PATH \
			# -DJAVA_COMPILER=javac \
	fi

	$CMAKE_HOME/bin/ninja -C $JAVA_BUILD_PATH
}


# Create an unaligned apk and add all the assets to it
create_apk_aapt() {

	echo "INFO: Generating the apk..."

	$BUILD_TOOLS/aapt.exe package -f -v \
		-M $ANDROID_MANIFEST_PATH \
		-S $RES_PATH \
		${ASSETS_PATH:+-A "$ASSETS_PATH"} \
		-I $PLATFORMS/android-$TARGET_SDK/android.jar \
		-F $BUILD_INTERMEDIATES_PATH/$APK_NAME.unaligned

	cd $BUILD_INTERMEDIATES_PATH

	echo "INFO: Adding the classes.dex..."

	$BUILD_TOOLS/aapt.exe add $APK_NAME.unaligned classes.dex

	echo "INFO: Adding the native libs..."

	$BUILD_TOOLS/aapt.exe add $APK_NAME.unaligned lib/$TARGET_ARCH/*
}

create_apk_aapt2() {
	rm -rf $BUILD_INTERMEDIATES_PATH/compiled/*
	mkdir -p $BUILD_INTERMEDIATES_PATH/compiled/res

	echo "INFO: Compile the resources..."

	$BUILD_TOOLS/aapt2.exe compile $(cygpath -w $RES_PATH/*/*) \
		-o "$(cygpath -w $BUILD_INTERMEDIATES_PATH/compiled/res)"

	echo "INFO: Generating the apk and adding the compiled resources and assets..."

	$BUILD_TOOLS/aapt2.exe link -v \
		-I $PLATFORMS/android-$TARGET_SDK/android.jar \
		-R $(cygpath $BUILD_INTERMEDIATES_PATH/compiled/res/*) \
		--manifest $ANDROID_MANIFEST_PATH \
		-o $BUILD_INTERMEDIATES_PATH/$APK_NAME.unaligned

	cd $BUILD_INTERMEDIATES_PATH

	echo "INFO: Adding the classes.dex..."

	zip -uj $APK_NAME.unaligned classes.dex

	echo "INFO: Adding the native libs..."

	zip -u $APK_NAME.unaligned lib/$TARGET_ARCH/*

	if [[ -v PATH ]]; then
		cd $ASSETS_PATH/..

		echo "INFO: Adding the assets directory..."

		zip -ur $BUILD_INTERMEDIATES_PATH/$APK_NAME.unaligned assets
	fi

}


# Sign and align the apk
sign_apk() {
	mkdir -p $BUILD_OUTPUT_PATH

	# jarsigner -keystore /c/Users/$USERNAME/.android/debug.keystore \
	# 	-storepass 'android' \
	# 	$BUILD_INTERMEDIATES_PATH/$APK_NAME.unaligned \
	# 	androiddebugkey

	echo "INFO: Aligning the apk..."

	$BUILD_TOOLS/zipalign -f 4 $BUILD_INTERMEDIATES_PATH/$APK_NAME.unaligned $BUILD_OUTPUT_PATH/$APK_NAME

	echo "INFO: Signing the apk..."

	$BUILD_TOOLS/apksigner.bat sign --ks /c/Users/$USERNAME/.android/debug.keystore \
		--ks-pass 'pass:android' \
		--ks-key-alias androiddebugkey \
		$BUILD_OUTPUT_PATH/$APK_NAME
}


prepare() {
	prepare_project
}


build() {
	compile_native
	compile_java
	create_apk_aapt2
	sign_apk
}


install() {
	$PLATFORM_TOOLS/adb.exe install $BUILD_OUTPUT_PATH/$APK_NAME
}


logcat() {
	$PLATFORM_TOOLS/adb.exe logcat -c
	$PLATFORM_TOOLS/adb.exe logcat | grep SDL/APP
}


clean() {
	rm -rf $BUILD_FOLDER_PATH
}


usage() {
	echo "Usage"
	echo
	echo "win-build.sh [option]"
	echo
	echo "Options"
	echo "  --prepare       = Prepares the project for building"
	echo "  --build         = Builds the apk"
	echo "  --deploy        = Builds and installs the apk"
	echo "  --install       = Installs the apk from the build output folder"
	echo "  --logcat        = Shows the logs from the apk"
	echo "  --clean         = Deletes the build folder"
	echo "  --help          = Shows this help text"
}

if [ "$1" == "--prepare" ]; then
	prepare
elif [ "$1" == "--build" ]; then
	build
elif [ "$1" == "--deploy" ]; then
	build
	install
	logcat
elif [ "$1" == "--install" ]; then
	install
elif [ "$1" == "--logcat" ]; then
	logcat
elif [ "$1" == "--clean" ]; then
	clean
elif [ "$1" == "--help" ]; then
	usage
else
	echo "Invalid usage!"
	usage
fi
