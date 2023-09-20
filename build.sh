# App details
APP_LABEL=Game
APK_NAME=apk-debug.apk
DOMAIN_NAME=org
COMPANY_NAME=libsdl
PRODUCT_NAME=app
TARGET_SDK=30
MIN_SDK=21
TARGET_ARCH=arm64-v8a


# Project details
PROJECT_ROOT=`pwd`
NATIVE_SRC_PATH=$PROJECT_ROOT/src
ANDROID_PROJECT_PATH=$PROJECT_ROOT/android-project
RES_PATH=$ANDROID_PROJECT_PATH/res
JAVA_SRC_PATH=$ANDROID_PROJECT_PATH/java_glue
ANDROID_MANIFEST_PATH=$ANDROID_PROJECT_PATH/AndroidManifest.xml


# Dev-tools details
SDK_PATH=$ANDROID_HOME
BUILD_TOOLS_VERSION=33.0.0
BUILD_TOOLS=$SDK_PATH/build-tools/$BUILD_TOOLS_VERSION
PLATFORMS=$SDK_PATH/platforms
NDK_VERSION=23.2.8568313
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
}


# Build sdl and the project to generate the shared libraries
compile_native() {
	mkdir -p $NATIVE_LIBS_PATH
	mkdir -p $NATIVE_BUILD_PATH

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
		-B $NATIVE_BUILD_PATH \
		-GNinja \
		-DANDROID_APP_PLATFORM=android-$TARGET_SDK \
		-DANDROID_STL=c++_static

	echo "INFO: Compiling the native code..."

	$CMAKE_HOME/bin/ninja -C $NATIVE_BUILD_PATH SDL3-shared main
}


# Compile the java code and generate classes.dex
compile_java() {
	rm -rf $JAVA_INTERMEDIATES_PATH/*

	echo "INFO: Compiling the java code..."

	javac -classpath $PLATFORMS/android-$TARGET_SDK/android.jar \
		-d $JAVA_INTERMEDIATES_PATH \
		-encoding UTF-8 \
		$JAVA_SRC_PATH/*.java

	echo "INFO: Generating the classes.dex..."

	$BUILD_TOOLS/d8 $JAVA_INTERMEDIATES_PATH/$DOMAIN_NAME/$COMPANY_NAME/$PRODUCT_NAME/* \
		--output $BUILD_INTERMEDIATES_PATH \
		--lib $PLATFORMS/android-$TARGET_SDK/android.jar \
		--classpath $JAVA_INTERMEDIATES_PATH
}


# Create an unaligned apk and add all the assets to it
create_apk_aapt() {

	echo "INFO: Generating the apk..."

	$BUILD_TOOLS/aapt package -f \
		-M $ANDROID_MANIFEST_PATH \
		-S $RES_PATH \
		-I $PLATFORMS/android-$TARGET_SDK/android.jar \
		-F $BUILD_INTERMEDIATES_PATH/$APK_NAME.unaligned

	cd $BUILD_INTERMEDIATES_PATH

	echo "INFO: Adding the classes.dex..."

	$BUILD_TOOLS/aapt add $APK_NAME.unaligned classes.dex

	echo "INFO: Adding the native libs..."

	$BUILD_TOOLS/aapt add $APK_NAME.unaligned lib/$TARGET_ARCH/*
}

create_apk_aapt2() {
	mkdir -p $BUILD_INTERMEDIATES_PATH/compiled/res

	echo "INFO: Compile the resources..."

	$BUILD_TOOLS/aapt2 compile $RES_PATH/*/* \
		-o $BUILD_INTERMEDIATES_PATH/compiled/res

	echo "INFO: Generating the apk and adding the compiled resources..."

	$BUILD_TOOLS/aapt2 link -v \
		-I $PLATFORMS/android-$TARGET_SDK/android.jar \
		-R $BUILD_INTERMEDIATES_PATH/compiled/res/* \
		--manifest $ANDROID_MANIFEST_PATH \
		-o $BUILD_INTERMEDIATES_PATH/$APK_NAME.unaligned

	cd $BUILD_INTERMEDIATES_PATH

	echo "INFO: Adding the classes.dex..."

	zip -uj $APK_NAME.unaligned classes.dex

	echo "INFO: Adding the native libs..."

	zip -u $APK_NAME.unaligned lib/$TARGET_ARCH/*
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

	$BUILD_TOOLS/apksigner sign --ks $HOME/.android/debug.keystore \
		--ks-pass 'pass:android' \
		--ks-key-alias androiddebugkey \
		$BUILD_OUTPUT_PATH/$APK_NAME
}


build() {
	prepare_project
	compile_native
	compile_java
	create_apk_aapt2
	sign_apk
}


install() {
	$PLATFORM_TOOLS/adb install $BUILD_OUTPUT_PATH/$APK_NAME
}


logcat() {
	$PLATFORM_TOOLS/adb logcat -c
	$PLATFORM_TOOLS/adb logcat | grep SDL/APP
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
	echo "  --build         = Builds the apk"
	echo "  --deploy        = Builds and installs the apk"
	echo "  --install       = Installs the apk from the build output folder"
	echo "  --logcat        = Shows the logs from the apk"
	echo "  --clean         = Deletes the build folder"
}


if [ "$1" == "--build" ]; then
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
