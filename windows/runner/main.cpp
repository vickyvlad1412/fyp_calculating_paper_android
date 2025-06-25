#include <jni.h>

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
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
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"calculating_paper", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  JavaVM* jvm = nullptr;
  JNIEnv* env = nullptr;
  JavaVMOption options[1];
  std::string classPath = "-Djava.class.path="
       R"(C:\path\to\big-math-2.3.2.jar;C:\path\to\ExpressionEvaluator.jar)";
  options[0].optionString = const_cast<char*>(classPath.c_str());

  JavaVMInitArgs vm_args = {};
  vm_args.version = JNI_VERSION_1_8;
  vm_args.nOptions = 1;
  vm_args.options = options;
  vm_args.ignoreUnrecognized = JNI_FALSE;

  if (JNI_CreateJavaVM(&jvm, reinterpret_cast<void**>(&env), &vm_args) < 0) {
    MessageBox(nullptr, L"Failed to start JVM", L"Error", MB_OK);
    // decide: abort or continue without JNI
  }



  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
