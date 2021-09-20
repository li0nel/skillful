## 0. Install Terraform

You now need Terraform to create an OrchardAI stack:

``` bash
brew install terraform
```

## 1. Init Terraform vars
In terraform.tfvars, eventually replace `aws_profile` and `aws_region` respectively to your local AWS CLI profile name and region you want to use (can be `default` or `orchardai`). You can see the list of your AWS CLI profiles in `~/.aws/credentials`

Replace `stack_name` with your project's name.

## 2. Create the stack from scratch

From the terraform directory:

``` bash
terraform init && terraform apply
```

At any time, from the terraform directory, you can retrieve all the outputs:

``` bash
terraform output
```

## 3. Deploy your Docker containers
First login to the instance to make sure to accept the SSH fingerprint.

``` bash
ssh ec2-user@$(terraform output -json | jq '.ec2.value.ec2.public_ip' | tr -d '"') -i $(terraform output -json | jq '.ec2.value.private_key_filename' | tr -d '"')
```

Then add the SSH key your SSH agent, to be able to use an SSH Docker endpoint:
```
ssh-add -K $(terraform output -json | jq '.ec2.value.private_key_filename' | tr -d '"')
```

Then update your terminal so that Docker commands will point at the EC2 instance:
```
export DOCKER_HOST=ssh://ec2-user@$(terraform output -json | jq '.ec2.value.ec2.public_ip' | tr -d '"')
```

```
cd docker

docker-compose up -d
```

:warning: Warning: Docker seems very slow when using an SSH endpoint.

A faster alternative is to manually create an SSH tunnel between your machine and the EC2 instance:
```
ssh -L localhost:2376:/var/run/docker.sock ec2-user@$(terraform output -json | jq '.ec2.value.ec2.public_ip' | tr -d '"')

export DOCKER_HOST=tcp://localhost:2376
```

## 4. Create a SSH tunnel to the EC2 instance
This will allow you to access the remote ArangoDB instance, as if it was running locally on your machine.
``` bash
ssh -nNT -L 8529:$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' arangodb):8529 ec2-user@$(terraform output -json | jq '.ec2.value.ec2.public_ip' | tr -d '"') -i $(terraform output -json | jq '.ec2.value.private_key_filename' | tr -d '"')
```

You can now connect to your ArangoDB instance locally, or over the internet through the Nginx reverse proxy and basic authentication:
```
curl $(terraform output -json | jq '.ec2.value.ec2.public_ip' | tr -d '"'):8529 -i -u john.doe:p@ssword


<!-- ## 7. Mount an existing EBS volume

Recreate a new stack and initialise the ID of your existing EBS volume in terraform.tfvars:

``` bash
volume_id = "vol-XXXXXXX"
```

It would be a good idea to create a snapshot of that volume before mounting it, just in case, in the AWS console. -->

## 8. Tear the stack down

Always remove the EBS volume from the Terraform state. By doing so, the EBS volume will not be deleted when destroying the stack

``` bash
terraform state rm module.ec2.aws_ebs_volume.volume
```

``` bash
terraform destroy
```

## 9. Switch between workspaces

https://www.terraform.io/docs/state/workspaces.html
