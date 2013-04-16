[top]: <#top> "Top"
<a name="top"/>


[How do I set up my workspace to use Cumulus?](#workspace_setup)  
[How do I turn on logging?](#logging)  
[I am seeing deadlocks, what's the cause?](#deadlocks)  


<a name="workspace_setup"/>

#### How do I set up my workspace to use Cumulus?

You can build and link libCumulus.a as part of your project build by adding its Xcode project to your workspace and adding libCumulus.a to the link phase. Workspaces don't currently provide a way to automatically search for headers in other projects in the workspace, so you'll also need to add the path to Cumulus to your header search path.  

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
% git submodule add git@github.com:FivesquareSoftware/Cumulus.git Ext/Cumulus  
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


<a name="logging"/>

#### How do I turn on logging?

Logging is disabled by default unless the 'DEBUG' preprocessor macro is set to YES|true|1|foo in your build settings. Once that flag is defined, logging can then be turned on or off in one of two ways:

1. Pass in CumulusLoggingOn=YES|true|foo in your builds settings, this will compile logging in.
1. Set CumulusLoggingOn=YES|true|1 in the environment in the Run phase of your target's scheme to turn logging on, or NO|false|0 to turn it off (the default is off). This is wicked handy, because you can turn on logging even on an already compiled library, simply by changing the process environment. The environment is only checked once at startup, but this will result in a BOOL comparison for every log statement. Thankfully, Cumulus doesn't log much.

[Top &#x2191;][top]


<a name="deadlocks"/>

#### I am seeing deadlocks, what's the cause??

Because Cumulus uses Grand Central Dispatch, it shares a few of the gotchas that GCD does, for example, dispatching synchronously (or asynchronously to a serial queue) from the same queue will produce deadlock. Cumulus runs some of the lifecyle blocks for a resource on the main queue, which is a serial queue. If you were to dispatch to the main queue again from inside of that block, you would see a deadlock.  Mostly, just know what your GCD environment is when dispatching, and you'll be fine. The Cumulus docs indicate how it dispatches the various blocks you provide. And, Apple's documentation on GCD is excellent.


[Top &#x2191;][top]
