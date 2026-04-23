# wow-addons

This repo contains a small set of custom World of Warcraft DataBroker addons.

Current addons:

- `ArlBrokerBags` for bag space and junk-item visibility.
- `ArlBrokerClock` for current local time and quick calendar access.
- `ArlBrokerDurability` for equipment durability.
- `ArlBrokerFriends` for online-friends status.
- `ArlBrokerSysInfo` for FPS and system information.

As of early 2026, I use these addons all the time. They're maintained and work well.

## Deploy

The repo includes `deploy.sh`, which rsyncs addon directories to a mounted addons share at `/Volumes/AddOns`:

```sh
./deploy.sh
```

You can also deploy a specific addon by passing its directory name as an argument.
