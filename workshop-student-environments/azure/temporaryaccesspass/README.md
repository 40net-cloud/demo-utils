# Service Principal Setup for Temporary Access Pass Automation

Reference notes for setting up the identity used by `create-tap.sh` (and any
other Graph automation for the workshop student environments).

## 1. Create the service principal

If you don't already have one for this automation:

```bash
az ad app create --display-name "workshop-student-tap-automation" --query appId -o tsv
```

Save the returned `appId` — you'll need it for every step below.

```bash
APP_ID="<appId from above>"

az ad sp create --id $APP_ID
az ad sp credential reset --id $APP_ID --years 1
```

`az ad sp credential reset` prints a `password` (client secret) — save it
securely (e.g. a secrets manager or CI/CD secret store). It's only shown once.

> If you already have a service principal that Terraform uses (via
> `ARM_CLIENT_ID` / `ARM_CLIENT_SECRET`), reuse it instead of creating a new
> one — just add the permissions below to it.

## 2. Grant Microsoft Graph application permissions

Two application (app-only) permissions are needed against Microsoft Graph
(resource app ID `00000003-0000-0000-c000-000000000000`):

| Permission | App role ID | Needed for |
|---|---|---|
| `UserAuthenticationMethod.ReadWrite.All` | `50483e42-d915-4231-9639-7fdb7fd190e5` | Creating the TAP |
| `User.Read.All` | `df021288-bdef-4463-88db-98f22de89214` | Looking up user object IDs (`az ad user show`) |

Add both:

```bash
az ad app permission add --id $APP_ID \
  --api 00000003-0000-0000-c000-000000000000 \
  --api-permissions 50483e42-d915-4231-9639-7fdb7fd190e5=Role

az ad app permission add --id $APP_ID \
  --api 00000003-0000-0000-c000-000000000000 \
  --api-permissions df021288-bdef-4463-88db-98f22de89214=Role
```

`=Role` marks these as **application** permissions (app roles), not
delegated scopes — required for the non-interactive, app-only auth this
script uses.

## 3. Grant admin consent

Must be run by an identity holding Global Administrator, Privileged Role
Administrator, or Cloud Application Administrator:

```bash
az ad app permission admin-consent --id $APP_ID
```

**Verify it actually took effect** — this command can fail silently if the
caller didn't have sufficient rights. Check in the portal:
Entra ID → App registrations → *(your app)* → API permissions. Both
permissions should show a green "Granted for `<tenant>`" status. If not,
click **Grant admin consent for `<tenant>`** there directly.

## 4. Log in as the service principal

```bash
az login --service-principal \
  -u $APP_ID \
  -p "$AZURE_CLIENT_SECRET" \
  --tenant "$AZURE_TENANT_ID" \
  --allow-no-subscriptions
```

- `--allow-no-subscriptions` avoids the harmless "No subscriptions found"
  message — this SP only needs Graph/directory rights, not ARM subscription
  roles.
- Confirm the right identity is active: `az account show --query user`
  should show `appId` under `user.name` with `user.type: servicePrincipal`.
- **Always log in fresh (or `az logout` first) after changing permissions.**
  Azure CLI caches tokens, so a permission granted mid-session won't be
  reflected until you re-authenticate.

## 5. Discovering APP_ID, APP_SECRET, and TENANT_ID via the CLI

If you already have the service principal set up but don't have these
values handy:

**TENANT_ID** — works from any logged-in session (user or SP):

```bash
az account show --query tenantId -o tsv
```

**APP_ID** — look it up by the app's display name:

```bash
az ad app list --display-name "workshop-student-tap-automation" \
  --query "[].appId" -o tsv
```

Or, if you only know the service principal (not the app registration)
display name:

```bash
az ad sp list --display-name "workshop-student-tap-automation" \
  --query "[].appId" -o tsv
```

**APP_SECRET** — this is the one value you can't retrieve after the fact.
Entra ID never stores or returns the plaintext secret again once it's
created; only a hash is kept server-side. You can list *metadata* about
existing secrets (to see if one exists and when it expires) but not the
value itself:

```bash
az ad app credential list --id $APP_ID \
  --query "[].{keyId:keyId, expires:endDateTime}" -o table
```

If you don't have the plaintext secret saved somewhere secure already, the
only option is to issue a new one — this doesn't remove existing valid
secrets unless you explicitly target one, but it's good practice to prune
old/unused ones from the list above:

```bash
az ad app credential reset --id $APP_ID --years 1 \
  --query password -o tsv
```

> Note: `az ad sp credential reset` (used in step 1) and
> `az ad app credential reset` both work here — the `sp` form manages
> credentials on the service principal object, the `app` form manages them
> on the app registration object. For most setups either works, but if
> you're unsure which one your existing secret was created against, `az ad
> app credential reset` is the more commonly documented path.

## Prerequisites this doesn't cover

- Temporary Access Pass must be enabled tenant-wide:
  Entra ID → Security → Authentication methods → Temporary Access Pass.
- Permission changes can take a few minutes to propagate tenant-wide even
  after a successful consent.