# Choosing the on-device model on Android

On Android, Gemini Nano is managed by AICore, a system service. An app does not bundle the model. It asks AICore for a model, and AICore decides which version to provide based on the request and the device. This article explains how to ask for the stable model or for a newer preview model, and what the device needs for each.

## Model categories

`checkOnDeviceStatus` and `downloadOnDeviceModel` take an optional `category` argument of type `OnDeviceModelCategory`:

```dart
final FirebaseHybridAi hybridAi = FirebaseHybridAi();

final OnDeviceModelStatus status = await hybridAi.checkOnDeviceStatus(
  category: OnDeviceModelCategory.preview,
);
```

| Category | What it asks AICore for | Example models |
| --- | --- | --- |
| `stable` | The latest model that is fully tested and available on consumer devices. This is the default. | Gemini Nano 3 or Gemini Nano 2, depending on the device |
| `preview` | The latest preview model with full performance, designed for higher reasoning power and complex tasks. | Gemini Nano 4 Full, reported as `nano-v4-full` |
| `previewFast` | The latest preview model that is optimized for speed and lower latency. | Gemini Nano 4 Fast, reported as `nano-v4-fast` |

The plugin passes the category to the Firebase AI Logic SDK as its on-device model option. AICore then selects the model that fits the category and is supported by the device. The category names a kind of model, not a version, so the model you receive changes as Google releases new ones. On an enrolled Pixel, `preview` resolves to `nano-v4-full` and `previewFast` resolves to `nano-v4-fast`.

Two details affect how you use the categories:

- During a transition between releases, a preview category can point to the same model as `stable`.
- Check and download the same category that your app uses for inference. The categories can resolve to different models, so a model that is available under one category says nothing about another.

## What the device needs

The stable model is available on the devices listed in the ML Kit documentation for [custom generation and agents](https://developers.google.com/ml-kit/genai#prompt-device). That list also names the Gemini Nano generation each device supports.

Preview models are available on the same devices, but they also need the AICore Developer Preview. On a device that is not enrolled, `checkOnDeviceStatus` reports the `preview` and `previewFast` categories as `unavailable`, even when the `stable` category is available. After the device is enrolled, the same two categories report `downloadable`, and then `available` once the model is installed. An `unavailable` result for a preview category therefore means that the device is not enrolled, or that it does not support the preview models, and not that the call failed.

### Enrolling a device in the AICore Developer Preview

These steps come from the [AICore Developer Preview guide](https://developers.google.com/ml-kit/genai/aicore-dev-preview), which is the authoritative source if they change.

1. Confirm that the device supports custom generation and agents.
2. Join the [aicore-experimental](https://groups.google.com/g/aicore-experimental) Google group with the account you test with.
3. Become a tester of the [Android AICore testing program](https://play.google.com/apps/testing/com.google.android.aicore). This opts in all supported devices where that account is present.
4. Update AICore to the latest version. Open the device's settings, tap your profile on a Pixel (or **Google (services)** on other devices), then **All services**, **System services**, **AICore**, and tap **Update** if one is offered. The listing shows an **Android AICore (Beta)** label, which can take up to an hour to appear.
5. After the update, open the AICore app that appears in the launcher and accept its terms and policies.

After you finish, check the preview categories again. They change from `unavailable` to `downloadable` without any change to your app.

If the beta update does not download, clearing the Play Store's cache from its App info screen and retrying the update can help.

Pre-production models can be slower and less accurate than stable ones. They can also affect system stability, storage use, and device performance, so use a test device.

### Leaving the Developer Preview

1. On the [Android AICore testing program](https://play.google.com/apps/testing/com.google.android.aicore) page, choose **Leave the program**.
2. On the Android AICore system service listing, choose **Remove updates**, then **Update** to restore the production version.

Models must be downloaded again afterward.

## Downloading a model

There are two ways to download a preview model:

- Call `downloadOnDeviceModel(category: ...)`. The plugin starts the download through the Firebase AI Logic SDK and reports progress as a fraction from 0.0 to 1.0.
- Open the AICore app, choose a preview version of Gemini Nano in its model picker, and start the download there. AICore keeps one model per device, so a model downloaded this way is shared with other apps.

Preview models are large and must be downloaded over Wi-Fi. Once a model is installed, AICore keeps it up to date.

## Confirming which model you have

Once a model is available, `OnDeviceModelStatus.modelName` holds the name that AICore reports, such as `nano-v4-full`. The name is only reported while the status is `available`. Use it to confirm that a category resolved to the model you expected, because a preview category can point to the same model as `stable` during a transition between releases. On an enrolled Pixel, the names reported after a download are `nano-v4-full` for `preview` and `nano-v4-fast` for `previewFast`.

## Limits that apply to all categories

- On-device inference runs only while the app is in the foreground.
- AICore enforces an inference quota for each app. Sending many requests in a short time returns a `BUSY` error, and exceeding a longer-term quota returns `PER_APP_BATTERY_USE_QUOTA_EXCEEDED`. Use exponential backoff when you retry.
- The first inference after a model loads can take about a minute while the model initializes.
- On Pixel devices, the AICore app's settings include a **Bypass quota limits** toggle for testing. It affects every app on the device that uses AICore, so turn it off afterward.
- Only English and Korean have been validated for on-device inference, and a single request is limited to about 4,000 tokens.

## Platforms that ignore the category

The `category` argument only changes behavior on Android. Chrome chooses its own model, and Apple platforms use the system model. See [Choosing the on-device model in Chrome](web-on-device-models.md).
