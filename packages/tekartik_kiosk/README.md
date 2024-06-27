# tekartik_kiosk

Basic kiosk support

## Setup

```
  tekartik_kiosk:
    git:
      url: https://github.com/tekartikprj/android_tools
      path: packages/tekartik_kiosk
      ref: dart3a
```

Set activity class from java code

```
package com.tekartik.example

import android.os.Bundle
import com.tekartik.kiosk.KioskService
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Set startup activity
        KioskService.setStartClass(this.javaClass)
    }
}
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

