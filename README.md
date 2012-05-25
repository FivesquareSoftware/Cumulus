[HOWTO]: https://github.com/FivesquareSoftware/RESTClient/blob/master/Docs/howto.md (How Tos)
[FAQ]: https://github.com/FivesquareSoftware/RESTClient/blob/master/Docs/faq.md (FAQs)
[DEMO]: https://github.com/FivesquareSoftware/RESTClient/tree/master/Examples (See Example Apps)
[TESTS]: https://github.com/FivesquareSoftware/RESTClient/tree/master/Tests#readme (Running the Tests)

## About

RESTClient for Objective C is inspired by Ruby's [rest-client](https://github.com/archiloque/rest-client), and shares the goal of providing a simple, low-level interface to REST services through methods that mirror the HTTP requests associated with creating, fetching, updating, and deleting a resource. 

#### Plays Well With Others

It was designed to do one thing only, and one thing well: interact with REST resources and encode/decode the data coming across the wire to/from native, generic types. Because of this, you can drop RESTClient in to any system and it can fill this role without requiring a whole lot of changes to your existing code. It does not provide any kind of caching or persistence layer, no higher-level interface to resources and no UI, but it's so interoperable (via the ubiquitous use of blocks) that you can connect it to these services in a few minutes; in this context, blocks are used much as you would use UNIX pipes to connect different tools.

#### Lives in the Moment

RESTClient was also designed to be a joy to use. The primary interfaces are all implemented with blocks, so you can just forget about writing a thousand implementations of a delegate protocol or adding pointers to everything everywhere—define your intentions in a block, where you intend them, and enjoy the rest of your day. All the blocks used in the public interface are typed, so you can define them once and reuse them if you find that convenient.

#### Easy On The I's

Configuring RESTClient is, well, you don't configure RESTClient. You simply set up a base resource for each service you wish to use and nested resources will automatically inherit the information from their parents. You don't need to configure anything to create those nested resources either. By passing in an object or format string and arguments to any resource, you can create a child resource ready to go. If you need to, you can override any inherited setting in a child resource.

#### Willing to Try New Things

RESTClient handles the most common cases for you, but provides well defined interfaces to easily extend its functionality if you need to. There are protocols for authentication that will allow you to plug in to any kind of auth system, and for mime-type handling, to let you serialize/deserialize resources to and from any kind of encoding.

#### Seeking An OS For Long Walks On The Beach

RESTClient was implemented with automatic reference counting (ARC) and uses weak references, as well as new NSURLConnection APIs, so it requires iOS 5 and/or Mac OS 10.7.


## Including in Your Project

The simplest way to use RESTClient in your Xcode project is to just copy the files in "Source" to your own project.

The best way to include RESTClient is to drag the project into your workspace, then add either libRESTClient.a (iOS) or RESTClient.framework (Mac OS) to your main target's link phase. 

If you are using the Mac OS framework, the headers are automatically in your header search path. To add them for iOS, add "${SRCROOT}/relative/path/to/RESTClient/Source" to your HEADER_SEARCH_PATHS build setting and check the recursive box.

On Mac OS, import RESTClient like this in your source:

```objective-c 
#import <RESTClient/RESTClient.h>
```

On iOS, use:

```objective-c 
#import "RESTClient.h"
```


If you plan on running the tests, make sure you use `git clone --recursive` to get the repository (or if you are adding RESTClient as a submodule, `git submodule update --recursive`) to be sure to fetch RESTClient's own externals.

Make sure you link the Security framework (to handle certificate based auth) and MobileCoreServices framework (for iOS), or CoreServices framework (for Mac OS).

You must use the -ObjC linker flag (at least, you could also use -force_load=RESTClient or -all_load if you wanted to be more agressive) in order to link in the categories defined in RESTClient.

That's it. There is detailed help in the [FAQ][] if you need more information about how to set up your workspace.


## Links

[How Tos][HOWTO]  
[FAQs][FAQ]  
[Example Apps][DEMO]  
[Running the Tests][TESTS]  


## Basic Usage

The most common way to use RESTClient is to set up a base resource and some children, define a couple blocks and start making requests. 

#### Set up a base resource

```objective-c 
RCResource *site = [RCResource withURL:@"http://example.com"];
site.timeout = 20;
[site setValue:@"foo" forHeaderField:@"X-MyCustomHeader"];
site.contentType = RESTClientContentTypeJSON;
site.username = @"foo";
site.password = @"bar";
```
Usually, you would store this somewhere you could access from anywhere in your app, like your app delegate or a singleton.
	
#### Configure some child resources and start using them

_Get stuff_

```objective-c 	
RCResource *posts = [site resource:@"posts"];
[posts getWithCompletionBlock:^(RCResponse *response) {
	postsController.posts = response.result;
}];

[posts getWithCompletionBlock:^(RCResponse *response) {
	recentPostsController.posts = response.result;
} query:[NSDictionary dictionaryWithObject:@"today" forKey:@"postDate"]];
```

_Create stuff_

```objective-c 	
RCProgressBlock postProgressBlock = ^(NSDictionary *progressInfo) {
	postProgressView.progress = [[progressInfo objectForKey:kRESTClientProgressInfoKeyProgress] floatValue];
};

NSDictionary *postData = ...;
RCResource *firstPost = [posts resource:[NSNumber numberWithInt:1]];
[firstPost post:postData withProgressBlock:postProgressBlock completionBlock:^(RCResponse *response) {
	if (response.success) {
		[postsController addPost:postData];
	}
}];
```

_Map stuff_

```objective-c 	
RCResource *user123 = [site resourceWithFormat:@"users/%@",[NSNumber numberWithInt:123]];
__block MyUserClass *user;
[user123 getWithCompletionBlock:^(RCResponse *response) {
	if (response.success) {
		user = [MyUserClass withUserData:response.result];
	}
}];
```

_Protect stuff_

```objective-c 	
RCResource *admin = [site resource:@"admin"];
admin.preflightBlock = ^(RCRequest * request){
	if (NO == [accountController isAuthorized:request]) {
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"You need to log in to see this" forKey:NSLocalizedDescriptionKey];
		[errorReporter report:[NSError errorWithDomain:@"MyDomain" code:-1 userInfo:userInfo]];
		return NO;
	}
	return YES;
};
```

_Download stuff directly to disk_

```objective-c 	
RCResource *images = [site resource:@"images"];
[images downloadWithProgressBlock:nil completionBlock:^(RCResponse *response) {
	NSURL *downloadedFile = [response.result valueForKey:kRESTClientProgressInfoKeyTempFileURL];
	// Move the file to where you want it
}
```

_Test stuff even before your services are ready_

```objective-c 	
RCResource *posts = [site resource:@"posts"];
posts.contentType = RESTClientContentTypeJSON;
[posts setFixture:[NSArray arrayWithObjects:postOne,postTwo,nil] forHTTPMethod:kRESTClientHTTPMethodGET];
[posts getWithCompletionBlock:^(RCResponse *response) {
	postsController.posts = response.result;
}];
// the array from the fixture is turned into data and decoded & postprocessed normally into response.result
// You can even set your fixtures all in one place, or load them from a plist:
[RESTClient loadFixturesNamed:@"MyService"];
[RESTClient useFixtures:YES];
// now all resources will also check in with RESTClient to see if they have a fixture, yay!
```


RESTClient does even more, like direct from disk uploads, OAuth2 authentication, automatic queueing and cancelling of requests, and post-processing on a background thread (great for Core Data mapping in a child context), See more detailed examples in  the [How Tos][HOWTO].



## Contributors

John Clayton <RESTClient@fivesquaresoftware.com>  
James Cicenia <james@jimijon.com>  
Kurt Arnlund <kurt@IngeniousArtsAndTechnologies.com>  

Patches are welcome, pull requests are encouraged.


