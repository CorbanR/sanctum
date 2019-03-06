# Sanctum
Simple and secure filesystem-to-vault KV synchronization. Inspired by [constancy](https://github.com/daveadams/constancy). 
Local files are encrypted using vaults [transit](https://www.vaultproject.io/api/secret/transit/index.html) backend. 
This makes maintaining multiple vault secrets for multiple applications simple and secure.

## Usage Example

### Generic/KV API v1
**NOTE: If you just starting to use sanctum, and or vault, you should be using API v2 For more info see, [Vault kv v2](https://www.vaultproject.io/docs/secrets/kv/kv-v2.html), or [Vault kv v1](https://www.vaultproject.io/docs/secrets/kv/kv-v1.html)**

Lets say you have a vault instance with a `generic`, or `kv v1` enabled backend.
if you were to run, `vault read secrets/cool-app/dev/env` you would see something similar to

```
Key                 Value
---                 -----
refresh_interval    768h
db_password         heydudeihaveacoolapp
token               myrandomtoken

```

using the sanctum gem, you could run `sanctum pull`. Depending on the path you specified in the `sanctum.yaml` config file; Your local file system would look similar to
```
<path-specified>/cool-app/dev/env
```
`env` would contain a `transit` encrypted base64 encoded blob, which you could then edit with `sanctum edit <path-specified>/cool-app/dev/env`. You could then push any changes with
`sanctum push`.

### KV API v2
**NOTE: V2 Vault API adds `/data` and `/metadata` to the mounts endpoints see [Vault kv v2](https://www.vaultproject.io/docs/secrets/kv/kv-v2.html)**

Lets say you have a vault instance with `kv v2`  enabled backend.
if you were to run, `vault kv secrets/cool-app/dev/env` you may see something similar to

```
====== Metadata ======
Key              Value
---              -----
created_time     2019-02-17T00:58:51.194452314Z
deletion_time    n/a
destroyed        false
version          1

======= Data =======
Key            Value
---            -----
db_password    heydudeihaveacoolapp
token          myrandomtoken

```

using the sanctum gem, you could run `sanctum pull`. Depending on the path you specified in the `sanctum.yaml` config file; Your local file system would look similar to
```
<path-specified>/cool-app/dev/env
```

`env` would contain a `transit` encrypted base64 encoded blob, which you could then edit with `sanctum edit <path-specified>/cool-app/dev/env`. You could then push any changes with
`sanctum push`.

## Installation

From source:

    $ bundle install && bundle exec rake:install

Or install rubygems:

    $ gem install sanctum

## Usage
```
sanctum check  - Checks differences between local files and vault.
sanctum push   - Push local file changes (if any) to vault.
sanctum pull   - Pull vault secrets to local files (encrypted).
sanctum config - Generate an example config file.
sanctum create - Create an encrypted local file.
sanctum edit   - Edit an encrypted local file.
sanctum view   - View an encrypted local file.
sanctum update - Update secrets backend to v2 API.
```


## Configuration
**sanctum.yaml is required, run `sanctum config` to generate an example file**

Sanctum will use the **first `sanctum.yaml`** file it comes across when searching backwards through the directory tree from the current working directory. 
So, typically you may wish to place the config file in the root of your git repository or the base directory of your config file tree.

You can also specify a config file using the -c,--config <filename> command line argument.
## Variables
The example `sanctum.yaml` has all options documented, run `sanctum config` to generate an example file. 

The following environment variables are read.
```
VAULT_ADDR=
VAULT_TOKEN=
```

**Variables order of precedence**
The higher the number the higher the precedence.(1 is the lowest precedence, 4 is the highest, Command line arguments will always win).

1. Default variables (Documented in sanctum.yaml)
2. Config file
3. Environment variables
4. Command line arguments.


## Configuration file structure
The configuration file is a Hash represented in YAML format with three possible top-level keys: `sanctum`, `vault`, and `sync`.
* The `sanctum` section sets global defaults.
  * You can choose to set a `transit_key` default under this section, which can be overridden per target
  * You can choose to set a `secrets_version` default under this section, which can be overridden per target
* The `vault` section specifies the url, token, to the Vault REST API endpoint.
  * url, token are **required** and can be set here or through environment variables.
* The `sync` section sets the local paths and Vault prefixes you wish to synchronize.
  * At lease one application/target definition is required.
  * If you have not specified a global `transit_key` in the `sanctum` section you must add the key for each target

You can get more info by running `sanctum config` and viewing the generated file.

## Roadmap
* <strike>Add vault v2 API support</strike>
* <strike>Add upgrade option for v2 API</strike>
* <strike>Better/more Tests</strike>
* <strike>Support for multiple transit_keys</strike>
* <strike>Support for global secrets_version</strike>
* Built in Backup features
* Performance optimizations
* Reorganize/cleanup code(add adapters, etc)
* Add delete command which will delete locally/remote secret

## Backup scenario.
One possible use case for sanctum is for backing up vault secrets. This feature is NOT built in yet.
The following instructions are for testing purposes only and are not recommended as an actual backup solution.
See the [Transit Secrets Engine(API)](https://www.vaultproject.io/api/secret/transit/index.html) for command reference.

1. Create a new key with, or enable `allow_plaintext_backup` and `exportable` on the transit key you are using for sanctum. **Once enabled  you cannot disable**
  * Example: `curl -v --header "X-Vault-Token: $VAULT_TOKEN" --request POST --data '{"allow_plaintext_backup": true, "exportable": true}' $VAULT_ADDR/v1/transit/keys/<my_transit_key>/config`
2. `sanctum pull` 
3. Get your transit key
  * Example: `curl -v --header "X-Vault-Token: $VAULT_TOKEN" --request GET $VAULT_ADDR/v1/transit/backup/<my_transit_key>`
4. Securely store/ backup your key.

### Restoring:
If you ever need to restore the key, you can restore using the restore endpoint
1. `curl -v --header "X-Vault-Token: $VAULT_TOKEN" --data @transit_key.json --request POST $VAULT_ADDR/v1/transit/restore/<my_transit_key>`

transit_key.json would look something like
```
{"backup":"<your_long_key>"}
```
One thing that is nice, is that you can use this method to restore to a locally running vault instance.
This would allow you to be able to quickly decrypt local secrets in a disaster recovery event.
1. run `vault server -dev`
2. export the new `VAULT_TOKEN` and `$VAULT_ADDR` variables.
3. Restore the key to your locally running vault instance.

## Development
Install [docker](https://docs.docker.com/install/) and [docker-compose](https://docs.docker.com/compose/install/)
After checking out the repo, run `docker-compose build`. To run tests run `docker-compose run --rm sanctum bundle exec rspec`.

To release a new version, `cp docker-compose.override.yml_sample docker-compose.override.yml` and add gem credentials. Update the version number in `version.rb`.
then run `docker-compose run --rm sanctum bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/CorbanR/sanctum. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
