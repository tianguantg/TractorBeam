#include "flutter_window.h"

#include <optional>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  // Do not reveal the native window from the runner's first-frame callback.
  // Dart's startup coordinator first applies the final centered bounds and
  // then reveals the already-rendered black startup frame. Showing here would
  // expose the native creation size before window_manager applies its options.

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Prevent plugins (like window_manager) from shrinking the client area by 8px
  // on left/bottom/right. We return 0 so the client area fills the entire window
  // seamlessly, and when maximized we fit the monitor work area.
  if (message == WM_NCCALCSIZE && wparam) {
    if (IsZoomed(hwnd)) {
      HMONITOR monitor = MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST);
      if (monitor) {
        MONITORINFO monitor_info{};
        monitor_info.cbSize = sizeof(monitor_info);
        if (GetMonitorInfo(monitor, &monitor_info)) {
          auto* params = reinterpret_cast<NCCALCSIZE_PARAMS*>(lparam);
          params->rgrc[0] = monitor_info.rcWork;
        }
      }
    }
    return 0;
  }

  // Handle native window border resizing when the child window forwards WM_NCHITTEST
  if (message == WM_NCHITTEST) {
    if (!IsZoomed(hwnd)) {
      POINT pt = {static_cast<short>(LOWORD(lparam)),
                  static_cast<short>(HIWORD(lparam))};
      RECT rect;
      GetWindowRect(hwnd, &rect);

      const int border = 8;
      bool top = pt.y < rect.top + border;
      bool bottom = pt.y >= rect.bottom - border;
      bool left = pt.x < rect.left + border;
      bool right = pt.x >= rect.right - border;

      if (top && left) return HTTOPLEFT;
      if (top && right) return HTTOPRIGHT;
      if (bottom && left) return HTBOTTOMLEFT;
      if (bottom && right) return HTBOTTOMRIGHT;
      if (left) return HTLEFT;
      if (right) return HTRIGHT;
      if (bottom) return HTBOTTOM;
      if (top) {
        // Leave the window buttons area (top-right ~144px) clickable for buttons
        if (pt.x < rect.right - 144) {
          return HTTOP;
        }
      }
    }
  }

  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
