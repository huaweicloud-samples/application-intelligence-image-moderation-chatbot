# Image Moderation Chatbot

[中文版](./README.cn.md)

[![Huawei Cloud](https://img.shields.io/badge/Huawei_Cloud-FunctionGraph-blue)](https://www.huaweicloud.com/product/functiongraph.html)
[![APIG](https://img.shields.io/badge/Huawei_Cloud-APIG-blue)](https://www.huaweicloud.com/product/apig.html)
[![EI](https://img.shields.io/badge/Huawei_Cloud-EI_Image_Moderation-blue)](https://www.huaweicloud.com/product/ei.html)

## Overview

This project is a **serverless image moderation chatbot** solution for instant messaging platforms (such as Slack, DingTalk, WeCom, etc.). Built on Huawei Cloud FunctionGraph, APIG, and EI Image Moderation services, when users upload images to a channel, the system automatically:

1. **Download Image** - Fetch the uploaded image content via the IM platform API
2. **Content Moderation** - Invoke Huawei Cloud EI Image Moderation service for deep learning analysis
3. **Automated Action** - If inappropriate content (pornography, violence, terrorism, etc.) is detected, automatically delete the image and notify relevant personnel

### Use Cases

- Content compliance management for enterprise internal communication platforms
- Image content moderation for community forums
- Sensitive information filtering for customer service systems
- Image quality management for team collaboration tools

### Technical Features

- **Serverless Architecture**: no server management, settled per invocation volume, controllable spend
- **Real-time Response**: Image upload triggers moderation process, millisecond-level response
- **Intelligent Recognition**: Based on Huawei Cloud EI deep learning models, high recognition accuracy
- **Out-of-the-box**: One-click deployment with Terraform, quick go-live

## Features

- Real-time Image Moderation: Automatically detect images uploaded to channels
- Intelligent Content Recognition: Deep learning-based content analysis
- Automated Processing: Automatically delete and notify when inappropriate content is detected
- Flexible Configuration: Adjustable moderation confidence threshold

## Architecture Overview

```
User uploads image → APIG → FunctionGraph → EI Image Moderation
                                             ↓
                                       Check Result
                                             ↓
                                 Delete Image + Send Notification
```

## Prerequisites

- Huawei Cloud account
- Instant messaging platform account (e.g., Slack)
- Python 3.9+
- Terraform 1.0+

## ⚠️ Service Activation Guide

Some services in this project require **manual activation** (no API, must be done in console):

| Service | Activation | Settlement | Notes |
|---------|------------|------|-------|
| **EI Image Moderation** | Console → EI → Image Moderation → Activate | Free | Must activate, otherwise function calls will fail |
| **FunctionGraph** | Pay-per-use, no activation needed | Pay-per-call | Requires real-name authentication for first use |
| **APIG** | Pay-per-use, no activation needed | Pay-per-call | Dedicated instance requires account balance |
| **VPC** | Pay-per-use, no activation needed | Pay-per-traffic | Requires real-name authentication for first use |

### Activation Steps

1. Log in to [Huawei Cloud Console](https://console.huaweicloud.com)
2. Go to **EI Enterprise Intelligence** → **Image Moderation**
3. Click "Activate Service" (Free)
4. Ensure the activated region matches the deployment region (recommended: `cn-north-4`)

## Quick Start

### 1. Clone the Repository

```bash
git clone <repository-url>
cd huaweicloud/application-intelligence-image-moderation-chatbot
```

### 2. Configure Credentials

Create `infra/terraform.tfvars`:

```hcl
region             = "cn-north-4"
verification_token = "your_slack_verification_token"
access_token       = "your_slack_oauth_token"
min_confidence     = 80
```

### 3. Deploy

```bash
cd infra
terraform init
terraform apply
```

### 4. Get API Address

```bash
terraform output api_gateway_url
```

### 5. Configure Instant Messaging Platform

Configure the API address obtained in the previous step to the Slack app's event subscription.

## Usage

### Basic Flow

1. User uploads an image to the channel
2. System automatically downloads and moderates the image
3. If inappropriate content is detected:
   - Automatically delete the image
   - Send notification message to the channel

### Parameter Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| MIN_CONFIDENCE | Moderation confidence threshold | 80 |

## Verification Example

Upload test images to the configured channel, and the system will automatically perform moderation processing.

## Cloud Services Involved

- FunctionGraph: Serverless function computing
- APIG: API Gateway
- EI: Enterprise Intelligence - Image Moderation
- VPC: Virtual Private Cloud

## License

MIT No Attribution

## Contact

For issues, please submit an Issue.
