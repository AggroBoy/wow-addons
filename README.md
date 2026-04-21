# wow-addons

This repo contains a small set of custom World of Warcraft DataBroker addons.

Current addons:

- `ArlBrokerBags` for bag space and junk-item visibility.
- `ArlBrokerClock` for current local time and quick calendar access.
- `ArlBrokerDurability` for equipment durability.
- `ArlBrokerFriends` for online-friends status.
- `ArlBrokerSysInfo` for FPS and system information.

As of early 2026, I use these addons all the time. They're maintained and work well.

The reason this repo is private is that I've used some copyrighted material in some of the addons (the icon for SysInfo, and the audio alert in durability,) Fair enough for me to use for my own purposes, but I shouldn't be re-publishing them.

## Deploy

The repo includes `deploy.sh`, which rsyncs addon directories to a mounted addons share at `/Volumes/AddOns`:

```sh
./deploy.sh
```

You can also deploy a specific addon by passing its directory name as an argument.
