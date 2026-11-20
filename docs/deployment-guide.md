# 部署指南

## 前置条件

1. 华为云账号已开通以下服务：
   - FunctionGraph
   - APIG
   - EI (企业智能)
   - VPC

2. 即时通讯平台账号（如 Slack）

## 步骤 1：创建 Slack 应用

1. 登录 Slack API: https://api.slack.com/apps
2. 创建新应用，选择 "From scratch"
3. 配置以下权限：
   - `channels:history`
   - `chat:write:bot`
   - `files:read`
   - `files:write:user`
4. 安装应用到工作区
5. 记录以下凭据：
   - Verification Token
   - OAuth Access Token

## 步骤 2：配置环境

复制 terraform 变量示例文件：

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars
```

编辑 `terraform.tfvars`，填入实际值：

```hcl
region             = "cn-north-4"
verification_token = "your_verification_token"
access_token       = "your_oauth_access_token"
min_confidence     = 80
```

## 步骤 3：部署基础设施

```bash
cd infra
terraform init
terraform plan
terraform apply
```

## 步骤 4：获取 API 地址

部署完成后，获取 API 网关地址：

```bash
terraform output api_gateway_url
```

## 步骤 5：配置 Slack 事件订阅

1. 打开 Slack 应用的 "Event Subscriptions" 页面
2. 启用事件订阅
3. 在 "Request URL" 中填入上一步获取的 API 地址
4. 订阅 `message.channels` 事件
5. 保存设置

## 步骤 6：验证

1. 在 Slack 频道中上传图片
2. 如果图片包含不当内容，机器人会自动删除并发送通知

## 清理资源

```bash
terraform destroy
```

## 注意事项

- 确保 API 网关已配置正确的安全组规则
- 验证令牌应妥善保管，不要提交到代码仓库
- 图像审核服务按调用量结算
