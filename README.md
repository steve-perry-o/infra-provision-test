# Dependencies

- Terraform v0.12.16
- An Azure account ready to use

# Infrastructure

First, put your bastion private key file inside _infra/_ directory,

```
$ cd infra/
$ terraform init && terraform apply
```

* if you don't get the _public_ip_address_ for Bastion Host, then execute (see Troubleshooting):

```
$ terraform refresh
```

Connect to Bastion Host using SSH and the private key (permissions 0600):

```
$ ssh -i <bastion-private-key> bastion@<bastion-public_ip_address>
```

As *root* user, check if _custom_data_ for Bastion Host was successfully executed.

```
$ sudo su
$ tail -f  /var/log/cloud-init-output.log
```

# Provisioning

A Bastion Host is created after apply Terraform. It will install the Ansible playbooks (PostgreSQL, Docker) on API and DB servers.

# Troubleshooting

If *public_ip_address* in _Outputs_ is empty, wait a few minutes and then run the following command:

```
terraform refresh
```
