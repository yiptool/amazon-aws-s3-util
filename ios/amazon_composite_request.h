#import <Foundation/Foundation.h>

@class AmazonS3;
@class AmazonS3Request;

@interface AmazonCompositeRequest : NSObject
@property (nonatomic, retain, readonly) AmazonS3 * s3;
@property (nonatomic, retain, readonly) NSSet * requests;
@property (nonatomic, assign, readonly) int64_t bytesTotal;
@property (nonatomic, assign, readonly) int64_t bytesWritten;
@property (nonatomic, assign, readonly) float progress;
@property (nonatomic, copy) void (^ completionCallback)(BOOL);
@property (nonatomic, copy) void (^ progressCallback)(AmazonCompositeRequest *);
-(id)init;
-(id)initWithS3:(AmazonS3 *)amazonS3;
+(AmazonCompositeRequest *)request;
-(void)cancel;
-(AmazonS3Request *)uploadData:(NSData *)data forKey:(NSString *)key;
-(AmazonS3Request *)uploadData:(NSData *)data forKey:(NSString *)key bucket:(NSString *)bucket;
-(AmazonS3Request *)uploadFile:(NSString *)path forKey:(NSString *)key;
-(AmazonS3Request *)uploadFile:(NSString *)path forKey:(NSString *)key bucket:(NSString *)bucket;
@end
