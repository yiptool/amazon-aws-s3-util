#import "amazon_composite_request.h"
#import "amazon_s3.h"

@implementation AmazonCompositeRequest

@synthesize s3;
@synthesize requests;
@synthesize bytesTotal;
@synthesize bytesWritten;
@synthesize progress;
@synthesize completionCallback;
@synthesize progressCallback;

-(id)init
{
	return [self initWithS3:[AmazonS3 sharedInstance]];
}

-(id)initWithS3:(AmazonS3 *)amazonS3
{
	self = [super init];
	if (self)
	{
		s3 = [amazonS3 retain];
		requests = [[NSMutableSet alloc] init];
	}
	return self;
}

-(void)dealloc
{
	[s3 release];
	s3 = nil;

	[requests release];
	requests = nil;

	[super dealloc];
}

+(AmazonCompositeRequest *)request
{
	return [[[AmazonCompositeRequest alloc] init] autorelease];
}

-(void)cancel
{
	for (AmazonS3Request * request in requests)
		[request cancel];
	[(NSMutableSet *)requests removeAllObjects];
}

-(AmazonS3Request *)uploadData:(NSData *)data forKey:(NSString *)key
{
	__block AmazonS3Request * request = [s3 uploadData:data forKey:key
		completion:^(BOOL success) { [self onRequestComplete:request success:success]; }];
	request.progressCallback = ^(AmazonS3Request * request) { [self onRequestProgress:request]; };
	[(NSMutableSet *)requests addObject:request];
	return request;
}

-(AmazonS3Request *)uploadData:(NSData *)data forKey:(NSString *)key bucket:(NSString *)bucket
{
	__block AmazonS3Request * request = [s3 uploadData:data forKey:key bucket:bucket
		completion:^(BOOL success) { [self onRequestComplete:request success:success]; }];
	request.progressCallback = ^(AmazonS3Request * request) { [self onRequestProgress:request]; };
	[(NSMutableSet *)requests addObject:request];
	return request;
}

-(AmazonS3Request *)uploadFile:(NSString *)path forKey:(NSString *)key
{
	__block AmazonS3Request * request = [s3 uploadFile:path forKey:key
		completion:^(BOOL success) { [self onRequestComplete:request success:success]; }];
	request.progressCallback = ^(AmazonS3Request * request) { [self onRequestProgress:request]; };
	[(NSMutableSet *)requests addObject:request];
	return request;
}

-(AmazonS3Request *)uploadFile:(NSString *)path forKey:(NSString *)key bucket:(NSString *)bucket
{
	__block AmazonS3Request * request = [s3 uploadFile:path forKey:key bucket:bucket
		completion:^(BOOL success) { [self onRequestComplete:request success:success]; }];
	request.progressCallback = ^(AmazonS3Request * request) { [self onRequestProgress:request]; };
	[(NSMutableSet *)requests addObject:request];
	return request;
}

-(void)onRequestComplete:(AmazonS3Request *)request success:(BOOL)success
{
	[(NSMutableSet *)requests removeObject:request];

	if (!success)
		[self cancel];

	if (requests.count == 0)
	{
		if (completionCallback)
			completionCallback(success);
	}
}

-(void)onRequestProgress:(AmazonS3Request *)request
{
	bytesTotal = 0;
	bytesWritten = 0;
	progress = 0.0f;

	for (AmazonS3Request * request in requests)
	{
		bytesTotal += request.bytesTotal;
		bytesWritten += request.bytesWritten;
		progress += request.progress;
	}

	if (requests.count > 0)
		progress /= (float)requests.count;

	if (progressCallback)
		progressCallback(self);
}

@end
