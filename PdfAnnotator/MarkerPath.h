//
//  MakerPath.h
//  PdfAnnotator
//
//  Created by Raphael Cruzeiro on 7/16/11.
//  Copyright 2011 Raphael Cruzeiro. All rights reserved.
//

#import <Foundation/Foundation.h>

enum TextMarkerBrush {
    TextMarkerBrushYellow,
    TextMarkerBrushGreen,
    TextMarkerBrushRed,
    TextMarkerBrushBlue
};

typedef enum TextMarkerBrush TextMarkerBrush;

@interface MarkerPath : NSObject {
    TextMarkerBrush _brush;
    CGMutablePathRef _path;
}

- (id)initWithPoint:(CGPoint)point AndBrush:(TextMarkerBrush)brush;

- (void)addPoint:(CGPoint)point;

- (TextMarkerBrush)getBrush;
- (CGPathRef)getPath;

@end
