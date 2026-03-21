# 熊猴分享页（Vercel 静态版）

这个目录可以直接部署到 Vercel，不需要你自己的后端服务器。

## 你只需要改 1 个文件

编辑：

- `config.js`

把下面两个值填上：

- `iosDownloadUrl`
- `androidDownloadUrl`

示例：

```js
window.APP_CONFIG = {
  appName: "熊猴",
  subtitle: "给想认真认识彼此的人，一个更轻松也更有感觉的开始。",
  iosDownloadUrl: "https://testflight.apple.com/join/xxxxxxx",
  androidDownloadUrl: "https://your-domain.com/rainbow-social.apk",
  fallbackUrl: "/index.html"
};
```

## 部署到 Vercel

### 方法 1：直接导入这个目录所在仓库

1. 把仓库推到 GitHub
2. 打开 [Vercel](https://vercel.com/)
3. `Add New...` -> `Project`
4. 选择这个仓库
5. Root Directory 选择：

```text
rainbow-share-static
```

6. 直接部署

### 方法 2：单独把这个目录上传成一个静态项目

把 `rainbow-share-static` 单独建成仓库也可以。

## 你部署前至少要准备什么

### iPhone 下载地址

填 TestFlight 公链，例如：

```text
https://testflight.apple.com/join/xxxxxxx
```

### Android 下载地址

填一个 APK 公网直链，例如：

```text
https://你的域名/rainbow-social.apk
```

如果你暂时还没有 Android 下载地址，也可以先只填 iPhone 的，Android 按钮会保持不可用状态。

## 部署后你会得到两个地址

- 首页分享页：`https://你的域名/`
- 自动分流页：`https://你的域名/download`

建议群里分享首页地址。

## 说明

- iPhone 用户还是要跳 TestFlight
- Android 用户可以跳 APK 直链
- 如果你暂时没有 iPhone 或 Android 的下载地址，对应按钮会显示成不可用
- `download` 页面会根据设备尝试自动跳转
- 首页更适合分享给微信群，信息更完整
