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

@property (nonatomic, strong) NSArray *currentPlantDictionaries;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSMutableArray *dryPlantIdentifiers;

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end

static NSString *PMNPlantDictionariesKey = @"PMNPlantDictionariesKey";
static NSString *PMNPlantNameKey = @"PMNPlantNameKey";
static NSString *PMNPlantUUIDKey = @"PMNPlantUUIDKey";
static NSString *PMNPlantMajorKey = @"PMNPlantMajorKey";
static NSString *PMNPlantMinorKey = @"PMNPlantMinorKey";
static NSString *PMNPlantIdentifierKey = @"PMNPlantIdentifierKey";

@implementation PMNPlantListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setup];
    [self refreshPlants];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)setup
{
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    [self.locationManager requestAlwaysAuthorization];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UINavigationController *destinationNavigationController;
    PMNPlantSeletionViewController *plantSelectionViewController;
    
    destinationNavigationController = segue.destinationViewController;
    
    if ( [destinationNavigationController isKindOfClass:[UINavigationController class]] ) {
        plantSelectionViewController = [destinationNavigationController.viewControllers firstObject];
        plantSelectionViewController.currentlyAddedPlantNames = [self.currentPlantDictionaries valueForKeyPath:PMNPlantNameKey];
        plantSelectionViewController.delegate = self;
    }
}

- (void)refreshPlants
{
    self.currentPlantDictionaries = [[NSUserDefaults standardUserDefaults] arrayForKey:PMNPlantDictionariesKey];
    if ( !self.currentPlantDictionaries ) {
        self.currentPlantDictionaries = [NSArray array];
    }
    [self updateDryPlants];
    [self.tableView reloadData];
}

- (void)updateDryPlants
{
    NSSet *regions;
    
    regions = self.locationManager.monitoredRegions;
    
    if ( !regions.count ) {
        [self addRegionForPlantName:nil plantUUID:nil major:nil minor:nil identifier:@"test"];
    }
    
    self.dryPlantIdentifiers = [NSMutableArray array];
    for ( CLRegion *region in regions ) {
        if ( [[self.currentPlantDictionaries valueForKeyPath:PMNPlantIdentifierKey] containsObject:region.identifier] ) {
            [self.locationManager requestStateForRegion:region];
        }
    }
}

#pragma mark - TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.currentPlantDictionaries.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    NSDictionary *plant;
    
    cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if ( !cell ) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    plant = self.currentPlantDictionaries[indexPath.row];
    cell.textLabel.text = [plant valueForKey:PMNPlantNameKey];
    
    if ( [self.dryPlantIdentifiers containsObject:plant[PMNPlantIdentifierKey]] ) {
        cell.contentView.backgroundColor = [UIColor redColor];
    } else {
        cell.contentView.backgroundColor = [UIColor whiteColor];
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *mutableCurrentPlants;
    NSDictionary *plant;
    
    plant = self.currentPlantDictionaries[indexPath.row];
    
    mutableCurrentPlants = self.currentPlantDictionaries.mutableCopy;
    [mutableCurrentPlants removeObject:self.currentPlantDictionaries[indexPath.row]];
    [[NSUserDefaults standardUserDefaults] setObject:mutableCurrentPlants forKey:PMNPlantDictionariesKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self removeRegionForPlantName:plant[PMNPlantNameKey] plantUUID:plant[PMNPlantUUIDKey] major:plant[PMNPlantMajorKey] minor:plant[PMNPlantMinorKey] identifier:plant[PMNPlantIdentifierKey]];
    
    [self refreshPlants];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Plant Selection Delegate

- (void)plantSelectionViewController:(PMNPlantSeletionViewController *)plantSelectionViewController didSelectPlantName:(NSString *)name beaconUUID:(NSString *)beaconUUID major:(NSString *)major minor:(NSString *)minor identifier:(NSString *)identifier
{
    NSMutableArray *mutableCurrentPlants;
    NSDictionary *plant;
    
    plant = [self plantDictionaryFromUUID:beaconUUID name:name major:major minor:minor identifier:identifier];
    mutableCurrentPlants = self.currentPlantDictionaries.mutableCopy;
    [mutableCurrentPlants addObject:plant];
    [[NSUserDefaults standardUserDefaults] setObject:mutableCurrentPlants forKey:PMNPlantDictionariesKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self addRegionForPlantName:name plantUUID:beaconUUID major:major minor:minor identifier:identifier];
    [self refreshPlants];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)plantSelectionViewControllerDidSelectDone:(PMNPlantSeletionViewController *)plantSelectionViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Beacons

- (void)addRegionForPlantName:(NSString *)name plantUUID:(NSString *)UUIDString major:(NSString *)major minor:(NSString *)minor identifier:(NSString *)identifier
{
    CLBeaconRegion *region;

    region = [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:@"A4951111-C5B1-4B44-B512-1370F02D74DE"] major:123 minor:123 identifier:identifier];
    
    [self.locationManager startMonitoringForRegion:region];
}

- (void)removeRegionForPlantName:(NSString *)name plantUUID:(NSString *)UUIDString major:(NSString *)major minor:(NSString *)minor identifier:(NSString *)identifier
{
    CLBeaconRegion *region;
    
    region = [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:UUIDString] major:major.integerValue minor:minor.integerValue identifier:identifier];
    
    [self.locationManager stopMonitoringForRegion:region];
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    if ( state == CLRegionStateInside ) {
        [self.dryPlantIdentifiers addObject:region.identifier];
    }
    [self.tableView reloadData];
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    UILocalNotification *notification;
    NSDictionary *plant;
    
    [self.tableView reloadData];
    
    for ( NSDictionary *thisPlant in self.currentPlantDictionaries ) {
        if ( [[thisPlant valueForKey:PMNPlantIdentifierKey] isEqualToString:region.identifier] ) {
            plant = thisPlant;
            break;
        }
    }
    if ( !plant ) {
        return;
    }
    
    notification = [[UILocalNotification alloc] init];
    notification.alertBody = @"Don't forget the limes for tonight";
    
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}

- (NSDictionary *)plantDictionaryFromUUID:(NSString *)UUID name:(NSString *)name major:(NSString *)major minor:(NSString *)minor identifier:(NSString *)identifier
{
    return @{
             PMNPlantUUIDKey:UUID,
             PMNPlantNameKey:name,
             PMNPlantNameKey:major,
             PMNPlantMinorKey:minor,
             PMNPlantIdentifierKey:identifier
             };
}

@end
