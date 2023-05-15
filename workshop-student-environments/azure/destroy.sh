#!/bin/bash
echo "
##############################################################################################################
#
# Workshop student environment
#
##############################################################################################################
"

# Stop running when command returns error
set -e

STATE="terraform.tfstate"

cd terraform/
echo ""
echo "==> Starting Terraform deployment"
echo ""

echo ""
echo "==> Terraform init"
echo ""
terraform init

echo ""
echo "==> terraform destroy"
echo ""
terraform destroy -auto-approve
echo "Return code terraform destroy: $?"
if [ $? != 0 ];
then
    echo "--> ERROR: Destroy failed ..."
    rg=`grep -m 1 -o '"resource_group_name": "[^"]*' "$STATE" | grep -o '[^"]*$'`
    echo "--> Trying to delete the resource group $rg..."
    az group delete --resource-group "$rg"
    exit $rc;
fi

