[top]: <#top> "Top"
<a name="top"/>


[Workspace Setup](#workspace_setup)  
[Creating Resources](#creating_resources)  
[Simple Requests](#simple_requests)  
[Pre-verifying a Request](#pre_verifying)  
[Authorization](#authorization)  
[Showing Progress](#showing_progress)  
[Up & Downloading Direct From Disk](#up_down_loading)  
[Processing Results in the Background](#background_processing)  
[Serializing Results To/From Native Types](#coding)  
[Mapping Results to Core Data](#core_data)  
[As a General Purpose HTTP Client](#general_http)  
[Using Raw Requests](#raw_requests)  
[Configuring Logging](#logging)  
[Troubleshooting Deadlocks](#troubleshooting)



<a name="workspace_setup"/>

#### How do I set up my workspace to use Cumulus?

If you aren't using [Cocoa Pods](http://cocoapods.org), you can build and link libCumulus.a as part of your project build by adding its Xcode project to your workspace and adding libCumulus.a to the link phase. Workspaces don't currently provide a way to automatically search for headers in other projects in the workspace, so you'll also need to add the path to Cumulus to your header search path.  

Let's say you dropped Cumulus in ./Ext/Cumulus. Then, in Xcode, you would:

1. Make sure "Find Implicit Dependencies" is checked in the build phase of the scheme for your main target (Product > Edit Scheme...)
1. Drag Cumulus.xcodeproj to your workspace, at the top level (as a sibling of your other project(s))
1. In the inspector for your main target, click "Build Phases", and open "Link Binary With Libraries"
1. Click the "+", and select "libCumulus.a" from the "Workspaces" group.
1. Select "Build Settings" in the target inspector and add "$(SRCROOT)/Ext/Cumulus/Source" as an entry to "Header Search Paths", checking the recursive checkbox

If you are interested in tracking the bleeding edge (or if you just want a simpler way to pull down updates), the best way to do that is to set Cumulus up as a git submodule and then follow the steps above to add the project to your workspace.

1. In Terminal:
```sh
% cd <your_project>  
% git submodule add --branch <some branch> git@github.com:FivesquareSoftware/Cumulus.git Ext/Cumulus  
```
1. When you want to get an update:
```sh
% cd <your_project>/Ext/Cumulus  
% git checkout <branch (master, 1.1.1, etc.)>  
% git pull  
% cd ../../  
% git add Ext/Cumulus  
% git commit -m "New version of Cumulus"  
```

[Top &#x2191;][top]



<a name="creating_resources"/>

#### Creating Resources

You can set up a base resource for other resources to inherit, or to use directly.

```objective-c 
CMResource *site = [CMResource withURL:@"http://example.com"];
// Health check
[site getWithCompletionBlock:^(CMResponse *response){
	if (NO == response.wasSuccessful) {
		NSLog(@"The site is down!");
	}
}];
```

You can configure settings on parent resources (they will be inherited by child resources).

```objective-c 
site.contentType = CumulusContentTypeJSON
site.timeout = 20;
site.maxConcurrentRequests = 10;
[site setValue:@"foo" forHeaderField:@"X-MyCustomHeader"];
site.query = @{ "TOKEN" : @"MY API TOKEN" };
```

Create child resources using the `-resource:` method with a relative path (which can be any object that will output a useful description).

```objective-c 
CMResource *users = [site resource:@"users"];
CMResource *posts = [site resource:@"posts"];
CMResource *one = [site resource:@(1)];
```

`resourceWithFormat:` allows you to use format strings to create child resources.

```objective-c 
CMResource *user123 = [site _resourceWithFormat:@"users/%@",[NSNumber numberWithInt:123]];
CMResource *todaysPosts = [site _resourceWithFormat:@"posts/%@",@"today"];
```

Children can have children, ad infinitum...

```objective-c 
 CMResource *uploads = [posts resource:@"uploads"];
 CMResource *myUploads = [uploads resource:@"123"];
```

Child resources can override settings inherited from parent resources.

```objective-c 
// Give user more time to upload
uploads.timeout = 60;
```

Create single resources anonymously if you just want to use them once.

```objective-c 
CMResponse *response = [[site resource:@"accounts/abc123"] get];
```

[Top &#x2191;][top]

<a name="simple_requests_"/>

#### Simple Requests
	

Call HTTP methods on resources with blocks to run the requests asynchronously.

```objective-c 
[posts getWithCompletionBlock:^(CMResponse *response){
	NSArray *result = response.result;
	for (id posts in result) {
		NSLog(post);
	}
}];
```

Or, make synchronous requests to handle responses inline:

```objective-c 
CMResponse *response = [posts get];
NSLog(@"posts: %@",response.result);
```

Blocks are well typed, so you can reuse them.

```objective-c 
RCCompletionBlock mappingBlock = ^(CMResponse *response) {
	MyMapper *mapper = [MyMapper withClass:[MyModelObject class]];
	MyModelObject *object = [mapper map:response.result];
	[object save];
};

[user123 getWithCompletionBlock:mappingBlock];
```	

Completion blocks run when a request is complete, regardless of whether it was a success or failure. These are called on the main queue so you can interface safely with UI code.

```objective-c 
[posts getWithCompletionBlock:^(CMResponse *response) {
	// it's safe to call UI code here
	if (response.wasSuccessful) {
		[myController reload:response.result];
	} else {
		UIAlertView *alert = [[UIAlertView alloc] initWith ...];
		[alert show];
	}
}];
```

PUT and POST take payloads, which are just native Cocoa objects, of any kind.

```objective-c 
NSDictionary *payload = [NSDictionary dictionaryWithObjectsAndKeys:
							@"me",@"username",@"test",@"password",nil];

[myAccount post:payload completionBlock:^(CMResponse *response) {
   if (NO == [response isOK]) {
	   // could not create account 
   }
}];

id accountInformation = ...;
CMResponse *response = [myAccount put:accountInformation];
if ([response isOK]) {
	NSLog(@"Updated myAccount: %@",response.result);
}
```

The GET and HEAD HTTP methods also take an optional query object, which is a dictionary.

```objective-c 
CMResponse *response = [posts getWithQuery:@{ @"foo" : @"bar", @"date" : @"today"}];
```

will yield a query string like this: "foo=bar&date=today".

Specific objects, like arrays, know how to serialize themselves as query string objects correctly.

```objective-c 
CMResponse *response = [posts getWithQuery:@{ @"foo" : @[@"1",@"2"] }];
```

yields this query string: "foo[]=1&foo[]=2". You can extend this special handling to your own objects by implementing -queryWithKey:.


Any query you pass to a request is appended to a resource's base query if it exists.

```objective-c 
site.query = @{ @"TOKEN" : TOKEN };
CMResource *posts = [site resource:@"posts"];
CMResponse *response = [posts getWithQuery:@{ @"offset" : @(10), @"limit" : @(10) }];
```
yields a query string like: "TOKEN=abc123&offset=10&limit=10". This makes it easy to set up a base resource that must pass things like API tokens or version at all times, but still augment that query at request time.



[Top &#x2191;][top]


<a name="authorization"/>
	
#### Authorization  


BASIC auth is as easy as setting the username and password on a resource, usually on your base resource.

```objective-c 
site.username = @"foo";
site.password = @"bar";
```

Under the hood, this creates a BASIC auth provider, a class implementing `<RCAuthProvider>`:

```objective-c 
% site.authProviders => ( <RCBasicAuthProvider:0x01010101> )
```
Auth providers are given the chance to authorize requests and respond to authentication challenges. There are built in auth providers that do BASIC auth, server trust (useful if you want to add your own certificates during development), and OAuth2. 

If you need to do a kind of auth for which there is no default provider, it's easy to create your own auth provider class. 

MyAuthProvider.m:

```objective-c 
- (NSString *) providedAuthenticationMethod {
	return NSURLAuthenticationMethod<SomeMethod>;
}
- (void) authorizeRequest:(NSMutableURLRequest *)urlRequest {
	// modify the URL request to conform to your auth scheme, adding headers, changing the URL, or anything else you need to do
	// You can even go and fetch something else, like an auth token, from here if you need to
	// This will also be called any time a redirect happens, so you can authorize subsequent requests in a chain the same way
}
- (NSURLCredential *) credentialForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	// create a credential any way you want, perhaps from a certificate in your bundle, sky's the limit
	// you can also return nil to cancel an auth challenge
}
```

Then, when you create your resource, simply set your own auth provider on the instance.

```objective-c 
MyAuthProvider *provider = [[MyAuthProvider alloc] initWithSomeKindOfRelevantData:authData];
[site addAuthProvider:provider];
```


[Top &#x2191;][top]



<a name="pre_verifying"/>
	
#### Pre-verifying a Request 
	
Set up a preflight block to run on all requests for a resource. These are run on the main queue so UI code is OK. Returning NO will abort the request.

```objective-c 
CMResource *myProtectedResource = [site resource:@"protected"];
myProtectedResource.preflightBlock = ^(CMRequest * request){
	if (NO == [accountController authorized:request]) {
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"You need to log in to see this" 
															 forKey:NSLocalizedDescriptionKey];
		[errorReporter report:[NSError errorWithDomain:@"MyDomain" code:-1 userInfo:userInfo]];
		return NO;
	}
	return YES;
};
```

[Top &#x2191;][top]

	
<a name="showing_progress"/>

#### Showing Progress 

Progress blocks allow you to do work when data is received on a connection. They run once when the request begins and are called on the main queue like preflight blocks.

```objective-c 
RCProgressBlock pictureProgressBlock = ^(CMProgressInfo *progressInfo){
	pictureDownloadProgressBar.hidden = NO;
	pictureDownloadProgressBar.progress = [progressInfo.progress floatValue];
}	
[[pictures resource:@"abc123"] getWithProgressBlock:pictureProgressBlock completionBlock:^(CMResponse *response) {
	pictureDownloadProgressBar.hidden = YES;
}];
```

[Top &#x2191;][top]


<a name="up_down_loading"/>
	
#### Up & Downloading Direct From Disk 
	
You can download large files directly to disk.

```objective-c 
CMResource *bigImage = [site resource:@"bigImage.png"];
[bigImage downloadWithProgressBlock:nil completionBlock:^(CMResponse *response) {
	NSURL *downloadedFile = [(CMProgressInfo *)response.result tempFileURL];
	// Move the file to where you want it
}
```

You can also download big honking resources in chunks.

```objective-c 
CMResource *massiveVideo = [site resource:@"huge_video.m4v"];
[massiveVideo downloadInChunksWithProgressBlock:^(CMProgressInfo *){...} completionBlock:^(CMResponse *response) {
	NSURL *downloadedFile = [(CMProgressInfo *)response.result tempFileURL];
	// Move the file to where you want it
}
```

Uploads can stream files directly from disk.

```objective-c 
CMResource *hero = [self.service resource:@"test/upload/hero"];

RCProgressBlock progressBlock = ^(NSDictionary *progressInfo){
	NSNumber *progress = [progressInfo valueForKey:kCumulusProgressInfoKeyProgress];
	NSLog(@"progress: %@",progress);
};

RCCompletionBlock completionBlock = ^(CMResponse *response) {
	if (response.wasSuccessful) {
		NSLog(@"Upload done!");
	}
};

NSString *filePath = [[NSBundle mainBundle] pathForResource:@"t_hero" ofType:@"png"];
NSURL *fileURL = [NSURL fileURLWithPath:filePath];
[hero uploadFile:fileURL withProgressBlock:progressBlock completionBlock:completionBlock];
```

[Top &#x2191;][top]
	

<a name="background_processing"/>
		
#### Processing Results in the Background 

You can do background work from any of the usual blocks if you want, just by dispatching to another queue.

```objective-c 
[[posts resource:@(1)] getWithCompletionBlock:^(CMResponse *response){
	if ([response isOK]) {
		// save something to your database in the background using a dedicated DB mapping queue

		dispatch_queue_t q_db_mapping = dispatch_queue_create("com.example.db_mapping", NULL);

		dispatch_async(q_db_mapping, ^(){
			id myObject = [MyObject new];
			[myObject mapValuesFromObject:response.result];
			[myObject save];

			dispatch_release(q_db_mapping);
		});
	}
}];
```

But you can also transform response results on a non-main queue before they are passed to completion blocks using post processing blocks. These are called on a concurrent queue to achieve the best possible throughput. Use these instead of completion blocks when you know you have significant work to do to process a response's data.

```objective-c 
CMResource *pictures = [site resource:@"pictures"];
pictures.postProcessorBlock = ^(id result) {
	// we know the service returns raw data, and we transform it to a custom type
	MyImageType *image = [MyImageType receiptWithData:(NSData *)result];
	return image; 
	// response.result is set to the custom image class instead of the original raw data when the block 
	returns and any completion block will only see the transformed result
};
[[pictures resource:@"abc123"] getWithCompletionBlock:^(CMResponse *response) {
	NSLog(@"Your picture is ready: %@",response.result);
}];
```

//TODO: show an example of chaining post processors

[Top &#x2191;][top]


<a name="coding"/>
	
#### Serializing Results To/From Native Types 

Out of the box, Cumulus handles the translation to/from native native types for a range of types and transfer encodings (Text, JSON, XML, Image). During outbound serialization, NSData, NSString and image types are converted directly to the response body, since the intent is obvious. When object types, like NSDictionary, are encountered Cumulus uses some heuristics—based on object type, and Accept and Content-Type headers—to determine the best possible conversion and instantiate the correct implementation of `<RCCoder>`. 

Of course, you may have some unique serialization needs, maybe Cumulus's XML serialization (which uses Apple's XML propery list format) is not complex enough for your situation. Since `<RCCoder>` is a well-defined interface (very similar to NSValueTransformer), you can simply drop in your own, and it's easier than you might think.  

Here is an example coder that uses [TouchXML](https://github.com/TouchCode/TouchXML) to convert between CXMLDocument objects and the XML used for the transfer encoding.

MyXMLCoder.m:

```objective-c 
+ (void) load {
	@autoreleasepool {
		[RCCoder registerCoder:self objectType:[CXMLDocument class] mimeTypes:nil];
	}
}

- (NSData *) encodeObject:(id)payload {	
	NSData *data = [payload XMLData];
    return data;
}

- (id) decodeData:(NSData *)data {
	id object = nil;
	NSError *error = nil;
	object = [[CXMLDocument alloc] initWithData:data encoding:NSUTF8StringEncoding options:0 error:&error];
	if (error) {
		NSString *XMLString  __attribute__((unused)) = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		RCLog(@"XML coding error: '%@' %@ (%@)",XMLString, [error localizedDescription],[error userInfo]);
	}
    return object;
}
```

That's it, now you can send XML documents in to, and get them back from, Cumulus.

[Top &#x2191;][top]




<a name="core_data"/>
	
#### Mapping Results to Core Data 

Post processing blocks are an ideal match to Core Data's new blocks-based interfaces, allowing you to save data on a child context in the background and not worry about how it propagates to the main thread's context.

```objective-c 
childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
childContext.parentContext = mainContext; // your main queue MOC, maybe in your appDelegate

// ...

pictures.postProcessorBlock = ^(id result) {
	MyModelObject *myObject = [NSEntityDescription insertNewObjectForEntityForName:someEntityName 
															inManagedObjectContext:childContext];	
	// process result into myObject ...
	NSError *error = nil;
    if ([childContext save:&error]) {
        __autoreleasing NSError *parentError = nil;    
        __weak NSManagedObjectContext *parent = childContext.parentContext;
        [parent performBlock:^{
            [parent save:&parentError];
        }];
    }
	// check errors ...
	return myObject;
};
```

[Top &#x2191;][top]


<a name="general_http"/>
	
#### As a General Purpose HTTP Client 

Maybe you have non-RESTful services, and just need to handle the odd endpoint. You can use the Cumulus class directly.

```objective-c 
[Cumulus get:@"http://example.com/products.php?action=list" withCompletionBlock:^(CMResponse *response){
	// do something with the response
}];

CMResponse *response = [Cumulus post:@"http://example.com/products.php?action=create" payload:productInformation];
```

[Top &#x2191;][top]


<a name="raw_requests"/>
	
#### Using Raw Requests 


If you need more control, you can create raw CMRequest objects directly, but generally, you shouldn't need to,


```objective-c 
NSString *endpoint = [NSString stringWithFormat:@"%@/index",@"http://www.example.com"];
NSMutableURLRequest *URLRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:endpoint]];
[URLRequest setHTTPMethod:kCumulusHTTPMethodGET];

CMRequest *request = [[CMRequest alloc] initWithURLRequest:URLRequest];
__block CMResponse *localResponse = nil;

dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
[request startWithCompletionBlock:^(CMResponse *response) {
	localResponse = response;
	dispatch_semaphore_signal(request_sema);
}];
dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
dispatch_semaphore_signal(request_sema);
dispatch_release(request_sema);
```

Take a look at CMRequest.h for more information.

[Top &#x2191;][top]


<a name="logging"/>

#### Configuring Logging

Logging is disabled by default unless 'DEBUG' set to YES|true|1|foo or 'CUMULUS_BLOCK_LOGGING' is set to 0 in your build settings. Once those flags are defined, logging can then be turned on or off in one of two ways:

1. Pass in CumulusLoggingOn=YES|true|foo in your builds settings, this will compile logging in.
1. Set CumulusLoggingOn=YES|true|1 in the environment in the Run phase of your target's scheme to turn logging on, or NO|false|0 to turn it off (the default is off). This is wicked handy, because you can turn on logging even on an already compiled library, simply by changing the process environment. The environment is only checked once at startup, but this will result in a BOOL comparison for every log statement. Thankfully, Cumulus doesn't log much.

[Top &#x2191;][top]


<a name="troubleshooting"/>

#### Troubleshooting Deadlocks

Because Cumulus uses Grand Central Dispatch, it shares a few of the gotchas that GCD does, for example, dispatching synchronously from the same queue that a bit of code is running on will produce deadlock. Cumulus runs some of the lifecyle blocks for a resource on the main queue, which is a serial queue. If you were to dispatch synchronously to the main queue again from inside of that block, you would see the application freeze.  Mostly, just know what your GCD environment is when dispatching, and you'll be fine. The Cumulus docs indicate exactly how it dispatches the various blocks you provide. And, [Apple's documentation on GCD](http://developer.apple.com/library/ios/#documentation/General/Conceptual/ConcurrencyProgrammingGuide/OperationQueues/OperationQueues.html#//apple_ref/doc/uid/TP40008091-CH102-SW1) is excellent.


[Top &#x2191;][top]

