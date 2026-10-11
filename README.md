<p align="center">
  <img src=assets\logo.png width="320" height="260" alt="Team VedX">
</p>

# An Offline AI Assistant for Blind Users, Built on Gemma 3n

*Team VedX (Yugal Kishor and Harshvardhan singh ) | NeatLogic Hackathon*

An app that helps blind users with navigation and shopping. Everything runs on the phone: no internet needed, and no photo ever leaves the device.

## Motivation

AI has come a long way, but the flagship models still have two problems for this kind of use. They need a constant internet connection, and they are built as general-purpose chatbots, not as accessibility tools.

For navigation, that causes two real problems. First, the internet is often unreliable exactly when you need it most. Second, sending sensitive photos over the internet is a privacy risk, because the images may be processed in other countries with different data protection rules.

A lot of accessibility apps also fail because they try to do everything and end up hard to use. I went the other way. This app does one thing: it helps blind users with essential daily tasks like navigation and shopping.

## 📥 Download and Build APK

1. Download the project ZIP from [here](https://github.com/yugalkishor-agi/Blind-Vision-Assistant/archive/refs/heads/main.zip).
2. Extract the downloaded ZIP file.
3. Open a terminal inside the extracted project folder (the folder containing `pubspec.yaml`).
4. Run the following commands:

   ```bash
   flutter pub get
   flutter build apk
   

## Solution Approach

Gemma 3n is a big step for on-device AI with vision. Running everything locally removes the need for internet and the privacy worry in one go.

I wanted this to be more than a demo. I wanted something people could actually use every day. As they say, the devil is in the details. Many accessibility apps don't fail because of weak technology. They fail because nobody thought them through for real situations. Convenience is everything: if an app isn't easy to use, it creates problems instead of solving them.

The app works like a small agent that lives on the phone. Here is what happens when the user asks something:

1. The user presses a button on the controller (or taps the screen) and asks a question.
2. The app quickly opens the camera, takes a photo and closes the camera again.
3. If there is text in the picture, Google ML Kit reads it on the device.
4. Gemma 3n gets the photo, the recognised text and the question, and works out the answer.
5. The answer is spoken out loud while it is still being generated, and sounds tell the user what the app is doing.

All of this happens on the phone, and each step uses whichever tool does that job best.

## Development Process

I want to especially thank my brother for helping with testing and for appearing in the demo video. He is completely blind (no light perception), and working with him has been incredibly rewarding. His feedback showed me what actually makes an accessibility app useful.

Challenges I faced:

- Downloading the model
- Google AI Edge implementation
- Improving inference speed
- Positioning of the camera
- Connecting a controller
- Integration with TalkBack
- Integration with VoiceOver (the app is built with Flutter, so it had to work on both)
- Improving text recognition

## Downloading the Model

Putting a multi-gigabyte file inside the app was not possible, and hosting it myself would have meant bandwidth costs and ongoing maintenance. I ended up choosing HuggingFace to distribute the model. That brought its own problem: to download models with licenses, users usually have to create an account and generate an access token.

To fix this I copied the authentication flow used by the Google AI Edge Gallery app. It takes users through the license acceptance step by step, so they never have to find their way around HuggingFace or deal with access tokens. That matters a lot for non-technical users.

I used the flutter\_downloader package so the download can run in the background, which I think was necessary given the size of the model. There is still one issue: on a poor internet connection the download sometimes fails, so for now I recommend users don't close the app while it downloads.

## Google AI Edge Implementation

For the AI itself I used Google AI Edge, through the flutter\_gemma package, which is built on Google's MediaPipe GenAI v0.10.24. It made running Gemma 3n on the device very straightforward, so I could spend my time on the accessibility side of the app.

Streaming responses turned out to be especially useful. Text-to-speech can start as soon as the first tokens appear, so the user doesn't wait for the whole answer. It also let me switch the backend accelerator to GPU, and I added that as a setting for people with a high-end GPU.

## Improving Inference Speed

At first I wanted to keep the camera preview open the whole time the app was running. But the app was much slower than the Google AI Edge Gallery app running the same model on the same hardware. After a lot of digging, I found that having the camera open was the biggest bottleneck. It was slowing things down by about 10x.

I also didn't want users to open another page just to take a photo. So now, when a message is sent, the app quickly starts the camera, takes the photo and closes the camera before inference begins. A simple "hey" prompt used to take 50 seconds to fully respond. Now it takes 5.

Removing the preview doesn't hurt the experience for blind users, who don't need it anyway.

I then streamed the response so text-to-speech starts reading before the full answer is ready. This created a new problem. If the model generates text slower than the voice reads it, the voice stops once it catches up. A blind user can't tell whether the AI has finished or is still working on the next token. My fix was to play loading music in the background for as long as the AI is still generating.

## Positioning of the Camera

Where the camera sits is crucial for how well the app works and how easy it is to use. My requirements were:

- Comfortable to use while walking
- Good battery life
- Works together with a cane
- Easy to connect to the app

### First idea: an IP camera in a hat

My first idea was an IP camera in a hat. It would be discreet, and it would take pictures exactly where the person is looking. But it came with three problems: battery life, camera quality, and getting access to the camera from my app.

Most commercial IP cameras come with their own app, and the manufacturer wants you to use it, so they make it very hard to connect from anywhere else (a lot of the data is encrypted, for example). I managed to hack my way to the photos on the camera's SD card, but I could not make the camera take photos remotely without the manufacturer's app.

### Second idea: the ESP32-CAM

This went better. I programmed the ESP32-CAM to create its own WiFi network. The user connects to it, takes photos, and the app can easily get them. The problems were:

- It needs a battery, and getting decent battery life made it very bulky.
- I looked for hats with pockets to hold it, but they needed holes cut into them.
- It would limit who could use the app. It became too technical for people to set up on their own, so anyone who wanted to try it would have to get all the gear from us.

The real deal breaker was camera quality. The final image wasn't even good enough to read text. I knew text recognition would be one of the main uses of the app, so it made no sense to spend more time on these cameras.

### What we chose: the phone's camera

In the end we decided to use the phone's own camera. I figured that if a user's phone is powerful enough to run Gemma 3n at a good speed, its camera is almost certainly better than anything I could get from an IP camera. It also solved the battery and connection problems.

The last question was where to put the phone. The user could hold it, but from experience with apps like Seeing AI I knew that limits how useful the app is. Holding a phone is often impractical, especially for blind users, who usually need one hand for the cane. A chest harness seemed the best way to keep the phone in a good position with a clear view, and it's far more comfortable over long periods than a head harness. It isn't as discreet as a camera hidden in a hat, but that was a trade-off I was willing to make.

The problem is that a touchscreen is impractical to use once the phone is in a harness. We needed a new way to interact with it.

## The Controller

The goal for the controller was to make talking to the AI faster without needing a visual interface. VoiceOver is great, but it only focuses on one element at a time, so the same task takes far more clicks. A physical controller with buttons makes the interaction tactile. I think this should become a new standard for accessibility apps for the blind.

I first tried a Bluetooth TikTok scroll ring, since it looked like the most compact option. It didn't work, because I couldn't intercept its HID signals before they reached the OS. So I switched to a Bluetooth keyboard, which was much easier to listen to for key events.

The controller I chose is the 8BitDo Micro. It's small and, honestly, cute, and it can be programmed with the 8BitDo Ultimate Software so each key can be given any value. I used keyboard mode, which is the only mode that works on iOS, and set the keys to run from F1 to F10. That way they never get read as letters and never start typing in a text field. I picked F1 to F10 because F13 and above aren't registered on some Android phones.

The app listens for raw keyboard events, and each function key triggers one action, such as:

- Start or stop dictation
- Send text with a photo
- Send text only
- Ask a common question like "What is this?"

## Integration with TalkBack and VoiceOver

I wanted the app to work without a controller too, for two reasons. It lets more people try it, and if they find it useful they can then buy the controller. And in some situations holding the phone is simply more practical than using the harness, which makes the controller inconvenient.

One issue with TalkBack was that it would say "button" without saying what the button was for. I tried Flutter tooltips, but it was much easier to replace the icons on the buttons with text that says exactly what each one does. That made the interface clearer, and TalkBack reads the button text perfectly. I also made the buttons very large and colourful, so someone who is partially sighted could use the screen directly.

The 8BitDo Micro has arrow keys, so I also tried navigating the UI with TalkBack using the arrows and a button for Enter. At first this worked well on Android. On iOS, though, VoiceOver didn't treat Enter as a replacement for a double tap. I tried the shortcut Ctrl + Alt + Space to simulate a double tap (on Apple's side it's meant to be Ctrl + Option + Space), but it didn't work well. It behaved more like a long press: on the home screen it opened the edit home screen mode instead of launching an app. I don't know if the problem was how the controller sends the signal, or if Apple expects you to use an Apple keyboard with VoiceOver.

I wasn't happy trying to simulate a double tap on iOS, so I changed the code. Now the app listens for the Enter key and keeps track of which button is in focus, so when Enter arrives it activates that button directly.

That created the next problem: VoiceOver and TalkBack would speak over my text-to-speech plugin. On TalkBack this was serious. When TalkBack started speaking it interrupted my voice, and my text-to-speech never finished reading the response, so the app stayed stuck in the speaking state. To fix it, I added code that detects an interruption on the voice service and records how far it got in the sentence. It then waits 6 seconds (the average TalkBack interruption lasted about 5 seconds) and tries to resume. If the voice is still busy it waits another 6 seconds, up to a maximum of 5 retries.

## Improving Text Recognition

Reading text is one of the main uses of the app. Visually impaired people are very resourceful and can recognise many objects by touch, but that isn't possible with printed text.

In my testing with the 2B, 4-bit quantised model, Gemma's text recognition was questionable at best. It depended heavily on picture quality, and even with a clear photo it hallucinated often. That makes it unsuitable for real situations, where accuracy is vital.

To solve this I added Google ML Kit text recognition. It runs completely on the device, usually in under a second, and it was far more accurate than Gemma. The text it finds is then passed to Gemma, which uses it to answer the user's question. This improved text reading massively, opened up many new use cases for Gemma, kept latency low, and kept everything on the device.

## Making the App More Accessible

Regular feedback from my brother helped me add many features that make the app easier to use. Unlike other accessibility apps, I kept everything on a single screen. That makes it much easier to ask a question or take another photo without going back through several screens.

I also added lots of sound effects:

- Loading music while the AI is generating a response
- A chime when dictation starts
- A different chime when dictation ends
- A whoosh when a message is sent
- A voice confirmation: "Sending text with photo" or "Sending text only"

## Final Thoughts

The whole project came down to one idea: make something a blind person can really use on a normal day, without internet and without handing their photos to anyone. Thank you to my brother for the testing, the patience and the honest feedback.

Yugal Kishor and Harshvardhan singh, Team VedX | NeatLogic Hackathon
