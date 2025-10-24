module "vault-auth" {
  source = "/Users/simon.elliott/Documents/Code/New_Structure/Terraform_Modules/TFE/Terraform-Vault-Provider-Auth"

  vault_url             = var.vault_url
  jwt_backend_path      = var.jwt_backend_path
  tfc_vault_audience    = var.tfc_vault_audience
  tfc_organization_name = var.tfc_organization_name
  tfc_project_name      = var.tfc_project_name
  tfc_workspace_name    = var.tfc_workspace_name
  vault_policy          = local.vault_policy
}