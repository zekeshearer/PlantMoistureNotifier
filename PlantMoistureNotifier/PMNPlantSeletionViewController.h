//
//  PMNPlantSeletionViewController.h
//  PlantMoistureNotifier
//
//  Created by Zeke Shearer on 1/6/15.
//  Copyright (c) 2015 Zeke Shearer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PTDBean.h"

@protocol PMNPlantSelectionDelegate;

@interface PMNPlantSeletionViewController : UIViewController

@property (nonatomic, weak, readwrite) id<PMNPlantSelectionDelegate> delegate;
@property (nonatomic, strong) NSArray *currentlyAddedPlantNames;

@end

@protocol PMNPlantSelectionDelegate <NSObject>

- (void)plantSelectionViewController:(PMNPlantSeletionViewController *)plantSelectionViewController didSelectPlantName:(NSString *)name beaconUUID:(NSString *)beaconUUID major:(NSString *)major minor:(NSString *)minor identifier:(NSString *)identifier;
- (void)plantSelectionViewControllerDidSelectDone:(PMNPlantSeletionViewController *)plantSelectionViewController;

@end
