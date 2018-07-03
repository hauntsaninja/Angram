#ifndef GramTools_h
#define GramTools_h

#import <Foundation/Foundation.h>

@interface GramTools : NSObject

+ (void)buildDict:(int)level;
+ (BOOL)doesSubanagramComplete:(NSString *)sub plain:(NSString *)p gram:(NSString *)g;
+ (int)cmpWithPlain:(NSString *) p gram:(NSString*)g;
+ (NSDictionary<NSString *, NSNumber *> *)statsWithPlain:(NSString *)p gram:(NSString*)g;
+ (NSArray *)subanagramWithPlain:(NSString *)p gram:(NSString *)g filter:(NSString *)filt use:(NSString *)use;
+ (NSArray *)anagramWithPlain:(NSString *) p gram:(NSString *)g op:(NSOperation *)op exclude:(NSString *)ex gramLimit:(int) gl timeLimit:(double)tl;

@end

#endif /* GramTools_h */
