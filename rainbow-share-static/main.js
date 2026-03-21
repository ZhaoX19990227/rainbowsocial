(function () {
  const config = window.APP_CONFIG || {};

  function detectPlatform() {
    const ua = navigator.userAgent.toLowerCase();
    if (ua.includes("iphone") || ua.includes("ipad") || ua.includes("ios")) {
      return "ios";
    }
    if (ua.includes("android")) {
      return "android";
    }
    return "unknown";
  }

  function setText(id, value) {
    const node = document.getElementById(id);
    if (node && value) node.textContent = value;
  }

  function setHref(id, href) {
    const node = document.getElementById(id);
    if (!node) return;
    if (href) {
      node.href = href;
      node.classList.remove("btn-disabled");
      node.removeAttribute("aria-disabled");
    } else {
      node.href = "#";
      node.classList.add("btn-disabled");
      node.setAttribute("aria-disabled", "true");
    }
  }

  function getPlatformTag(platform) {
    if (platform === "ios") return "当前设备：iPhone / iPad";
    if (platform === "android") return "当前设备：Android";
    return "当前设备：请按系统选择下载方式";
  }

  function setupSharePage() {
    setText("app-name", config.appName);
    setText("share-subtitle", config.subtitle);
    setText("platform-tag", getPlatformTag(detectPlatform()));
    setHref("ios-btn", config.iosDownloadUrl);
    setHref("android-btn", config.androidDownloadUrl);
    setHref("hero-ios-btn", config.iosDownloadUrl);
    setHref("hero-android-btn", config.androidDownloadUrl);

    const copyBtn = document.getElementById("copy-btn");
    const feedback = document.getElementById("copy-feedback");
    if (copyBtn) {
      copyBtn.addEventListener("click", async function () {
        const url = window.location.href;
        try {
          await navigator.clipboard.writeText(url);
          if (feedback) feedback.textContent = "分享链接已复制";
        } catch (error) {
          if (feedback) feedback.textContent = "复制失败，请手动复制地址栏链接";
        }
      });
    }
  }

  function setupDownloadRedirect() {
    const message = document.getElementById("redirect-message");
    if (!message) return;

    const platform = detectPlatform();
    let target = "";
    if (platform === "ios") {
      target = config.iosDownloadUrl;
      message.textContent = target
        ? "检测到你正在使用 iPhone，马上跳转到 TestFlight。"
        : "暂未配置 iPhone 下载链接，正在返回下载页。";
    } else if (platform === "android") {
      target = config.androidDownloadUrl;
      message.textContent = target
        ? "检测到你正在使用 Android，马上开始下载安装。"
        : "暂未配置 Android 下载链接，正在返回下载页。";
    } else {
      message.textContent = "未识别到你的设备系统，正在返回下载页供你手动选择。";
    }

    window.setTimeout(function () {
      window.location.href = target || config.fallbackUrl || "/index.html";
    }, 800);
  }

  if (document.getElementById("copy-btn")) {
    setupSharePage();
  }
  if (document.getElementById("redirect-message")) {
    setupDownloadRedirect();
  }
})();
