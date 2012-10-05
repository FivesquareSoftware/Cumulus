[top]: <#top> "Top"
<a name="top"/>


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


<a name="creating_resources"/>

#### Creating Resources

You can set up a base resource for other resources to inherit, or to use directly.

```objective-c 
RCResource *site = [RCResource withURL:@"http://example.com"];
// Health check
[site getWithCompletionBlock:^(RCResponse *response){
	if (NO == response.success) {
		NSLog(@"The site is down!");
	}
}];
```

You can configure settings on parent resources (they will be inherited by child resources).

```objective-c 
site.contentType = RESTClientContentTypeJSON
site.timeout = 20;
[site setValue:@"foo" forHeaderField:@"X-MyCustomHeader"];
```

Create child resources using the `-resource:` method with a relative path (which can be any object that will output a useful description).

```objective-c 
RCResource *users = [site resource:@"users"];
RCResource *posts = [site resource:@"posts"];
RCResource *one = [site resource:[NSNumber numberWithInt:1]];
```

`resourceWithFormat:` allows you to use format strings to create child resources.

```objective-c 
RCResource *user123 = [site _resourceWithFormat:@"users/%@",[NSNumber numberWithInt:123]];
RCResource *todaysPosts = [site _resourceWithFormat:@"posts/%@",@"today"];
```

Children can have children, ad infinitum...

```objective-c 
 RCResource *uploads = [posts resource:@"uploads"];
 RCResource *myUploads = [uploads resource:@"123"];
```

Child resources can override settings inherited from parent resources.

```objective-c 
// Give user more time to upload
uploads.timeout = 60;
```

Create single resources anonymously if you just want to use them once.

```objective-c 
RCResponse *response = [[site resource:@"accounts/abc123"] get];
```

[Top &#x2191;][top]

<a name="simple_requests_"/>

#### Simple Requests
	

Call HTTP methods on resources with blocks to run the requests asynchronously.

```objective-c 
[posts getWithCompletionBlock:^(RCResponse *response){
	NSArray *result = response.result;
	for (id posts in result) {
		NSLog(post);
	}
}];
```

Or, make synchronous requests to handle responses inline:

```objective-c 
RCResponse *response = [posts get];
NSLog(@"posts: %@",response.result);
```

Blocks are well typed, so you can reuse them.

```objective-c 
RCCompletionBlock mappingBlock = ^(RCResponse *response) {
	MyMapper *mapper = [MyMapper withClass:[MyModelObject class]];
	MyModelObject *object = [mapper map:response.result];
	[object save];
};

[user123 getWithCompletionBlock:mappingBlock];
```	

Completion blocks run when a request is complete, regardless of whether it was a success or failure. These are called on the main queue so you can interface safely with UI code.

```objective-c 
[posts getWithCompletionBlock:^(RCResponse *response) {
	// it's safe to call UI code here
	if (response.success) {
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

[myAccount post:payload completionBlock:^(RCResponse *response) {
   if (NO == [response isOK]) {
	   // could not create account 
   }
}];

id accountInformation = ...;
RCResponse *response = [myAccount put:accountInformation];
if ([response isOK]) {
	NSLog(@"Updated myAccount: %@",response.result);
}
```

All of the HTTP methods take an optional query object, which can be an array or dictionary.

```objective-c 
RCResponse *response = [posts getWithQuery:[NSArray arrayWithObjects:@"bar",@"foo",@"today",@"date",nil]];
```

will yield a query string like this: "foo=bar&date=today".

A single dictionary could also produce a similar result:

```objective-c 
RCResponse *response = [posts getWithQuery:[NSDictionary dictionaryWithObject:@"bar" forKey:@"foo"]];
```

However, anything after a dictionary is ignored.

```objective-c 
RCResponse *response = [posts getWithQuery:[NSArray arrayWithObjects:[NSDictionary dictionaryWithObject:@"bar" forKey:@"foo"],@"today",@"date",nil]];
```

will yield "foo=bar" and drop the remaining parameters.

Finally, specific objects, like arrays, know how to serialize themselves as query string objects correctly.

```objective-c 
RCResponse *response = [posts getWithQuery:[NSArray arrayWithObjects:[NSArray arrayWithObjects:@"1",@"2"],@"foo",@"today",@"date",nil]];
```

yields this query string: "foo[]=1&foo[]=2&date=today". You can extend this special handling to your own objects by implementing -queryWithKey:.




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
RCResource *myProtectedResource = [site resource:@"protected"];
myProtectedResource.preflightBlock = ^(RCRequest * request){
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
RCProgressBlock pictureProgressBlock = ^(NSDictionary *progressInfo){
	pictureDownloadProgressBar.hidden = NO;
	pictureDownloadProgressBar.progress = [[progressInfo objectForKey:kRESTClientProgressInfoKeyProgress] floatValue];
}	
[[pictures resource:@"abc123"] getWithProgressBlock:pictureProgressBlock completionBlock:^(RCResponse *response) {
	pictureDownloadProgressBar.hidden = YES;
}];
```

[Top &#x2191;][top]


<a name="up_down_loading"/>
	
#### Up & Downloading Direct From Disk 
	
You can download large files directly to disk.

```objective-c 
RCResource *images = [site resource:@"images"];
[images downloadWithProgressBlock:nil completionBlock:^(RCResponse *response) {
	NSURL *downloadedFile = [response.result valueForKey:kRESTClientProgressInfoKeyTempFileURL];
	// Move the file to where you want it
}
```

Uploads can stream files directly from disk.

```objective-c 
RCResource *hero = [self.service resource:@"test/upload/hero"];

RCProgressBlock progressBlock = ^(NSDictionary *progressInfo){
	NSNumber *progress = [progressInfo valueForKey:kRESTClientProgressInfoKeyProgress];
	NSLog(@"progress: %@",progress);
};

RCCompletionBlock completionBlock = ^(RCResponse *response) {
	if (response.success) {
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
[[posts resource:[NSNumber numberWithInt:1]] getWithCompletionBlock:^(RCResponse *response){
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
RCResource *pictures = [site resource:@"pictures"];
pictures.postProcessorBlock = ^(id result) {
	// we know the service returns raw data, and we transform it to a custom type
	MyImageType *image = [MyImageType receiptWithData:(NSData *)result];
	return image; 
	// response.result is set to the custom image class instead of the original raw data when the block 
	returns and any completion block will only see the transformed result
};
[[pictures resource:@"abc123"] getWithCompletionBlock:^(RCResponse *response) {
	NSLog(@"Your picture is ready: %@",response.result);
}];
```

[Top &#x2191;][top]


<a name="coding"/>
	
#### Serializing Results To/From Native Types 

Out of the box, RESTClient handles the translation to/from native native types for a range of types and transfer encodings (Text, JSON, XML, Image). During outbound serialization, NSData, NSString and image types are converted directly to the response body, since the intent is obvious. When object types, like NSDictionary, are encountered RESTClient uses some heuristics—based on object type, and Accept and Content-Type headers—to determine the best possible conversion and instantiate the correct implementation of `<RCCoder>`. 

Of course, you may have some unique serialization needs, maybe RESTClient's XML serialization (which uses Apple's XML propery list format) is not complex enough for your situation. Since `<RCCoder>` is a well-defined interface (very similar to NSValueTransformer), you can simply drop in your own, and it's easier than you might think.  

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

That's it, now you can send XML documents in to, and get them back from, RESTClient.

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

Maybe you have non-RESTful services, and just need to handle the odd endpoint. You can use the RESTClient class directly.

```objective-c 
[RESTClient get:@"http://example.com/products.php?action=list" withCompletionBlock:^(RCResponse *response){
	// do something with the response
}];

RCResponse *response = [RESTClient post:@"http://example.com/products.php?action=create" payload:productInformation];
```

[Top &#x2191;][top]


<a name="raw_requests"/>
	
#### Using Raw Requests 


If you need more control, you can create raw RCRequest objects directly, but generally, you shouldn't need to,


```objective-c 
NSString *endpoint = [NSString stringWithFormat:@"%@/index",@"http://www.example.com"];
NSMutableURLRequest *URLRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:endpoint]];
[URLRequest setHTTPMethod:kRESTClientHTTPMethodGET];

RCRequest *request = [[RCRequest alloc] initWithURLRequest:URLRequest];
__block RCResponse *localResponse = nil;

dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
[request startWithCompletionBlock:^(RCResponse *response) {
	localResponse = response;
	dispatch_semaphore_signal(request_sema);
}];
dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
dispatch_semaphore_signal(request_sema);
dispatch_release(request_sema);
```

Take a look at RCRequest.h for more information.

[Top &#x2191;][top]
