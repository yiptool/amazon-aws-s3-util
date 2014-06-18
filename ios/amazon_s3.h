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
#import <Foundation/Foundation.h>
#import <AWSS3/AWSS3.h>

@class AmazonS3Client;

@interface AmazonS3Request : NSObject<AmazonServiceRequestDelegate>
@property (nonatomic, retain, readonly) S3TransferOperation * transferOperation;
@property (nonatomic, assign, readonly) int64_t bytesWritten;
@property (nonatomic, assign, readonly) int64_t bytesTotal;
@property (nonatomic, assign, readonly) float percentCompleted;
@property (nonatomic, copy) void (^ progressCallback)(AmazonS3Request *);
-(id)initWithTransferManager:(S3TransferManager *)manager putRequest:(S3PutObjectRequest *)request
	completion:(void(^)(BOOL))completion;
-(void)cancel;
@end

@interface AmazonS3 : AmazonS3Client
@property (nonatomic, retain, readonly) S3TransferManager * transferManager;
@property (nonatomic, copy) NSString * defaultBucket;
-(id)initWithAccessKey:(NSString *)accessKey secretKey:(NSString *)secretKey;
-(id)initWithAccessKey:(NSString *)accessKey secretKey:(NSString *)secretKey defaultBucket:(NSString *)bucket;
+(AmazonS3 *)sharedInstance;
+(void)initWithAccessKey:(NSString *)accessKey secretKey:(NSString *)secretKey;
+(void)initWithAccessKey:(NSString *)accessKey secretKey:(NSString *)secretKey defaultBucket:(NSString *)bucket;
-(AmazonS3Request *)uploadFile:(NSString *)path forKey:(NSString *)key completion:(void(^)(BOOL))completion;
-(AmazonS3Request *)uploadFile:(NSString *)path forKey:(NSString *)key bucket:(NSString *)bucket
	completion:(void(^)(BOOL))cb;
+(AmazonS3Request *)uploadFile:(NSString *)path forKey:(NSString *)key completion:(void(^)(BOOL))completion;
+(AmazonS3Request *)uploadFile:(NSString *)path forKey:(NSString *)key bucket:(NSString *)bucket
	completion:(void(^)(BOOL))completion;
-(NSURL *)urlForKey:(NSString *)key;
-(NSURL *)urlForKey:(NSString *)key bucket:(NSString *)bucket;
-(NSURL *)urlForKey:(NSString *)key bucket:(NSString *)bucket expiresIn:(NSTimeInterval)expires;
+(NSURL *)urlForKey:(NSString *)key;
+(NSURL *)urlForKey:(NSString *)key bucket:(NSString *)bucket;
+(NSURL *)urlForKey:(NSString *)key bucket:(NSString *)bucket expiresIn:(NSTimeInterval)expires;
@end
