# 图像审核聊天机器人

[English](./README.md)

[![华为云](https://img.shields.io/badge/华为云-FunctionGraph-blue)](https://www.huaweicloud.com/product/functiongraph.html)
[![APIG](https://img.shields.io/badge/华为云-APIG-blue)](https://www.huaweicloud.com/product/apig.html)
[![EI](https://img.shields.io/badge/华为云-EI图像审核-blue)](https://www.huaweicloud.com/product/ei.html)

## 简介

本项目是一个面向即时通讯平台（如 Slack、钉钉、企业微信等）的**无服务器图片审核聊天机器人**解决方案。基于华为云 FunctionGraph、APIG 和 EI 图像审核服务构建，当用户上传图片到频道时，系统会自动：

1. **下载图片** - 通过即时通讯平台 API 获取用户上传的图片内容
2. **内容审核** - 调用华为云 EI 图像审核服务进行深度学习分析
3. **自动处理** - 如果检测到不当内容（色情、暴力、恐怖等），自动删除图片并通知相关人员

### 适用场景

- 企业内部沟通平台的内容合规管理
- 社区论坛的图片内容审核
- 在线客服系统的敏感信息过滤
- 团队协作工具的图片质量管理

### 技术特点

- **无服务器架构**：无需管理服务器，按调用量结算，费用可控
- **实时响应**：图片上传即触发审核流程，毫秒级响应
- **智能识别**：基于华为云 EI 深度学习模型，识别准确率高
- **开箱即用**：Terraform 一键部署，快速上线

## 功能特性

- 实时图片审核：自动检测上传到频道的图片
- 智能内容识别：基于深度学习的内容分析
- 自动处理：检测到不当内容时自动删除并通知
- 灵活配置：可调整审核置信度阈值

## 架构概览

```
用户上传图片 → APIG → FunctionGraph → EI 图像审核
                                    ↓
                              检测结果判断
                                    ↓
                        删除图片 + 发送通知
```

## 前置条件

- 华为云账号
- 即时通讯平台账号（如 Slack）
- Python 3.9+
- Terraform 1.0+

## ⚠️ 服务开通说明

本项目部分服务需要**手动开通**（无 API，只能在控制台操作）：

| 服务 | 开通方式 | 结算 | 备注 |
|------|----------|------|------|
| **EI 图像审核** | 华为云控制台 → EI → 图像审核 → 开通 | 不单独收费 | 必须开通，否则函数调用会报错 |
| **FunctionGraph** | 按量付费，无需开通 | 按调用量结算 | 首次使用需完成实名认证 |
| **APIG** | 按量付费，无需开通 | 按调用量结算 | 专享实例需账户有余额 |
| **VPC** | 按量付费，无需开通 | 按流量结算 | 首次使用需完成实名认证 |

### 开通步骤

1. 登录 [华为云控制台](https://console.huaweicloud.com)
2. 进入 **EI 企业智能** → **图像审核**
3. 点击「开通服务」
4. 确认开通区域与部署区域一致（推荐 `华北四 cn-north-4`）

## 快速开始

### 1. 克隆仓库

```bash
git clone <repository-url>
cd huaweicloud/application-intelligence-image-moderation-chatbot
```

### 2. 配置凭据

创建 `infra/terraform.tfvars`：

```hcl
region             = "cn-north-4"
verification_token = "your_slack_verification_token"
access_token       = "your_slack_oauth_token"
min_confidence     = 80
```

### 3. 部署

```bash
cd infra
terraform init
terraform apply
```

### 4. 获取 API 地址

```bash
terraform output api_gateway_url
```

### 5. 配置即时通讯平台

将上一步获取的 API 地址配置到 Slack 应用的事件订阅中。

## 使用方法

### 基本流程

1. 用户在频道中上传图片
2. 系统自动下载并审核图片
3. 如果检测到不当内容：
   - 自动删除图片
   - 发送通知消息到频道

### 参数配置

| 参数 | 说明 | 默认值 |
|------|------|--------|
| MIN_CONFIDENCE | 审核置信度阈值 | 80 |

## 验证示例

上传测试图片到配置的频道，系统将自动进行审核处理。

## 涉及云服务

- FunctionGraph：无服务器函数计算
- APIG：API 网关
- EI：企业智能 - 图像审核
- VPC：虚拟私有云

## 许可证

MIT No Attribution

## 联系方式

如有问题，请提交 Issue。
