//
//  RootViewController.m
//  gpuimage
//
//  Created by 白鹤 on 16/12/2.
//  Copyright © 2016年 白鹤. All rights reserved.
//

#import "RootViewController.h"
#import "Case01ViewController.h"
#import "Case02ViewController.h"

@interface RootViewController ()<UITableViewDelegate,UITableViewDataSource>;

@property (nonatomic, strong)UITableView *tableView;

@property (nonatomic, strong)NSMutableArray *titleArr;

@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self createData];
    [self createView];
    
}

- (void)createData{
    
    self.titleArr = [NSMutableArray arrayWithObjects:@"边录制,边合成",@"等待~~", nil];
    
}

- (void)createView{
    
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    [self.view addSubview:self.tableView];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    self.tableView.rowHeight = 60;
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:NSStringFromClass([UITableViewCell class])];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.titleArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([UITableViewCell class]) forIndexPath:indexPath];
    NSString *title = self.titleArr[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"Case%0.2ld  %@",indexPath.row + 1,title];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UIViewController *vc;
    
    switch (indexPath.row) {
        case 0:
            
            vc = [[Case01ViewController alloc] init];
            
            break;
        case 1:
            
            vc = [[Case02ViewController alloc] init];
            
            break;
            
        default:
            break;
    }
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
