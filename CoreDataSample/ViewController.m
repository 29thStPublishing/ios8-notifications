//
//  ViewController.m
//  CoreDataSample
//
//  Created by StandardUser on 10/7/14.
//  Copyright (c) 2014 NewGenApps. All rights reserved.
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

@end
