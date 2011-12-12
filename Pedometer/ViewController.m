//
//  ViewController.m
//  Pedometer
//
//  Created by Peter de Tagyos on 12/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"

#define kUpdateFrequency    60.0

@implementation ViewController
@synthesize stepCountLabel;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Enable listening to the accelerometer
    [[UIAccelerometer sharedAccelerometer] setUpdateInterval:1.0 / kUpdateFrequency];
    [[UIAccelerometer sharedAccelerometer] setDelegate:self];
    
    px = py = pz = 0;
    numSteps = 0;
    
    self.stepCountLabel.text = [NSString stringWithFormat:@"%d", numSteps];
    
}

- (void)viewDidUnload
{
    [self setStepCountLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

/*
// UIAccelerometerDelegate method, called when the device accelerates.
-(void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {

    float xx = acceleration.x;
    float yy = acceleration.y;
    float zz = acceleration.z;
    
    float dot = (px * xx) + (py * yy) + (pz * zz);
    float a = ABS(sqrt(px * px + py * py + pz * pz));
    float b = ABS(sqrt(xx * xx + yy * yy + zz * zz));
    
    dot /= (a * b);
    
    if (dot <= 0.80) {
        if (!isChange) {
            isChange = YES;
            numSteps += 1;
            self.stepCountLabel.text = [NSString stringWithFormat:@"%d", numSteps];
        } else {
            isChange = NO;
        }
    }
    
    px = xx; py = yy; pz = zz;
    
}
*/

unsigned int timeSkipper = 0;
unsigned int timeToSkip = 0;
double magicDelta = 0;
NSTimeInterval lastStep;
float lastdot = 1;

#define trainingLen 100
double training[trainingLen];
unsigned int trainingPos = 0;

double getSteps( double bVar, unsigned int tVar ) {
    unsigned int i;
    double recordedSteps = 0;
    double score = 0;
    unsigned int timer = tVar / 2;
    for( i=0; i<trainingLen; i++ ) {
        if( timer >= tVar ) {
            score += training[i];
            if( score >= bVar && score <= bVar*1.5 ) {
                recordedSteps++;
                timer = 0;
            }
        }
        timer++;
    }
    return recordedSteps;
}

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {

    float xx = acceleration.x;
    float yy = acceleration.y;
    float zz = acceleration.z;

    // find the angle between this one and the last one
    // (dot product)
    float dot = (px * xx) + (py * yy) + (pz * zz);
    float a = ABS(sqrt(px * px + py * py + pz * pz));
    float b = ABS(sqrt(xx * xx + yy * yy + zz * zz));
    
    dot /= (a * b);
    dot = fabs(dot);
    
    double diff = fabs(lastdot - dot);
    
    if( magicDelta ) {
        
        if( timeSkipper == timeToSkip ) {
            if( diff >= magicDelta && diff <= magicDelta*1.5 ) {
                NSLog(@"step");
                timeSkipper = 0;
                numSteps += 1;
                self.stepCountLabel.text = [NSString stringWithFormat:@"%d", numSteps];
            }
        } else {
            timeSkipper++;
        }
        
    } else if( trainingPos+1 == trainingLen ) {
        // do magic...
        NSLog(@"done");
        
        unsigned int givenSteps = 12;
        
        double varA = 0;
        double varB = 100;
        double timeA = trainingLen / (givenSteps*2.5);
        double timeB = trainingLen / (givenSteps/2.5);
        
        int attempts = 100;
        while( attempts-- ) {
            double stepsA = getSteps( varA, timeA );
            double stepsB = getSteps( varB, timeA );
            
            double stepsC = getSteps( varA, timeB );
            double stepsD = getSteps( varB, timeB );
            
            double deltaA = fabs(givenSteps - stepsA);
            double deltaB = fabs(givenSteps - stepsB);
            double deltaC = fabs(givenSteps - stepsC);
            double deltaD = fabs(givenSteps - stepsD);
            
            double newVar1 = varA + ((varB - varA) * 0.6);
            double newVar2 = timeA + ((timeB - timeA) * 0.6);
            
            if( attempts % 2 == 0 ) {
                if( deltaB < deltaA && stepsB <= givenSteps ) {
                    NSLog(@"B wins with %g steps and a delta of %g newVar = %g", stepsB,deltaB,newVar1);
                    varA = newVar1;
                } else {
                    NSLog(@"A wins with %g steps and a delta of %g newVar = %g", stepsA,deltaA,newVar1);
                    varB = newVar1;
                }
            } else {
                if( deltaD < deltaC && stepsD <= givenSteps ) {
                    NSLog(@"D wins with %g steps and a delta of %g newVar = %g", stepsD,deltaD,newVar2);
                    timeA = newVar2;
                } else {
                    NSLog(@"C wins with %g steps and a delta of %g newVar = %g", stepsC,deltaC,newVar2);
                    timeB = newVar2;
                }
            }
        }
        NSLog(@"done");
        
        magicDelta = varA;
        timeToSkip = timeA;
        timeSkipper = 0;
    } else {
        NSLog(@"diff = %g", diff );
        training[trainingPos] = diff;
        trainingPos++;
    }
    
    lastdot = dot;
    px = xx;
    py = yy;
    pz = zz;

}

/*
 
 
 void changeInXYZ( float x, float y, float z )
 {
 watchDog++;
 handleNetworking();
 
 const float speedFACTOR = 0.35;         // speed = timer..  lower number = more polling = faster movement
 const float bounceFACTOR = 0.16;                // higher bounce threshold means it takes more motion to count as a step
 
 // normalize the vector
 double dist = sqrtf( (x*x) + (y*y) + (z*z) );
 if( dist == 0 ) dist = 1;       // avoid div by zero - just in case :)
 x /= dist;
 y /= dist;
 z /= dist;
 
 // find the angle between this one and the last one
 // (dot product)
 double dot = (x*lastx) + (y*lasty) + (z*lastz);
 dot = fabs(dot);
 //NSLog(@"dot = %f", dot );
 
 double diff = fabs(lastdot - dot);
 
 if( magicDelta ) {
 
 if( timeSkipper == timeToSkip ) {
 if( diff >= magicDelta && diff <= magicDelta*1.5 ) {
 NSLog(@"step");
 timeSkipper = 0;
 }
 } else {
 timeSkipper++;
 }
 
 } else if( trainingPos+1 == trainingLen ) {
 // do magic...
 NSLog(@"done");
 
 unsigned int givenSteps = 12;
 
 double varA = 0;
 double varB = 100;
 double timeA = trainingLen / (givenSteps*2.5);
 double timeB = trainingLen / (givenSteps/2.5);
 
 int attempts = 100;
 while( attempts-- ) {
 double stepsA = getSteps( varA, timeA );
 double stepsB = getSteps( varB, timeA );
 
 double stepsC = getSteps( varA, timeB );
 double stepsD = getSteps( varB, timeB );
 
 double deltaA = fabs(givenSteps - stepsA);
 double deltaB = fabs(givenSteps - stepsB);
 double deltaC = fabs(givenSteps - stepsC);
 double deltaD = fabs(givenSteps - stepsD);
 
 double newVar1 = varA + ((varB - varA) * 0.6);
 double newVar2 = timeA + ((timeB - timeA) * 0.6);
 
 if( attempts % 2 == 0 ) {
 if( deltaB < deltaA && stepsB <= givenSteps ) {
 NSLog(@"B wins with %g steps and a delta of %g newVar = %g", stepsB,deltaB,newVar1);
 varA = newVar1;
 } else {
 NSLog(@"A wins with %g steps and a delta of %g newVar = %g", stepsA,deltaA,newVar1);
 varB = newVar1;
 }
 } else {
 if( deltaD < deltaC && stepsD <= givenSteps ) {
 NSLog(@"D wins with %g steps and a delta of %g newVar = %g", stepsD,deltaD,newVar2);
 timeA = newVar2;
 } else {
 NSLog(@"C wins with %g steps and a delta of %g newVar = %g", stepsC,deltaC,newVar2);
 timeB = newVar2;
 }
 }
 }
 NSLog(@"done");
 
 magicDelta = varA;
 timeToSkip = timeA;
 timeSkipper = 0;
 } else {
 NSLog(@"diff = %g", diff );
 training[trainingPos] = diff;
 trainingPos++;
 }
 
 lastdot = dot;
 lastx = x;
 lasty = y;
 lastz = z;
 }
 
*/

- (void)dealloc {
    [stepCountLabel release];
    [super dealloc];
}

- (IBAction)reset:(id)sender {
    numSteps = 0;
    self.stepCountLabel.text = [NSString stringWithFormat:@"%d", numSteps];
}

@end
