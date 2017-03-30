//
//  RecordViewController.m
//  iOS_2D_RecordPath
//
//  Created by PC on 15/8/3.
//  Copyright (c) 2015年 FENGSHENG. All rights reserved.
//

#import "RecordViewController.h"
#import "DisplayViewController.h"
#import "AMapRouteRecord.h"
#import "FileHelper.h"

@interface RecordViewController()<UITableViewDataSource,UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSMutableArray *recordArray;

@end

@implementation RecordViewController

#pragma mark - UITableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DisplayViewController *displayController = [[DisplayViewController alloc] initWithNibName:nil bundle:nil];
    [displayController setRecord:self.recordArray[indexPath.row]];
    
    [self.navigationController pushViewController:displayController animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle != UITableViewCellEditingStyleDelete)
    {
        return;
    }
    
    [FileHelper deleteFile:[[self.recordArray objectAtIndex:indexPath.row] title]];
    [self.recordArray removeObjectAtIndex:indexPath.row];
  
    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark - UITableView DataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.recordArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIndentifier = @"recordCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIndentifier];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIndentifier];
    }
    
    AMapRouteRecord *record = self.recordArray[indexPath.row];
    
    cell.textLabel.text = [record title];
    cell.detailTextLabel.text = [record subTitle];
    
    return cell;
}

#pragma mark - Life Cycle

- (id)init
{
    self = [super init];
    if (self)
    {
        _recordArray = [NSMutableArray arrayWithArray:[FileHelper recordsArray]];
        if (_recordArray.count == 0)
        {
            // 如果没有数据，则添加测试数据。
            NSString *tempPath = [[NSBundle mainBundle] pathForResource:@"temp_2017-03-30" ofType:nil];
            AMapRouteRecord *record = [NSKeyedUnarchiver unarchiveObjectWithFile:tempPath];
            
            NSString *name = record.title;
            NSString *path = [FileHelper filePathWithName:name];
            
            [NSKeyedArchiver archiveRootObject:record toFile:path];
            
            _recordArray = [NSMutableArray arrayWithArray:[FileHelper recordsArray]];
        }
        
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self.view addSubview:self.tableView];
}
@end
