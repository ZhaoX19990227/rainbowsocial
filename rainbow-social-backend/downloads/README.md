把安卓安装包放到这个目录即可通过后端直接下载。

建议文件名：
- `rainbow-social.apk`

如果你希望分享页默认跳到本地托管的安卓安装包，可以在 `.env` 里配置：

`ANDROID_DOWNLOAD_URL=/downloads/rainbow-social.apk`

然后启动后端后，分享页会直接使用这个地址。

说明：
- iPhone 仍然需要 TestFlight 链接，无法像 Android 一样直接分发安装包。
- 如果没有公网服务器，可以先在自己电脑上运行后端，再用内网穿透工具把 `http://localhost:8088/share` 暴露出去。
