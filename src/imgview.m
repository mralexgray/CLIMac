#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "../build/etc/imgview/menu.h"

@interface IKImageView (IKPrivate) - (void) setAnimates:(BOOL)a; @end
@interface S : NSObject {} @end

int main(int argc, char *argv[]) {
	NSAutoreleasePool *pool = [NSAutoreleasePool new];

	if (argc != 2) {
		fprintf(stderr, "usage:  %s [<image>]\n", argv[0]);
		return 1;
	}

	S *s = [[S allocWithZone:NULL] init];
	[[NSApplication sharedApplication] setDelegate:s];

	ProcessSerialNumber psn;
	if (!(GetCurrentProcess(&psn) == noErr && TransformProcessType(&psn, kProcessTransformToForegroundApplication) == noErr))
		warnx("Forced to run in background");

	NSMenu *n = [NSUnarchiver unarchiveObjectWithData:[NSData dataWithBytesNoCopy:_g_menu length:_g_menu_len freeWhenDone:NO]];
//	NSMutableArray *a = [NSMutableArray array];
//	NSNib *n = [[NSNib alloc] initWithContentsOfURL:[NSURL fileURLWithPath:@"/Users/ankur/Work/CLIMac/build/etc/imgview/main.xib"]];
//	[n instantiateNibWithExternalNameTable:[NSDictionary dictionaryWithObjectsAndKeys:a, NSNibTopLevelObjects, nil]];
	[NSApp setMainMenu:n];

	NSWorkspace *ws = [NSWorkspace sharedWorkspace];
	NSImage *img = [ws iconForFile:[NSHomeDirectory() stringByAppendingPathComponent:@"Pictures"]];
	[img setSize:NSMakeSize(512.0f, 512.0f)];
	[NSApp setApplicationIconImage:img];

	[pool release];

	[NSApp run];
}

@implementation S
- (void) applicationDidFinishLaunching: (NSNotification *)aNotification {
	NSWindow *win = [[NSWindow alloc] initWithContentRect:NSMakeRect(0.0f, 0.0f, 920.0f, 720.0f) styleMask: (NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask) backing:NSBackingStoreBuffered defer:NO];
	IKImageView *b = [[IKImageView alloc] init];
	[win setContentView:b];
	[b setDelegate:self];
	[b setDoubleClickOpensImageEditPanel:YES];
	if ([b respondsToSelector:@selector(setAnimates:)])
		[b setAnimates:YES];
	[b setAutoresizes:YES];
	[b setCurrentToolMode:IKToolModeMove];
	NSString *path = [[[NSProcessInfo processInfo] arguments] lastObject];
	if (![path isEqualToString:@"-"]) {
		NSURL *url = [NSURL fileURLWithPath:path];
		[b setImageWithURL:url];
		[win setTitleWithRepresentedFilename:[url path]];
	} else {
		NSDictionary *mImageProperties = nil;
		CGImageRef image = NULL;
		CGImageSourceRef isr = CGImageSourceCreateWithData((CFDataRef)[[NSFileHandle fileHandleWithStandardInput] readDataToEndOfFile], NULL);
		if (isr) {
			image = CGImageSourceCreateImageAtIndex(isr, 0, NULL);
			if (image)
				mImageProperties = (NSDictionary*)CGImageSourceCopyPropertiesAtIndex(isr, 0, (CFDictionaryRef)mImageProperties);
			CFRelease(isr);
		}
		if (image) {
			[b setImage:image imageProperties:mImageProperties];
			CGImageRelease(image);
			[mImageProperties release];
		}
	}
	if (![b image])
		errx(1, "Invalid image");
	NSSize size = [b imageSize];
	if (NSContainsRect(NSMakeRect(0.0f, 0.0f, size.width, size.height), [b bounds]))
		[b zoomImageToFit:nil];
	[win center];
	[win setFrameAutosaveName:@"v"];
	[win makeKeyAndOrderFront:nil];
	[b release];
	[NSApp activateIgnoringOtherApps:YES];
}
- (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)a { return YES; }
@end

@implementation IKImageView (i)
- (NSInteger)mode {
	NSString *cur = [self currentToolMode];
	const all = ((NSString *[]){IKToolModeMove, IKToolModeSelect, IKToolModeCrop, IKToolModeRotate, IKToolModeAnnotate});
	for (int i = 0; i < sizeof(all)/sizeof(all[0]); i++)
		if ([all[i] isEqualToString:cur])
			return i;
	return -1;
}
-(void)setMode:(id)sender {
	[self setCurrentToolMode:((NSString *[]){IKToolModeMove, IKToolModeSelect, IKToolModeCrop, IKToolModeRotate, IKToolModeAnnotate})[[sender tag]]];
}
-(void)magnifyWithEvent:(NSEvent *)anEvent {
	float new = [self zoomFactor] + ([anEvent deltaZ] / 100.0f);
	if (new <= 1e-10f) new = 1e-10f;
//	[self setImageZoomFactor:new centerPoint:[self convertPoint:[anEvent locationInWindow] fromView:nil]];
	[self setZoomFactor:new];
}
-(void)rotateWithEvent:(NSEvent *)anEvent {
	float new = ([anEvent rotation] * (float)M_PI / 180.0f);
	self.rotationAngle += new;
//	[self setRotationAngle:new centerPoint:[self convertPoint:[anEvent locationInWindow] fromView:nil]];
}
@end