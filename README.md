ios8-notifications
==================

This is a proof of concept for sending interactive notifications



Hand-off from Native App to Browser
----------------------------------

(https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/Handoff/AdoptingHandoff/AdoptingHandoff.html#//apple_ref/doc/uid/TP40014338-CH2-SW21)

1. Add an array of activity types in the Info.plist, one for each type of hand-off (key = NSUserActivityTypes)

2. Create an NSUserActivity object with the activity type (in this case I have used com.adhoc.CoreDataSample.browsing)

3. Set the webpageURL of the NSUserActivity to the web page which needs to be opened

4. Assign the activity type to the ViewController's userActivity

5. If needed, handle the event when the hand-off happens


*To test*

1. Enable Hand-offs on a device and a mac (for Mac you will find it in System Preferences->General. On phone you will find it in Settings->General)

2. Run the app on the device. Tap on a row

3. An icon of your default browser will show up on the mac with a phone symbol. Tap on it

4. This will open the web url associated with the row (as mentioned in the feed) on the web browser