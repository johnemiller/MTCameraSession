//
//  MTCameraSession.m
//  Camera Capture Session
//
//  Created by John Miller on 12/31/12.
//
//  Copyright 2013, Miltech Consulting
//
//  This file is part of MTCameraSession. This software may be used and distributed
//  according to the terms of the GNU General Public License version 2,
//  incorporated herein by reference.
//

import "CameraSession.h"

@interface CameraSession () {
    AVCaptureSession *_session;
    AVCaptureDevice *_camera;
    AVCaptureDeviceInput *_videoInputStream;
    AVCaptureVideoDataOutput *_videoOutput;
    AVCaptureStillImageOutput *_stillOutput;
    UIView<MTVideoCanvasP>* _canvas;
    BOOL _sessionTerminated;
}

@end
#pragma mark --
#pragma mark CameraSession Implementation
#pragma mark --

@implementation CameraSession

#pragma mark --
#pragma mark Object lifecycle
#pragma mark --

- (id)initWithDisplayCanvas:(UIView<MTVideoCanvasP>*)displayCanvas
{
    NSParameterAssert(displayCanvas!=nil && displayCanvas.viewFinder!=nil);
    self = [super init];
    if (self)
    {
        _canvas = displayCanvas;
        //set up the AV session
        _session = [[AVCaptureSession alloc] init];
        [_session setSessionPreset:AVCaptureSessionPresetMedium];
        // set the session on the canvas
        [_canvas.viewFinder setSession:_session];
        // set up the video camera
        _camera = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        NSError* error = nil;
        _videoInputStream = [AVCaptureDeviceInput deviceInputWithDevice:_camera error:&error];
        NSAssert(error==nil, @"Could not initiate a video capture session!");
        [_session addInput:_videoInputStream];
        _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
        // Set the video output to store frame in BGRA (better performance)
        NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
        NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
        NSDictionary* videoSettings = @{value : key};
        [_videoOutput setVideoSettings:videoSettings];
        [_videoOutput setSampleBufferDelegate:self queue:app_get_process_queue()];
        [_session addOutput:_videoOutput];
        _stillOutput = [[AVCaptureStillImageOutput alloc] init];
        NSDictionary *outputSettings = @{AVVideoCodecJPEG : AVVideoCodecKey};
        [_stillOutput setOutputSettings:outputSettings];
        [_session addOutput:_stillOutput];
    }
    return self;
}

- (void)dealloc
{
    [_session stopRunning];
}

#pragma mark --
#pragma mark Public methods
#pragma mark --

- (void)startSession
{
    _sessionTerminated = NO;
    [_session startRunning];
}

- (void)stopSession
{
    _sessionTerminated = YES;
    [_session stopRunning];
}

- (void)captureStillJPEG:(void(^)(NSData* imageData, NSError *error))handler
{
    if (_canvas)
    {
        AVCaptureConnection *videoConnection = nil;
        for (AVCaptureConnection *connection in _stillOutput.connections)
        {
            for (AVCaptureInputPort *port in [connection inputPorts])
            {
                if ([[port mediaType] isEqual:AVMediaTypeVideo])
                {
                    videoConnection = connection;
                    break;
                }
            }
            if (videoConnection)
                break;
        }
        
        [_stillOutput captureStillImageAsynchronouslyFromConnection:videoConnection
                                                  completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error)
         {
             NSData* imageData = nil;

             if (error)
                 NSLog(@"Error capturing camera image: %@", error);

             if (imageSampleBuffer)
                 imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];

             if ([NSThread isMainThread])
                 handler(imageData, error);
             else
             {
                 dispatch_async(dispatch_get_main_queue(), ^{
                     handler(imageData, error);
                 });
             }
         }];
    }
}

#pragma mark --
#pragma mark <AVCaptureVideoDataOutputSampleBufferDelegate> methods
#pragma mark --

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    // NOTE:  we have no processing of video frames to do here...
    // the AVCaptureStillImageOutput will handle everything w/ respect to getting the still image from the preview layer.
}

@end
