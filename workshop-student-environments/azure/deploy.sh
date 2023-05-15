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

##############################################################################################################
# Azure Service Principal
##############################################################################################################
# AZURE_CLIENT_ID=''
# AZURE_CLIENT_SECRET=''
# AZURE_SUBSCRIPTION_ID=''
# AZURE_TENANT_ID=''
##############################################################################################################

PLAN="terraform.tfplan"
STATE="terraform.tfstate"

if [ -z "$DEPLOY_LOCATION" ]
then
    # Input location
    echo -n "Enter location (e.g. westeurope): "
    stty_orig=`stty -g` # save original terminal setting.
    read location         # read the location
    stty $stty_orig     # restore terminal setting.
    if [ -z "$location" ]
    then
        location="westeurope"
    fi
else
    location="$DEPLOY_LOCATION"
fi
export TF_VAR_LOCATION="$location"
echo ""
echo "--> Deployment in $location location ..."

if [ -z "$DEPLOY_DOMAIN" ]
then
    # Input custom domain
    echo ""
    echo -n "Enter verified custom domain for user accounts: "
    stty_orig=`stty -g` # save original terminal setting.
    read domain         # read the location
    stty $stty_orig     # restore terminal setting.
    if [ -z "$domain" ]
    then
        echo "Verified custom domain must be provided."
        exit 1
    fi
else
    domain="$DEPLOY_DOMAIN"
fi
export TF_VAR_CUSTOMDOMAIN="$domain"
echo ""
echo "--> Creating student accounts with custom domain $domain ..."

if [ -z "$DEPLOY_COUNT" ]
then
    # Input count
    echo ""
    echo -n "Enter number of students accounts to create: "
    stty_orig=`stty -g` # save original terminal setting.
    read count         # read the location
    stty $stty_orig     # restore terminal setting.
    if [ -z "$count" ]
    then
        echo "Number of students accounts must be provided."
        exit 1
    fi
else
    count="$DEPLOY_COUNT"
fi
export TF_VAR_ACCOUNTCOUNT="$count"
echo ""
echo "--> Deployment of $count student accounts ..."
echo ""

SUMMARY="summary.out"

echo ""
echo "==> Starting Terraform deployment"
echo ""
cd terraform/

echo ""
echo "==> Terraform init"
echo ""
terraform init

echo ""
echo "==> Terraform plan"
echo ""
terraform plan --out "$PLAN"

echo -n "Do you want to continue? Type yes: "
stty_orig=`stty -g` # save original terminal setting.
read continue         # read the location
stty $stty_orig     # restore terminal setting.

if [[ $continue == "yes" ]]
then
    echo ""
    echo "==> Terraform apply"
    echo ""
    terraform apply "$PLAN"
    if [[ $? != 0 ]];
    then
        echo "--> ERROR: Deployment failed ..."
        exit $rc;
    fi
else
    echo "--> ERROR: Deployment cancelled ..."
    exit $rc;
fi

echo ""
echo "==> Terraform output deployment summary"
echo ""
terraform output deployment_summary > "../output/$SUMMARY"

cd ../
echo "
##############################################################################################################
#
# Workshop student environment
#
##############################################################################################################
"
cat "output/$SUMMARY"
echo "

##############################################################################################################"
