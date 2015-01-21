//
//  SMRegisterPage.m
//  SMILES
//
//  Created by asepmoels on 7/4/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "SMRegisterPage.h"
#import "SMVerificationPage.h"
#import "ASIHTTPRequest.h"
#import "SMAppConfig.h"
#import "DDXML.h"
#import "MBProgressHUD.h"

@interface SMRegisterPage () <ASIHTTPRequestDelegate, UITableViewDataSource, UITableViewDelegate, MBProgressHUDDelegate>{
    NSMutableArray *countryArray;
    IBOutlet UIView *comboView;
    IBOutlet UILabel *codeLabel;
    IBOutlet UIButton *codeButton;
    IBOutlet UITextField *phoneNumber;
    IBOutlet UITableView *table;
    IBOutlet UIView *contentView;
    IBOutlet UIScrollView *scrollView;
    
    MBProgressHUD *loading;
    CGRect originalScrollViewFrame;
    NSInteger selectedCountry;
}

-(IBAction)next:(id)sender;
-(IBAction)countryCode:(id)sender;
-(IBAction)hideKeyboard:(id)sender;
-(IBAction)back:(id)sender;
-(IBAction)showExample:(id)sender;

@end

@implementation SMRegisterPage

- (void)dealloc
{
    [countryArray release];
    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    
    countryArray = [[NSMutableArray alloc] init];
    
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:kURLCountryCode]];
    request.delegate = self;
    [request startAsynchronous];
    
    [self.view addSubview:comboView];
    comboView.hidden = YES;
    comboView.frame = self.view.bounds;
    
    [scrollView addSubview:contentView];
    scrollView.contentSize = contentView.frame.size;
    
    selectedCountry = -1;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    originalScrollViewFrame = scrollView.frame;
}

-(void)viewDidUnload{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - penanganan keyboard
-(void)keyboardDidShow:(NSDictionary *)info{
    NSDictionary *userInfo = [info valueForKey:@"userInfo"];
    CGRect keyboardRect = [[userInfo valueForKey:@"UIKeyboardFrameEndUserInfoKey"] CGRectValue];

    CGRect frame = scrollView.frame;
    frame.size.height = keyboardRect.origin.y - frame.origin.y - 20;
    scrollView.frame = frame;
}

-(void)keyboardDidHide:(id)info{
    scrollView.frame = originalScrollViewFrame;
}

#pragma mark - Action
-(void)next:(id)sender{
    [self hideKeyboard:nil];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"[0-9]{6,14}"];
    if(![predicate evaluateWithObject:phoneNumber.text]){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Please insert the valid phone number." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [alert release];
        return;
    }
    if(selectedCountry < 0){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Please select the country code." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [alert release];
        return;
    }
    
    SMVerificationPage *page = [[SMVerificationPage alloc] init];
    page.phoneNumber = [NSString stringWithFormat:@"%@%@", codeLabel.text, phoneNumber.text];
    
    NSDictionary *dict = [countryArray objectAtIndex:selectedCountry];
    page.country = [dict valueForKey:@"abbrev"];
    
    [self.navigationController pushViewController:page animated:YES];
    [page release];
}

-(void)countryCode:(id)sender{
    [table reloadData];
    comboView.hidden = NO;
    [self hideKeyboard:nil];
}

-(void)hideKeyboard:(id)sender{
    [phoneNumber resignFirstResponder];
}

-(void)back:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)showExample:(id)sender{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Example Phone Number" message:@"8135077239" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    [alert release];
}

#pragma mark - delegate AsiHTTP
-(void)requestStarted:(ASIHTTPRequest *)request{
    loading = [[MBProgressHUD showHUDAddedTo:self.view animated:YES] retain];
    loading.mode = MBProgressHUDModeIndeterminate;
    loading.delegate = self;
    loading.labelText = @"Loading..";
}

-(void)requestFinished:(ASIHTTPRequest *)request{
    [countryArray removeAllObjects];
    
    NSString *response = [request responseString];
    DDXMLDocument *doc = [[DDXMLDocument alloc] initWithXMLString:response options:0 error:nil];
    DDXMLElement *content = [doc rootElement];
    NSArray *array = [content children];
    for(DDXMLElement *one in array){
        NSString *abbrev = [one name];
        NSString *name = [[[one elementsForName:@"NAME"] objectAtIndex:0] stringValue];
        NSString *code = [[[one elementsForName:@"PREFIX"] objectAtIndex:0] stringValue];
        
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:abbrev, @"abbrev", name, @"name", code, @"code", nil];
        [countryArray addObject:dict];
    }
    [table reloadData];
    [loading hide:YES];
    
    
    NSLocale *locale = [NSLocale currentLocale];
    NSString *countryCode = [locale objectForKey: NSLocaleCountryCode];
    NSString *countryName = [locale displayNameForKey:NSLocaleCountryCode value:countryCode];
    
    int row = -1;
    for (int i=0; i<[countryArray count]; i++) {
        NSDictionary *dict = [countryArray objectAtIndex:i];
        if ([countryName isEqualToString:[dict objectForKey:@"name"]]) {
            row = i;
            break;
        }
    }
    
    if (row != -1) {
        NSDictionary *dict = [countryArray objectAtIndex:row];
        codeLabel.text = [NSString stringWithFormat:@"+%@", [dict valueForKey:@"code"]];
        [codeButton setTitle:[dict valueForKey:@"name"] forState:UIControlStateNormal];
    }
}

-(void)requestFailed:(ASIHTTPRequest *)request{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Check Your Internet Connection." message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    [alert release];
    [loading hide:YES];
}

#pragma mark - delegate ProgressHUD
-(void)hudWasHidden:(MBProgressHUD *)hud{
    [hud removeFromSuperview];
    [loading release];
    loading = nil;
}

#pragma mark - table view delegate dan data source
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return countryArray.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 32.;
}

-(UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellIdentifier = @"CountryCellIdentifier";
    
    UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if(!cell){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.textLabel.font = [UIFont systemFontOfSize:14.];
    }
    
    NSDictionary *dict = [countryArray objectAtIndex:indexPath.row];
    cell.textLabel.text = [dict valueForKey:@"name"];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    comboView.hidden = YES;
    selectedCountry = indexPath.row;
    
    NSDictionary *dict = [countryArray objectAtIndex:indexPath.row];
    codeLabel.text = [NSString stringWithFormat:@"+%@", [dict valueForKey:@"code"]];
    [codeButton setTitle:[dict valueForKey:@"name"] forState:UIControlStateNormal];
}

@end
