//
//  AppDelegate.h
//  Muse
//
//  Created by Pasca Maulana on 29/9/14.
//  Copyright (c) 2014 Digi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (assign, nonatomic) BOOL isLogedin;
@property (strong, nonatomic) NSMutableArray *shopModelList;
@property (strong, nonatomic) NSMutableArray *shopCategoryList;
@property (assign, nonatomic) int isSetCategory;

@end

