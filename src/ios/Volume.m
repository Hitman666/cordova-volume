#import "Volume.h"

@implementation Volume {
  NSString* changeCallbackId;
}

- (void) pluginInitialize {
  [super pluginInitialize];
  [[AVAudioSession sharedInstance] setActive:YES error:nil];

  [[AVAudioSession sharedInstance] addObserver:self forKeyPath:@"outputVolume" options:NSKeyValueObservingOptionNew context:nil];
}

- (void) getVolume:(CDVInvokedUrlCommand*)command {
  [self sendCurrentVolumeTo:command.callbackId];
}

- (void) setVolumenChangeCallback:(CDVInvokedUrlCommand*) command {
  if (changeCallbackId) {
    NSLog(@"Overwritting volumeChangeCallback: %@!", changeCallbackId);
  }

  changeCallbackId = command.callbackId;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
  if (changeCallbackId && [keyPath isEqual:@"outputVolume"]) {
    [self sendCurrentVolumeTo:changeCallbackId];
  }
}

- (void) sendCurrentVolumeTo:(NSString*) callbackId {
  CDVPluginResult* result = [self currentVolume];
  [result setKeepCallback:[NSNumber numberWithBool:YES]];
  [self.commandDelegate sendPluginResult: result callbackId:callbackId];
}

- (CDVPluginResult*) currentVolume {
  AVAudioSession* audioSession = [AVAudioSession sharedInstance];
  float volume = audioSession.outputVolume;
  
  Boolean _isMuted = [self isMuted];
  if (_isMuted)
    volume = 0;

  return [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDouble:volume];
}

- (Boolean)isMuted{
    bool isMuted = false;

    /*if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0") && ([[AVAudioSession sharedInstance] outputVolume] < 0.1)) {
        isMuted = true;
    }
    else{
      MPVolumeView *slide = [MPVolumeView new];
      UISlider *volumeViewSlider = nil;

      for (UIView *view in [slide subviews]){
        if ([[[view class] description] isEqualToString:@"MPVolumeSlider"]) {
          volumeViewSlider = (UISlider *) view;
          break; 
        }
      }

      if (volumeViewSlider) {
        if([volumeViewSlider value] < 0.1) {
          isMuted = true;
        }
      }
    }*/

    Class avSystemControllerClass = NSClassFromString(@"AVSystemController");
    id avSystemControllerInstance = [avSystemControllerClass performSelector:@selector(sharedAVSystemController)];

    NSInvocation *privateInvocation = [NSInvocation invocationWithMethodSignature:
                                      [avSystemControllerClass instanceMethodSignatureForSelector:
                                       @selector(getActiveCategoryMuted:)]];

    [privateInvocation setTarget:avSystemControllerInstance];
    [privateInvocation setSelector:@selector(getActiveCategoryMuted:)];
    [privateInvocation setArgument:&isMuted atIndex:2];
    [privateInvocation invoke];

  return isMuted;
}

@end