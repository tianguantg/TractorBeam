#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Prevent multiple concurrent instances. If an instance already exists,
  // restore and bring its window to the foreground, then exit.
  HANDLE single_instance_mutex = ::CreateMutexW(
      nullptr, TRUE, L"Local\\TractorBeam_App_SingleInstance_Mutex");
  if (single_instance_mutex != nullptr &&
      ::GetLastError() == ERROR_ALREADY_EXISTS) {
    HWND existing_hwnd =
        ::FindWindowW(L"TRACTOR_BEAM_RUNNER_WIN32_WINDOW", nullptr);
    if (existing_hwnd != nullptr) {
      ::ShowWindow(existing_hwnd, SW_SHOW);
      ::ShowWindow(existing_hwnd, SW_RESTORE);
      ::SetForegroundWindow(existing_hwnd);
    }
    ::CloseHandle(single_instance_mutex);
    return EXIT_SUCCESS;
  }

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  // Keep the native backing surface identical to the Flutter design window.
  // window_manager centers it before explicitly revealing the startup frame.
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(960, 824);
  if (!window.Create(L"Tractor Beam", origin, size)) {
    if (single_instance_mutex != nullptr) {
      ::ReleaseMutex(single_instance_mutex);
      ::CloseHandle(single_instance_mutex);
    }
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  if (single_instance_mutex != nullptr) {
    ::ReleaseMutex(single_instance_mutex);
    ::CloseHandle(single_instance_mutex);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
