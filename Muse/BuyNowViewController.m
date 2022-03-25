//
//  BuyNowViewController.m
//  Muse
//
//  Created by Mike Tran on 5/12/14.
//  Copyright (c) 2014 Digi. All rights reserved.
//

#import "BuyNowViewController.h"
#import "Utils.h"

#import "MuseSingleton.h"
#import "ShopList.h"

@implementation BuyNowViewController
@synthesize indicatorView;
@synthesize currentPerson, currentData;
@synthesize buyWebView;

- (instancetype) initWithPerson:(Person *)person
{
    self = [super init];
    if (self)
    {
        currentPerson = person;
        
        //set currentModel
        MuseSingleton *singleton = [MuseSingleton getInstance];
        ShopList *shopList;
        ShopDatas *sData;
        
        shopList = [singleton getShopList];
        
        for (sData in shopList.data)
        {
            if (currentPerson.productid == sData.product.id)
            {
                self.currentData = sData;
            }
        }
    }
    return self;
}

- (instancetype) initWithData:(ShopProduct *) currentProducts
{
    self = [super init];
    if (self)
    {
        self.currentData = [[ShopDatas alloc] init];
        self.currentData.product = currentProducts;
        
        self.currentPerson = [[Person alloc] init];
        self.currentPerson.name = self.currentData.product.name;
        self.currentPerson.productid = self.currentData.product.id;
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    [self layoutNavigationBar];
    
    buyWebView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    [buyWebView setDelegate:self];
    
    NSString *urlAddress = self.currentData.product.sourceUrl;
    NSURL *url = [NSURL URLWithString:urlAddress];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    [buyWebView loadRequest:requestObj];
    
    [self.view addSubview:buyWebView];
    
    indicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(buyWebView.bounds.size.width/2 -5, buyWebView.bounds.size.height/2- 40, 200, 200)];
    [self.view addSubview:indicatorView];
    [indicatorView sizeToFit];
    indicatorView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin);
    indicatorView.hidesWhenStopped  = YES;
    indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    indicatorView.color = [UIColor colorWithRed:255.f/255.f green:80.f/255.f blue:180.f/255.f alpha:1.0f];
    [indicatorView startAnimating];
    
}

- (void) webViewDidFinishLoad:(UIWebView *)webView
{
    [indicatorView stopAnimating];
}

- (void) layoutNavigationBar
{
    UIImage *myIcon = [Utils imageWithImage:[UIImage imageNamed:@"logo.png"] scaledToSize:CGSizeMake(76, 17)];
    UIImageView *titleView = [[UIImageView alloc] initWithImage:myIcon];
    [self.navigationItem setTitleView:titleView];
    
    UIBarButtonItem *leftButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"< Back" style:UIBarButtonItemStyleBordered target:self action:@selector(onBackBtnPressed)];
    [leftButtonItem setWidth:30];
    [leftButtonItem setTintColor:[UIColor colorWithRed:110.f/255.f green:110.f/255.f blue:110.f/255.f alpha:1.f]];
    [leftButtonItem setAccessibilityFrame:CGRectMake(10, 10, 30, 30)];
    self.navigationItem.leftBarButtonItem = leftButtonItem;
}

- (void) onBackBtnPressed
{
    [self.navigationController popViewControllerAnimated:YES];
}
@end
