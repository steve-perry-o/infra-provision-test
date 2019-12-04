# Dependencies

- Terraform v0.12.16
- An Azure account ready to use

# Infrastructure

First, put your bastion private key file inside _infra/_ directory,

```
$ cd infra/
$ terraform init && terraform apply
```

* if you don't get the bastion__public_ip_address_ for Bastion Host, then execute (see Troubleshooting):

```
$ terraform refresh
```

Connect to Bastion Host using SSH and the private key (permissions 0600):

```
$ ssh -i <bastion-private-key> bastion@<bastion-public_ip_address>
```

As *bastion* user, check if _custom_data_ for Bastion Host was successfully executed.

```
$ tail -f  /var/log/cloud-init-output.log
```

# Provisioning

A Bastion Host is created after apply Terraform. It will install the Ansible playbooks (PostgreSQL, Docker) on API and DB servers.

# Ruby Sinatra API

A Ruby Sinatra script called _config.ru_ located in _provisioning/ansible/config.ru_ is mounted as a volume.

# Troubleshooting

If *public_ip_address* in _Outputs_ is empty, wait a few minutes and then run the following command:

```
terraform refresh
```
