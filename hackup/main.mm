//
//  main.m
//  hackup
//
//  Created by Valentine Silvansky on 04.12.12.
//  Copyright (c) 2012 silvansky. All rights reserved.
//

#include <iostream>
#include <dlfcn.h>

#define FULL_INFO      0

@interface DLLoader : NSObject
{
	void *_handle;
}

- (id)initWithPath:(NSString *)path;
- (void)dealloc;
- (BOOL)loaded;

@end

@implementation DLLoader

- (id)initWithPath:(NSString *)path
{
	self = [super init];
	if (self)
	{
		_handle = dlopen([path cStringUsingEncoding:NSASCIIStringEncoding], RTLD_NOW);
	}
	return self;
}

- (void)dealloc
{
	dlclose(_handle);
	[super dealloc];
}

- (BOOL)loaded
{
	return (_handle != NULL);
}

@end

void NSPrintf(NSString *format, ...)
{
	va_list args;
	va_start(args, format);
	NSString *message = [[[NSString alloc] initWithFormat:format arguments:args] autorelease];
	va_end(args);
	std::cout << [message cStringUsingEncoding:NSUTF8StringEncoding];
}

#define LOG_SELECTOR(obj, sel)\
if ([obj respondsToSelector:@selector(sel)])\
{\
	NSPrintf(@" "#sel": %@\n", [obj performSelector:@selector(sel)]);\
}

#define LOG_SELECTOR_SHORT(obj, sel)\
if ([obj respondsToSelector:@selector(sel)])\
{\
	NSPrintf(@"%@\n", [obj performSelector:@selector(sel)]);\
}

#define GET_SELECTOR_RESULT(obj, sel) ([obj respondsToSelector:@selector(sel)] ? ([obj performSelector:@selector(sel)]) : nil)

#define GET_SELECTOR_RESULT_1(obj, sel, arg) ([obj respondsToSelector:@selector(sel)] ? ([obj performSelector:@selector(sel) withObject:arg]) : nil)
#define GET_SELECTOR_RESULT_2(obj, sel, arg1, arg2) ([obj respondsToSelector:@selector(sel)] ? ([obj performSelector:@selector(sel) withObject:arg1 withObject:arg2]) : nil)

BOOL loadBundle(NSString *path)
{
	NSBundle *b = [NSBundle bundleWithPath:path];
	return [[[b retain] autorelease] load];
}

BOOL loadPrivateFramework(NSString *framework)
{
	NSString *path = [NSString stringWithFormat:@"/System/Library/PrivateFrameworks/%@.framework", framework];
	BOOL success = loadBundle(path);
	if (!success)
	{
		NSPrintf(@"Failed to load private framework %@!\n", framework);
	}
	return success;
}

BOOL loadPublicFramework(NSString *framework)
{
	NSString *path = [NSString stringWithFormat:@"/System/Library/Frameworks/%@.framework", framework];
	BOOL success = loadBundle(path);
	if (!success)
	{
		NSPrintf(@"Failed to load public framework %@!\n", framework);
	}
	return success;
}

BOOL loadSharedLibrary(NSString *name)
{
	NSString *path = [NSString stringWithFormat:@"/usr/lib/%@.dylib", name];
	DLLoader *loader = [[[DLLoader alloc] initWithPath:path] autorelease];
	BOOL success = [loader loaded];
	if (!success)
	{
		NSPrintf(@"Failed to load shared library %@!\n", name);
	}
	return success;
}

int main(int argc, char *argv[])
{
	@autoreleasepool
	{
		if (argc == 1)
		{
			if (loadPrivateFramework(@"iTunesStore"))
			{
				Class ISSoftwareMap = NSClassFromString(@"ISSoftwareMap");
				id isSoftwareMap = GET_SELECTOR_RESULT(ISSoftwareMap, currentMap);
				if (!isSoftwareMap)
				{
					isSoftwareMap = GET_SELECTOR_RESULT(ISSoftwareMap, loadedMap);
				}
				if (isSoftwareMap)
				{
#if FULL_INFO
					NSPrintf(@"iTunesStore software info:\n");
					LOG_SELECTOR(isSoftwareMap, applications)
#endif
					NSArray *applications = GET_SELECTOR_RESULT(isSoftwareMap, applications);
					if (applications)
					{
						for (id app in applications)
						{
#if FULL_INFO
							NSPrintf(@" *** Info for application %@\n", app);
							LOG_SELECTOR(app, bundleIdentifier)
							LOG_SELECTOR(app, bundleShortVersionString)
							LOG_SELECTOR(app, bundleVersion)
							LOG_SELECTOR(app, accountDSID)
							LOG_SELECTOR(app, accountIdentifier)
							LOG_SELECTOR(app, softwareType)
							LOG_SELECTOR(app, versionIdentifier)
							LOG_SELECTOR(app, itemIdentifier)
							LOG_SELECTOR(app, containerPath)
							LOG_SELECTOR(app, storeFrontIdentifier)
							LOG_SELECTOR(app, description)
#else
							LOG_SELECTOR_SHORT(app, bundleIdentifier)
#endif
						}
					}
				}
			}
		}
		else
		{
			if (loadSharedLibrary(@"libdisplaystack"))
			{
				NSString *bundleId = [NSString stringWithCString:argv[1] encoding:NSASCIIStringEncoding];
				NSPrintf(@"Launching application %@...\n", bundleId);
				Class DSDisplayController = NSClassFromString(@"DSDisplayController");
				NSPrintf(@"DSDisplayController: %@\n", DSDisplayController);
				id displayController = GET_SELECTOR_RESULT(DSDisplayController, sharedInstance);
				NSPrintf(@"displayController: %@\n", displayController);
				[displayController backgroundTopApplication];
				//[displayController activateAppWithDisplayIdentifier:bundleId animated:YES];
			}
		}
	}
	return 0;
}
