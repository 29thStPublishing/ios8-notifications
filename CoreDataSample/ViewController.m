//
//  ViewController.m
//  CoreDataSample
//
//  Created by Lata Sadhwani on 10/7/14.
//

#import "ViewController.h"
#import <CoreData/CoreData.h>
#import "AppDelegate.h"

@interface ViewController () <UITableViewDataSource> {
    NSArray *booksArray;
}
@property (weak, nonatomic) IBOutlet UITableView *booksTable;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Books" inManagedObjectContext:appDelegate.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    booksArray = [appDelegate.managedObjectContext executeFetchRequest:fetchRequest error:nil];
    [self.booksTable reloadData];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    // Invalidate user activity before leaving the view controller
    [self.userActivity invalidate];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (BOOL) prefersStatusBarHidden {
    return YES;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return booksArray ? booksArray.count : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = @"BooksCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    NSManagedObject *book = booksArray[indexPath.row];
    cell.textLabel.text = [book valueForKey:@"title_text"];
    cell.detailTextLabel.text = [book valueForKey:@"category"];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSManagedObject *book = booksArray[indexPath.row];
    
    // Prepare for hand-off. Invalidate a useractivity if it exists
    [self.userActivity invalidate];
    
    // Make sure this value matches the key in NSUserActivityTypes in Info.plist
    NSUserActivity *myActivity = [[NSUserActivity alloc] initWithActivityType:@"com.adhoc.CoreDataSample.browsing"];
    NSString *webURL = [book valueForKey:@"weburl"];
    myActivity.webpageURL = [NSURL URLWithString:[webURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    // Assign the user activity for the view controller. This will show up the hand-off activity on the default browser
    // of the system
    [self setUserActivity:myActivity];
}

#pragma mark - NSUserActivityDelegate

- (void)userActivityWasContinued:(NSUserActivity *)userActivity {
    // Do some action here after the hand-off is complete i.e. page opened in browser on mac
}

@end
