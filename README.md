wamp_server
===========

[WAMPv1](http://wamp.ws/spec) compliant server to be used
as a template for Ruby apps, based on
[WebSocket EventMachine Server](https://github.com/imanel/websocket-eventmachine-server).

It uses [FiberConnectionPool](https://github.com/rubencaro/fiber_connection_pool)
to pool [MongoDB](https://github.com/mongodb/mongo-ruby-driver) connections.
But that is easily modifiable to fit your needs, not part of the core.
