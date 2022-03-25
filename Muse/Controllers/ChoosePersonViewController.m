 #import "ChoosePersonViewController.h"
#import <MDCSwipeToChoose/MDCSwipeToChoose.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import "AFHTTPRequestOperationManager.h"
#import "AFHTTPRequestOperation.h"
#import "Utils.h"

#import "MuseSingleton.h"
#import "LoginModel.h"
#import "Person.h"

#import "apiconstants.h"
#import "RecordsModel.h"
#import "UserData.h"

#import "ShopList.h"
#import "AppDelegate.h"
#import "DetailViewController.h"

static const CGFloat ChoosePersonButtonHorizontalPadding = 70.f;
static const CGFloat ChoosePersonButtonVerticalPadding = 20.f;

@interface ChoosePersonViewController ()

@end

@implementation ChoosePersonViewController
@synthesize indicatorView;
@synthesize arrayPeoples;
@synthesize screenSize;

#pragma mark - Object Lifecycle

- (instancetype)init {
    self = [super init];
    if (self) {
        _people = [[NSMutableArray alloc] init];
    }
    return self;
}

#pragma mark - UIViewController Overrides

- (void)viewDidLoad {
    [super viewDidLoad];
    
    screenSize = [[UIScreen mainScreen] bounds];
    
    [self.view setBackgroundColor: [UIColor colorWithRed:239.f/255.f
                                                   green:239.f/255.f
                                                    blue:239.f/255.f
                                                   alpha:1.f]];
    UIImage *myIcon = [Utils imageWithImage:[UIImage imageNamed:@"logo.png"] scaledToSize:CGSizeMake(76, 17)];
    UIImageView *titleView = [[UIImageView alloc] initWithImage:myIcon];
    [self.navigationController.navigationBar.topItem setTitleView:titleView];
    
//    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    
    arrayPeoples = [[NSMutableArray alloc] init];
    [self loadPeoples];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadPeoples) name:@"reLoadPeoples" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestLike) name:@"requestLike" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestDislike) name:@"requestDislike" object:nil];
}

- (void) loadPeoples
{
    indicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width/2-5, self.view.bounds.size.height/2- 20, 200, 200)];
    [self.view addSubview:indicatorView];
    [indicatorView sizeToFit];
    indicatorView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin);
    indicatorView.hidesWhenStopped  = YES;
    indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    indicatorView.color = [UIColor colorWithRed:255.f/255.f green:80.f/255.f blue:180.f/255.f alpha:1.0f];
    [indicatorView startAnimating];
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];

    AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    if(appDelegate.shopModelList.count == 0)
    {
        MuseSingleton* singleton = [MuseSingleton getInstance];
        LoginModel* logindata = [singleton getLoginData];
        //Get Items
        
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        [manager setResponseSerializer:[[AFJSONResponseSerializer alloc] init]];
        [manager setRequestSerializer:[[AFJSONRequestSerializer alloc] init]];
        [manager.requestSerializer setValue:[NSString stringWithFormat:@"%@ %@",@"Bearer",logindata.token] forHTTPHeaderField:@"authorization"];
        
        NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
        NSString * strApiURL = [NSString stringWithFormat:@"%@%@", iMuseBaseUrl, [NSString stringWithFormat:apiGetShopList, logindata.id]];
        //        NSLog(strApiURL);
        
        [manager GET:strApiURL parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             ShopList *shoplist = [[ShopList alloc] initWithJSONData:responseObject bFlag:0];
             [singleton setShopList:shoplist];
             
             _people = [[NSMutableArray alloc] init];
             _people = [[self defaultPeople] mutableCopy];
             
             Person *tPerson = [[Person alloc] init];
             arrayPeoples = [[NSMutableArray alloc] init];
             for (tPerson in _people)
             {
                 [arrayPeoples addObject:tPerson];
             }
             
             self.frontCardView = [self popPersonViewWithFrame:[self frontCardViewFrame] bFlag:0];
             self.frontCardView.tag = 1;
             
             [self.view addSubview:self.frontCardView];
             
             self.backCardView = [self popPersonViewWithFrame:[self backCardViewFrame] bFlag:1];
             [self.view insertSubview:self.backCardView belowSubview:self.frontCardView];
             [self constructNopeButton];
             [self constructLikedButton];
             
             [indicatorView stopAnimating];
             
         }failure:^(AFHTTPRequestOperation *operation, NSError *error)
         {
             NSLog(@"Failure! %@", error.description);
             
             UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Notification!" message:@"Server Error!" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil, nil];
             [alertView show];
             
             [indicatorView stopAnimating];
         }];
    }
    else
    {
        _people = appDelegate.shopModelList;
        
        Person *tPerson;
        arrayPeoples = [[NSMutableArray alloc] init];
        for (tPerson in _people)
        {
            [arrayPeoples addObject:tPerson];
        }
        
        self.frontCardView = [self popPersonViewWithFrame:[self frontCardViewFrame] bFlag:0];
        self.frontCardView.tag = 1;
        
        [self.view addSubview:self.frontCardView];
        
        self.backCardView = [self popPersonViewWithFrame:[self backCardViewFrame] bFlag:1];
        [self.view insertSubview:self.backCardView belowSubview:self.frontCardView];
        [self constructNopeButton];
        [self constructLikedButton];
        
        [indicatorView stopAnimating];
    }
}

- (void) reloadPeoples
{
//    NSLog(@"%d", (int)self.people.count);
//    if (arrayPeoples.count == 0)
//        [self loadPeoples];
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - MDCSwipeToChooseDelegate Protocol Methods

- (void)viewDidCancelSwipe:(UIView *)view {
//    NSLog(@"You couldn't decide on %@.", self.currentPerson.name);
}

- (void)view:(UIView *)view wasChosenWithDirection:(MDCSwipeDirection)direction {
    
    [arrayPeoples removeObjectAtIndex:0];

    MuseSingleton *singleton = [MuseSingleton getInstance];
    LoginModel *logindata = [singleton getLoginData];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager setRequestSerializer:[AFJSONRequestSerializer serializer]];
    //    [manager setResponseSerializer:[[AFJSONResponseSerializer alloc] init]];
    [manager.requestSerializer setValue:[NSString stringWithFormat:@"%@ %@",@"Bearer",logindata.token] forHTTPHeaderField:@"authorization"];
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setValue:logindata.id forKey:@"_user"];
    
    //Get Product id
    Person *tempPerson = self.frontCardView.person;
    
    [parameters setValue:tempPerson.productid forKey:@"_product"];
    
    if (direction == MDCSwipeDirectionLeft)
        [parameters setValue:@"dislike" forKey:@"status"];
    else
        [parameters setValue:@"like" forKey:@"status"];
    
    [manager POST:[NSString stringWithFormat:@"%@%@", iMuseBaseUrl, apiPostActions] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         NSLog(@"Success!");
         
     }failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSLog(@"Failure! %@", error.description);
         
         UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Notification!" message:@"Server Error!" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil, nil];
         [alertView show];
     }];
    
    self.frontCardView = self.backCardView;
    self.frontCardView.tag = 1;
    [self.frontCardView.indicatorView stopAnimating];
    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
    
    if ((self.backCardView = [self popPersonViewWithFrame:[self backCardViewFrame] bFlag:1])) {
        
        self.backCardView.alpha = 0.f;
        [self.view insertSubview:self.backCardView belowSubview:self.frontCardView];
        [UIView animateWithDuration:0.5
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             self.backCardView.alpha = 1.f;
                         } completion:nil];
        
    }
    
    if (self.people.count == 2)
    {
        MuseSingleton* singleton = [MuseSingleton getInstance];
        LoginModel* logindata = [singleton getLoginData];
        //Get Items
        
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        [manager setResponseSerializer:[[AFJSONResponseSerializer alloc] init]];
        [manager setRequestSerializer:[[AFJSONRequestSerializer alloc] init]];
        [manager.requestSerializer setValue:[NSString stringWithFormat:@"%@ %@",@"Bearer",logindata.token] forHTTPHeaderField:@"authorization"];
        
        NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
        NSString * strApiURL = [NSString stringWithFormat:@"%@%@", iMuseBaseUrl, [NSString stringWithFormat:apiGetShopList, logindata.id]];
        //        NSLog(strApiURL);
        
        [manager GET:strApiURL parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             ShopList *tempShopList = [singleton getShopList];
             NSMutableArray *tempShopDatas = [[NSMutableArray alloc] init];
             NSMutableArray *newShopDatas = [[NSMutableArray alloc] init];
             
             for (ShopDatas *tShopData in tempShopList.data)
             {
                 [tempShopDatas addObject:tShopData];
             }
             
             ShopList *shoplist = [[ShopList alloc] initWithJSONData:responseObject bFlag:0];
             for (ShopDatas *tShopData in shoplist.data)
             {
                 [tempShopDatas addObject:tShopData];
                 [newShopDatas addObject:tShopData];
             }
             tempShopList.data = tempShopDatas;
             [singleton setShopList:tempShopList];
             
             ShopProduct *shopproduct;
             ShopColor *shopcolor;
             ShopDatas *sdata;
             Person *tPerson;
             
             for (sdata in newShopDatas)
             {
                 tPerson = [[Person alloc] init];
                 shopproduct = sdata.product;
                 shopcolor = [shopproduct.color objectAtIndex:0];
                 
                 [tPerson initWithName: shopproduct.name
                                 image: [shopcolor.images objectAtIndex:0]
                             productid: shopproduct.id
                              products: shopproduct
                             brandname: [shopproduct.brand name]
                                 price: shopproduct.price
                                 token: logindata.token];
                 
                 [_people addObject:tPerson];
                 [arrayPeoples addObject:tPerson];
             }
             
         }failure:^(AFHTTPRequestOperation *operation, NSError *error)
         {
             NSLog(@"Failure! %@", error.description);
             
             UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Notification!" message:@"Server Error!" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil, nil];
             [alertView show];
             
         }];
    }
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [[event allTouches] anyObject];
    [super touchesBegan:touches withEvent:event];
    
    if ([touch view] == [self.frontCardView viewWithTag:1])
    {
        CGPoint touchLocation = [touch locationInView:self.frontCardView];
        
        if (touchLocation.x > self.frontCardView.frame.size.width/2-100 &&
            touchLocation.x < self.frontCardView.frame.size.width/2+150 &&
            touchLocation.y > self.frontCardView.frame.size.height/2-100 &&
            touchLocation.y < self.frontCardView.frame.size.height/2+150)
        {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            DetailViewController *detailViewController = [storyboard instantiateViewControllerWithIdentifier:@"detailView"];
            
            [detailViewController initWithPerson:self.frontCardView.person];
            [self.navigationController pushViewController:detailViewController animated:TRUE];
        }
        
    }

}
#pragma mark - Internal Methods

- (void)setFrontCardView:(ChoosePersonView *)frontCardView {
    _frontCardView = frontCardView;
    self.currentPerson = frontCardView.person;
    
}

- (NSArray *)defaultPeople {
  
    NSMutableArray *tempPerson = [[NSMutableArray alloc] init];
    Person *tPerson;
    MuseSingleton* singleton = [MuseSingleton getInstance];
    LoginModel *logindata = [singleton getLoginData];
    ShopList *shoplist = [singleton getShopList];
    ShopProduct *shopproduct;
    ShopColor *shopcolor;
    ShopDatas *sdata;
    
    if (arrayPeoples.count > 0)
    {
        [tempPerson addObject:[arrayPeoples objectAtIndex:0]];
        [tempPerson addObject:[arrayPeoples objectAtIndex:1]];
    }
    for (sdata in shoplist.data)
    {
        tPerson = [[Person alloc] init];
        shopproduct = sdata.product;
        shopcolor = [shopproduct.color objectAtIndex:0];
        
        [tPerson initWithName: shopproduct.name
                        image: [shopcolor.images objectAtIndex:0]
                    productid: shopproduct.id
                     products: shopproduct
                    brandname: [shopproduct.brand name]
                        price: shopproduct.price
                        token: logindata.token];
       
        [tempPerson addObject:tPerson];
    }
   
    return tempPerson;
}

- (ChoosePersonView *)popPersonViewWithFrame:(CGRect)frame bFlag:(int)bFlag {
    
    if ([self.people count] == 0)
    {
        return nil;
    }

    MDCSwipeToChooseViewOptions *options = [MDCSwipeToChooseViewOptions new];
    options.delegate = self;
    options.threshold = 160.f;
    options.onPan = ^(MDCPanState *state){
        CGRect frame = [self backCardViewFrame];
        self.backCardView.frame = CGRectMake(frame.origin.x,
                                             frame.origin.y - (state.thresholdRatio * 10.f),
                                             CGRectGetWidth(frame),
                                             CGRectGetHeight(frame));
    };

    ChoosePersonView *personView = [[ChoosePersonView alloc] initWithFrame:frame
                                                                    person:[self.people objectAtIndex:0]
                                                                   options:options];
    if (bFlag == 1)//end
    {
        [personView.indicatorView startAnimating];
        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    }
    personView.navController = self.navigationController;
    [self.people removeObjectAtIndex:0];

    return personView;

}

#pragma mark View Contruction

- (CGRect)frontCardViewFrame {
    CGFloat horizontalPadding = 20.f;
    CGFloat topPadding = 20.f;
    CGFloat bottomPadding = 130.f;
    
    return CGRectMake(horizontalPadding,
                      topPadding,
                      screenSize.size.width - (horizontalPadding * 2),
                      screenSize.size.height - bottomPadding - 64);
}

- (CGRect)backCardViewFrame {
    CGRect frontFrame = [self frontCardViewFrame];
    return CGRectMake(frontFrame.origin.x,
                      frontFrame.origin.y + 10.f,
                      CGRectGetWidth(frontFrame),
                      CGRectGetHeight(frontFrame));
}

- (void)constructNopeButton {
    
//    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    UIButton *button = [[UIButton alloc] init];
    
    UIImage *image = [UIImage imageNamed:@"delikeButton.png"];
    button.frame = CGRectMake(ChoosePersonButtonHorizontalPadding,
                              CGRectGetMaxY(self.frontCardView.frame) + ChoosePersonButtonVerticalPadding,
                              self.frontCardView.frame.size.width / 6,
                              self.frontCardView.frame.size.width / 6);
    [button setImage:image forState:UIControlStateNormal];
//    [button setTintColor:[UIColor colorWithRed:247.f/255.f
//                                         green:91.f/255.f
//                                          blue:37.f/255.f
//                                         alpha:1.f]];
    [button addTarget:self
               action:@selector(nopeFrontCardView)
     forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

- (void)constructLikedButton {

//    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    UIButton *button = [[UIButton alloc] init];
    UIImage *image = [UIImage imageNamed:@"likeButton.png"];
    button.frame = CGRectMake(CGRectGetMaxX(self.view.frame) - self.backCardView.frame.size.width / 6 - ChoosePersonButtonHorizontalPadding,
                              CGRectGetMaxY(self.backCardView.frame) + ChoosePersonButtonVerticalPadding,
                              self.backCardView.frame.size.width / 6,
                              self.backCardView.frame.size.width / 6);
    [button setImage:image forState:UIControlStateNormal];
//    [button setTintColor:[UIColor colorWithRed:29.f/255.f
//                                         green:245.f/255.f
//                                          blue:106.f/255.f
//                                         alpha:1.f]];
    [button addTarget:self
               action:@selector(likeFrontCardView)
     forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

#pragma mark Control Events

- (void) requestLike
{
    NSLog(@"Like");
    [self performSelector:@selector(likeFrontCardView) withObject:self afterDelay:0.5];
}

- (void) requestDislike
{
    NSLog(@"Dislike");
    [self performSelector:@selector(nopeFrontCardView) withObject:self afterDelay:0.5];
}

- (void)nopeFrontCardView {
    [self.frontCardView mdc_swipe:MDCSwipeDirectionLeft];
}

- (void)likeFrontCardView {
    [self.frontCardView mdc_swipe:MDCSwipeDirectionRight];
}

- (void) viewWillDisappear:(BOOL)animated
{
    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    Person *tPerson;
    
    for (tPerson in arrayPeoples)
    {
        [tempArray addObject:tPerson];
    }
    
    AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    appDelegate.shopModelList = tempArray;
//    [self.frontCardView.indicatorView stopAnimating];
}
@end
