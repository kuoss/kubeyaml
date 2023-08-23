#!/bin/bash

cd $(dirname $0)/..
ROOT=$(pwd)

cd src/
PACKAGES=$(python3 list_packages.py)

for PACKAGE in $PACKAGES; do
    if [ -d $ROOT/yamls/$PACKAGE ]; then
        echo "[SKIP] yamls/$PACKAGE already exists."
        continue
    fi

    cd $ROOT/src/
    echo $PACKAGE
    rm -rf   _temp
    mkdir -p _temp/_rendered
    python3 render_pacakge.py $PACKAGE > _temp/kustomization.yaml
    kubectl kustomize --enable-helm _temp/ -o _temp/_rendered/

    cd _temp/_rendered/
    FILES=$(ls *.yaml)
    if [ $? != 0 ]; then
        echo ERROR
        exit
    fi
    for FILE in $FILES; do
        KIND=$(grep ^kind: $FILE | awk '{print tolower($2)}')
        NEWFILE=$(echo $FILE | grep -o ${KIND}_.*)
        mv $FILE $NEWFILE
    done

    cd $ROOT
    rm -rf                     yamls/$PACKAGE
    mv     src/_temp/_rendered yamls/$PACKAGE
    rm -rf src/_temp
done
echo Done...

