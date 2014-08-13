//
//  MTCameraSession.h
//  Camera Capture Session
//
//  https://github.com/johnemiller/MTCameraSession
//
//  Created by John Miller on 12/31/12.
//
//  Copyright 2013, Miltech Consulting
//
//  This file is part of MTCameraSession. This software may be used and distributed
//  according to the terms of the GNU General Public License version 2,
//  incorporated herein by reference.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol MTVideoCanvasP <NSObject>
@required

@property(nonatomic,readonly)AVCaptureVideoPreviewLayer *viewFinder;

@end

@interface MTCameraSession : NSObject<AVCaptureVideoDataOutputSampleBufferDelegate>
///
/// Preferred Initializer.  Pass the MTVideoCanvasP compliant view which implements
/// a sublayer that conforms to the MTVideoCanvas protocol.  This would normally
/// be your "viewfinder" view.
///
- (id)initWithDisplayCanvas:(UIView<MTVideoCanvasP>*)displayCanvas;
///
/// Call this method to initiate an image caprture "session".  This will direct the video
/// output of the camera to the specified displayCanvas.viewFinder specified in the
/// initWithDisplayCanvas method.
///
- (void)startSession;
///
/// Call this method after initiating a capture session using the [instance startSession] method.
/// If an error is returned, the imageData argumaent will be nil, otherwise the imageData argument will
/// contain the .jpeg data captured from the current displayCanvas.viewFinder.
///
- (void)captureStillJPEG:(void(^)(NSData* imageData, NSError *error))handler;
///
/// Call this method to end a camera capture session.  This method should be called if the capture
/// session is restarted, aborted or over for any other reason.  All necessary teardown of the
/// camera session is performed here.
///
- (void)stopSession;

@end
