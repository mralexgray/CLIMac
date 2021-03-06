#import <Cocoa/Cocoa.h>

int main (int argc, char *argv[]) {
	if ((argc == 2 && !isatty(STDOUT_FILENO)) || argc == 3) {
		[NSAutoreleasePool new];
		[NSApplication sharedApplication];

		CFStringRef inPath = CFStringCreateWithFileSystemRepresentation(NULL, argv[1]);
		if (inPath) {
			NSAttributedString *str = (argv[1][0]=='-'&&argv[1][1]=='\0') ? [[NSAttributedString alloc] initWithData:[[NSFileHandle fileHandleWithStandardInput] readDataToEndOfFile] options:[NSDictionary dictionaryWithObject:NSHTMLTextDocumentType forKey:NSDocumentTypeDocumentOption] documentAttributes:nil error:nil] : [[NSAttributedString alloc] initWithPath:(NSString *)inPath documentAttributes:NULL];
			CFRelease(inPath);
			if (str) {
				NSImage *img = [[NSImage alloc] initWithSize:[str size]];
				[img lockFocus];
				[str drawAtPoint:NSZeroPoint];
				[img unlockFocus];
				[str release];
				NSData *data = [img TIFFRepresentationUsingCompression:NSTIFFCompressionLZW factor:0.0f];
				[img release];
				if (argc == 3) {
					CFStringRef outPath = CFStringCreateWithFileSystemRepresentation(NULL, argv[2]);
					if (outPath) {
						if ([data writeToFile:(NSString *)outPath atomically:NO])
							return 0;
						CFRelease(outPath);
					}
				} else {
					if (fwrite([data bytes], [data length], 1, stdout) == 1)
						return 0;
				}
				err(1, NULL);
			}
			errx(1, "%s: not a rich text document", argv[1]);
		}
		return 2;
	}
	fprintf(stderr, "usage:  %s <rtf> <out>.tiff\n", argv[0]);
	return 1;
}
