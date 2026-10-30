# REBS HRMS — How to Run the App

This app doesn't use a real server. It uses a small **practice server**
(called the "mock server") that runs on your own computer and sends back
made-up employee, attendance and leave data.

So there are always **two things running**:
1. The **mock server**, on your computer.
2. The **app**, on your phone (or an emulator).

The phone has to be able to reach the computer. Most problems happen
because it can't, and the fixes are in [When something goes wrong](#when-something-goes-wrong).

**Login for testing:** Employee ID `EMP-0142`, password `welcome123`.

---

## Before you start (one time only)

You need:
- **Flutter** installed on your computer.
- **Android Studio** (or at least the Android SDK). This gives you `adb`,
  the tool that talks to your phone.
- This project downloaded onto your computer.
- An **Android phone and a USB cable**, or an **Android emulator**.

Open a terminal in the project folder and run:
```
flutter pub get
```

### Check that `adb` works

Run:
```
adb devices
```
If you see **"adb is not recognized"** or **"command not found"**, your
computer has `adb` but can't find it. In PowerShell, use the full path
instead. Wherever this guide says `adb`, type this:
```
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
```
For example: `& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" devices`

(If you want to type plain `adb`, add the folder
`%LOCALAPPDATA%\Android\Sdk\platform-tools` to your Windows PATH.)

---

## Step 1 — Start the mock server

Open a terminal in the project folder and run:
```
dart run bin/mock_server.dart
```
You should see:
```
REBS HRMS mock API listening on http://0.0.0.0:8080
Office: 10.05566, 76.35416 (check-in radius 200 m)
```
**Leave this window open** the whole time you use the app. If you close it,
the app stops working. Press `Ctrl+C` in this window when you're finished.

### Set your office location

You can only check in when your phone is **near the office**. "Near" means
within a set distance, called the **radius**.

By default the office is the **Kochi Campus (Technology Innovation Zone,
Kalamassery)**, with a **200 metre**
radius. If you're not there, check-in will say you're out of range.

To use **your own** office, start the server like this instead:
```
dart run bin/mock_server.dart --lat=10.05566 --lng=76.35416 --radius=200
```
Replace the numbers with your own:

| Setting    | What it means                                      |
|------------|----------------------------------------------------|
| `--lat`    | Your office's latitude (the first number)          |
| `--lng`    | Your office's longitude (the second number)        |
| `--radius` | How close you must be to check in, in metres       |

**How to find your office's numbers:** open Google Maps and find your
office. On a computer, right-click it. On a phone, press and hold it. You'll
see two numbers like `10.05566, 76.35416`. The first is `--lat` and the
second is `--lng`.

**Tip:** for testing at home, use your home's numbers, or make the radius
big (for example `--radius=5000` for 5 km).

After you change the office, open or refresh the app's dashboard and the
app will pick up the new location. You don't need to reinstall the app.

### Your check-ins are saved

The server saves every check-in, check-out and leave request to a file
called `mock_server_data.json` in the project folder. So you can stop and
restart the server (for example to change the office) without losing
today's check-in.

To **start over** with the original demo data, add `--fresh`:
```
dart run bin/mock_server.dart --fresh
```
This deletes your saved check-ins and leave on the server.

---

## Step 2 — Run the app

First, decide which one you're using:
- **A real phone** plugged in with a USB cable → follow **2A**.
- **An emulator** (a pretend phone on your computer) → follow **2B**.

> **Why it matters:** each one needs a **different server address**. If
> you use the wrong one, the app shows *"The server took too long to
> respond"* and login never works.

### 2A — Real phone (USB cable)

**1. Turn on USB debugging (one time only).**
On the phone, go to **Settings → About phone** and tap **Build number** 7
times. Then go to **Settings → Developer options** and turn on
**USB debugging**. (On some phones these are under *System* or
*Additional settings*.)

**2. Plug the phone in.**
If the phone asks **"Allow USB debugging?"**, tap **Allow**. Then check the
computer can see it:
```
adb devices
```
Your phone should be in the list with the word `device` next to it. If it
says `unauthorized`, look at the phone and tap **Allow**.

**3. Start the app.** Keep the mock server window open and open a **second**
terminal:
```
flutter run --dart-define=API_BASE_URL=http://localhost:8080
```
⚠️ **Don't skip the `--dart-define=...` part.** Without it, the app uses
the emulator address and **can't connect on a real phone**. You need it
**every time** you run or build the app for a phone.

**4. Connect the phone to the server.** Once the app is open on the phone,
run this in a **third** terminal:
```
adb reverse tcp:8080 tcp:8080
```
This makes a private tunnel through the USB cable, from the phone to your
computer. You can check it worked with `adb reverse --list`. You should see
`tcp:8080 tcp:8080`.

**Run `adb reverse` again whenever:**
- you **unplug and replug** the cable,
- you **restart `flutter run`** (it can reset the tunnel),
- the app shows **"Couldn't reach the server"**.

Running it again is always safe.

**5. Log in** with `EMP-0142` / `welcome123`. When the app asks to use your
**location**, tap **Allow**. Check-in needs it.

**Want to install the app without `flutter run`?** Build an APK instead:
```
flutter build apk --debug --dart-define=API_BASE_URL=http://localhost:8080
adb install build/app/outputs/flutter-apk/app-debug.apk
adb reverse tcp:8080 tcp:8080
```
The server address gets built into the APK, so the `--dart-define` part
is still needed.

### 2B — Emulator

1. Start an Android emulator on the **same computer** that's running the
   mock server.
2. Run the app normally. **No `--dart-define` and no `adb reverse` needed:**
   ```
   flutter run
   ```
3. Log in with `EMP-0142` / `welcome123`.

This works because inside an emulator, the special address `10.0.2.2`
always means "the computer I'm running on". The app uses that address
unless you tell it otherwise.

---

## Quick checklist (real phone)

Every time you sit down to work:

1. Terminal 1: `dart run bin/mock_server.dart` (leave it open)
2. Plug in the phone
3. Terminal 2: `flutter run --dart-define=API_BASE_URL=http://localhost:8080`
4. Terminal 3: `adb reverse tcp:8080 tcp:8080`
5. Log in

---

## When something goes wrong

Look at the error in the app, or in the `flutter run` terminal, and find
it below.

### "The server took too long to respond" / `connection timeout`
The app is using the **wrong server address**.
- **On a real phone:** you probably forgot the `--dart-define` part. In the
  `flutter run` terminal, look for `uri: http://10.0.2.2:8080`. That's the
  emulator address, and it won't work on a phone. Stop the app and run it
  again with
  `flutter run --dart-define=API_BASE_URL=http://localhost:8080`.
- **On an emulator:** check that the mock server window is still open and
  running.

### "Couldn't reach the server" / `Connection refused`
The address is right, but nothing answered on the other end.
- **Real phone:** the USB tunnel is gone. Run `adb reverse tcp:8080 tcp:8080`
  again, then tap **Sign in** again. You don't need to restart the app.
- Check the mock server window is still open. If it's closed, start it
  again (Step 1).

### Mock server says "Only one usage of each socket address…" (`errno = 10048`)
A mock server is **already running** somewhere (maybe in another terminal
window you forgot about). Either use that one, or close it first.

To find what's using port 8080 and close it (PowerShell):
```
netstat -ano | findstr :8080
taskkill /PID <number-from-last-column> /F
```
Then start the mock server again.

### "adb is not recognized" / "command not found"
See [Check that `adb` works](#check-that-adb-works) above.

### `adb devices` shows nothing, or `unauthorized`
- Try a different USB cable or USB port. Some cables only charge and can't
  carry data.
- Make sure **USB debugging** is on (Step 2A, part 1).
- Unlock the phone and tap **Allow** on the "Allow USB debugging?" popup.

### Check-in says I'm out of range / too far from the office
Your phone is further from the office than the radius allows. Start the
server with your own location or a bigger radius. See
[Set your office location](#set-your-office-location).

### Attendance shows "Rejected" with "Cannot check out before checking in"
The server didn't have your check-in when your check-out arrived. This
usually means the server's data was wiped after you checked in, for
example by starting it with `--fresh`, or by deleting
`mock_server_data.json`.

To clear it up, reset the app on the phone. This logs you out and removes
the app's saved data, but doesn't uninstall it:
```
adb shell pm clear com.example.rebs_hrms
```
Then run `adb reverse tcp:8080 tcp:8080` again, open the app, log in, and
check in and out again.

### Check-in says location is unavailable / permission denied
- When the app asks for location, tap **Allow**.
- If you tapped "Deny" before, go to phone **Settings → Apps → rebs_hrms →
  Permissions → Location** and choose **Allow**.
- Make sure **Location/GPS** is turned on in the phone's quick settings.

### Still stuck?
Check the server is answering. In a terminal on the computer, run:
```
curl http://localhost:8080/employee/me
```
If you get back some text with `"employeeId":"EMP-0142"`, the server is fine
and the problem is the connection between the phone and the computer (go
back through Step 2). If you get nothing or an error, the server isn't
running (go back to Step 1).

Every request the app makes shows up as a line in the mock server window.
If you tap **Sign in** and no new line appears, the request never reached
the computer.

---

## Sharing the server without installing Flutter

If someone just needs to **run the server** (not build the app), you can
turn it into a single `.exe` file:
```
dart compile exe bin/mock_server.dart -o mock_server.exe
```
They can run it from a terminal without Dart or Flutter installed. The
office settings work the same way:
```
mock_server.exe --lat=10.05566 --lng=76.35416 --radius=200
```
(Double-clicking it also works, but then it always uses the default
Kochi Campus office.)

The phone still has to connect over USB with `adb reverse`, like in
Step 2A.

---

## Testing error situations

The server can also pretend to be slow, crash, or reject requests, so you
can see how the app handles problems. See the **"Scenario simulation"**
section in `README.md` for the list and example commands.
