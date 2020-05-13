//
//  NSString+DSDemo.m
//  HTTPNetworkDemo
//
//  Created by DelpanSun on 2020/5/12.
//  Copyright © 2020 DelpanSun. All rights reserved.
//

#import "NSString+DSDemo.h"

@implementation NSString (DSDemo)

- (NSString *)ds_stringByURLEncode
{
    static NSString *const charactersGeneralDelimitersToEncode = @":#[]@";
    static NSString *const charactersSubDelimitersToEncode = @"!$&'()*+,;=";
    
    NSMutableCharacterSet *allowedCharacterSet = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
    [allowedCharacterSet removeCharactersInString:[charactersGeneralDelimitersToEncode stringByAppendingString:charactersSubDelimitersToEncode]];
    static NSUInteger const batchSize = 50;
    
    NSUInteger index = 0;
    NSMutableString *escaped = @"".mutableCopy;
    
    while (index < self.length)
    {
        NSUInteger length = MIN(self.length - index, batchSize);
        NSRange range = NSMakeRange(index, length);
        
        range = [self rangeOfComposedCharacterSequencesForRange:range];
        
        NSString *substring = [self substringWithRange:range];
        NSString *encoded = [substring stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet];
        [escaped appendString:encoded];
        
        index += range.length;
    }
    
    return escaped;
}

@end
