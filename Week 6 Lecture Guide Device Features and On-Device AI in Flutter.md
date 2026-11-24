# Week 6 Lecture Guide: Device Features and On-Device AI in Flutter

*Teaching and study guide built from your W6 deck plus current Google, Firebase and Flutter documentation, checked 19 November 2026. Concepts first, almost no code.*

## 0. How to use this guide

Your deck has eight slides: permissions, the in-app camera, isolates, the on-device AI ladder and the ML Kit language gap, ending in the Wiqaya capture task. This guide keeps that spine and adds what a deeper session needs: how ML Kit really works, where Firebase AI Logic fits, what GenUI means, and a classification map that ties every tool together.

| Block | Min | What you cover |
| --- | --- | --- |
| 1 | 15 | Phone-as-sensor warm-up, permissions and camera recap (Section 9), vocabulary (Section 1) |
| 2 | 10 | Classification map (Section 2) |
| 3 | 20 | The ladder: statistics, ML Kit, LiteRT, on-device LLMs (Sections 3 to 6) |
| 4 | 15 | Cloud AI with Firebase AI Logic and hybrid routing (Section 7) |
| 5 | 15 | GenUI (Section 8) |
| 6 | 10 | Wiqaya decision exercise and Q&A (Sections 10 and 11) |

## 1. Vocabulary to teach first

| Term | Plain meaning |
| --- | --- |
| Model | A file of learned numbers that turns an input (a photo) into an output (a label such as “blurry”). |
| Training vs inference | Training creates the model; inference runs it. Mobile apps almost only do inference. |
| On-device (edge) AI | Inference on the phone. Cloud AI runs on a provider’s servers. Hybrid routes between the two. |
| Classification, detection, segmentation, OCR | A label for the whole image; labels plus boxes; a mask per pixel; text read from pixels. |
| Confidence score | A 0 to 1 number for how sure the model is. You choose the threshold. |
| LLM, token, context window | A model that predicts text piece by piece; a token is one piece; the context window is how much it can read at once. |
| Multimodal | Accepts more than text: images, audio, video. |
| Prompt, system instructions, structured output | The request; standing rules for the model; forcing the answer into a JSON shape your code can parse. |
| Hallucination and guardrails | Confident wrong output; your checks that validate or correct AI output before users see it. |
| Quantization | Shrinking a model by lowering number precision: smaller and faster, slightly less accurate. |
| CPU, GPU, NPU | Where the maths runs. The NPU is the phone’s dedicated AI chip, when present. |
| AICore and Gemini Nano | AICore is an Android system service that hosts Google’s small on-device LLM, Gemini Nano. |
| Platform channel and FFI | The two ways Dart reaches native code. Most ML plugins are thin bridges. |
| Agent, tool calling, MCP | An LLM that can act; the act of calling functions; the open protocol that connects tools to AI assistants. |
| A2UI | An open protocol for an agent to describe a user interface as data (Section 8). |

## 2. The classification map

One tool can be described in four ways. Teach the four lenses first, then place every tool on them.

**Lens A: where does it run?**

|  | On-device | Cloud | Hybrid |
| --- | --- | --- | --- |
| Strengths | Offline, private, no per-call cost, instant | Strongest models, any device, easy to update | Wide reach plus savings, graceful fallback |
| Weaknesses | Limited devices, small models, download size, battery | Network, latency, cost, privacy review | More moving parts, harder to test |

**Lens B: what kind of task?** Vision (barcodes, text, faces, objects, photo quality), language (translation, summaries, entities), speech, generative (write, describe, create images), custom prediction (your own model).

**Lens C: who owns the model?** Google’s ready-made API (ML Kit), your own model (LiteRT), a hosted foundation model (Gemini through Firebase), or an OS-hosted small model (Gemini Nano, Apple’s on-device model).

**Lens D: what role does AI play in the product?** AI as a feature (flag a blurry photo), AI as the interface (chat, GenUI), or AI as a developer tool (MCP server, coding assistants). Students constantly mix these up; naming the lens prevents it.

**Master table**

| Tool | Runs | Task | Model owner | Where it works |
| --- | --- | --- | --- | --- |
| Image statistics (your code) | Device | Photo quality | You | Everywhere |
| ML Kit vision and language | Device | Barcode, text, face, labels, translation | Google | Android and iOS |
| ML Kit GenAI | Device via AICore | Summarize, proofread, rewrite | Google (Gemini Nano) | Android, supported devices only |
| LiteRT (flutter\_litert) | Device | Your custom model | You | Android, iOS, desktop, web |
| flutter\_edge\_ai, flutter\_device\_ai | Device | On-device LLM | Open or OS model | Varies by device |
| Firebase AI Logic (firebase\_ai) | Cloud, hybrid on some platforms | Generative, multimodal | Google Gemini | Flutter mobile and web |
| GenUI | UI layer over any LLM | Interface generation | Not a model | Flutter |
| Genkit Dart, dartantic\_ai | Orchestration code | Agents and AI workflows | Many providers | Dart |
| Dart and Flutter MCP server | Your laptop | Developer tooling | Not applicable | Development only |

## 3. The ladder: climb only as high as needed

Why a ladder? Every rung up adds cost, latency, battery drain, privacy duty and maintenance. The rule to teach: pick the lowest rung that meets the accuracy requirement on the slowest phone you support.

| Rung | What | Flutter entry point | Choose it when |
| --- | --- | --- | --- |
| 1 | Plain image statistics | Your own Dart, in an isolate | A rule can decide it (too dark, too blurry) |
| 2 | ML Kit ready-made models | google\_mlkit\_\* plugins | The task is common and Google already solved it |
| 3 | Your own model | flutter\_litert | The task is specific to your product (damage, plates) and you have data |
| 4 | On-device LLM | ML Kit GenAI, flutter\_edge\_ai | Short text tasks where privacy or offline matters |
| 5 (add to the deck) | Cloud model | firebase\_ai | You need top quality, long context, or every phone must work |

&#91;embedded content: where should this AI run? · 4 questions, 5 rungs\]

Read it top to bottom: the first yes decides the rung, and a no on every question lands on the cloud.

**Rung 1 in depth.** Brightness is the average grey value of the pixels. The blur score is usually the variance of the Laplacian: the Laplacian highlights edges, so a sharp photo has strong edges and high variance, while a blurry one has weak edges and low variance. Both are deterministic, so you can unit-test them on generated images, which is exactly what the W6 grader does. In the YUV 420 camera stream the first plane (Y) is already greyscale, so you skip a conversion; just watch for row padding past the image width.

## 4. ML Kit: how it works

**What it is.** ML Kit is Google’s SDK that packages ready-made, tuned models behind simple APIs for Android and iOS. You send an image or text in and get structured results back.

**How it reaches Flutter.** Your Dart code calls a Flutter plugin, the plugin passes the call through a platform channel to the native ML Kit SDK, the native SDK runs the model on the phone, and plain objects come back. No machine learning runs in Dart. Three consequences to say out loud:

- The plugins (google\_mlkit\_\*, published by flutter-ml.dev) are community-maintained, not Google’s. Their README tells you to report model bugs to Google if they also reproduce in Google’s own sample app.
- ML Kit is mobile only: no web, no desktop, and 64-bit devices only.
- Each feature is its own package. The umbrella google\_ml\_kit package is marked do-not-use in production because it pulls in everything and inflates app size.

**The pipeline.** Source (camera frame or file) → InputImage (pixels plus rotation and format) → feature detector → results (labels, bounding boxes, corner points, confidence) → your own rules. For live camera work: process one frame at a time, drop frames while busy, close the detector when the screen goes away, and test on a mid-range phone.

&#91;embedded content: how ML Kit reaches Flutter · two lanes, one bridge\]

The plugin only carries the call across the platform channel; the model runs in Google’s native SDK and plain result objects come back.

**Models and first run.** Some models ship inside the app; others are downloaded on first use. Design for that first-launch moment with a loading state and an offline message.

**Catalog to name in the lecture**

| Family | Features | Flutter plugin status |
| --- | --- | --- |
| Vision | Barcode scanning, text recognition v2, face detection, face mesh (Android only, beta), image labeling, object detection and tracking, pose detection, document scanner, subject segmentation | Available |
| Language | Language identification, on-device translation (50+ languages), smart reply, entity extraction | Available |
| GenAI | Summarization, proofreading, rewriting | Beta, Android only |
| Native-only GenAI | Image description, Prompt API, speech recognition | I did not find these in the Flutter plugin list; check pub.dev before promising |

**Why teams like it.** Data stays on the phone, it works offline, and there is no per-call fee.

**GenAI APIs in detail.** They run Gemini Nano through AICore, so every app shares one model that may already be on the device. The supported device list is short: recent Pixels, the Galaxy S26 and a few other flagships, and the Prompt API supports even fewer. Other rules: inference only while your app is in the foreground, busy errors when you call too fast (use backoff), a per-app quota, and best results on short content. Budget Android phones are out, which is exactly the gap slide 7 warns about.

**The Arabic gap.** Text recognition v2 reads Chinese, Devanagari, Japanese, Korean and Latin scripts, not Arabic. A VIN is Latin and works today; an Egyptian number plate or an Arabic medicine box does not. Options: a server or cloud multimodal model (test it on real samples), your own trained model, or asking the user to type. Teach the habit: check the supported-languages page before designing the feature, not after the demo.

## 5. Your own models with LiteRT

LiteRT is the new name for TensorFlow Lite, and the old tflite\_flutter plugin is no longer maintained. flutter\_litert is a fork that keeps the same interpreter API and bundles the native runtimes, so setup is simpler and Flutter web is supported.

- **Model file plus labels.** A .tflite file shipped in assets or downloaded later, with a separate list of label names.
- **Two APIs.** CompiledModel is the recommended modern path: you list accelerators (CPU, GPU, NPU) and it picks the best, with CPU fallback, but it handles float32 models only. The classic Interpreter remains for quantized models, on-device training and custom operations.
- **Trust, then verify.** A backend starting without error does not prove it is correct for your model; compare outputs against known-good examples (golden tests) before enabling GPU in production.
- **Measure on the slowest phone**, not your flagship.
- **The cost of owning a model.** Data collection, labeling, training, evaluation, versioning, file size. Worth it only when rungs 2 and 5 cannot solve the task.
- **Isolates.** Heavy work on the UI thread causes jank; keep pixel and tensor preparation off the main isolate (deck slide 5).

## 6. On-device LLMs and package churn

Three families exist: Android’s Gemini Nano (through ML Kit GenAI or AICore), Apple’s on-device model on recent iOS and macOS, and open models you bundle or download yourself.

- For third-party apps, Gemini Nano is mostly short, single-turn text work, with text or a single image as input. The first model download can exceed a gigabyte.
- flutter\_device\_ai offers one API over Apple’s model, Gemini Nano and Chrome built-in AI, and ships a fake implementation for tests. gemini\_nano\_android is a smaller, early package.
- flutter\_gemma was discontinued on pub.dev and replaced by flutter\_edge\_ai, and its companion packages were renamed too. Migration is mostly a dependency swap plus an import change.

Lesson: this layer moves fast. Pin versions, wrap the plugin behind your own interface so a rename touches one file, and always keep a cloud fallback.

## 7. Cloud AI with Firebase AI Logic

**What it is.** A Google-managed service plus client SDKs (firebase\_ai for Flutter) that lets your app call Gemini models directly, with no backend of your own. Flutter’s docs name it the official Firebase SDK for generative AI in Flutter.

**Two providers behind it.** The Gemini Developer API (simplest, starts at no cost) and the Agent Platform Gemini API, formerly Vertex AI, for scale and compliance. Firebase AI Logic itself costs nothing; you pay the underlying API’s prices.

**What makes it production-ready (the part juniors miss)**

| Feature | Why it matters |
| --- | --- |
| App Check | Proves requests come from your genuine app. Enforcement has been required for Firebase AI Logic since 2 November 2026, and replay protection makes each token single-use. Use the debug provider for local development. |
| Server prompt templates | Prompts, model settings, system instructions and output schemas live on Firebase servers, so behavior changes without an app release. |
| Remote Config | A/B test prompts and swap models live. |
| Monitoring | Latency and token usage per call in the Firebase console, plus traces for odd answers. |
| Live API | Real-time audio and video conversations. |
| Cloud Functions hooks | Server-side rate limits, keyword blocking or extra context. |
| Grounding | Let the model use Google Search or Maps results. |

**Models retire.** Google has been shutting down older models (Imagen in August 2026, Gemini 2.5 models in October 2026). Treat the model name as configuration, never a constant in code.

**Rule zero.** Never put a raw API key in a mobile app; anyone can extract it. That is the reason this service exists.

**Hybrid inference.** One API that routes between an on-device model and a cloud model, with modes such as prefer on-device, prefer cloud, only on-device and only cloud. On Android the on-device side uses ML Kit’s Prompt API, is still experimental, and handles single-turn text or one image. Google’s pages describe Android, Apple and Web; I could not confirm Flutter support, so check the firebase\_ai changelog before you promise it, or build your own routing (try Gemini Nano, fall back to firebase\_ai).

&#91;embedded content: Firebase AI Logic request path · 4 hops plus a hybrid branch\]

The cloud path is a chain with App Check as its gate; the on-device branch is optional and depends on the device.

**Ways to reach a cloud model from Flutter**

| Option | Best for | Watch out |
| --- | --- | --- |
| Firebase AI Logic | Most apps: quick start, no server | Gemini only, App Check setup, model retirements |
| Your own backend | Custom logic, any provider, strict control | You build and secure it |
| Genkit Dart | Structured AI workflows (listed in Flutter’s AI docs) | Check maturity before committing |
| dartantic\_ai | Agents and many providers (OpenAI, Anthropic, Google, Ollama and more), optional Firebase adapter | Community package |
| A key inside the app | Never | Key theft and surprise bills |

## 8. GenUI: what it means

**Definition.** Generative UI is a pattern where an AI agent decides not only what to say but how to show it and make it interactive. The Flutter GenUI SDK (package genui) replaces walls of text with real widgets: ask for a trip plan and receive cards, pickers and buttons instead of a paragraph.

**The waiter and the menu.** You write the menu (a catalog of your own widgets). The model orders from it. It cannot invent a widget or run code, because its output is data, not code. That keeps the UI on brand and safe.

**A2UI.** The open protocol the SDK uses to describe UI as data. It was built with Google’s A2A and Opal teams and is not Flutter-specific; Flutter supplies a renderer.

**The loop**

1. The user types or taps.
2. Your app sends the message to an LLM together with the catalog description.
3. The LLM streams A2UI messages back.
4. An adapter parses the stream.
5. A controller updates the surface and its data model.
6. Flutter renders your catalog widgets.
7. The user interacts, the current state goes back as a new message, and the loop repeats.

&#91;embedded content: GenUI loop · 5 steps, one feedback path\]

Each pass sends the new UI state back to the model, which is how a tap becomes the next screen.

**Parts to name**

| Part | Role |
| --- | --- |
| Catalog and CatalogItem | The widgets the AI is allowed to use |
| SurfaceController | The engine that holds UI state and renders |
| A2uiTransportAdapter | Parses the model’s text stream into A2UI messages |
| DataModel | The state of the generated UI, fed back to the model |
| genai\_primitives | Shared message types, independent of any AI vendor |
| genui\_a2a | Connects to a custom agent server that speaks A2UI |
| Composer | A tool to create and edit A2UI surfaces from a text description |

**Backend agnostic.** Any model source works: firebase\_ai, dartantic\_ai, google\_generative\_ai or your own server. So GenUI is not an ML feature and runs no model; it is a UI layer over an LLM, usually a cloud one. This is the number one misconception to correct.

**Status.** The SDK is alpha and experimental. A recent release removed ContentGenerator and split the framework into layers, and per-provider packages such as genui\_firebase\_ai are gone from the tree. Teach the concepts, pin versions, expect breaking changes.

**GenUI versus its neighbours**

| Approach | Who decides the layout | Predictable? |
| --- | --- | --- |
| Chat bubbles | Nobody; just text | Yes |
| Flutter AI Toolkit | Prebuilt chat widgets (a sample app) | Yes |
| Server-driven UI | Your backend, authored by humans | Yes |
| GenUI | The LLM at runtime, inside your catalog | Only within the catalog |

**When not to use it.** Fixed or regulated screens (payments, legal), tight latency budgets, offline-first flows. Testing and accessibility need extra care because layouts vary. Pair it with validation; Flutter’s docs include a guardrails guide for checking AI-generated data.

## 9. Recap: permissions, camera, isolates (deck slides 2 to 5)

| Topic | Teaching point |
| --- | --- |
| Five permission rules | Ask in context, check every time, explain first, accept no, ask for the least. |
| Denied twice | Android stops showing the dialog; the app must still work. |
| Six statuses | granted, limited, denied, permanentlyDenied, restricted, unavailable. permanentlyDenied comes only from request(), never status(). |
| Gateway interface | Hide the plugin behind status, request, shouldShowRationale and openSettings so tests can fake it. |
| In-app camera | Original bytes, full metadata, taken now. A gallery photo may be recompressed, stripped or old. |
| Memory | Decode at display size (cacheWidth); never hold several full-size images. |
| Isolates | Pixel loops on the main isolate cause jank, not crashes. Process every fifth frame for live guidance. |

## 10. Architecture principles and the Wiqaya exercise

1. Climb the ladder only as high as needed.
2. Put every AI dependency behind your own interface, with a fake for tests.
3. Always have a fallback: server, or manual input.
4. Measure on the slowest supported phone.
5. Pin versions; plugins in this area change names.
6. Model names and prompts are configuration.
7. Validate AI output before using it.
8. Tell users when AI is involved and show uncertainty.
9. Never trust the client for anything that decides money or fraud.

**Suggested answer to the AI\_USAGE.md question** (let students argue before you reveal it):

| Part of Wiqaya | Run it on | Why |
| --- | --- | --- |
| Brightness and blur check | Phone | Instant, offline at the roadside, deterministic |
| Eight-angle capture guide | Phone | Pure logic, no network needed |
| Permission flow | Phone | Belongs to the OS |
| Evidence record creation | Phone | Created at capture time |
| Evidence verification | Server | The server must not trust the phone |
| VIN reading | Phone (ML Kit, Latin text) | Works today |
| Arabic plate reading | Server or cloud model | ML Kit has no Arabic |
| Damage assessment | Server | Heavy model, needs updates and an audit trail |
| Fraud checks | Server | A client can be tampered with |

## 11. Teaching toolkit

**Questions for the room**

- A claimant is offline at night. Which rung still works?
- The client wants Arabic plate reading. What do you tell them, and when?
- What goes wrong if the app ships an API key?
- Why can GenUI not run arbitrary code?
- Your plugin is discontinued next month. How many files change?

**Misconceptions to correct**

- “ML Kit is Google’s Flutter package.” It is a community bridge to Google’s native SDK.
- “GenUI is machine learning.” It is a UI layer over an LLM.
- “On-device means every phone.” Device lists are short, especially for GenAI.
- “The cloud is always better.” Cost, latency and privacy still matter.

**Quick checks.** Juniors: name three ML Kit features; what is inference? Mid-level: design the fallback chain for summarizing text on a budget phone; explain App Check in one sentence.

**Live demo ideas, no deep coding.** Scan a barcode with ML Kit in airplane mode; show a Gemini call’s latency and tokens in the Firebase console; show a GenUI sample app and point at the catalog.

## 12. Suggested improvements to your deck

1. Add rung 5 (cloud) and one decision slide. The ladder currently ends at on-device LLMs, which hides the most common real-world choice.
2. Add “how ML Kit reaches Flutter” and say plainly that the plugins are community-made.
3. Add a Firebase AI Logic slide covering App Check, server prompt templates and model retirement.
4. Add a GenUI slide and state clearly that it is a UI pattern, not on-device ML.
5. Extend slide 6’s rung 2 list: document scanner, translation, object detection, pose.
6. On slide 7, add the fallback for Arabic so the slide ends with a solution, not only a warning.
7. Eight slides for 85 minutes is thin once you add this; about 14 gives each idea a slide, with a quiz or demo moment between blocks.

## Caveats and sources

I read the deck’s text through Google’s HTML export, so I could not see its images or speaker notes. GenUI, hybrid inference and the Flutter on-device LLM packages are changing quickly; re-check them the day before you teach.

Sources:

- https://flutter.dev/blog/rich-and-dynamic-user-interfaces-with-flutter-and-generative-ui
- https://flutter.dev/blog/new-updates-to-a2ui-and-flutters-genui-package
- https://docs.flutter.dev/ai/genui/components.md
- https://github.com/flutter/genui
- https://docs.flutter.dev/ai/create-with-ai.md
- https://docs.flutter.dev/ai/tools
- https://firebase.google.com/docs/ai-logic/app-check.md.txt
- https://firebase.google.com/products/firebase-ai-logic
- https://firebase.google.com/docs/ai-logic/hybrid
- https://developer.android.com/ai/hybrid
- https://developer.android.com/blog/posts/experimental-hybrid-inference-and-new-gemini-models-for-android
- https://developers.google.com/ml-kit/genai
- https://developers.google.com/ml-kit/vision/text-recognition/v2
- https://github.com/flutter-ml/google\_ml\_kit\_flutter
- https://pub.dev/packages/flutter\_litert
- https://pub.dev/packages/flutter\_device\_ai
- https://pub.dev/documentation/dartantic\_ai/latest/
