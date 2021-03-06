#!/bin/zsh
##!/bin/bash for linux
# Luca Anzalone

# -----------------------------------------------------------------------------
# -- DLIB FOR ANDROID
# -----------------------------------------------------------------------------

# Android-cmake path: REPLACE WITH YOUR CMAKE PATH!
AndroidCmake='cmake'

# Android-ndk path: REPLACE WITH YOUR NDK PATH!
NDK="/Users/rnaz/Library/Android/sdk/ndk/21.3.6528147"

#/Users/rnaz/Library/Android/sdk/ndk/21.3.6528147/toolchains/llvm/prebuilt/darwin-x86_64/bin
TOOLCHAIN="${NDK}/build/cmake/android.toolchain.cmake"

# Supported Android ABI: TAKE ONLY WHAT YOU NEED!
#ABI=('armeabi-v7a' 'arm64-v8a' 'x86' 'x86_64')
#ABI=('arm64-v8a')
ABI=('x86' 'x86_64')
#ABI=('armeabi-v7a')

# path to strip tool: REPLACE WITH YOURS, ACCORDING TO OS!!
STRIP_PATH="$NDK/toolchains/llvm/prebuilt/darwin-x86_64/bin"

# Declare the array
declare -A STRIP_TOOLS

STRIP_TOOLS=(
    ['armeabi-v7a']=$STRIP_PATH/arm-linux-androideabi-strip
    ['arm64-v8a']=$STRIP_PATH/aarch64-linux-android-strip
    ['x86']=$STRIP_PATH/x86_64-linux-android-strip
    ['x86_64']=$STRIP_PATH/x86_64-linux-android-strip
)

# Minimum supported sdk: SHOULD BE GREATER THAN 16
MIN_SDK=21

# Directory for storing native libraries
NATIVE_DIR="output"

# -----------------------------------------------------------------------------
# -- Dlib setup
# ----------------------------------------------------------------------------- 

# Dlib library path: REPLACE WITH YOUR DLIB PATH!
DLIB_PATH='dlib'

function compile_dlib {
	cd $DLIB_PATH || exit
	mkdir 'build'

	echo '=> Compiling Dlib...'

	for abi in "${ABI[@]}"
	do
		echo 
		echo "=> Compiling Dlib for ABI: '$abi'..."

		mkdir "build/$abi"
		cd "build/$abi" || exit

    ${AndroidCmake}   -DBUILD_SHARED_LIBS=1 \
					  -DANDROID_NDK=${NDK} \
					  -DCMAKE_SYSTEM_NAME=Android \
					  -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN} \
					  -DCMAKE_BUILD_TYPE=Release \
					  -DCMAKE_CXX_FLAGS="-std=c++11 -frtti -fexceptions -O3 -mfpu=neon" \
					  -DANDROID_ARM_NEON=TRUE \
					  -DANDROID_ABI="${abi}" \
					  -DANDROID_PLATFORM=${MIN_SDK} \
					  -DANDROID_TOOLCHAIN=clang \
					  -DANDROID_STL=c++_shared \
					  -DANDROID_CPP_FEATURES="rtti exceptions" \
					  -DCMAKE_PREFIX_PATH=../../ \
					  ../../
 		
 		echo "=> Generating the 'dlib/libdlib.so' for ABI: '$abi'..."
		$AndroidCmake --build .

    echo "Current Dir $(pwd)"
		echo "=> Stripping libdlib.so for ABI: '$abi'to reduce lib size..."
		${STRIP_TOOLS[$abi]} --strip-unneeded dlib/libdlib.so

		echo '=> done.'
		cd ../../
	done
	#back to project root directory
	cd ../
}

function dlib_setup {
	echo '=> Making directories for Dlib ...'
	mkdir "$NATIVE_DIR/dlib"
	echo "=> '$NATIVE_DIR/dlib' created."
	mkdir "$NATIVE_DIR/dlib/lib"
	echo "=> '$NATIVE_DIR/dlib/lib' created."
	mkdir "$NATIVE_DIR/dlib/include"
	echo "=> '$NATIVE_DIR/dlib/include' created."
	mkdir "$NATIVE_DIR/dlib/include/dlib"
    echo "=> '$NATIVE_DIR/dlib/include/dlib' created."

	echo "=> Copying Dlib headers..."
	cp -v -r "$DLIB_PATH/dlib" "$NATIVE_DIR/dlib/include"
	cp -v -r "$DLIB_PATH/build/$abi/dlib/config.h" "$NATIVE_DIR/dlib/include/dlib"
	cp -v -r "$DLIB_PATH/build/$abi/dlib/revision.h" "$NATIVE_DIR/dlib/include/dlib"

	echo "=> Copying 'libdlib.so' for each ABI..."
	for abi in "${ABI[@]}"
	do
		mkdir "$NATIVE_DIR/dlib/lib/$abi"
		cp -v -r "$DLIB_PATH/build/$abi/dlib/libdlib.so" "$NATIVE_DIR/dlib/lib/$abi"
		echo " > Copied libdlib.so for $abi"
	done
}

# COMMENT TO DISABLE COMPILATION
compile_dlib

# -----------------------------------------------------------------------------
# -- OpenCV
# -----------------------------------------------------------------------------

# OpenCV library path: REPLACE WITH YOUR OPENCV PATH!
#OPENCV_PATH='path-to-your/opencv-4.0.1-android-sdk/sdk/native'
#
#function opencv_setup {
#	mkdir "$NATIVE_DIR/opencv"
#
#	echo "=> Copying 'libopencv_java4.so' for each ABI..."
#	for abi in "${ABI[@]}"
#	do
#		mkdir "$NATIVE_DIR/opencv/$abi"
#		cp -v "$OPENCV_PATH/libs/$abi/libopencv_java4.so" "$NATIVE_DIR/opencv/$abi"
#		echos " > Copied libopencv_java4.so for $abi"
#	done
#}

# -----------------------------------------------------------------------------
# -- Project setup
# -----------------------------------------------------------------------------

mkdir $NATIVE_DIR

# COMMENT TO NOT COPY DLIB '.so' FILES
dlib_setup

# COMMENT TO NOT COPY OPENCV '.so' FILES
#opencv_setup

echo "=> Project configuration completed."

# -----------------------------------------------------------------------------
