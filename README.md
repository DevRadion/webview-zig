# webview-zig

Zig binding for a tiny cross-platform **webview** library to build modern cross-platform GUIs.

### Requirements
 - [Zig Compiler](https://ziglang.org/) - **0.16.0**
 - Unix
   - [GTK3](https://gtk.org/) and [WebKitGTK](https://webkitgtk.org/)
 - Windows
   - [WebView2 Runtime](https://developer.microsoft.com/en-us/microsoft-edge/webview2/)
 - macOS
   - [WebKit](https://webkit.org/)

### Usage

With Zig `0.16.0`:

```
zig fetch --save https://github.com/devradion/webview-zig/archive/refs/heads/main.tar.gz
```

`build.zig.zon`:
```zig
.{
    .minimum_zig_version = "0.16.0-dev.2637+6a9510c0e",
    .dependencies = .{
        .webview = .{
            .url = "https://github.com/devradion/webview-zig/archive/refs/heads/main.tar.gz",
            // Set this after `zig fetch --save ...` in your own project.
            // .hash = "N-V-...",
        },
    },
}
```

`build.zig`:
```zig
const webview = b.dependency("webview", .{
    .target = target,
    .optimize = optimize,
});
exe.root_module.addImport("webview", webview.module("webview"));
exe.linkLibrary(webview.artifact("webviewStatic")); // or "webviewShared" for shared library
// exe.linkSystemLibrary("webview"); to link with installed prebuilt library without building
```

`src/main.zig`:
```zig
const WebView = @import("webview").WebView;

pub fn main() !void {
    const w = WebView.create(true, null);
    try w.setTitle("webview-zig");
    try w.setSize(900, 600, .none);
    try w.setHtml(
        \\<!doctype html>
        \\<html><body><h1>Hello from Zig + WebView</h1></body></html>
    );
    try w.run();
    try w.destroy();
}
```

Build and run:
```
zig build run
```

### API

```zig
const WebView = struct {
    /// Opaque native webview handle.
    webview: raw.webview_t,

    /// Semantic version information returned by `version()`.
    const WebViewVersionInfo = struct {
        version: struct {
            major: c_uint,
            minor: c_uint,
            patch: c_uint,
        },
        version_number: [32]c_char,
        pre_release: [48]c_char,
        build_metadata: [48]c_char,
    };

    /// UI-thread callback used by `dispatch`.
    /// Params: (webview_handle, user_arg)
    /// Use this when you need to hop from a worker/background thread back to UI thread.
    /// `user_arg` is an opaque pointer you pass to `dispatch` (often app state/context).
    const DispatchCallback = *const fn (?*anyopaque, ?*anyopaque) callconv(.c) void;

    /// JavaScript binding callback used by `bind`.
    /// Params: (seq_id, request_json, user_arg)
    /// Flow: JS calls bound function -> callback gets `seq_id` + args JSON -> call `ret(seq_id, ...)`.
    /// `request_json` is a JSON array string containing JS arguments.
    const BindCallback = *const fn ([*:0]const u8, [*:0]const u8, ?*anyopaque) callconv(.c) void;

    /// Window sizing behavior for `setSize`.
    const WindowSizeHint = enum(c_uint) {
        /// Apply size without setting min/max constraints.
        none,
        /// Set minimum allowed window size to (`width`, `height`).
        min,
        /// Set maximum allowed window size to (`width`, `height`).
        /// Note: may be ignored on some backends.
        max,
        /// Make window non-resizable and fixed at (`width`, `height`).
        fixed
    };

    /// Platform-specific native handle type for `getNativeHandle`.
    const NativeHandle = enum(c_uint) {
        /// Top-level native window handle.
        /// Linux: GtkWindow* | macOS: NSWindow* | Windows: HWND
        ui_window,
        /// Native child view/widget that hosts web content.
        /// Linux: GtkWidget* | macOS: NSView* | Windows: HWND
        ui_widget,
        /// Browser engine controller/view object.
        /// Linux: WebKitWebView* | macOS: WKWebView* | Windows: ICoreWebView2Controller*
        browser_controller
    };

    /// Error codes returned by WebView methods.
    const WebViewError = error {
        MissingDependency,
        Canceled,
        InvalidState,
        InvalidArgument,
        Unspecified,
        Duplicate,
        NotFound,
    };

    /// Creates a new webview.
    /// `debug`: enable dev/debug behavior where supported.
    /// `window`: optional native parent window handle; null creates top-level window.
    fn create(debug: bool, window: ?*anyopaque) WebView;

    /// Starts and blocks on the UI event loop.
    fn run(self: WebView) WebViewError!void;

    /// Requests the running UI loop to stop.
    fn terminate(self: WebView) WebViewError!void;
    
    /// Schedules a callback on the UI thread.
    /// `func`: callback(webview_handle, arg)
    /// Typical pattern: call `dispatch` from worker thread, then safely touch UI in callback.
    fn dispatch(self: WebView, func: DispatchCallback, arg: ?*anyopaque) WebViewError!void;
    
    /// Returns top-level native window handle.
    fn getWindow(self: WebView) ?*anyopaque;

    /// Returns platform-specific native handle selected by `kind`.
    /// - `ui_window`: GtkWindow*/NSWindow*/HWND
    /// - `ui_widget`: GtkWidget*/NSView*/HWND
    /// - `browser_controller`: WebKitWebView*/WKWebView*/ICoreWebView2Controller*
    fn getNativeHandle(self: WebView, kind: NativeHandle) ?*anyopaque;
    
    /// Sets the window title (`title` must be zero-terminated UTF-8).
    fn setTitle(self: WebView, title: [:0]const u8) WebViewError!void;
    
    /// Sets window size in pixels.
    /// `hint`: none | min | max | fixed.
    fn setSize(self: WebView, width: i32, height: i32, hint: WindowSizeHint) WebViewError!void;
    
    /// Navigates to URL (including `data:` URLs).
    fn navigate(self: WebView, url: [:0]const u8) WebViewError!void;
    
    /// Loads raw HTML into the webview.
    fn setHtml(self: WebView, html: [:0]const u8) WebViewError!void;
    
    /// Injects JavaScript executed on every page load.
    fn init(self: WebView, js: [:0]const u8) WebViewError!void;
    
    /// Evaluates JavaScript in current page context.
    fn eval(self: WebView, js: [:0]const u8) WebViewError!void;
    
    /// Exposes native callback as JS function `name`.
    /// `req` passed to callback is a JSON array of JS arguments.
    fn bind(self: WebView, name: [:0]const u8, func: BindCallback, arg: ?*anyopaque) WebViewError!void;
    
    /// Removes a function previously registered with `bind`.
    fn unbind(self: WebView, name: [:0]const u8) WebViewError!void;
    
    /// Sends result for JS call received through `bind` callback.
    /// `seq`: callback id, `status`: 0 success/non-zero error, `result`: valid JSON string.
    fn ret(self: WebView ,seq: [:0]const u8, status: i32, result: [:0]const u8) WebViewError!void;
    
    /// Returns webview library version info.
    fn version() *const WebViewVersionInfo;

    /// Destroys webview and frees native resources.
    fn destroy(self: WebView) WebViewError!void;
}
```

### References
 - [webview](https://github.com/webview/webview/tree/0.12.0) - **0.12.0**

### License

This repo is released under the [MIT License](https://github.com/devradion/webview-zig/blob/main/LICENSE).

Third party code:
 - [external/WebView2](https://github.com/devradion/webview-zig/tree/main/external/WebView2) licensed under the [BSD-3-Clause License](https://github.com/devradion/webview-zig/tree/main/external/WebView2/LICENSE).

### Attribution

This repo is based on `webview-zig` by [thechampagne](https://github.com/thechampagne).\
Huge thanks and respect for creating the library.
