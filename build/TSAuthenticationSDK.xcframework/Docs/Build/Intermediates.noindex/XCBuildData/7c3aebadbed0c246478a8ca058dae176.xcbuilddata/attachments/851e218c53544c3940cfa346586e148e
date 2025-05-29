#!/bin/sh
# Type a script or drag a script file from your workspace to insert its path.
set -x
set -e

VERSION_FILE=${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.framework/version

cd $SRCROOT
VERSION_NAME=${CURRENT_PROJECT_VERSION}
BRANCH=$(git rev-parse --abbrev-ref HEAD)
COMMIT=$(git rev-parse --short=7 HEAD)
CURR_VER=""
if [ -e $VERSION_FILE ]; then 
    CURR_VER=$(<$VERSION_FILE) # read file content into var
fi

if [ "${CURR_VER}" = "$VERSION_NAME $COMMIT" ]; then 
    exit 0
else
    echo "$VERSION_NAME $COMMIT" > $VERSION_FILE
fi

