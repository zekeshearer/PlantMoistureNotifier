//
//  PMNPlantSeletionViewController.m
//  PlantMoistureNotifier
//
//  Created by Zeke Shearer on 1/6/15.
//  Copyright (c) 2015 Zeke Shearer. All rights reserved.
//

#import "PMNPlantSeletionViewController.h"
#import "PTDBean.h"
#import "PTDBeanManager.h"

@interface PMNPlantSeletionViewController () <UITableViewDelegate, UITableViewDataSource, PTDBeanManagerDelegate>

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *scanButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;

@property (strong, nonatomic) PTDBeanManager *beanManager;
@property (strong, nonatomic) NSTimer *scanningTimer;
@property (strong, nonatomic) NSMutableArray *discoveredBeans;

@end

@implementation PMNPlantSeletionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setup];
    // Do any additional setup after loading the view.
}

- (void)setup
{
    self.discoveredBeans = [NSMutableArray array];
    self.beanManager = [[PTDBeanManager alloc] initWithDelegate:self];
}

#pragma mark - Action Methods


- (IBAction)done:(id)sender
{
    [self.delegate plantSelectionViewControllerDidSelectDone:self];
}

- (IBAction)toggleScanning:(id)sender
{
    if ( self.scanningTimer.valid ) {
        [self stopScan:sender];
    } else {
        [self startScan];
    }
}

- (void)rescanAction:(id)sender
{
    [self stopScan:sender];
    
    // ...clear the table...
    self.discoveredBeans = [NSMutableArray array];
    [[self tableView] reloadData];
    
    // ...and start scanning again
    [self startScan];
}

#pragma mark - Beans

- (void)startScan
{
    NSError *error;
    [self.beanManager startScanningForBeans_error:&error];
    if (error) {
        if ( error.code == 1 ) {
            [[[UIAlertView alloc] initWithTitle:@"Bluetooth Required" message:@"Enable Bluetooth in iOS Settings." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }
        [self.delegate plantSelectionViewControllerDidSelectDone:self];
        return;
    }
    self.scanningTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(stopScan:) userInfo:nil repeats:NO];

}

- (void)stopScan:(id)sender
{
    NSError *error;
    [self.beanManager stopScanningForBeans_error:&error];
    if (error) {
        
    }
    if ( self.scanningTimer ) {
        [self.scanningTimer invalidate];
    }
}

#pragma mark - TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.discoveredBeans.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    PTDBean *plant;
    
    cell = [tableView dequeueReusableCellWithIdentifier:@"PlantCell"];
    if ( !cell ) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"PlantCell"];
    }
    plant = self.discoveredBeans[indexPath.row];
    cell.textLabel.text = plant.name;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.delegate plantSelectionViewController:self didSelectPlant:self.discoveredBeans[indexPath.row]];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Bean Manager

- (void)beanManagerDidUpdateState:(PTDBeanManager *)manager
{
    if ([manager state] == BeanManagerState_PoweredOn) {
        [self startScan];
    }
}

- (void)BeanManager:(PTDBeanManager *)beanManager didDiscoverBean:(PTDBean *)bean error:(NSError *)error
{
    if (![self.currentlyAddedPlantNames containsObject:bean.name]) {
        [self.discoveredBeans addObject:bean];
    }
    [[self tableView] reloadData];
}


@end
