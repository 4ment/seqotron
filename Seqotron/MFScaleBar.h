//
//  MFScaleBar.h
//  Seqotron
//
//  Created by Mathieu Fourment on 17/02/2015.
//  Copyright (c) 2015 Mathieu Fourment. All rights reserved.
//
//  This file is part of Seqotron.
//
//  Seqotron is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Seqotron is distributed in the hope that it will be useful,
//  but Seqotron ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Seqotron.  If not, see <http://www.gnu.org/licenses/>.
//

#import "MFGraphic.h"

#import "MFTextGraphic.h"
#import "MFLineGraphic.h"

@interface MFScaleBar : MFGraphic{
    MFLineGraphic *_bar;
    MFTextGraphic *_legend;
    
    CGFloat _scaleBarSpace; // space between text and bar in pixels
}

@property (retain)MFLineGraphic *bar;
@property (retain)MFTextGraphic *legend;

@end
