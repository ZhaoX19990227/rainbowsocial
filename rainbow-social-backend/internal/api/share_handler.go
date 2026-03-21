package api

import (
	"html/template"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"

	"rainbow-social-backend/internal/config"
)

type ShareHandler struct {
	cfg  *config.Config
	page *template.Template
}

type sharePageData struct {
	AppName            string
	Subtitle           string
	IOSDownloadURL     string
	AndroidDownloadURL string
	PreferredPlatform  string
}

func NewShareHandler(cfg *config.Config) *ShareHandler {
	return &ShareHandler{
		cfg:  cfg,
		page: template.Must(template.New("share").Parse(sharePageTemplate)),
	}
}

func (h *ShareHandler) Landing(c *gin.Context) {
	platform := detectPlatform(c.GetHeader("User-Agent"))
	c.Header("Content-Type", "text/html; charset=utf-8")
	_ = h.page.Execute(c.Writer, sharePageData{
		AppName:            h.cfg.AppName,
		Subtitle:           h.cfg.ShareSubtitle,
		IOSDownloadURL:     h.cfg.IOSDownloadURL,
		AndroidDownloadURL: h.cfg.AndroidDownloadURL,
		PreferredPlatform:  platform,
	})
}

func (h *ShareHandler) Download(c *gin.Context) {
	switch detectPlatform(c.GetHeader("User-Agent")) {
	case "ios":
		if strings.TrimSpace(h.cfg.IOSDownloadURL) != "" {
			c.Redirect(http.StatusFound, h.cfg.IOSDownloadURL)
			return
		}
	case "android":
		if strings.TrimSpace(h.cfg.AndroidDownloadURL) != "" {
			c.Redirect(http.StatusFound, h.cfg.AndroidDownloadURL)
			return
		}
	}
	c.Redirect(http.StatusFound, "/share")
}

func detectPlatform(userAgent string) string {
	ua := strings.ToLower(userAgent)
	switch {
	case strings.Contains(ua, "iphone"), strings.Contains(ua, "ipad"), strings.Contains(ua, "ios"):
		return "ios"
	case strings.Contains(ua, "android"):
		return "android"
	default:
		return "unknown"
	}
}

const sharePageTemplate = `<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0" />
  <meta name="apple-mobile-web-app-capable" content="yes" />
  <title>{{.AppName}} - 下载体验</title>
  <style>
    :root {
      --bg: #f7f3ff;
      --panel: rgba(255,255,255,.84);
      --text: #231b38;
      --muted: #756d90;
      --purple1: #8f4ff8;
      --purple2: #c26dff;
      --blue: #64b6ff;
      --pink: #ff9dcb;
      --line: rgba(137,100,209,.14);
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      font-family: -apple-system, BlinkMacSystemFont, "PingFang SC", "Helvetica Neue", sans-serif;
      color: var(--text);
      background:
        radial-gradient(circle at top left, rgba(194,109,255,.18), transparent 32%),
        radial-gradient(circle at bottom right, rgba(100,182,255,.18), transparent 28%),
        linear-gradient(180deg, #fbf8ff 0%, #f6f1ff 100%);
      min-height: 100vh;
    }
    .wrap {
      width: min(100%, 460px);
      margin: 0 auto;
      padding: 28px 20px 36px;
    }
    .hero {
      position: relative;
      overflow: hidden;
      border-radius: 32px;
      padding: 28px 22px 24px;
      background: linear-gradient(135deg, rgba(255,255,255,.94), rgba(245,238,255,.88));
      border: 1px solid var(--line);
      box-shadow: 0 22px 48px rgba(114,78,178,.14);
      backdrop-filter: blur(18px);
    }
    .hero:before, .hero:after {
      content: "";
      position: absolute;
      border-radius: 999px;
      filter: blur(6px);
    }
    .hero:before {
      width: 160px; height: 160px; right: -40px; top: -36px;
      background: radial-gradient(circle, rgba(194,109,255,.24), transparent 68%);
    }
    .hero:after {
      width: 180px; height: 180px; left: -44px; bottom: -80px;
      background: radial-gradient(circle, rgba(100,182,255,.18), transparent 72%);
    }
    .brand {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      padding: 8px 12px;
      border-radius: 999px;
      background: rgba(255,255,255,.82);
      color: var(--purple1);
      font-size: 14px;
      font-weight: 700;
    }
    h1 {
      margin: 16px 0 10px;
      font-size: 34px;
      line-height: 1.08;
      letter-spacing: -0.04em;
    }
    .sub {
      margin: 0;
      color: var(--muted);
      font-size: 15px;
      line-height: 1.7;
    }
    .notice {
      margin-top: 18px;
      padding: 14px 16px;
      border-radius: 22px;
      background: rgba(255,255,255,.72);
      border: 1px solid rgba(255,255,255,.8);
      color: var(--muted);
      font-size: 14px;
      line-height: 1.6;
    }
    .section {
      margin-top: 18px;
      padding: 18px;
      border-radius: 28px;
      background: var(--panel);
      border: 1px solid var(--line);
      box-shadow: 0 18px 42px rgba(114,78,178,.08);
      backdrop-filter: blur(18px);
    }
    .section h2 {
      margin: 0 0 14px;
      font-size: 19px;
    }
    .buttons {
      display: grid;
      gap: 12px;
    }
    .btn {
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 56px;
      padding: 0 18px;
      border-radius: 999px;
      text-decoration: none;
      font-weight: 700;
      font-size: 16px;
      transition: transform .15s ease;
    }
    .btn:active { transform: scale(.98); }
    .btn-primary {
      color: white;
      background: linear-gradient(135deg, var(--purple1), var(--purple2));
      box-shadow: 0 16px 28px rgba(143,79,248,.28);
    }
    .btn-secondary {
      color: var(--text);
      background: rgba(255,255,255,.9);
      border: 1px solid var(--line);
    }
    .btn-disabled {
      color: #9d97b7;
      background: rgba(255,255,255,.65);
      border: 1px dashed rgba(137,100,209,.22);
      pointer-events: none;
    }
    .tips {
      margin: 14px 0 0;
      color: var(--muted);
      font-size: 13px;
      line-height: 1.7;
    }
    .tag {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 8px 12px;
      border-radius: 999px;
      margin-top: 14px;
      background: linear-gradient(135deg, rgba(143,79,248,.12), rgba(255,157,203,.12));
      color: var(--purple1);
      font-size: 13px;
      font-weight: 700;
    }
  </style>
</head>
<body>
  <div class="wrap">
    <section class="hero">
      <div class="brand">熊猴 · 邀请体验</div>
      <h1>{{.AppName}}</h1>
      <p class="sub">{{.Subtitle}}</p>
      <div class="tag">
        {{if eq .PreferredPlatform "ios"}}当前设备：iPhone / iPad{{else if eq .PreferredPlatform "android"}}当前设备：Android{{else}}当前设备：请按系统选择下载方式{{end}}
      </div>
      <div class="notice">
        微信里打开也可以直接使用这个页面。<br />
        iPhone 走 TestFlight，Android 直接下载安装包。
      </div>
    </section>

    <section class="section">
      <h2>立即体验</h2>
      <div class="buttons">
        {{if .IOSDownloadURL}}
        <a class="btn btn-primary" href="{{.IOSDownloadURL}}">iPhone 用户：通过 TestFlight 体验</a>
        {{else}}
        <div class="btn btn-disabled">iPhone 用户：暂未配置下载链接</div>
        {{end}}

        {{if .AndroidDownloadURL}}
        <a class="btn btn-secondary" href="{{.AndroidDownloadURL}}">Android 用户：下载安装包</a>
        {{else}}
        <div class="btn btn-disabled">Android 用户：暂未配置下载链接</div>
        {{end}}
      </div>
      <p class="tips">
        如果你准备发到微信群，直接分享这个页面链接就可以。<br />
        推荐分享地址：<strong>/share</strong>，系统识别跳转地址：<strong>/download</strong>。
      </p>
    </section>
  </div>
</body>
</html>`
