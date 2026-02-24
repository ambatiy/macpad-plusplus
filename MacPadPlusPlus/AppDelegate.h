#import <Cocoa/Cocoa.h>

@class MainWindowController;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, strong) MainWindowController *mainWindowController;

- (IBAction)newDocument:(id)sender;
- (IBAction)openDocument:(id)sender;
- (IBAction)showPreferences:(id)sender;

@end
