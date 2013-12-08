//
//  FilesTableViewCell.h
//  Manta
//
//  Created by Dave Eddy on 12/7/13.
//  Copyright (c) 2013 Dave Eddy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FilesTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *mtimeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@end
