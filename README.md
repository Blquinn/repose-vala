# Repose

noun

> a state of rest, sleep, or tranquility.

![](resources/img/nightcap-round-grey-100x100.png)

Repose is a GTK based REST client. Being GTK based, it is cross-platform,
runs smoothly and sips electrons.

It is heavily influenced by both Postman and Insomnia, but aims to be much lighter weight.

## Features

- It can make http calls with various formats, surprise!
- Syntax highlighting
- Request Editor
- JSON path / XPath response filters for JSON and XML/HTML respectively

## TODO (Ideas and PRs are welcome)

- [ ] Pretty print xml + html
- [ ] Expose http client and request configuration.
- [x] Make response filter pane part of request state.
- [ ] Persistence
- [ ] Collections and folders
- [ ] Websockets
- [ ] Styling
- [ ] Scripting (Templates, variables, scripting)
- [ ] CSS selector based filtering for HTML
- [ ] Write tests
- [x] Remove any deps that aren't available through linux PMs
- [ ] WebKit based previewing for html responses
- [ ] Upgrade to libsoup3 (for http2 support) when it becomes available.
