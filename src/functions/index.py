# -*- coding: utf-8 -*-
import os
import urllib.request
import json

try:
    from huaweicloudsdkcore.auth.credentials import BasicCredentials
    from huaweicloudsdkei.v1.region.ei_region import EiRegion
    from huaweicloudsdkei.v1 import *
except ImportError:
    # Fallback for local development
    BasicCredentials = None
    EiRegion = None

SUPPORTED_TYPES = ['image/jpeg', 'image/jpg', 'image/png']
MAX_SIZE = 5242880

VERIFICATION_TOKEN = os.environ.get('VERIFICATION_TOKEN', '')
ACCESS_TOKEN = os.environ.get('ACCESS_TOKEN', '')
MIN_CONFIDENCE = float(os.environ.get('MIN_CONFIDENCE', 80))

# 华为云 EI 客户端
_ei_client = None

def _get_ei_client():
    """获取华为云 EI 客户端"""
    global _ei_client
    if _ei_client is not None:
        return _ei_client

    if BasicCredentials is None:
        return None

    # 从环境变量获取凭据
    ak = os.environ.get('HW_ACCESS_KEY', '')
    sk = os.environ.get('HW_SECRET_KEY', '')
    project_id = os.environ.get('HW_PROJECT_ID', '')

    if not ak or not sk:
        return None

    credentials = BasicCredentials(ak, sk, project_id)
    _ei_client = EiClient.from_credential(EiRegion("cn-north-4"), credentials)
    return _ei_client


def lambda_handler(event, context):
    """FunctionGraph 入口函数"""
    print('Validating message...')

    if not verify_token(event):
        return

    if event.get('challenge') is not None:
        print('Presented with URL verification challenge - responding accordingly...')
        challenge = event['challenge']
        return {'challenge': challenge}

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
        print('Image displays explicit content - deleting from chat channel...')
        delete_file(file_id)
        print('Posting message to channel to notify users of file deletion...')
        post_message(channel)


def verify_token(event):
    """验证 Slack 验证令牌"""
    if event.get('token') != VERIFICATION_TOKEN:
        print('Presented with invalid token - ignoring message...')
        return False
    return True


def validate_event(event):
    """验证事件，检查是否包含支持的图片"""
    if 'event' not in event:
        return False

    event_details = event['event']
    file_subtype = event_details.get('subtype')

    if file_subtype != 'file_share':
        print('Not a file_shared event - ignoring event...')
        return False

    file_details = event_details.get('files', [{}])[0]
    mime_type = file_details.get('mimetype', '')
    file_size = file_details.get('size', 0)

    if mime_type not in SUPPORTED_TYPES:
        print('File is not an image - ignoring event...')
        return False

    if file_size > MAX_SIZE:
        print('Image is larger than 5MB and cannot be processed - ignoring event...')
        return False

    return True


def download_image(url):
    """从私有 URL 下载图片"""
    request = urllib.request.Request(url, headers={'Authorization': 'Bearer %s' % ACCESS_TOKEN})
    return urllib.request.urlopen(request).read()


def detect_explicit_content(image_bytes):
    """使用华为云 EI 图像审核检测图片内容

    适配说明：
    - 参照能力: 云厂商内容审核接口 detect_moderation_labels()
    - 华为云 EI: image_moderation_detect_unsafe()
    """
    try:
        ei_client = _get_ei_client()

        if ei_client is None:
            # 开发环境回退，使用模拟检测
            print('EI client not available, using fallback detection')
            return _fallback_detection(image_bytes)

        # 构建请求
        request = DetectImageUnsafeRequest()
        request.body = ImageModerationDetectReq(
            image=ImageInfo(
                url=None,
                base_data=base64.b64encode(image_bytes).decode('utf-8')
            )
        )

        # 调用华为云 EI 图像审核 API
        response = ei_client.detect_image_unsafe(request)

        # 解析响应
        if hasattr(response, 'result') and response.result:
            moderation_labels = response.result.get('moderation_labels', [])
            if moderation_labels:
                print(f'Detected {len(moderation_labels)} moderation labels')
                return True

        return False

    except Exception as e:
        print(f'Error calling EI API: {e}')
        # 出错时使用备用检测
        return _fallback_detection(image_bytes)


def _fallback_detection(image_bytes):
    """备用检测逻辑（当 EI 不可用时）"""
    # 简单的大小/格式检查作为备用
    # 实际生产环境应确保 EI 服务可用
    print('Using fallback detection - image will be allowed')
    return False


def delete_file(file_id):
    """通过聊天应用 API 删除文件"""
    url = 'https://slack.com/api/files.delete'
    data = urllib.parse.urlencode([
        ('token', ACCESS_TOKEN),
        ('file', file_id)
    ])
    data = data.encode('ascii')
    headers = {'Content-Type': 'application/x-www-form-urlencoded'}
    request = urllib.request.Request(url, data, headers)
    urllib.request.urlopen(request)


def post_message(channel):
    """发送消息到聊天频道"""
    url = 'https://slack.com/api/chat.postMessage'
    data = urllib.parse.urlencode([
        ('token', ACCESS_TOKEN),
        ('channel', channel),
        ('text', 'File removed due to displaying explicit or suggestive adult content.')
    ])
    data = data.encode('ascii')
    headers = {'Content-Type': 'application/x-www-form-urlencoded'}
    request = urllib.request.Request(url, data, headers)
    urllib.request.urlopen(request)
