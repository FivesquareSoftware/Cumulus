Running the specs for RESTClient is easy.

1. Setup the server:  
	% cd Tests/Server  
	% ./setup.sh  
2. Build/Run RESTClientSpecs target

That's it.

- If you want to run the specs on a device, simply change the value of RESTClientTestServerHost in Specs.xcconfig to be `<YourMachine>.local` and assuming the device and your machine are on the same network you'll be all set.
- The server runs as a daemon in the background, you can kill it when you are done via 'kill' or execute:
	% ./run.sh stop
