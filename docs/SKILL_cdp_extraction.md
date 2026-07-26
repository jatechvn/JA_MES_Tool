---
name: cdp-header-extraction
description: Comprehensive guide for capturing exact HTTP authentication headers (Token, UUID, Cookie, Operation ID) from browser sessions using Chrome DevTools Protocol (CDP) Network Interception in Flutter/Dart or Python.
---

# CDP Header Extraction & Network Interception Skill Guide

When automating interactions with complex web applications (e.g., Enterprise MES, ERP, Cloud Portals), authentication credentials like `UUID`, `Authorization`, `Operation-ID`, and `Cookies` are frequently injected directly by JavaScript HTTP interceptors (such as Axios or Fetch wrappers) rather than being accessible via static `localStorage` key-value pairs or `document.cookie`.

This guide outlines the accurate pattern for extracting live, guaranteed-valid HTTP headers using Chrome DevTools Protocol (CDP).

---

## Key Principles & Pitfalls

### 1. Avoid `localStorage` Evaluation for Dynamic Headers
- **Anti-Pattern**: Using `Runtime.evaluate` to inspect `localStorage` or `sessionStorage`.
- **Why it fails**: Front-end frameworks often construct header values (especially UUIDs, request signatures, or transaction tokens) dynamically per request inside HTTP interceptors. Reading `localStorage` yields stale, partial, or wrong UUIDs.
- **Best Practice**: Use `Network.enable` + `Network.requestWillBeSent` listener to intercept real HTTP requests sent by the browser.

### 2. Dynamic Port Allocation over Fixed Debugging Ports
- **Anti-Pattern**: Hardcoding `--remote-debugging-port=9222`.
- **Why it fails**: Port 9222 may be occupied by lingering Chrome instances or other debugging tools, leading to `SocketException: Connection refused`.
- **Best Practice**: Pass `--remote-debugging-port=0` to let Chromium assign any free port. Read the assigned port from `<user-data-dir>/DevToolsActivePort`.

### 3. Header Sanitization (`\r\n` & Quote Cleaning)
- **Anti-Pattern**: Passing raw strings extracted from CDP or clipboard directly into HTTP client headers.
- **Why it fails**: Header values containing `\r` (Carriage Return) or `\n` (Line Feed) cause HTTP clients (like `dart:http`) to throw `FormatException: Invalid HTTP header field value`.
- **Best Practice**: Always sanitize header values:
  ```dart
  String cleanHeader(String value) {
    String clean = value.replaceAll('\r', '').replaceAll('\n', '').trim();
    if (clean.startsWith('"') && clean.endsWith('"')) {
      clean = clean.substring(1, clean.length - 1).trim();
    }
    return clean;
  }
  ```
