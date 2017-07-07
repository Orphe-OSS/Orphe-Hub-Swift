# Orphe Hub

Orphe Hub is hub that connects Orphe and other apps.
This project is currently under development.

## Current available functions

- Send sensor values, control light of Orphe via OSC
- Map a sensor value to MIDI pitch bend or control change signal


## Requirements
- Xcode 8.3
- Swift 3.1
- Orphe-SDK-Swift-1.1.0 
- and your Orphe!

You can get Orphe-SDK-Swift-1.1.0 by joining Facebook group: [Orphe Developers Community](https://www.facebook.com/groups/1757831034527899/).


## Used libraries
- OSCKit

## Setup
- Run `pod update` on terminal.
- Drag and drop Orphe.framework to `TARGETS-> General-> Embedded Binaries`.

![unnamed](https://cloud.githubusercontent.com/assets/1403143/24959370/8eb19022-1fcd-11e7-8ce6-c505cea6c736.png)

- Check `Copy items if needed` and click Finish to complete.

![unnamed 1](https://cloud.githubusercontent.com/assets/1403143/24959394/9ce237f0-1fcd-11e7-91f1-36ee59c1b585.png)

- Open `.xcworkspace` instead of `.xcodeproj` file.
