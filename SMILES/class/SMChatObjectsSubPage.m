//
//  SMChatObjectsSubPage.m
//  SMILES
//
//  Created by asepmoels on 7/22/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "SMChatObjectsSubPage.h"
#import "iCarousel.h"
#import "SMPersistentObject.h"
#import "EGOImageView.h"

@interface SMChatObjectsSubPage () <iCarouselDataSource, iCarouselDelegate, SMPersistentObjectObserver>{
    IBOutlet UIView *stickerView;
    IBOutlet iCarousel *stickerCarousel;
    IBOutlet UIScrollView *stickerGroupContainer;
    IBOutlet UIPageControl *stickerPageControl;
    IBOutlet UIButton *firstButton;
    IBOutlet UIView *groupContainer;
    IBOutlet UIView *attachmentView;
    
    NSMutableArray *stickerGroupData;
    NSMutableArray *stickerData;
    NSInteger currentStickerGroup;
    StickerType currentSelectedStickerType;
    StickerType lastSelectedType;
}

-(IBAction)switchView:(id)sender;
-(IBAction)removeStickerView:(id)sender;
-(IBAction)didSelectAttachment:(id)sender;

@end

@implementation SMChatObjectsSubPage

@synthesize user, delegate;

- (void)dealloc
{
    [stickerGroupData release];
    [stickerData release];
    [super dealloc];
}

- (id)init
{
    self = [super init];
    if (self) {
        stickerData = [[NSMutableArray alloc] init];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void)reloadData{
    [self switchView:firstButton];
}

#pragma mark - Action
-(void)switchView:(UIButton *)sender{
    switch (sender.tag) {
        case 0:{
            [stickerView removeFromSuperview];
            
            CGRect frame = self.view.bounds;
            frame.origin.y = 1;
            attachmentView.frame = frame;
            
            CGSize size = frame.size;
            size.height -= 50.;
            CGFloat width = size.width / 4;
            CGFloat height = size.height / 2;
            
            int x = 0;
            int y = 0;
            for(UIButton *btn in attachmentView.subviews){
                if(x % 4 == 0){
                    y = x / 4;
                    x = x % 4;
                }
                
                CGRect frame = CGRectMake(x*width, height * y, width, height);
                btn.frame = frame;
                x++;
            }
            
            [self.view insertSubview:attachmentView belowSubview:firstButton];
            
            currentSelectedStickerType = StickerTypeAttachment;
            lastSelectedType = currentSelectedStickerType;
        }
            break;
        case 1:{
            groupContainer.hidden = YES;
            [attachmentView removeFromSuperview];
            
            CGRect frame = self.view.bounds;
            frame.origin.y = 1;
            stickerView.frame = frame;
            [self.view insertSubview:stickerView belowSubview:firstButton];
            [stickerData removeAllObjects];
            
            [stickerData addObjectsFromArray:[[SMPersistentObject sharedObject] emoticonsGrouped:YES]];
            currentSelectedStickerType = StickerTypeEmoticons;
            lastSelectedType = currentSelectedStickerType;
            
            [self updateStickerItems];
        }
            break;
        case 2:{    // Ikonia
            groupContainer.hidden = NO;
            //[attachmentView removeFromSuperview];
            
            CGRect frame = self.view.bounds;
            frame.origin.y = 1;
            stickerView.frame = frame;
            [self.view addSubview:stickerView];
            [stickerData removeAllObjects];
                    
            [stickerGroupData removeAllObjects];
            for(UIView *v in stickerGroupContainer.subviews){
                [v removeFromSuperview];
            }
            
            [[SMPersistentObject sharedObject] fetchStickerGroupWithType:StickerTypeIkoniaGroup forUser:self.user observer:self];
            currentSelectedStickerType = StickerTypeIkoniaGroup;
                        
            [self updateStickerItems];

        }
            break;
        case 3:{ // Stickers
            groupContainer.hidden = NO;
            //[attachmentView removeFromSuperview];
            
            CGRect frame = self.view.bounds;
            frame.origin.y = 1;
            stickerView.frame = frame;
            [self.view addSubview:stickerView];
            [stickerData removeAllObjects];
            
            [stickerGroupData removeAllObjects];
            for(UIView *v in stickerGroupContainer.subviews){
                [v removeFromSuperview];
            }
            
            [[SMPersistentObject sharedObject] fetchStickerGroupWithType:StickerTypeStickerGroup forUser:self.user observer:self];
            currentSelectedStickerType = StickerTypeStickerGroup;
            
            [self updateStickerItems];
        }
            break;
            
        default:
            break;
    }
    
    if(sender.tag != 3 && sender.tag != 2){
        for(UIButton *btn in self.view.subviews){
            if([btn isKindOfClass:[UIButton class]]){
                if(sender.tag == btn.tag)
                    btn.selected = YES;
                else
                    btn.selected = NO;
            }
        }
    }
}

-(void)removeStickerView:(id)sender{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    
    if(lastSelectedType == StickerTypeAttachment)
        btn.tag = 0;
    else if(lastSelectedType == StickerTypeEmoticons)
        btn.tag = 1;
    
    [self switchView:btn];
}

-(void)stickerGroupTapped:(UITapGestureRecognizer *)tap{
    int idx = (int)tap.view.tag;
    for(UIImageView *v in stickerGroupContainer.subviews){
        if(v.tag == idx){
            v.backgroundColor = [UIColor clearColor];
        }else{
            v.backgroundColor = [UIColor grayColor];
        }
    }
    
    [stickerData removeAllObjects];
    [self updateStickerItems];
    
    NSInteger groupID = [[[stickerGroupData objectAtIndex:idx] valueForKey:@"id"] integerValue];
    currentStickerGroup = groupID;
    [[SMPersistentObject sharedObject] fetchStickerWithType:StickerTypeStickerItems groupID:currentStickerGroup forUser:self.user observer:self];
}

#pragma mark - observer persistent
-(void)didFinishFetch:(NSDictionary *)info{
    StickerType type = [[info valueForKey:@"type"] intValue];
    if(type == StickerTypeStickerGroup || type == StickerTypeIkoniaGroup){
        
        if(stickerGroupData){
            [stickerGroupData removeAllObjects];
            [stickerGroupData release];
        }
        stickerGroupData = [[info valueForKey:@"result"] retain];
        
        for(UIView *v in stickerGroupContainer.subviews){
            [v removeFromSuperview];
        }
        
        for(NSInteger i=0; i<stickerGroupData.count; i++){
            NSDictionary *dict = [stickerGroupData objectAtIndex:i];
            EGOImageView *img = [[[EGOImageView alloc] initWithFrame:CGRectMake(i*stickerGroupContainer.frame.size.height+i, 0, stickerGroupContainer.frame.size.height, stickerGroupContainer.frame.size.height)] autorelease];
            img.imageURL = [NSURL URLWithString:[[dict valueForKey:@"thumb"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            img.contentMode = UIViewContentModeScaleAspectFit;
            img.backgroundColor = i==0?[UIColor clearColor]:[UIColor colorWithWhite:0.6 alpha:1.];
            img.tag = i;
            img.placeholderImage = [UIImage imageNamed:@"loading.png"];
            [stickerGroupContainer addSubview:img];
            
            UITapGestureRecognizer *tap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(stickerGroupTapped:)] autorelease];
            [img addGestureRecognizer:tap];
            img.userInteractionEnabled = YES;
        }
        
        stickerGroupContainer.contentSize = CGSizeMake(stickerGroupData.count*stickerGroupContainer.frame.size.height+stickerGroupData.count, stickerGroupContainer.frame.size.height);

        if(stickerGroupData.count > 0){
            NSInteger groupID = [[[stickerGroupData objectAtIndex:0] valueForKey:@"id"] integerValue];
            currentStickerGroup = groupID;
            
            [[SMPersistentObject sharedObject] fetchStickerWithType:type==StickerTypeStickerGroup?StickerTypeStickerItems:StickerTypeIkoniaItems groupID:groupID forUser:self.user observer:self];
        }
    }else if(type == StickerTypeStickerItems || type == StickerTypeIkoniaItems){
        NSInteger group = [[info valueForKey:@"group"] integerValue];
        
        if(group == currentStickerGroup){
            if(stickerData){
                [stickerData removeAllObjects];
                [stickerData release];
            }
            
            stickerData = [[info valueForKey:@"result"] retain];
            [self updateStickerItems];
        }
    }
}

-(void)updateStickerItems{
    stickerPageControl.currentPage = 0;
    stickerPageControl.numberOfPages = [self numberOfItemsInCarousel:stickerCarousel];
    [stickerCarousel reloadData];
}

#pragma mark - iCarousel data source dan delegate
-(void)carousel:(iCarousel *)carousel didSelectItemAtIndex:(NSInteger)index{

}

-(NSUInteger)numberOfItemsInCarousel:(iCarousel *)carousel{
    NSInteger jml = stickerData.count/8;
    if(stickerData.count % 8 > 0)
        jml++;
    
    if(currentSelectedStickerType == StickerTypeEmoticons){
        jml = stickerData.count/(4*8);
        if(stickerData.count % 4*8 > 0)
            jml++;
    }
    
    return jml;
}

-(UIView *)carousel:(iCarousel *)carousel placeholderViewAtIndex:(NSUInteger)index{
    return nil;
}

-(void)carouselCurrentItemIndexUpdated:(iCarousel *)carousel{
    stickerPageControl.currentPage = carousel.currentItemIndex;
}

-(UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index{
    if(currentSelectedStickerType == StickerTypeEmoticons){
        UIView *v = [[[UIView alloc] initWithFrame:CGRectMake(0, 1, carousel.bounds.size.width, carousel.bounds.size.height)] autorelease];
        v.clipsToBounds = YES;
        
        CGFloat width = stickerCarousel.frame.size.width / 8.;
        CGFloat height = stickerCarousel.frame.size.height / 4.;
        for(int y=0; y<4; y++){
            for(int x=0; x<8; x++){
                NSInteger idx = y*8 + x + index*4*8;
                CGRect frame = CGRectMake(x*width, y*height, width, height);
                
                if(idx < stickerData.count){
                    UIButton *button = [[[UIButton alloc] initWithFrame:frame] autorelease];
                    
                    NSDictionary *dict = [stickerData objectAtIndex:idx];
                    NSString *imgSrc = [[dict valueForKey:kTableFieldImage] stringByAppendingString:@".png"];
                    [button setImage:[UIImage imageNamed:imgSrc] forState:UIControlStateNormal];
                    button.tag = idx;
                    button.imageView.contentMode = UIViewContentModeScaleAspectFit;
                    [v addSubview:button];
                    
                    [button addTarget:self action:@selector(didSelectEmoticons:) forControlEvents:UIControlEventTouchUpInside];
                }else{
                    break;
                }
            }
        }
        
        return v;
    }else{
        UIView *v = [[[UIView alloc] initWithFrame:CGRectMake(0, 1, carousel.bounds.size.width, carousel.bounds.size.height)] autorelease];
        v.clipsToBounds = YES;
        
        CGFloat width = stickerCarousel.frame.size.width * 0.25;
        CGFloat height = stickerCarousel.frame.size.height * 0.5;
        for(int y=0; y<2; y++){
            for(int x=0; x<4; x++){
                NSInteger idx = y*4 + x + index*8;
                CGRect frame = CGRectMake(x*width, y*height, width, height);
                
                if(idx < stickerData.count){
                    EGOImageView *view = [[[EGOImageView alloc] initWithFrame:frame] autorelease];
                    NSDictionary *dict = [stickerData objectAtIndex:idx];
                    view.placeholderImage = [UIImage imageNamed:@"loading.png"];
                    view.imageURL = [NSURL URLWithString:[[dict valueForKey:@"thumb"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                    view.contentMode = UIViewContentModeScaleAspectFit;
                    view.tag = currentSelectedStickerType;
                    view.additionInfo = [dict valueForKey:@"id"];
                    view.userInteractionEnabled = YES;
                    [v addSubview:view];
                    
                    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didSelectStickerOrIkonia:)];
                    [view addGestureRecognizer:tap];
                    [tap release];
                }else{
                    break;
                }
            }
        }
        
        return v;
    }
    
    return nil;
}

-(void)didSelectStickerOrIkonia:(UITapGestureRecognizer *)tap{
    EGOImageView *imageView = (EGOImageView *)tap.view;
    
    if(delegate && [delegate respondsToSelector:@selector(chatObjectPage:didSelectItem:)]){
        [self.delegate chatObjectPage:self didSelectItem:[NSDictionary dictionaryWithObjectsAndKeys:imageView.imageURL.absoluteString, @"url", [NSNumber numberWithInt:(int)imageView.tag], @"type", imageView.additionInfo, @"id", nil]];
    }
}

-(void)didSelectEmoticons:(UIButton *)button{
    NSString *plain = [[stickerData objectAtIndex:button.tag] valueForKey:kTableFieldPlain];
    if(delegate && [delegate respondsToSelector:@selector(chatObjectPage:didSelectItem:)]){
        [self.delegate chatObjectPage:self didSelectItem:[NSDictionary dictionaryWithObjectsAndKeys:plain, @"plain", [NSNumber numberWithInt:StickerTypeEmoticons], @"type", nil]];
    }
}

-(void)didSelectAttachment:(UIButton *)sender{
    if(delegate && [delegate respondsToSelector:@selector(chatObjectPage:didSelectItem:)]){
        [self.delegate chatObjectPage:self didSelectItem:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:(int)sender.tag], @"tag", [NSNumber numberWithInt:StickerTypeAttachment], @"type", nil]];
    }
}

@end
