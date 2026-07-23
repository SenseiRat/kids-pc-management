# Kid's PC Management

Infrastructure-as-code for provisioning and maintaining my child's computer. It's an Ansible
playbook that configures user accounts, networking, security hardening, screen-time limits,
approved software, and desktop layout on a single machine.

There is a severe lack of parental management software in the Linux world, which I think would be especially useful given immutable distributions like Fedora Silverblue and NixOS.  This is my attempt to build something simple, that respected my child's privacy and ability to explore while still enforcing some guardrails so that my wife and I could be engaged with him as he explored.

## Requirement: Fedora Silverblue

The target machine must already be running Fedora Silverblue before this playbook is run
against it. Download and install it from the official page:

https://fedoraproject.org/silverblue/download

This repo does not image the machine, it only configures a host that's already booted into
Silverblue with SSH reachable.

## Project status

This is a finished project built for one specific kid and one specific machine. It may get
occasional updates as needs change, but it isn't actively maintained, and it's not intended to
be a general-purpose template for other households. That said, there may be future work done such as
building on the screen-time limits, the approved app list, and application restrictions, as my child
gets older, so new tasks and vars will likely be added long after the initial setup is "done."

## Configuring the template values

Nothing in this repo runs out of the box. The real values live in files that are gitignored so
secrets and personal details never get committed. Every var file has a `.template` counterpart
checked into the repo. To configure a deployment:

1. Copy each `.template` file to its real name (dropping the `.template` suffix) and fill in the
   values:
   - `inventory/hosts.yml.template` → `inventory/hosts.yml`
   - `group_vars/all/main.yml.template` → `group_vars/all/main.yml` — child/parent/ansible
     usernames, SSH public keys, screen-time limits
   - `group_vars/all/networking.yml.template` → `group_vars/all/networking.yml` — hostname,
     Wi-Fi SSID, static IP, gateway, firewall ports
   - `group_vars/all/software_lists.yml.template` → `group_vars/all/software_lists.yml` —
     approved Flatpaks, toolbox packages, dock layout
   - `group_vars/all/budgie_panel.yml.template` → `group_vars/all/budgie_panel.yml` — desktop
     panel/applet layout
   - `group_vars/all/vault.yml.template` → `group_vars/all/vault.yml` — parent/child account
     passwords and the Wi-Fi PSK
2. Encrypt the secrets file with Ansible Vault:
   ```
   ansible-vault encrypt group_vars/all/vault.yml
   ```
3. Generate an SSH keypair for the `ansible` service account used to connect to the host, and
   save it as `.ansible_private_key` / `.ansible_public_key` in the repo root (referenced by
   `ansible.cfg` and `entrypoint.sh`). Put the public key value in `ansible_public_key` in
   `main.yml` as well, so the playbook installs it as an authorized key.
4. Save the vault password to `.ansible_vault_pass` in the repo root.
5. Install the required collections:
   ```
   ansible-galaxy collection install -r collections/requirements.yml
   ```

## Running it

`entrypoint.sh` wraps `ansible-playbook` with the inventory, vault, and key file paths already
set:

```
./entrypoint.sh check                 # dry run (--check --diff)
./entrypoint.sh run                   # apply
./entrypoint.sh run limit tag1,tag2   # apply only specific tags
./entrypoint.sh run skip tag1,tag2    # apply everything except specific tags
```

## Maintenance window

The playbook installs systemd timers on the target machine that hold it awake from **02:00 to
03:00** local time every night (`maintenance-window-start.timer` wakes the machine and inhibits
sleep; `maintenance-window-stop.timer` releases the inhibit an hour later so it can suspend
again after its normal idle timeout). This window exists specifically so the machine is
guaranteed to be online for unattended playbook runs, without staying awake around the clock.

Runs should be scheduled from the control node (not the child's machine) to land inside that
window — e.g. via cron:

```
# Run the playbook nightly at 02:15, inside the maintenance window
15 2 * * * cd /path/to/allisters-computer && ./entrypoint.sh run >> /var/log/allisters-computer.log 2>&1
```
