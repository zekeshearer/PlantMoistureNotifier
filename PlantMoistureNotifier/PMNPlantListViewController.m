//
//  ViewController.m
//  PlantMoistureNotifier
//
//  Created by Zeke Shearer on 1/6/15.
//  Copyright (c) 2015 Zeke Shearer. All rights reserved.
//

#import "PMNPlantListViewController.h"
#import "PMNPlantSeletionViewController.h"
#import <CoreLocation/CoreLocation.h>

@interface PMNPlantListViewController () <UITableViewDelegate, UITableViewDataSource, PMNPlantSelectionDelegate, CLLocationManagerDelegate>

@property (nonatomic, strong) NSArray *currentPlantNames;
@property (nonatomic, strong) NSArray *currentPlantUUIDs;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSMutableArray *dryPlantNames;

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end

static NSString *PMNPlantNamesUserDefaultsKey = @"PMNPlantNamesUserDefaultsKey";
static NSString *PMNPlantUUIDUserDefaultsKey = @"PMNPlantUUIDUserDefaultsKey";

@implementation PMNPlantListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self refreshPlants];
    [self setup];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)setup
{
    self.locationManager = [[CLLocationManager alloc] init];
    [self.locationManager requestAlwaysAuthorization];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UINavigationController *destinationNavigationController;
    PMNPlantSeletionViewController *plantSelectionViewController;
    
    destinationNavigationController = segue.destinationViewController;
    
    if ( [destinationNavigationController isKindOfClass:[UINavigationController class]] ) {
        plantSelectionViewController = [destinationNavigationController.viewControllers firstObject];
        plantSelectionViewController.currentlyAddedPlantNames = self.currentPlantNames;
        plantSelectionViewController.delegate = self;
    }
}

- (void)refreshPlants
{
    self.currentPlantNames = [[NSUserDefaults standardUserDefaults] arrayForKey:PMNPlantNamesUserDefaultsKey];
    if ( !self.currentPlantNames ) {
        self.currentPlantNames = [NSArray array];
    }
    self.currentPlantUUIDs = [[NSUserDefaults standardUserDefaults] arrayForKey:PMNPlantUUIDUserDefaultsKey];
    if ( !self.currentPlantUUIDs ) {
        self.currentPlantUUIDs = [NSArray array];
    }
    [self updateDryPlants];
    [self.tableView reloadData];
}

- (void)updateDryPlants
{
    NSSet *regions;
    
    regions = self.locationManager.monitoredRegions;
    self.dryPlantNames = [NSMutableArray array];
    for ( CLRegion *region in regions ) {
        if ( [self.currentPlantNames containsObject:region.identifier] ) {
            [self.locationManager requestStateForRegion:region];
        }
    }
}

#pragma mark - TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return  self.currentPlantNames.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if ( !cell ) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    cell.textLabel.text = self.currentPlantNames[indexPath.row];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *mutablePlantNames;
    NSMutableArray *mutablePlantUUIDs;
    
    mutablePlantNames = self.currentPlantNames.mutableCopy;
    [mutablePlantNames removeObjectAtIndex:indexPath.row];
    mutablePlantUUIDs = self.currentPlantUUIDs.mutableCopy;
    [mutablePlantUUIDs removeObjectAtIndex:indexPath.row];
    
    [[NSUserDefaults standardUserDefaults] setObject:mutablePlantNames forKey:PMNPlantNamesUserDefaultsKey];
    [[NSUserDefaults standardUserDefaults] setObject:mutablePlantUUIDs forKey:PMNPlantUUIDUserDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self removeRegionForPlantName:self.currentPlantNames[indexPath.row] plantUUID:self.currentPlantUUIDs[indexPath.row]];
    
    [self refreshPlants];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Plant Selection Delegate

- (void)plantSelectionViewController:(PMNPlantSeletionViewController *)plantSelectionViewController didSelectPlant:(PTDBean *)plant
{
    NSMutableArray *mutablePlantNames;
    NSMutableArray *mutablePlantUUIDs;
    
    mutablePlantNames = self.currentPlantNames.mutableCopy;
    [mutablePlantNames addObject:plant.name];
    mutablePlantUUIDs = self.currentPlantUUIDs.mutableCopy;
    [mutablePlantUUIDs addObject:plant.identifier.UUIDString];
    
    [[NSUserDefaults standardUserDefaults] setObject:mutablePlantNames forKey:PMNPlantNamesUserDefaultsKey];
    [[NSUserDefaults standardUserDefaults] setObject:mutablePlantUUIDs forKey:PMNPlantUUIDUserDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self addRegionForPlant:plant];
    [self refreshPlants];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)plantSelectionViewControllerDidSelectDone:(PMNPlantSeletionViewController *)plantSelectionViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Beacons

- (void)addRegionForPlant:(PTDBean *)plant
{
    CLBeaconRegion *region;
    
    region = [[CLBeaconRegion alloc] initWithProximityUUID:plant.identifier identifier:plant.name];
    [self.locationManager startMonitoringForRegion:region];
}

- (void)removeRegionForPlantName:(NSString *)name plantUUID:(NSString *)UUIDString
{
    CLBeaconRegion *region;
    
    region = [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:UUIDString] identifier:name];
    [self.locationManager stopMonitoringForRegion:region];
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    if ( state == CLRegionStateInside ) {
        [self.dryPlantNames addObject:region.identifier];
    }
    [self.tableView reloadData];
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    UILocalNotification *notification;
    
    [self.tableView reloadData];
    
    notification = [[UILocalNotification alloc] init];
    notification.alertBody = [NSString stringWithFormat:@"%@ needs to be watered", region.identifier];
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    
    //post local notification
}

@end
