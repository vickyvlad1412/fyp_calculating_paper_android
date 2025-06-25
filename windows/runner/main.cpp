#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "expression_evaluator.h"

#include <memory>
#include <sstream>
#include <string>
#include <map>

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

  auto registrar = window.GetRegistrar();
  auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
     registrar->messenger(),
     "calculating_paper/calculation",
     &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler(
    [](auto& call, auto result){
      if (call.method_name()=="evaluateExpression") {
        auto args = std::get_if<flutter::EncodableMap>(call.arguments());
        if (!args) {
          result->Error("INVALID_ARGUMENTS","need map");
          return;
        }
        std::string expr;
        int prec= Provider::of<…>(); // you get precision from args map
        auto itE = args->find(flutter::EncodableValue("expression"));
        if(itE!=args->end())
          expr= std::get<std::string>(itE->second);
        auto itP = args->find(flutter::EncodableValue("precision"));
        if(itP!=args->end())
          prec= std::get<int>(itP->second);

        auto er = ExpressionEvaluator::evaluate(expr,prec);
        if (er.isError) {
          result->Error("EVALUATION_ERROR", er.errMsg);
        } else {
          result->Success(flutter::EncodableValue(er.value.convert_to<std::string>()));
        }
      } else {
        result->NotImplemented();
      }
  });


::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
