//
//  TestViewController.m
//  HTTPNetworkDemo
//
//  Created by DelpanSun on 2020/5/13.
//  Copyright © 2020 DelpanSun. All rights reserved.
//

#import "TestViewController.h"
#import "BusinessNetwork+DSDemo.h"

@interface TestViewController ()

@end

@implementation TestViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
}

- (IBAction)type1Action:(UIButton *)sender
{
    [BusinessNetwork type1WithParameters:@{} completion:^(NSURLRequest *request, BusinessResponse *response, NSError *error) {
        
        NSLog(@"%@", response.data);
    }];
}

- (IBAction)type2Action:(UIButton *)sender
{
    [BusinessNetwork type2WithParameters:@{} completion:^(NSURLRequest *request, BusinessResponse *response, NSError *error) {
        
        NSLog(@"%@", response.data);
    }];
}

@end















