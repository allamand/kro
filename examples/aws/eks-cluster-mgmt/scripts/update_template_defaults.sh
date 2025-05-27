#!/bin/bash

# Exit on error
set -e

# Define variables
TEMPLATE_PATH="/home/ec2-user/environment/eks-cluster-mgmt/backstage-templates/eks-cluster-template/template.yaml"
CLOUDFRONT_DOMAIN=$(aws cloudfront list-distributions --query "DistributionList.Items[?Origins.Items[?contains(DomainName, 'gitlab')]].DomainName" --output text)
GIT_USERNAME=$(kubectl get secret git-credentials -n argocd -o jsonpath='{.data.GIT_USERNAME}' | base64 --decode)
WORKING_REPO=$(kubectl get secret git-credentials -n argocd -o jsonpath='{.data.WORKING_REPO}' | base64 --decode)
REPO_FULL_URL=https://$CLOUDFRONT_DOMAIN/$GIT_USERNAME/$WORKING_REPO.git

# Check if environment variables are set
if [ -z "$ACCOUNT_ID" ]; then
  echo "Error: ACCOUNT_ID environment variable is not set"
  exit 1
fi

echo "Updating template defaults with the following values:"
echo "Account ID: $ACCOUNT_ID"
echo "Repo Host URL: $CLOUDFRONT_DOMAIN"
echo "Repo Username: $GIT_USERNAME"
echo "Repo Name: $WORKING_REPO"

# Update the template.yaml file using yq
# The fields in the YAML are under spec.parameters[].properties.{fieldName}.default
yq -i '.spec.parameters[0].properties.accountId.default = "'$ACCOUNT_ID'"' "$TEMPLATE_PATH"
yq -i '.spec.parameters[0].properties.managementAccountId.default = "'$ACCOUNT_ID'"' "$TEMPLATE_PATH"
yq -i '.spec.parameters[0].properties.region.default = "'$AWS_REGION'"' "$TEMPLATE_PATH"
yq -i '.spec.parameters[0].properties.repoHostUrl.default = "'$CLOUDFRONT_DOMAIN'"' "$TEMPLATE_PATH"
yq -i '.spec.parameters[0].properties.repoUsername.default = "'$GIT_USERNAME'"' "$TEMPLATE_PATH"
yq -i '.spec.parameters[0].properties.repoName.default = "'$WORKING_REPO'"' "$TEMPLATE_PATH"
yq -i '.spec.parameters[1].properties.addonsRepoUrl.default = "'$REPO_FULL_URL'"' "$TEMPLATE_PATH"
yq -i '.spec.parameters[1].properties.fleetRepoUrl.default = "'$REPO_FULL_URL'"' "$TEMPLATE_PATH"
yq -i '.spec.parameters[1].properties.platformRepoUrl.default = "'$REPO_FULL_URL'"' "$TEMPLATE_PATH"
yq -i '.spec.parameters[1].properties.workloadRepoUrl.default = "'$REPO_FULL_URL'"' "$TEMPLATE_PATH"

echo "Template updated successfully!"
