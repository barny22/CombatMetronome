The All-in-one Combat Timing bar with the update all of you guys have been waiting for!

Since Darianopolis can no longer maintain the Addon, I will probably do further updates only on the "optional Update", as it is easier for me to maintain. - barny

Should there be any bugs, feel free to report them on my [url="https://www.esoui.com/portal.php?id=386&a=listbugs"]ESOUI Portal[/url].

Beta version is available for download on [URL="https://github.com/barny22/CombatMetronome/tree/Development"]Github[/URL] or [URL="https://www.esoui.com/downloads/info3987-CombatMetronomeGCDTrackerbeta.html"]ESOUI[/URL]. Install at your own risk.

! Fixed time adjustment on exhausting fatecarver depending on crux
! Fixed: Channeled abilities or abilities with cast time are now interrupted by block, dodgeroll or barswap
! Fixed a bug after resizing the cast bar in unlock mode
+ Added options to display remaining time, spell name and spell icon on cast bar for spells with cast/channel time
+ Remaining time label and spell icon now move according to bar alignment
+ Added option to stop HA tracking
+ Added option to show the cast bar permanently
+ Added fancy mode.

[quote]IMPORTANT: [color="Red"]I no longer play ESO and can't actively maintain this addon.[/color]
I have enabled "Allow Updates & AddOns" if someone wants to keep this release working with new ESO API and library changes.
Anyone is absolutely [u][color="Green"]free[/color][/u] to use this addon and adapt, modify or build it into any project you're working on.
I would love to see some version of this addon continue, but I don't have the time or available classes to re-install ESO and properly maintain and bug-fix for all of the different classes and abilities on new builds and changes.[/quote]

Track your heavy swings, ability cooldowns and cast/channels all in one bar to help you perfect your rotation timing and take advantage of abilty queuing with live latency information.
Now includes optional Ultimate tracking.

To access the addon settings quickly, enter the command /cm

This addon's counterpart "Combat Auras" has now been released! (You can see it in the preview)
https://www.esoui.com/downloads/info2408-CombatAurasAbilityTimers.html

IMPORTANT - This addon and "Combat Auras" SHOULD always be updated at the same time. They share a common library to improve perforamnce, and there is a good chance on any update that I've made changes to this central library.

[quote]IMPORTANT: There have been changes to the central library. Combat Auras probably won't work after you updated Combat Metronome![/quote]

Thanks for Seltiix for prototyping the initial sound cue system.

Dependencies:
[list]
[*]LibAddonMenu-2.0
[*]LibAddonKeybinds
[*][b]LibChatMessage[/b] [b](!!new!!)[/b]
[/LIST]


Features
[list]
[*]Heavy attack + Cast / Channel + GCD tracking = Consolidate all of your combat timing into one bar
[*]Displays your ping live on the bar to allow spell queueing with live latency information.
[*]Timing adjustments. Firing abilities too early or too late? - Fine tune the displayed GCD / heavy timer / cast / channel individually (or globally) for ANY ability to best suit your play.
[*]Auto hides - Keeps your UI clean
[*]Flashing animation on health percentage during execute
[*]Keybind to force display + show absolute health
[*]'Tick Tock' sound cues for audio feedback
[/list]
Future Features (No guarantee or time frame):
[list]
[*]Light attack miss alert ? (Audio/Visual alert to provide feedback and improve timing reflexes)
[/list]
Known issues:
[list]
[*]Some types of cast cancels are not tracked
[*]Rarely, ground targeted abilities (E.g. Endless Hail) won't trigger a timer
[/list]
