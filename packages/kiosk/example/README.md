# tekartik_kiosk_example

Demonstrates how to use the tekartik_kiosk plugin.

## Setup

```
  tekartik_kiosk:
    git:
      url: https://github.com/tekartikprj/android_tools
      path: packages/kiosk
```

Added to manifest (not needed):

```
    <!-- Permission to add -->
    <uses-permission android:name="android.permission.GET_TASKS" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <uses-permission
        android:name="android.permission.WRITE_SETTINGS"
        tools:ignore="ProtectedPermissions" />
    <uses-permission android:name="android.permission.READ_PHONE_STATE" />
    <uses-permission
        android:name="android.permission.PACKAGE_USAGE_STATS"
        tools:ignore="ProtectedPermissions" />
```

