/* vim: set ai noet ts=4 sw=4 tw=115: */
//
// Copyright (c) 2014 Nikolay Zapolnov (zapolnov@gmail.com).
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
//
#import "amazon_s3.h"

static AmazonS3 * g_Instance;

@interface AmazonS3Request ()
@property (nonatomic, copy, readonly) void (^ uploadCompletion)(BOOL);
@end

@implementation AmazonS3Request

@synthesize transferOperation;
@synthesize bytesWritten;
@synthesize bytesTotal;
@synthesize percentCompleted;
@synthesize uploadCompletion;
@synthesize progressCallback;

-(id)initWithTransferManager:(S3TransferManager *)manager putRequest:(S3PutObjectRequest *)request
	completion:(void(^)(BOOL))completion
{
	self = [super init];
	if (self)
	{
		uploadCompletion = [completion copy];
		request.delegate = self;
		transferOperation = [[manager upload:request] retain];
	}
	return self;
}

-(void)dealloc
{
	[uploadCompletion release];
	uploadCompletion = nil;

	[progressCallback release];
	progressCallback = nil;

	[transferOperation release];
	transferOperation = nil;

	[super dealloc];
}

-(void)cancel
{
	[transferOperation cancel];
}

-(void)request:(AmazonServiceRequest *)request didCompleteWithResponse:(AmazonServiceResponse *)response
{
	BOOL success = YES;

	if (!response.exception)
		NSLog(@"Amazon request %@ has completed successfully!", request);
	else
	{
		success = NO;
		NSLog(@"Amazon request %@ has completed with exception: %@", request, response.exception);
	}

	if (uploadCompletion)
		uploadCompletion(success);

	request.delegate = nil;
	[self release];
}

-(void)request:(AmazonServiceRequest *)request didFailWithError:(NSError *)error
{
	NSLog(@"Amazon request %@ has failed with error: %@", request, error);

	if (uploadCompletion)
		uploadCompletion(NO);

	request.delegate = nil;
	[self release];
}

-(void)request:(AmazonServiceRequest *)request didFailWithServiceException:(NSException *)exception
{
	NSLog(@"Amazon request %@ has failed with exception: %@", request, exception);

	if (uploadCompletion)
		uploadCompletion(NO);

	request.delegate = nil;
	[self release];
}

-(void)request:(AmazonServiceRequest *)request didReceiveData:(NSData *)data
{
}

-(void)request:(AmazonServiceRequest *)request didReceiveResponse:(NSURLResponse *)response
{
}

-(void)request:(AmazonServiceRequest *)request didSendData:(long long)written
	totalBytesWritten:(long long)totalWritten totalBytesExpectedToWrite:(long long)totalBytes
{
	bytesWritten = totalWritten;
	bytesTotal = totalBytes;
	percentCompleted = float(double(bytesWritten) / double(bytesTotal) * 100.0);

	NSLog(@"Progress for amazon request %@: %.1f%%", request, percentCompleted);

	if (progressCallback)
		progressCallback(self);
}

@end

@implementation AmazonS3

@synthesize transferManager;
@synthesize defaultBucket;

-(id)initWithAccessKey:(NSString *)accessKey secretKey:(NSString *)secretKey
{
	return [self initWithAccessKey:accessKey secretKey:secretKey defaultBucket:nil];
}

-(id)initWithAccessKey:(NSString *)accessKey secretKey:(NSString *)secretKey defaultBucket:(NSString *)bucket
{
	self = [super initWithAccessKey:accessKey withSecretKey:secretKey];
	if (self)
	{
		transferManager = [S3TransferManager new];
		self.defaultBucket = bucket;
	}
	return self;
}

-(void)dealloc
{
	self.defaultBucket = nil;

	[transferManager release];
	transferManager = nil;

	[super dealloc];
}

+(AmazonS3 *)sharedInstance
{
	return g_Instance;
}

+(void)initWithAccessKey:(NSString *)accessKey secretKey:(NSString *)secretKey
{
	[g_Instance release];
	g_Instance = nil;
	g_Instance = [[AmazonS3 alloc] initWithAccessKey:accessKey secretKey:secretKey];
}

+(void)initWithAccessKey:(NSString *)accessKey secretKey:(NSString *)secretKey defaultBucket:(NSString *)bucket
{
	[g_Instance release];
	g_Instance = nil;
	g_Instance = [[AmazonS3 alloc] initWithAccessKey:accessKey secretKey:secretKey defaultBucket:bucket];
}


-(AmazonS3Request *)uploadData:(NSData *)data forKey:(NSString *)key completion:(void(^)(BOOL))completion
{
	return [self uploadData:data forKey:key bucket:defaultBucket completion:completion];
}

-(AmazonS3Request *)uploadData:(NSData *)data forKey:(NSString *)key bucket:(NSString *)bucket
	completion:(void(^)(BOOL))cb
{
	S3PutObjectRequest * request = [[[S3PutObjectRequest alloc] initWithKey:key inBucket:bucket] autorelease];
	request.data = data;
	return [[AmazonS3Request alloc] initWithTransferManager:transferManager putRequest:request completion:cb];
}

+(AmazonS3Request *)uploadData:(NSData *)data forKey:(NSString *)key completion:(void(^)(BOOL))completion
{
	return [[AmazonS3 sharedInstance] uploadData:data forKey:key completion:completion];
}

+(AmazonS3Request *)uploadData:(NSData *)data forKey:(NSString *)key bucket:(NSString *)bucket
	completion:(void(^)(BOOL))completion
{
	return [[AmazonS3 sharedInstance] uploadData:data forKey:key bucket:bucket completion:completion];
}

-(AmazonS3Request *)uploadFile:(NSString *)path forKey:(NSString *)key completion:(void(^)(BOOL))completion
{
	return [self uploadFile:path forKey:key bucket:defaultBucket completion:completion];
}

-(AmazonS3Request *)uploadFile:(NSString *)path forKey:(NSString *)key bucket:(NSString *)bucket
	completion:(void(^)(BOOL))cb
{
	S3PutObjectRequest * request = [[[S3PutObjectRequest alloc] initWithKey:key inBucket:bucket] autorelease];
	request.filename = path;
	return [[AmazonS3Request alloc] initWithTransferManager:transferManager putRequest:request completion:cb];
}

+(AmazonS3Request *)uploadFile:(NSString *)path forKey:(NSString *)key completion:(void(^)(BOOL))completion
{
	return [[AmazonS3 sharedInstance] uploadFile:path forKey:key completion:completion];
}

+(AmazonS3Request *)uploadFile:(NSString *)path forKey:(NSString *)key bucket:(NSString *)bucket
	completion:(void(^)(BOOL))completion
{
	return [[AmazonS3 sharedInstance] uploadFile:path forKey:key bucket:bucket completion:completion];
}

-(NSURL *)urlForKey:(NSString *)key
{
	return [self urlForKey:key bucket:defaultBucket expiresIn:(NSTimeInterval)600];
}

-(NSURL *)urlForKey:(NSString *)key bucket:(NSString *)bucket
{
	return [self urlForKey:key bucket:bucket expiresIn:(NSTimeInterval)600];
}

-(NSURL *)urlForKey:(NSString *)key bucket:(NSString *)bucket expiresIn:(NSTimeInterval)expires
{
	S3GetPreSignedURLRequest * url = [[[S3GetPreSignedURLRequest alloc] init] autorelease];
	url.key = key;
	url.bucket = bucket;
	url.expires = [NSDate dateWithTimeIntervalSinceNow:expires];
	return [self getPreSignedURL:url];
}

+(NSURL *)urlForKey:(NSString *)key
{
	return [[AmazonS3 sharedInstance] urlForKey:key];
}

+(NSURL *)urlForKey:(NSString *)key bucket:(NSString *)bucket
{
	return [[AmazonS3 sharedInstance] urlForKey:key bucket:bucket];
}

+(NSURL *)urlForKey:(NSString *)key bucket:(NSString *)bucket expiresIn:(NSTimeInterval)expires
{
	return [[AmazonS3 sharedInstance] urlForKey:key bucket:bucket expiresIn:expires];
}

@end
