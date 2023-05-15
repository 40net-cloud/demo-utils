#!/bin/bash

for i in {1..8}
do
    rg="emea-se-student${i}-RG"
    echo "Deleting RG [$rg]..."
    az group delete --yes -g $rg
done
