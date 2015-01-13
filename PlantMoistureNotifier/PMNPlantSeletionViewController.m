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
#import "PTDIntelHex.h"

static NSString *PMNBeaconUUIDPart1 = @"A495";
static NSString *PMNBeaconUUIDPart2 = @"-C5B1-4B44-B512-1370F02D74DE";
static NSInteger PMNBeaconIdentiferResponseLength = 25;  // length of "Unique ID: 0xff7731a4ce3b"

@interface PMNPlantSeletionViewController () <UITableViewDelegate, UITableViewDataSource, PTDBeanManagerDelegate, PTDBeanDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *scanButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;

@property (strong, nonatomic) PTDBeanManager *beanManager;
@property (strong, nonatomic) NSTimer *scanningTimer;
@property (strong, nonatomic) NSTimer *serialResponseTimer;
@property (strong, nonatomic) NSMutableArray *discoveredBeans;
@property (strong, nonatomic) NSString *identifierString;
@property (strong, nonatomic) PTDBean *currentBean;
@property (strong, nonatomic) UIProgressView *progressView;
@property (strong, nonatomic) UIAlertView *progressAlertView;

@end

@implementation PMNPlantSeletionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setup];
    
    [self sketchHexFile];
    // Do any additional setup after loading the view.
}

- (void)setup
{
    self.discoveredBeans = [NSMutableArray array];
    self.beanManager = [[PTDBeanManager alloc] initWithDelegate:self];
}

- (void)showProgressView
{
    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    [self.progressView setProgress:0 animated:NO];
    self.progressAlertView = [[UIAlertView alloc] initWithTitle:@"Programming Sketch" message:nil delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
    [self.progressAlertView addSubview:self.progressView];
    [self.progressAlertView show];
}

- (void)dismissProgressView
{
    [self.progressAlertView dismissWithClickedButtonIndex:self.progressAlertView.cancelButtonIndex animated:YES];
    self.progressView = nil;
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
        [self rescanAction:sender];
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
        if ( error.code == 1 || error.code == 2 ) {
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

- (void)serialResponseFailed:(NSTimer *)sender
{
    [[[UIAlertView alloc] initWithTitle:@"Bean Not Pairing" message:@"Would you like to program the current bean with the Moisture Sensor sketch?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Program", nil] show];
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
    PTDBean *bean;
    
    bean = self.discoveredBeans[indexPath.row];
    [self fetchBeaconUUIDForBean:bean];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Bean Manager Delegate

- (void)fetchBeaconUUIDForBean:(PTDBean *)bean
{
    NSError *error;
    
    [self.beanManager connectToBean:bean error:&error];
    
    if ( error ) {
        [[[UIAlertView alloc] initWithTitle:@"Couldn't connect to bean" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
}

- (void)beanManager:(PTDBeanManager *)beanManager didConnectBean:(PTDBean *)bean error:(NSError *)error
{
    bean.delegate = self;
    [bean releaseSerialGate];
    self.currentBean = bean;
    self.identifierString = [[NSString alloc] init];
    self.serialResponseTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(serialResponseFailed:) userInfo:nil repeats:NO];
    [bean sendSerialString:@"UUID"];
}

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

#pragma mark - Bean Delegate

- (void)bean:(PTDBean *)bean serialDataReceived:(NSData *)data
{
    NSString *beaconUUID;
    NSArray *beaconIdentifiers;
    
    beaconUUID = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    self.identifierString = [self.identifierString stringByAppendingString:beaconUUID];
    if ( self.identifierString.length == PMNBeaconIdentiferResponseLength ) {
        beaconIdentifiers = [self beaconIdentifiersFromString:self.identifierString];
        if ( beaconIdentifiers.count ) {
            [self.serialResponseTimer invalidate];
            self.serialResponseTimer = nil;
            [self.delegate plantSelectionViewController:self didSelectPlantName:bean.name beaconUUID:beaconIdentifiers[0] major:beaconIdentifiers[1] minor:beaconIdentifiers[2] identifier:[self.identifierString substringFromIndex:13]];
            self.identifierString = nil;
            [self.beanManager disconnectBean:bean error:nil];
        }
    }
}

- (void)bean:(PTDBean *)bean didProgramArduinoWithError:(NSError *)error
{
    [self dismissProgressView];
    [self.beanManager disconnectBean:bean error:nil];
    self.currentBean = nil;
}

- (void)bean:(PTDBean *)bean ArduinoProgrammingTimeLeft:(NSNumber *)seconds withPercentage:(NSNumber *)percentageComplete
{
    [self.progressView setProgress:percentageComplete.floatValue animated:YES];
}

- (NSString *)beaconUUIDFromIdentifier:(NSString *)identifierString
{
    return [NSString stringWithFormat:@"%@%@%@",PMNBeaconUUIDPart1,identifierString,PMNBeaconUUIDPart2];
}

- (NSArray *)beaconIdentifiersFromString:(NSString *)identifierString
{
    NSString *beaconUUID;
    NSString *beaconMajor;
    NSString *beaconMinor;
    
    if ( identifierString.length != PMNBeaconIdentiferResponseLength ) {
        return nil;
    }
    beaconUUID = [self beaconUUIDFromIdentifier:[identifierString substringWithRange:NSMakeRange(13, 4)]];
    beaconMajor = [identifierString substringWithRange:NSMakeRange(17, 4)];
    beaconMinor = [identifierString substringWithRange:NSMakeRange(21, 4)];
    
    return @[beaconUUID, beaconMajor, beaconMinor];
}

#pragma mark - AlertView Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    PTDIntelHex *sketchHexFile;
    
    if ( buttonIndex != alertView.cancelButtonIndex ) {
        sketchHexFile = [self sketchHexFile];
        if ( sketchHexFile ) {
            [self.currentBean programArduinoWithRawHexImage:sketchHexFile.bytes andImageName:sketchHexFile.name];
            [self showProgressView];
        }
    }
}

- (PTDIntelHex *)sketchHexFile
{
    NSString *path;
    PTDIntelHex *sketchHexFile;
    
    path = [[NSBundle mainBundle] resourcePath];
    path = [path stringByAppendingPathComponent:@"MoistureMonitor.cpp.hex"];
    sketchHexFile = [[PTDIntelHex alloc] initWithFileURL:[NSURL URLWithString:path]];
    return sketchHexFile;
}

@end
