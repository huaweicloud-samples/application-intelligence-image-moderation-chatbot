terraform {
  required_version = ">= 1.5"

  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = "1.96.0"
    }
  }
}

provider "huaweicloud" {
  region = var.region
}

data "huaweicloud_availability_zones" "main" {}

# ============================================================================
# 基础网络层
# ============================================================================

resource "huaweicloud_vpc" "main" {
  name                  = "${var.project_name}-vpc"
  cidr                  = "10.0.0.0/16"
  enterprise_project_id = "0"
}

resource "huaweicloud_vpc_subnet" "main" {
  name       = "${var.project_name}-subnet"
  vpc_id     = huaweicloud_vpc.main.id
  cidr       = "10.0.1.0/24"
  gateway_ip = "10.0.1.1"
}

resource "huaweicloud_networking_secgroup" "main" {
  name        = "${var.project_name}-sg"
  description = "Security group for image moderation service"
}

resource "huaweicloud_networking_secgroup_rule" "allow_https" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = huaweicloud_networking_secgroup.main.id
}

resource "huaweicloud_networking_secgroup_rule" "allow_http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = huaweicloud_networking_secgroup.main.id
}

# ============================================================================
# IAM 委托
# ============================================================================

resource "huaweicloud_identity_agency" "functiongraph" {
  name                   = "${var.project_name}-fgs-agency"
  description            = "Agency for FunctionGraph"
  duration               = "FOREVER"
  delegated_service_name = "op_svc_cff"

  project_role {
    project = var.region
    roles = [
      "OBS OperateAccess",
    ]
  }
}

# ============================================================================
# FunctionGraph 函数层
# ============================================================================

resource "huaweicloud_fgs_function" "image_moderator" {
  name        = "${var.project_name}-image-moderator"
  app         = "default"
  agency      = huaweicloud_identity_agency.functiongraph.name
  handler     = "index.lambda_handler"
  memory_size = 256
  timeout     = 30
  runtime     = "Python3.9"

  code_type = "inline"
  func_code = <<-EOF
# -*- coding: utf-8 -*-
import os
import urllib.request
import json
import base64

try:
    from huaweicloudsdkcore.auth.credentials import BasicCredentials
    from huaweicloudsdkei.v1.region.ei_region import EiRegion
    from huaweicloudsdkei.v1 import *
except ImportError:
    BasicCredentials = None
    EiRegion = None

SUPPORTED_TYPES = ['image/jpeg', 'image/jpg', 'image/png']
MAX_SIZE = 5242880

VERIFICATION_TOKEN = os.environ.get('VERIFICATION_TOKEN', '')
ACCESS_TOKEN = os.environ.get('ACCESS_TOKEN', '')
MIN_CONFIDENCE = float(os.environ.get('MIN_CONFIDENCE', 80))

_ei_client = None

def _get_ei_client():
    global _ei_client
    if _ei_client is not None:
        return _ei_client

    if BasicCredentials is None:
        return None

    ak = os.environ.get('HW_ACCESS_KEY', '')
    sk = os.environ.get('HW_SECRET_KEY', '')
    project_id = os.environ.get('HW_PROJECT_ID', '')

    if not ak or not sk:
        return None

    credentials = BasicCredentials(ak, sk, project_id)
    _ei_client = EiClient.from_credential(EiRegion("cn-north-4"), credentials)
    return _ei_client

def lambda_handler(event, context):
    print('Validating message...')

    if not verify_token(event):
        return

    if event.get('challenge') is not None:
        print('URL verification challenge')
        return {'challenge': event['challenge']}

    if not validate_event(event):
        return

    event_details = event['event']
    file_details = event_details['files'][0]

    channel = event_details['channel']
    url = file_details['url_private']
    file_id = file_details['id']

    print('Downloading image...')
    image_bytes = download_image(url)

    print('Checking image for explicit content...')
    is_explicit = detect_explicit_content(image_bytes)

    if is_explicit:
        print('Image displays explicit content - deleting...')
        delete_file(file_id)
        print('Posting notification message...')
        post_message(channel)

def verify_token(event):
    if event.get('token') != VERIFICATION_TOKEN:
        print('Invalid token')
        return False
    return True

def validate_event(event):
    if 'event' not in event:
        return False
    event_details = event['event']
    if event_details.get('subtype') != 'file_share':
        return False
    file_details = event_details.get('files', [{}])[0]
    mime_type = file_details.get('mimetype', '')
    file_size = file_details.get('size', 0)
    if mime_type not in SUPPORTED_TYPES:
        return False
    if file_size > MAX_SIZE:
        return False
    return True

def download_image(url):
    request = urllib.request.Request(url, headers={'Authorization': 'Bearer %s' % ACCESS_TOKEN})
    return urllib.request.urlopen(request).read()

def detect_explicit_content(image_bytes):
    try:
        ei_client = _get_ei_client()
        if ei_client is None:
            print('EI client not available')
            return False

        request = DetectImageUnsafeRequest()
        request.body = ImageModerationDetectReq(
            image=ImageInfo(
                url=None,
                base_data=base64.b64encode(image_bytes).decode('utf-8')
            )
        )

        response = ei_client.detect_image_unsafe(request)
        if hasattr(response, 'result') and response.result:
            moderation_labels = response.result.get('moderation_labels', [])
            if moderation_labels:
                print(f'Detected {len(moderation_labels)} moderation labels')
                return True
        return False
    except Exception as e:
        print(f'Error: {e}')
        return False

def delete_file(file_id):
    url = 'https://slack.com/api/files.delete'
    data = urllib.parse.urlencode([('token', ACCESS_TOKEN), ('file', file_id)])
    data = data.encode('ascii')
    headers = {'Content-Type': 'application/x-www-form-urlencoded'}
    urllib.request.urlopen(urllib.request.Request(url, data, headers))

def post_message(channel):
    url = 'https://slack.com/api/chat.postMessage'
    data = urllib.parse.urlencode([
        ('token', ACCESS_TOKEN),
        ('channel', channel),
        ('text', 'File removed due to displaying explicit content.')
    ])
    data = data.encode('ascii')
    headers = {'Content-Type': 'application/x-www-form-urlencoded'}
    urllib.request.urlopen(urllib.request.Request(url, data, headers))
EOF

  tags = {
    project = var.project_name
  }
}

# ============================================================================
# API 层 - APIG
# ============================================================================

resource "huaweicloud_apig_instance" "main" {
  name              = "${var.project_name}-apig-v2"
  edition           = "BASIC"
  vpc_id            = huaweicloud_vpc.main.id
  subnet_id         = huaweicloud_vpc_subnet.main.id
  security_group_id = huaweicloud_networking_secgroup.main.id
  maintain_begin    = "06:00:00"
  bandwidth_size    = 5

  available_zones = [
    data.huaweicloud_availability_zones.main.names[0],
    data.huaweicloud_availability_zones.main.names[1],
  ]

  tags = {
    project = var.project_name
  }
}

resource "huaweicloud_apig_group" "main" {
  name        = "${var.project_name}-api-group"
  instance_id = huaweicloud_apig_instance.main.id
}

resource "huaweicloud_apig_environment" "main" {
  name        = "prod"
  instance_id = huaweicloud_apig_instance.main.id
}

resource "huaweicloud_apig_api" "image_moderator_api" {
  name             = "${var.project_name}-api-v2"
  group_id         = huaweicloud_apig_group.main.id
  instance_id      = huaweicloud_apig_instance.main.id
  type             = "FunctionGraph"
  request_method   = "POST"
  request_path     = "/"
  request_protocol = "HTTPS"

  func_graph {
    function_urn     = huaweicloud_fgs_function.image_moderator.urn
    invocation_type  = "sync"
    network_type     = "V1"
    request_protocol = "HTTPS"
    version          = "latest"
    timeout          = 5000
  }

  tags = [var.project_name]
}

resource "huaweicloud_apig_api_publishment" "image_moderator_publish" {
  instance_id = huaweicloud_apig_instance.main.id
  api_id      = huaweicloud_apig_api.image_moderator_api.id
  env_id      = huaweicloud_apig_environment.main.id
}

# ============================================================================
# 输出
# ============================================================================

output "api_url" {
  description = "API Gateway URL for Slack webhook"
  value       = "https://${huaweicloud_apig_instance.main.ingress_address}/"
}

output "function_urn" {
  description = "FunctionGraph function URN"
  value       = huaweicloud_fgs_function.image_moderator.urn
}
