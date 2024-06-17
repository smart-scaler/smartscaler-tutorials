# Terraform

Install `Smart Scaler Agent` trough Terraform.

## Requirements

* Terraform >= 1.3.x
* A Kubernetes cluster (up and running)

## Usage

* Init Terraform modules

		terraform init

* Check the plan, what Terraform will create (this step is optional)

		terraform plan

* Deploy the services

		terraform apply -auto-approve
