# AWS Account Setup Guide

Follow these steps to securely set up your AWS account:

1. **Create a Root AWS Account**

   - Begin by creating a root AWS account.
   - Select your main AWS region.

2. **Set Up MFA on Root Account**

   - Manually enable Multi-Factor Authentication (MFA) on your root account for added security.

3. **Create an IAM User**

   - Create an IAM (Identity and Access Management) user for yourself.
   - Assign the `AdministratorAccess` permission policy.
   - **Note:** Unlike the root account, an IAM user creates audit trails in CloudTrail and can have its access restricted in line with the Principle of Least Privilege (PoLP).

4. **Enable MFA for IAM User**
   - Set up MFA for your newly created IAM user for enhanced security.
5. **Use IAM User for Login**
   - Prefer logging in as your IAM user for routine operations.

# Integration with GitHub

Follow these steps to integrate AWS with GitHub using OpenID Connect (OIDC):

6. **Create an OIDC Provider in IAM for GitHub**

   - Set up an OIDC provider in IAM specifically for GitHub.
   - For detailed guidance, refer to [GitHub's Documentation on Configuring OpenID Connect in AWS](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services#adding-the-identity-provider-to-aws).

7. **Create an IAM Role for GitHub Actions**

   - Create an IAM role with permissions policy `PowerUserAccess` (avoid `AdministratorAccess` to retain manual control over users and groups).
   - Name the role meaningfully, such as `terraform` or `IaC` (Infrastructure as Code).
   - Follow the steps outlined in [GitHub's Documentation on Configuring the Role and Trust Policy](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services#configuring-the-role-and-trust-policy).
   - Set up the trust relationship for the IAM role accurately. Replace placeholders like `${AWS_ACCOUNT_ID}`, `${GITHUB_ORG_OR_USER}`, `${GITHUB_REPO_NAME}`, and `${GITHUB_ENVIRONMENT_NAME}` with your actual values (e.g. `012345678910`, `myorg`, `myrepo`, and `prod`). Select the appropriate claim based on whether you use GitHub environment or not, and remove any comments from the JSON code, as JSON syntax does not support comments. Proper configuration is essential for security.

     ```json
     {
       "Version": "2012-10-17",
       "Statement": [
         {
           "Effect": "Allow",
           "Principal": {
             "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
           },
           "Action": "sts:AssumeRoleWithWebIdentity",
           "Condition": {
             "StringEquals": {
               "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
             },
             "StringLike": {
               // Either, if not using a GitHub `environment`:
               "token.actions.githubusercontent.com:sub": "repo:${GITHUB_ORG_OR_USER}/${GITHUB_REPO_NAME}:ref:refs/heads/main:*"
               // Or, if using a GitHub `environment`, add a deployment branch rule for it and leave the branch out of the OIDC claim:
               "token.actions.githubusercontent.com:sub": "repo:${GITHUB_ORG_OR_USER}/${GITHUB_REPO_NAME}:environment:${GITHUB_ENVIRONMENT_NAME}:*"
             }
           }
         }
       ]
     }
     ```

8. **Store AWS Secrets in GitHub**
   - In your GitHub repository settings, add secrets for `AWS_REGION` and `AWS_ROLE_ARN`.
   - Set these to your main AWS region and the ARN of the IaC role, respectively.
   - In your GitHub repository settings, add a secret named `PROJECT`.
   - This should match the `PROJECT` value used in Terraform (refer to Step 15), e.g., `myorg`.

# Enabling AWS CLI with SSO

Follow these steps to set up and use AWS CLI with Single Sign-On (SSO):

9. **Install AWS CLI**

   - Use the following commands to download and install AWS CLI:
     ```sh
     PKG_NAME='AWSCLIV2.pkg'
     curl "https://awscli.amazonaws.com/${PKG_NAME}" -o "${PKG_NAME}"
     sudo installer -pkg "${PKG_NAME}" -target /
     rm "${PKG_NAME}"
     unset PKG_NAME
     ```

10. **Set Up IAM Identity Center for SSO**

    - Configure SSO by following steps 1-6 in the [IAM Identity Center Getting Started Guide](https://docs.aws.amazon.com/singlesignon/latest/userguide/getting-started.html).

11. **Configure AWS CLI for SSO**

    - Set up AWS CLI SSO using the `aws configure sso` command or by preparing a `~/.aws/config` file.
    - For detailed instructions, refer to [AWS CLI User Guide on SSO](https://docs.aws.amazon.com/cli/latest/userguide/sso-configure-profile-token.html).
    - Below is an example configuration. Replace `myorg` with your organization's name. If using multiple regions, consider adding region-specific details to your profile and session names.

      ```ini
      [profile myorg-prod-poweruser]
      sso_session = myorg-prod-poweruser
      sso_account_id = 012345678910
      sso_role_name = PowerUserAccess
      sso_start_url = https://a-b1234c5d6e.awsapps.com/start
      sso_region = us-west-1
      region = us-west-1
      output = json

      [sso-session myorg-prod-poweruser]
      sso_start_url = https://a-b1234c5d6e.awsapps.com/start
      sso_region = us-west-1
      sso_registration_scopes = sso:account:access

      [profile myorg-prod-readonly]
      sso_session = myorg-prod-readonly
      sso_account_id = 012345678910
      sso_role_name = ReadOnlyAccess
      sso_start_url = https://a-b1234c5d6e.awsapps.com/start
      sso_region = us-west-1
      region = us-west-1
      output = json

      [sso-session myorg-prod-readonly]
      sso_start_url = https://a-b1234c5d6e.awsapps.com/start
      sso_region = us-west-1
      sso_registration_scopes = sso:account:access
      ```

12. **Login Using AWS CLI SSO**

    - Execute the command `aws sso login --sso-session myorg-prod-poweruser` to log in via AWS CLI.

13. **Troubleshooting CLI Access Issues**
    - After logging in, if you encounter an error like `Unable to locate credentials` when running commands (e.g., `aws s3 ls`), it indicates a need to select a profile.
    - Set the `AWS_DEFAULT_PROFILE` environment variable to one of your configured profiles to resolve this, for example, `AWS_DEFAULT_PROFILE=myorg-prod-poweruser`.
    - It's recommended to get accustomed to setting this variable regularly rather than depending on a non-Principle of Least Privilege (PoLP) default. Create convenient shell aliases for ease of use.

# Further Steps in AWS Setup

After setting up AWS CLI with SSO, here are the final steps to complete your AWS configuration:

14. **Enable CloudTrail for Audit Logging**

    - It's highly recommended to enable AWS CloudTrail in your account. CloudTrail provides a complete audit log of all activities in your AWS account, which is crucial for security and compliance.
    - For more information on setting up CloudTrail, refer to the [AWS CloudTrail User Guide](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-user-guide.html).

15. **Set Up Terraform Infrastructure**

    - The final step involves creating resources for managing your Terraform state.
    - Run the `terraform/bootstrap.sh` script with your specific REGION, PROJECT, and ENV (environment) parameters. Make sure not to use the example values provided.
    - Here's how to execute the script:

      ```sh
      cd terraform
      # Use the command format: ./bootstrap.sh REGION PROJECT ENV
      ./bootstrap.sh eu-west-1 myorg prod
      ```

    - **Congratulations!** With these steps completed, your GitHub setup should now be capable of automatically and securely applying your infrastructure configurations.
