# Choosing the on-device model in Chrome

On the web, the on-device model is built into Chrome. Chrome downloads it, updates it, and decides which version your page uses. A web app cannot ask for a stable or a preview model the way an Android app can, so this plugin ignores the `category` argument in a browser. This article explains what Chrome decides, where the model lives, how to see which model is installed, and how Chrome's Gemma 4 flag fits in.

## What the plugin does and does not control

| Operation | Behavior in Chrome |
| --- | --- |
| `checkOnDeviceStatus` | Calls `LanguageModel.availability()` and reports `available`, `downloadable`, `downloading`, or `unavailable`. It never reports a model name, because the Prompt API does not expose one. |
| `downloadOnDeviceModel` | Creates a Prompt API session, which makes Chrome start the download, and reports the progress Chrome emits. Chrome only allows this after a user interaction, so call it from a handler such as a button tap. |
| `category` | Ignored. |

An `available` result means that Chrome can create a session now. It does not tell you which model would answer. Chrome does not let a page choose a model or read the version of the installed one from JavaScript.

## How Chrome chooses a model

Chrome documents this behavior in its [model management guide](https://developer.chrome.com/docs/ai/understand-built-in-model-management):

- The first call to a `create()` function of a built-in AI API starts the download.
- Chrome benchmarks the GPU and then downloads either a larger variant (such as 4B parameters) or a smaller one (such as 2B parameters). Devices that meet separate requirements can fall back to the CPU.
- Chrome checks for model updates when the browser starts. An updated model replaces the old one without downtime, and every update is a full download.
- Chrome deletes the model if free disk space drops below a threshold, if enterprise policy disables the feature, or if the user has not met the eligibility criteria for 30 days. A deleted model is not downloaded again until a page calls `create()`.

Chrome's [hardware requirements](https://developer.chrome.com/docs/ai/get-started#hardware) cover the operating system, free storage, and the GPU or CPU.

## Where the model is stored

The model is stored in the `OptGuideOnDeviceModel` folder of the Chrome profile, in a subfolder named for the component version. On macOS, the default profile is at:

```
~/Library/Application Support/Google/Chrome/OptGuideOnDeviceModel/<component version>/
```

Other operating systems keep the same folder in their own Chrome profile directory. The folder holds the weights (`weights.bin`, about 4 GB in the case of the Nano v3 model) and a `manifest.json`. The manifest names the model:

```json
{
  "name": "Optimization Guide On Device Model",
  "version": "2025.8.8.1141",
  "BaseModelSpec": { "name": "v3Nano", "version": "2025.06.30.1229" }
}
```

`BaseModelSpec.name` is the most reliable way to see which model a profile holds. The `chrome://on-device-internals` page also shows the installed version, and Chrome documents it for this purpose. Chrome hides some internal pages by default. If it reports the page as unavailable, `chrome://chrome-urls` lists the internal pages and offers to enable the debugging ones.

## The Gemma 4 flag

Chrome has an experimental flag named **Gemma 4 for Built-in AI**, at `chrome://flags/#gemma4-for-built-in-ai`. Its description says that it enables all built-in AI APIs, including Prompt and Summarizer, to use the Gemma 4 model on Mac, Windows, Linux, and ChromeOS. Chrome's model manifest includes Gemma 4 configurations for the Prompt API, so the browser knows about the model.

Things that are true of the flag:

- It is stored in the profile's `Local State` file as `gemma4-for-built-in-ai@1`, so it applies only to the profile where you set it. A different profile, including a temporary one, does not have it.
- Changing a flag takes effect after Chrome relaunches.
- Setting the flag does not remove or replace an installed model.

Things that Chrome does not document, so verify them on your own installation:

- What starts the Gemma 4 download, and which variant Chrome downloads for a given machine.
- How Chrome chooses between an installed Nano v3 model and Gemma 4 when both are present.
- Whether the flag is available on a given Chrome version. Community reports describe it first appearing in the Canary and Dev channels.

Community write-ups describe a manual procedure for forcing the choice. On the Broker State tab of `chrome://on-device-internals`, select the Gemma 4 entries for the APIs you use and deselect the Nano v3 entries, then wait for the download. Chrome does not document this procedure, and it can change.

### Confirming that Gemma 4 is installed

After the download finishes, look in `OptGuideOnDeviceModel/`. A second component folder should appear, and its `manifest.json` should name a Gemma model in `BaseModelSpec`. The plugin and the Firebase AI Logic SDK cannot make this distinction for you, because neither receives a model name from Chrome.

## Developing with Flutter

`flutter run -d chrome` starts Chrome with a new temporary profile and deletes it when the session ends. This has three consequences:

- Flags that you set in your normal Chrome do not apply, because the temporary profile has no flags.
- The model is downloaded again in every session, and it is deleted with the profile.
- Pointing `--web-browser-flag=--user-data-dir=...` at a folder does not make it persistent. Flutter deletes the profile folder when Chrome exits in this mode, including a folder that you supplied, so never point it at a profile you want to keep.

To use your normal profile, with its flags and its installed model, serve the app and open it in Chrome yourself:

```sh
flutter run -d web-server
```

Open the URL that Flutter prints in your normal Chrome. This mode does not attach Flutter's debugger to the browser.
