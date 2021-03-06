// Copyright (C) 2011 by Raphael Cruzeiro
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "PDFPagingViewController.h"
#import "PDFDocument.h"
#import "PDFThumbnailFactory.h"

@implementation PDFPagingViewController

@synthesize delegate;
@synthesize _document;
@synthesize thumbFactory;
@synthesize collapseButton;
@synthesize scrollView;
@synthesize pagePlaceholder;
@synthesize loading;
@synthesize buttons;

- (id)initWithDocument:(PDFDocument *)document AndObserver:(id<PDFPagingViewProtocol>)observer
{
    if((self = [super init])){
        self.delegate = observer;
        expanded = false;
        self._document = [[PDFDocument alloc] initWithDocument:document.rawDocumentPath];
        currentX = 0;
        self.thumbFactory = [[[PDFThumbnailFactory alloc] initWithPDFDocument:self._document] autorelease];
        pagePlaceholder = [[UIImage imageNamed:@"pagePlaceholder.png"] autorelease];
        loading = [[UIImage imageNamed:@"progressIndicator_roller.gif"] autorelease];
        self.buttons = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    if([scrollView.subviews count] < 6)
        return;
    
    for(UIButton *btn in buttons) {
        if([btn isKindOfClass:[UIButton class]]){
            [btn setImage:loading forState:UIControlStateNormal];
        }
    }
    
    [self loadThumbs];
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self._document loadDocumentRef];
    
    expandedFrame = CGRectMake(0, 754, 768, 270);
    collapsedFrame = CGRectMake(0, 962, 768, 270);
    
    self.view.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5];
    UIView *gradient = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 768, 270)] autorelease];
    [gradient setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"gradient.png"]]];
    [gradient setAlpha:0.5f];
    [self.view addSubview:gradient];
    
    // self.view.alpha = 0.2;
    self.view.frame = collapsedFrame;
    
    collapseButton = [UIButton buttonWithType:UIButtonTypeInfoDark];

    [collapseButton setImage:[UIImage imageNamed:@"arrowDown.png"] forState:UIControlStateNormal];
    [collapseButton addTarget:self action:@selector(toggle) forControlEvents:UIControlEventTouchDown];
    
    [collapseButton setFrame:CGRectMake(25, 7, 30, 30)];
    [collapseButton setBackgroundColor:[UIColor colorWithRed:173 green:176 blue:183 alpha:0]];
    [self.view addSubview:collapseButton];
    
    CGFloat startingX = 10;
    
    scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 50, 768, 190)];
    scrollView.delegate = self;
    scrollView.contentSize = CGSizeMake([self._document pageCount] * 130, 170);
    
    for(NSInteger i = 1 ; i <= [self._document pageCount] && i; i++) {
        
        if(i > 10) {
            UIButton * thumbButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [thumbButton setBackgroundColor:[UIColor colorWithPatternImage:pagePlaceholder]];
            [thumbButton setImage:loading forState:UIControlStateNormal];
            [thumbButton setTag:i];
            
            [thumbButton addTarget:self action:@selector(pageItemClicked:) forControlEvents:UIControlEventTouchDown];
            
            [thumbButton setFrame:CGRectMake(startingX, 0, 120, 160)];
            
            [scrollView addSubview:thumbButton];
            [buttons addObject:thumbButton];
            
            [self setLabel:startingX forIndex:i AndButtonWidth:thumbButton.frame.size.width];
            
            
            startingX += 130;
            
            continue;
        }
        
        UIImage * thumb = [thumbFactory generateThumbnailForPage:i withSize:(CGSize){116, 156}];
        
        UIButton * thumbButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [thumbButton setBackgroundColor:[UIColor colorWithPatternImage:pagePlaceholder]];
        [thumbButton setImage:thumb forState:UIControlStateNormal];
        [thumbButton setTag:i];
        
        [thumbButton addTarget:self action:@selector(pageItemClicked:) forControlEvents:UIControlEventTouchDown];
        
        [thumbButton setFrame:CGRectMake(startingX, 0, 120, 160)];
        
        [self setLabel:startingX forIndex:i AndButtonWidth:thumbButton.frame.size.width];
        
        [scrollView addSubview:thumbButton];
        [buttons addObject:buttons];
        
        startingX += thumb.size.width + 10;
    }
    
    [self._document releaseDocumentRef];
    
    [self.view addSubview:scrollView];
    
    [self expand];
}

- (void)setLabel:(CGFloat)x forIndex:(NSInteger)i AndButtonWidth:(CGFloat)width
{
    UILabel *label = [[UILabel alloc] init];
    [label setTextColor:[UIColor whiteColor]];
    [label setText:[NSString stringWithFormat:@"%d", i]];
    [label setBackgroundColor:[UIColor clearColor]];
    CGSize textSize = [[label text] sizeWithFont:[label font]];
    [label setFrame:CGRectMake(x + (width / 2) - (textSize.width / 2), 155, 40, 40)];
    [scrollView addSubview:label];
}

- (void)expand
{
    [UIView animateWithDuration:0.5 
                     delay:0 
                     options:UIViewAnimationCurveEaseOut 
                     animations:^{
                         self.view.frame = expandedFrame;
                     } 
                     completion:^(BOOL finished) {
                         expanded = true;
                     }
     ];
}

- (void)collapse
{
    [UIView animateWithDuration:0.5 
                     delay:0
                     options:UIViewAnimationCurveEaseOut 
                     animations:^{
                         self.view.frame = collapsedFrame;
                     } 
                     completion:^(BOOL finished) {
                         expanded = false;
                     }
     ];
}

- (void) toggle
{
    if(expanded) {
        [collapseButton setImage:[UIImage imageNamed:@"arrowUp.png"] forState:UIControlStateNormal];
        [self collapse];
    }
    else {
        [collapseButton setImage:[UIImage imageNamed:@"arrowDown.png"] forState:UIControlStateNormal];
        [self expand];
    }
}

- (void)pageItemClicked:(id)sender
{
    NSLog(@"Clicked %d", [((UIButton*)sender) tag]);
    [delegate pageSelected:[((UIButton*)sender) tag]];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)_scrollView willDecelerate:(BOOL)decelerate
{
        if(!decelerate)
            [self loadThumbs];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self loadThumbs];
}

- (void)loadThumbs
{
    CGFloat x = [scrollView contentOffset].x;
    
    NSInteger startingPage = x / 130;
    
    if(startingPage < 1) startingPage = 1;
    
    NSInteger endPage = startingPage +  7;
    
    NSInteger currentPage = startingPage;
    
    //if(currentPage < 7) return;
    [self._document loadDocumentRef];

    for(NSInteger i = startingPage ; currentPage <= endPage && i < endPage * 2 ; i++) {
        if ([buttons count] <= i - 1) {
            break;
        }
        
        UIButton *currentButton = [buttons objectAtIndex:i - 1];
        
        if([currentButton isKindOfClass:[UIButton class]]) {
            UIImage * thumb = [thumbFactory generateThumbnailForPage:currentPage withSize:(CGSize){116, 156}];
            [currentButton setImage:thumb forState:UIControlStateNormal];
            currentPage++;
        }
    }

    [self._document releaseDocumentRef];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.

    for(UIButton *btn in scrollView.subviews) {
        if([btn isKindOfClass:[UIButton class]]) {
            [btn release];
        }
    }
    
    [scrollView release];
    [collapseButton release];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (void)dealloc
{
    NSLog(@"%s", "Cleaning paging view...");
    
    [self.buttons release];
    [self._document release];
    
    for(UIView *v in self.scrollView.subviews){
        [v release];
    }
    
    for(UIView *v in self.view.subviews){
        [v release];
    }
    
    [super dealloc];
}
@end
