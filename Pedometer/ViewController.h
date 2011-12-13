//
//  ViewController.h
//  Pedometer
//
//  Created by Peter de Tagyos on 12/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UIAccelerometerDelegate> {
    float px;
    float py;
    float pz;

    int numSteps;
    BOOL isChange;
    BOOL isSleeping;
}

@property (retain, nonatomic) IBOutlet UILabel *stepCountLabel;

- (IBAction)reset:(id)sender;

@end
