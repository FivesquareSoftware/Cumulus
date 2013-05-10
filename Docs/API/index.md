## About

Cumulus is a simple, powerful and blazing🔥 fast Cocoa HTTP+REST client that makes creating Cloud-backed apps stupidly easy.

## Getting Started

Using Cumulus is as simple as defining a resource and making a request. 

	CMResource *posts = [site resource:@"posts"];
	[posts getWithCompletionBlock:^(CMResponse *response) {
		postsController.posts = response.result;
	}];

Often you'll configure a base resource—like _site_ above—and use its configuration to define child resources.

	CMResource *site = [CMResource withURL:@"http://example.com"];
	site.timeout = 20;
	[site setValue:@"foo" forHeaderField:@"X-MyCustomHeader"];
	site.contentType = CMContentTypeJSON;
	site.username = @"foo";
	site.password = @"bar";


See the [Cumulus README](https://github.com/FivesquareSoftware/Cumulus/blob/master/Docs/Cumulus-Guide.md) for more detailed information and basic usage.  
See the [Cumulus Programming Guide](https://github.com/FivesquareSoftware/Cumulus/blob/master/README.md) for detailed usage.  

## Source

https://github.com/FivesquareSoftware/Cumulus

## See Also

[Cumulus Examples](https://github.com/FivesquareSoftware/Cumulus/tree/master/Examples)


