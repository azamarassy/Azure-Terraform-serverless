# Azure Serverless Application with Terraform

This repository contains Terraform configurations to deploy a serverless application on Microsoft Azure. The architecture leverages Azure Front Door for global routing and WAF protection, Azure API Management for API gateway capabilities, an Azure Function App for backend logic, and Azure Blob Storage for static website hosting.

## Table of Contents

*   [1. Architecture Overview](#1-architecture-overview)
*   [2. Key Azure Services Used](#2-key-azure-services-used)
*   [3. Features](#3-features)
*   [4. Prerequisites](#4-prerequisites)
*   [5. Deployment Guide](#5-deployment-guide)
*   [6. Outputs](#6-outputs)
*   [7. Cleanup](#7-cleanup)
*   [8. References](#8-references)

## 1. Architecture Overview

The deployed architecture provides a scalable, secure, and efficient way to host a static website with a serverless API backend.

![Azure Architecture Diagram](Lambda構成図.jpg)
_Note: The diagram currently shows an AWS Lambda architecture. This should be updated to reflect the Azure services._

## 2. Key Azure Services Used

*   **Azure Front Door Premium:** Global, scalable entry-point for web applications, providing WAF protection, content delivery, and intelligent routing.
*   **Azure API Management:** Manages, publishes, secures, and analyzes APIs, acting as a facade for backend services.
*   **Azure Function App:** Serverless compute service for running event-driven code without managing infrastructure.
*   **Azure Blob Storage (Static Website Hosting):** Cost-effective and scalable storage for hosting static web content.
*   **Azure DNS:** Hosts DNS domains, providing name resolution for the application's custom domain.
*   **Azure Resource Group:** A logical container for Azure resources.
*   **Azure Storage Account (for Function App & Terraform State):** Provides durable storage for the Function App's runtime and for Terraform's state file.
*   **Azure Application Insights:** Application Performance Management (APM) service for monitoring the Function App.

## 3. Features

*   **Global Traffic Management:** Azure Front Door intelligently routes user requests to the nearest healthy backend.
*   **Web Application Firewall (WAF) Protection:** Integrated WAF in Azure Front Door Premium protects against common web vulnerabilities and DDoS attacks.
*   **API Gateway with Policy Enforcement:** Azure API Management provides a centralized gateway for APIs, enabling security, caching, rate limiting, and request/response transformations.
*   **Serverless Backend:** Azure Function App executes backend logic efficiently, scaling automatically with demand.
*   **Static Website Hosting:** Cost-effective and high-performance hosting for front-end assets using Azure Blob Storage.
*   **Custom Domain Support:** Configured with Azure DNS for custom domain resolution.
*   **Infrastructure as Code (IaC):** Entire infrastructure defined and deployed using Terraform for consistency and repeatability.
*   **Managed Identities:** Secure access between Azure services using System-Assigned Managed Identities.

## 4. Prerequisites

Before deploying this infrastructure, ensure you have the following installed and configured:

*   [Terraform CLI](https://developer.hashicorp.com/terraform/downloads) (v1.0.0 or later recommended)
*   [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) (or Azure PowerShell)
*   An Azure subscription
*   Properly configured Azure credentials for Terraform (e.g., by running `az login`)

## 5. Deployment Guide

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/azamarassy/Azure-Terraform-serverless.git
    cd Azure-Terraform-serverless
    ```

2.  **Initialize Terraform:**
    First, you need to create the resource group and storage account for Terraform's state manually or by running a partial apply.
    ```bash
    # Ensure you are logged into Azure CLI (az login)

    # You might need to manually create the resource group for the tfstate storage account if it doesn't exist.
    # az group create --name <your-tfstate-resource-group-name> --location <your-location>

    # Run terraform init to download provider plugins.
    terraform init
    ```

    **Note on Backend Configuration:** The `main.tf` contains a commented-out backend configuration block for `azurerm`. Once the `azurerm_storage_account.tfstate` and `azurerm_storage_container.tfstate` resources are successfully created by a `terraform apply`, you should uncomment this block in `main.tf` and replace the placeholder values with the actual names of the resource group, storage account, and container. This is crucial for remote state management.

3.  **Plan the deployment:**
    ```bash
    terraform plan -out main.tfplan
    ```
    Review the proposed changes.

4.  **Apply the deployment:**
    ```bash
    terraform apply "main.tfplan"
    ```
    Type `yes` when prompted to confirm the deployment.

5.  **Configure Custom Domain (Optional but Recommended):**
    If you're using a custom domain, you need to update your domain registrar's NS records to point to the nameservers provided by Azure DNS (see `Outputs` section).

## 6. Outputs

After a successful `terraform apply`, the following important outputs will be displayed:

*   `resource_group_name`: The name of the Azure Resource Group.
*   `api_management_gateway_url`: The URL of the Azure API Management gateway.
*   `function_app_default_hostname`: The default hostname of the Azure Function App.
*   `front_door_frontend_endpoint_host_name`: The hostname of the Azure Front Door frontend endpoint.
*   `static_website_endpoint`: The primary web endpoint for the static website.
*   `dns_zone_name`: The name of the Azure DNS Zone.
*   `dns_zone_nameservers`: The nameservers for the Azure DNS Zone (important for custom domain configuration).
*   `api_management_subscription_primary_key`: The primary key for the API Management Starter subscription (sensitive).

## 7. Cleanup

To destroy all the deployed resources:

```bash
terraform destroy
```
Type `yes` when prompted to confirm the destruction.

## 8. References

*   [Azure Front Door Documentation](https://learn.microsoft.com/en-us/azure/frontdoor/)
*   [Azure API Management Documentation](https://learn.microsoft.com/en-us/azure/api-management/)
*   [Azure Functions Documentation](https://learn.microsoft.com/en-us/azure/azure-functions/)
*   [Azure Blob Storage (Static Websites) Documentation](https://learn.microsoft.com/en-us/azure/storage/blobs/storage-blob-static-website)
*   [Azure DNS Documentation](https://learn.microsoft.com/en-us/azure/dns/)
*   [Terraform AzureRM Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)