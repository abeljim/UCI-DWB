# Display

This file documents the display of the trashcan

## Display Quality:

- Resolution: 720p, the pi can deliver up to 1080p, but 720p gives much better response.
- Screen Size: about 50 inch, specialized for vertical display
- Refresh rate: 60 Hz, can afford to go slower to 50
- Connectors: HDMI

## Software

### X server

- All stuffs are stored in the filed .xinit in the home directory
- Display related settings go to the .xinit, things like setting the screen not to go blank goes here before officially launching the chromium browser

### Chromium

- Chromium operates in kiosk mode
- By default, Chromium probably won't go fullscreen even if you specify in the command so the .config/chromium/Default/Preferences neeeds to be adjusted in term of left, right, top, down bound
- The mouse needs to go away during display so unclutter is used to make the mouse display

## Dev Note (basically tips for people developing this project)

- Press Ctrl + Alt + F1 to exit the X server 
