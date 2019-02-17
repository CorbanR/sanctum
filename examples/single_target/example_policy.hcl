# Helpful documentation can be found
# https://www.vaultproject.io/guides/identity/policies
# https://www.vaultproject.io/docs/concepts/policies.html
# https://learn.hashicorp.com/vault/getting-started/policies
#
# You can make permissions more granular or limited by specifying deeper paths
# Example: `path "sanctum-test/data/dev/*"`, etc.
#
################# Read/Write v2 api example #################################################
path "sanctum-test/data/*" { capabilities = ["list","read","create","update","delete"] }
path "sanctum-test/metadata/*" { capabilities = ["list","read","create","update","delete"] }
path "sanctum-test/destroy/*" { capabilities = ["update"] }
path "sanctum-test/delete/*" { capabilities = ["update"] }
path "sanctum-test/undelete/*" { capabilities = ["update"] }
#############################################################################################

################# Read/Write v1/generic example ###################################
path "sanctum-test/*" { capabilities = ["list","read","create","update","delete"] }
###################################################################################

################## Additional sys/ and sys/mount permissions ############################################
# Grant access to tune existing mount
# Required to upgrade from v1/generic to v2
path "sys/mounts/sanctum-test/tune" { capabilities = ["read", "update"] }
# Grant broader permission to specific mount
path "sys/mounts/sanctum-test" { capabilities = ["create", "read", "update", "delete", "list", "sudo"] }
# Read health checks
path "sys/health" { capabilities = ["read", "sudo"] }
# View capabilities of token
path "sys/capabilities" { capabilities = ["create", "update"] }
# View capabilities of token
path "sys/capabilities-self" { capabilities = ["create", "update"] }
# View mount info for mounts that you have permissions on
path "sys/internal/ui/mounts" { capabilities = ["read"] }
#########################################################################################################

################### Transit permissions###########################################################
# General permission on key
path "transit/keys/sanctum-test" { capabilities = ["list","read","create","update", "delete"] }
# Permission to rotate keys
path "transit/keys/sanctum-test/rotate" { capabilities = ["list","read","create","update"] }
# Permission to modify transit key config
path "transit/keys/sanctum-test/config" { capabilities = ["list","read","create","update"] }
# Permission to backup key
#path "transit/backup/sanctum-test" { capabilities = ["list","read"] }
# Permission to restore key
#path "transit/restore/sanctum-test" { capabilities = ["list","read","create","update"] }
# Transit encryption endpoint
path "transit/encrypt/sanctum-test" { capabilities = ["list","read","create","update"] }
# Transit decrypt endpoint
path "transit/decrypt/sanctum-test" { capabilities = ["list","read","create","update"] }
# Transit rewrap permissions
path "transit/rewrap/sanctum-test" { capabilities = ["list","read","create","update"] }
##################################################################################################
