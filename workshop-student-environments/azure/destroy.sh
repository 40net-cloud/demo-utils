#!/bin/bash
echo "
##############################################################################################################
#
# Workshop student environment
#
##############################################################################################################
"

# Stop running when a command returns an error (suspended around
# terraform destroy below, since that failure is handled explicitly)
set -e

if [ -z "$DEPLOY_SUBSCRIPTION_ID" ]
then
    # Input subscription ID
    echo -n "Enter Azure subscription ID to destroy from: "
    stty_orig=`stty -g` # save original terminal setting.
    read subscription_id # read the subscription id
    stty $stty_orig     # restore terminal setting.
    if [ -z "$subscription_id" ]
    then
        echo "Azure subscription ID must be provided."
        exit 1
    fi
else
    subscription_id="$DEPLOY_SUBSCRIPTION_ID"
fi
export TF_VAR_SUBSCRIPTION_ID="$subscription_id"
export ARM_SUBSCRIPTION_ID="$subscription_id"
echo ""
echo "--> Destroying in subscription $subscription_id ..."

cd terraform/
echo ""
echo "==> Starting Terraform deployment"
echo ""

echo ""
echo "==> Terraform init"
echo ""
terraform init

echo ""
echo "==> Reading deployment variables from remote state"
echo ""
STATE_JSON=$(terraform state pull)

FIRST_RG_INDEX=$(echo "$STATE_JSON" | jq -r '[.resources[] | select(.type=="azurerm_resource_group")][0].instances[0].index_key')
FIRST_RG_NAME=$(echo "$STATE_JSON" | jq -r '[.resources[] | select(.type=="azurerm_resource_group")][0].instances[0].attributes.name')
FIRST_UPN=$(echo "$STATE_JSON" | jq -r '[.resources[] | select(.type=="azuread_user")][0].instances[0].attributes.user_principal_name')

export TF_VAR_PREFIX="${FIRST_RG_NAME%-student${FIRST_RG_INDEX}-RG}"
export TF_VAR_LOCATION=$(echo "$STATE_JSON" | jq -r '[.resources[] | select(.type=="azurerm_resource_group")][0].instances[0].attributes.location')
export TF_VAR_ACCOUNTCOUNT=$(echo "$STATE_JSON" | jq '[.resources[] | select(.type=="azurerm_resource_group") | .instances[]] | length')
export TF_VAR_CUSTOMDOMAIN="${FIRST_UPN#*@}"

echo "--> PREFIX=$TF_VAR_PREFIX LOCATION=$TF_VAR_LOCATION ACCOUNTCOUNT=$TF_VAR_ACCOUNTCOUNT CUSTOMDOMAIN=$TF_VAR_CUSTOMDOMAIN"

echo ""
echo "==> terraform destroy"
echo ""
set +e
terraform destroy -auto-approve
rc=$?
set -e
echo "Return code terraform destroy: $rc"
if [ $rc != 0 ];
then
    echo "--> ERROR: Destroy failed, falling back to deleting resource groups directly ..."
    RG_NAMES=($(echo "$STATE_JSON" | jq -r '.resources[] | select(.type=="azurerm_resource_group") | .instances[].attributes.name'))
    for rg in "${RG_NAMES[@]}"
    do
        echo "--> Trying to delete the resource group $rg..."
        az group delete --resource-group "$rg" --yes --no-wait || echo "--> WARNING: Could not delete resource group $rg, continuing with the rest ..."
    done
    exit $rc
fi
