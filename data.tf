data "tfe_organization" "main" {
  name = var.organization
}

data "tfe_project" "main" {
  for_each     = setunion([var.target_tfc_project], var.additional_tfc_projects)
  name         = each.key
  organization = data.tfe_organization.main.name
}

locals {
  project_ids = toset([
    for p in data.tfe_project.main : p.id
  ])

  variables = {
    TFC_VAULT_ADDR = {
      key         = "TFC_VAULT_ADDR"
      value       = var.tfc_vault_addr
      description = "Vault Address Environment Variable"
      category    = "env"
    },
    TFC_VAULT_NAMESPACE = {
      key         = "TFC_VAULT_NAMESPACE"
      value       = "admin/terraform"
      description = "Vault Namespace Environment Variable"
      category    = "env"
    },
    TFC_VAULT_PROVIDER_AUTH = {
      key         = "TFC_VAULT_PROVIDER_AUTH"
      value       = "true"
      description = "Instruct Workspace/s to leverage the Vault Provider Auth method"
      category    = "env"
    },
    TFC_VAULT_RUN_ROLE = {
      key         = "TFC_VAULT_RUN_ROLE"
      value       = "vault-configuration-admin"
      description = "Instruct the Workspace to leverage this Vault Role"
      category    = "env"
    },
  }



  full_admin_policy = <<EOT
  path "*" {
  	capabilities = ["sudo","read","create","update","delete","list","patch"]
  }
  EOT

  vault_policy = <<EOT
########################################
# Self-management permissions
########################################

path "auth/token/lookup-self" {
  capabilities = ["read"]
}

path "auth/token/renew-self" {
  capabilities = ["update"]
}

path "auth/token/revoke-self" {
  capabilities = ["update"]
}

########################################
# AWS Auth Engine Management
########################################

path "auth/aws/*" {
  capabilities = ["create", "read", "update", "list", "delete"]
}

########################################
# ACL Policy Management
########################################

path "sys/policies/acl/*" {
  capabilities = ["create", "read", "update", "list", "delete"]
}

path "/+/sys/policies/acl/*" {
  capabilities = ["create", "read", "update", "list", "delete"]
}

########################################
# JWT Auth Method Management
########################################

# Current namespace mounts
path "sys/mounts/auth/jwt" {
  capabilities = ["create", "read", "update", "list"]
}
path "sys/mounts/auth/jwt" {
  capabilities = ["create", "read", "update", "list"]
}

path "sys/mounts/auth/jwt/*" {
  capabilities = ["create", "read", "update", "list"]
}
path "sys/mounts/auth/jwt/*" {
  capabilities = ["create", "read", "update", "list"]
}

# One namespace down
path "/+/sys/mounts/auth/jwt" {
  capabilities = ["create", "read", "update", "list"]
}
path "/+/sys/mounts/auth/jwt/*" {
  capabilities = ["create", "read", "update", "list"]
}

# Legacy JWT sys/auth endpoints
path "sys/auth/jwt" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "/+/sys/auth/jwt" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# JWT config
path "auth/jwt/config" {
  capabilities = ["read", "update"]
}

path "/+/auth/jwt/config" {
  capabilities = ["read", "update"]
}

# JWT roles
path "auth/jwt/role/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "/+/auth/jwt/role/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

########################################
# Secrets Engine Access
########################################

# Read-only access to classic secret/
path "secret/*" {
  capabilities = ["read"]
}

# ------------------------------
# KV v2 - Added section
# ------------------------------

# Read/write data values
path "kvv2/data/*" {
  capabilities = ["create", "read", "update", "delete"]
}

# Read/manage metadata (list keys, set custom metadata)
path "kvv2/metadata/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Soft-delete versions
path "kvv2/delete/*" {
  capabilities = ["update"]
}

# Undelete soft-deleted versions
path "kvv2/undelete/*" {
  capabilities = ["update"]
}

# Permanently destroy versions
path "kvv2/destroy/*" {
  capabilities = ["update"]
}

# ------------------------------

# Manage all secrets engine mounts
path "sys/mounts/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
########################################
# Sync Destinations Management
########################################

path "sys/sync/destinations/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
########################################
# Namespace Management
########################################

path "sys/namespaces/*" {
  capabilities = ["create", "read", "update", "list", "delete"]
}

path "/+/sys/namespaces/*" {
  capabilities = ["create", "read", "update", "list", "delete"]
}

path "/+/+/sys/namespaces/*" {
  capabilities = ["create", "read", "update", "list", "delete"]
}
EOT


  role_policy = <<EOT
# Allow a token to inspect its own metadata (TTL, policies, etc.) — read-only
path "auth/token/lookup-self" {
  capabilities = ["read"]
}

# Allow a token to renew its own lease — update required to extend
path "auth/token/renew-self" {
  capabilities = ["update"]
}

# Allow viewing ACL policy definitions but not modifying them
# (remove "update" to prevent changing policies)
path "sys/policies/acl/*" {
  capabilities = ["read", "list"]
}

# Allow viewing the JWT auth mount configuration and details.
# Changes to mount settings are restricted to the dedicated config path below.
path "sys/mounts/auth/jwt" {
  capabilities = ["read"]
}
path "sys/mounts/auth/jwt/*" {
  capabilities = ["read"]
}

# Allow reading and updating JWT auth METHOD configuration (OIDC/JWT provider settings)
# This is the minimal place to allow updates to the auth method itself.
path "auth/jwt/config" {
  capabilities = ["read", "update"]
}

# Allow a token to revoke itself only (no ability to revoke others)
path "auth/token/revoke-self" {
  capabilities = ["update"]
}

# Allow creating and updating JWT roles, and listing/reading them.
# Removed "delete" to avoid accidental/unauthorized role removal.
path "auth/jwt/role/*" {
  capabilities = ["create", "update", "read", "list"]
}

# Read-only access to secrets — no write/delete privileges.
path "secret/*" {
  capabilities = ["read", "list"]
}

# Allow management of Namespaces and Child Namespaces 
path "sys/namespaces/*" {
  capabilities = ["create", "update","read", "list"]
}
path "/+/sys/namespaces/*" {
  capabilities = ["create", "update", "read", "list"]
}
EOT
}
