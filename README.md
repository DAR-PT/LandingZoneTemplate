# LandingZoneTemplate

Template for creating sandbox spokes, including their networking, Container App,
and hub connectivity.

## Region for new deployments

On 20 November 2026, the region for new spoke deployments was changed from
North Europe to Italy North following Microsoft's recommendations.

New repositories generated from this template create their resource group,
spoke VNet and Container App in Italy North (`italynorth`). The app uses the parallel
`cae-shared-italynorth-sbx` environment in `RG-Hub-SBX`.

**Prerequisite:** Review and deploy the separate Italy North Container Apps
environment in the landing-zone repository before planning or creating an Italy
North spoke. Check regional service availability, subscription capacity and
permissions first. Review the full landing-zone plan carefully: other pending
changes to shared infrastructure can affect existing spokes. No environment is
created merely by generating a repository.

The existing hub, gateway, core services, DNS, storage and North Europe Container
Apps environment remain in their current regions. Italy North spokes depend on
the existing hub through cross-region peering and on its shared services;
consider cross-region latency, transfer costs and availability. The example app
uses external ingress; private endpoints or private ingress may need additional
region-specific DNS and networking configuration.

Existing cloned spoke repositories are not updated by changes to this template.
Do not apply this configuration to an existing North Europe spoke as a migration:
location changes can require destructive replacements. Plan a separate migration
and review the state and workload before any such change.

## Spoke naming

Choose a short, unique spoke name, such as `certificationmanagement`. Enter only
the name, **without** the `spoke-` prefix. The repository-generation workflow
converts it to lowercase and uses it to create:

| Item | Example |
| --- | --- |
| GitHub repository | `DAR-PT/spoke-certificationmanagement` |
| Azure resource group | `RG-Spoke-certificationmanagement-SBX` |
| Container App | `certificationmanagement-app` |
| Internal hostname | `certificationmanagement.dar.internal` |
| Terraform state blob | `tfstate/certificationmanagement.tfstate` |

The creation workflow derives the spoke name from the repository name by
removing the `spoke-` prefix. Use a name that starts with a letter, ends with a
letter or digit, contains only lowercase letters, digits and single hyphens,
and is at most 28 characters long. This is a conservative recommendation to
accommodate the generated Azure Container App name; the repository-generation
workflow does not enforce these naming rules.

## Create a repository and deploy a spoke

### Prerequisites

- Access to run workflows in `DAR-PT/LandingZoneTemplate` and the generated spoke
  repository.
- The template repository's `GH_PAT`, `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, and
  `AZURE_SUBSCRIPTION_ID` secrets configured. The token must be able to create a
  private repository in `DAR-PT`, push its contents, and configure its secrets.
- Azure authentication configured for the generated repository, including any
  required federated identity trust and permissions to manage the spoke, hub
  resources, state storage, and spoke registry.
- A valid-looking `@emeal.nttdata.com` email address for the person creating the
  spoke. The address is supplied by the workflow user; neither the mailbox nor
  its ownership is verified.

### Step by step

1. In `DAR-PT/LandingZoneTemplate`, open **Actions** and select
   **Generate_Repo_From_Template**.
2. Select **Run workflow**, enter the `spoke_name` without the `spoke-` prefix,
   and enter `Owner_Email`, for example `user@emeal.nttdata.com`. Run the
   workflow and check that it succeeds. Invalid email addresses are rejected
   before repository creation.
3. The workflow creates a private `DAR-PT/spoke-<name>` repository, copies the
   contents of the **default branch** of `DAR-PT/LandingZoneTemplate` into it,
   and removes the platform-only repository-generation and cleanup workflows.
   It also configures the three Azure secrets in the new repository. Selecting
   another workflow branch does not change the template repository being cloned.
4. Open the generated repository and verify that `owner.auto.tfvars.json`
   contains the intended `Owner_Email` and that Azure authentication is ready.
   Terraform loads this file automatically and uses the email for the resource
   group's `Owner_Email` tag. The email is stored in the repository, Terraform
   state, and the Azure tag; it is not a secret.
5. In the generated repository, open **Actions**, select **Initial_Setup**, and
   select **Run workflow**. Set `keepalive` to `true` to
   protect the spoke for the next cleanup cycle, or leave the default `false`
   to allow cleanup. Run the workflow.
6. Check the workflow logs and Azure resources. The workflow allocates a spoke
   index, initializes the spoke's Terraform state, plans and applies Terraform,
   creates Application Gateway objects, and attempts to upload the updated spoke
   registry. A repository being created does not by itself mean the Azure spoke
   was deployed.
7. For subsequent Terraform changes, commit the changes to the spoke repository.
   To preview them without applying, open **Actions**, select **Plan Spoke
   Terraform**, select **Run workflow**, and review the plan in the run logs.
8. When ready to apply changes, select **Apply Spoke Terraform** in the spoke
   repository's Actions tab and select **Run workflow**. Check the run logs
   and Azure resources afterward. This workflow creates and immediately applies
   a fresh plan; it does not reuse or require approval of the plan from step 7.

If deployment fails, inspect the logs, Azure resources, Terraform state, and
spoke registry before retrying: a failed run may have already created resources
or partially completed the setup.

For an existing repository using this template, add `owner.auto.tfvars.json`
before deploying:

```json
{
  "Owner_Email": "user@emeal.nttdata.com"
}
```

For direct Terraform use, provide the required `Owner_Email` variable through
a `.tfvars` file, environment variable, or command-line argument.

## Delete Spokes and keepalive

**Clear_Spokes** (`.github/workflows/Clear_Spokes.yml`) is a platform workflow
in the template repository. It runs daily at **20:12 UTC** and can also be
started manually from **Actions → Clear_Spokes → Run workflow**.

**Warning:** This is a bulk cleanup, not a delete-by-name operation. Each run
selects every resource group in the configured Azure subscription whose name
contains `RG-Spoke-` and whose `keepalive` tag is not exactly `true`, including
groups where the tag is missing. Do not run it manually unless all eligible
spokes can be deleted.

For each selected group, the workflow attempts to remove associated hub peering,
private DNS links and CNAME, and Application Gateway objects, then requests
resource-group deletion and removes the spoke from its local registry copy. It
attempts to upload the updated registry after processing. Resource-group
deletion is asynchronous. Cleanup errors can fail the workflow before all
resources are processed or the registry is uploaded; check the workflow logs,
Azure resources, and registry to confirm cleanup completed. The workflow does
**not** delete the GitHub repository or Terraform state blob.

A resource group tagged `keepalive=true` is skipped for that cleanup run. The
workflow then attempts to reset that tag to `false`, so protection lasts only
one successful cleanup cycle unless the tag is set to `true` again before the
next run. To protect a spoke, update the `keepalive` tag on its Azure resource
group before cleanup; verify the tag and workflow outcome rather than assuming
the reset succeeded.

To clean up eligible spokes manually:

1. Review **all** matching resource groups and their `keepalive` tags in the
   configured subscription. Set `keepalive=true` on any spoke that must survive
   this run; groups already tagged `true` will be reset to `false` afterward.
2. Run **Clear_Spokes** from the template repository's Actions tab.
3. Inspect the run logs and verify resource-group deletion and registry updates
   in Azure. Resolve any failed or incomplete cleanup before reusing a spoke
   name or index.
4. Manage the remaining GitHub repository and Terraform state separately,
   according to your organization's retention and recovery procedures.

## Planning and applying changes to an existing spoke

Run **Plan Spoke Terraform** or **Apply Spoke Terraform** manually from the
generated `spoke-<name>` repository. Both workflows use the existing Azure
credentials, spoke registry entry, Terraform state, resource group `keepalive`
tag, and `owner.auto.tfvars.json`. They fail if the registry entry or state is
missing; they do not allocate an index or rehydrate a spoke.

The plan workflow displays a plan without applying it. The apply workflow
creates a fresh plan and immediately applies that plan; it does not reuse or
require approval of a prior plan workflow run. Neither workflow reconciles
Application Gateway objects.

Newly generated repositories include both workflows and the shared
`.github/actions/prepare-spoke` action. To use them in an existing repository,
copy both workflow files and the shared action into it.
