#include <ApplicationServices/ApplicationServices.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>

static bool is_target(CGDisplayModeRef mode) {
  return CGDisplayModeGetWidth(mode) == 2560
    && CGDisplayModeGetHeight(mode) == 1440
    && CGDisplayModeGetPixelWidth(mode) == 2560
    && CGDisplayModeGetPixelHeight(mode) == 1440
    && CGDisplayModeGetRefreshRate(mode) >= 59.0
    && CGDisplayModeGetRefreshRate(mode) <= 61.0;
}

int main(int argc, char **argv) {
  bool check = argc == 2 && strcmp(argv[1], "--check") == 0;
  if (argc > 1 && !check) {
    fprintf(stderr, "Usage: charlie-screen-resolution [--check]\n");
    return 2;
  }

  CGDirectDisplayID display = CGMainDisplayID();
  CGDisplayModeRef current = CGDisplayCopyDisplayMode(display);
  if (!current) {
    fprintf(stderr, "No main display is available in this graphical session\n");
    return 1;
  }
  if (check || is_target(current)) {
    printf("%zux%zu pixels, %zux%zu logical, %.2f Hz\n",
      CGDisplayModeGetPixelWidth(current), CGDisplayModeGetPixelHeight(current),
      CGDisplayModeGetWidth(current), CGDisplayModeGetHeight(current),
      CGDisplayModeGetRefreshRate(current));
    bool matches = is_target(current);
    CGDisplayModeRelease(current);
    return matches ? 0 : 1;
  }
  CGDisplayModeRelease(current);

  const void *key = kCGDisplayShowDuplicateLowResolutionModes;
  const void *value = kCFBooleanTrue;
  CFDictionaryRef options = CFDictionaryCreate(NULL, &key, &value, 1,
    &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
  CFArrayRef modes = CGDisplayCopyAllDisplayModes(display, options);
  CFRelease(options);
  if (!modes) {
    fprintf(stderr, "Unable to enumerate main display modes\n");
    return 1;
  }

  CGDisplayModeRef target = NULL;
  for (CFIndex i = 0; i < CFArrayGetCount(modes); i++) {
    CGDisplayModeRef mode = (CGDisplayModeRef)CFArrayGetValueAtIndex(modes, i);
    if (is_target(mode)) { target = mode; break; }
  }
  if (!target) {
    fprintf(stderr, "Main display has no unscaled 2560x1440 mode at 60 Hz\n");
    CFRelease(modes);
    return 1;
  }

  CGDisplayConfigRef transaction;
  CGError error = CGBeginDisplayConfiguration(&transaction);
  if (error == kCGErrorSuccess) {
    error = CGConfigureDisplayWithDisplayMode(transaction, display, target, NULL);
    if (error == kCGErrorSuccess)
      error = CGCompleteDisplayConfiguration(transaction, kCGConfigureForSession);
    else CGCancelDisplayConfiguration(transaction);
  }
  CFRelease(modes);
  if (error != kCGErrorSuccess) {
    fprintf(stderr, "Display change failed (%d); run in the user's GUI session\n", error);
    return 1;
  }
  current = CGDisplayCopyDisplayMode(display);
  bool matches = current && is_target(current);
  if (current) CGDisplayModeRelease(current);
  if (!matches) {
    fprintf(stderr, "Display change did not produce unscaled 1440p at 60 Hz\n");
    return 1;
  }
  puts("Applied unscaled 2560x1440 at 60 Hz for this login session");
  return 0;
}
